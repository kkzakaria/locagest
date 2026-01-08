# Research: Module Baux (Lease Management)

**Feature**: 005-lease-management
**Date**: 2026-01-08

## Executive Summary

This document consolidates research findings for implementing the Lease Management module. All technical unknowns have been resolved based on analysis of existing codebase patterns (tenants, units, buildings modules) and project constitution requirements.

---

## 1. Rent Schedule Generation Strategy

### Decision
Generate rent schedules at lease creation time using Flutter/Dart business logic, storing all generated schedules in the `rent_schedules` table.

### Rationale
- **Consistency**: Follows existing pattern where business logic resides in Dart code, not PostgreSQL functions
- **Testability**: Schedule generation logic can be unit tested in Dart
- **Flexibility**: Easy to modify generation rules without database migrations
- **Offline support**: Future offline mode can pre-generate schedules

### Alternatives Considered
| Alternative | Rejected Because |
|-------------|------------------|
| PostgreSQL trigger on lease insert | Complex to maintain, harder to test, less flexible |
| Supabase Edge Function | Additional infrastructure, not used in existing modules |
| Generate on-demand | Would require recalculation each time, performance overhead |

### Implementation Notes
- Generate schedules for each month from `start_date` to `end_date`
- For open-ended leases (no end_date), generate 12 months initially
- Pro-rate first month if `start_date` is not the 1st
- Handle month boundaries (payment_day > days in month → use last day)

---

## 2. Unit Status Update Strategy

### Decision
Update unit status via explicit repository method call after successful lease creation/termination, not via database trigger.

### Rationale
- **Explicitness**: Business logic is visible in Dart code
- **Control**: Can handle edge cases (e.g., maintenance units) explicitly
- **Transactions**: Can rollback if status update fails
- **Existing pattern**: Unit module already exposes `updateUnitStatus()` method

### Alternatives Considered
| Alternative | Rejected Because |
|-------------|------------------|
| PostgreSQL trigger on lease status change | Implicit behavior, harder to debug |
| Supabase real-time subscription | Eventual consistency, not immediate |

### Implementation Notes
- After lease creation: `unitRepository.updateUnitStatus(unitId, 'occupied')`
- After lease termination: `unitRepository.updateUnitStatus(unitId, 'vacant')`
- Handle case where unit was in 'maintenance' → warn but allow lease creation

---

## 3. Lease Status Transitions

### Decision
Implement as an enum with explicit transition rules validated in Dart.

### Statuses
| Status | Description | Next Valid States |
|--------|-------------|-------------------|
| `pending` | Lease created but not yet active (future start date) | `active`, `terminated` |
| `active` | Currently running lease | `terminated`, `expired` |
| `terminated` | Ended early by user action | (final state) |
| `expired` | End date passed naturally | (final state) |

### Rationale
- **Clear states**: Matches business reality (Ivory Coast rental contracts)
- **Explicit transitions**: Prevents invalid state changes
- **Existing pattern**: Similar to unit status (vacant/occupied/maintenance)

### Implementation Notes
- `pending` → `active`: Automatic when `start_date <= today` (or via batch job / app launch check)
- `active` → `expired`: Automatic when `end_date < today` (batch job / app launch check)
- Manual termination always available for `pending` and `active` leases

---

## 4. Pro-Rata Calculation for Partial Months

### Decision
Use simple daily rate calculation: `(monthly_rent / 30) * days_in_period`

### Rationale
- **Simplicity**: Easy to understand and explain to users
- **Industry standard**: Common practice in Ivory Coast rental market
- **Predictability**: Always uses 30 days regardless of actual month length

### Alternatives Considered
| Alternative | Rejected Because |
|-------------|------------------|
| Actual days in month | More complex, minimal benefit |
| No pro-rata (full month) | Unfair to tenant for mid-month starts |
| Bi-weekly schedules | Over-engineering for monthly rental market |

### Implementation Notes
- First month: `days = days_remaining_in_month` from start_date
- Last month (if lease ends mid-month): `days = day_of_end_date`
- Formula: `prorated_amount = (rent_amount + charges_amount) / 30 * days`

---

## 5. Lease Form: Tenant/Unit Selection

### Decision
Use dropdown pickers with search capability for selecting tenant and unit.

### Rationale
- **Existing pattern**: Building selection in unit form uses similar dropdown
- **User experience**: Managers can quickly search by name/reference
- **Validation**: Only shows valid options (existing tenants, vacant units for new leases)

### Implementation Notes
- Tenant picker: Search by name, show phone number
- Unit picker: Filter by building (optional), show only vacant units for new lease
- Pre-populate if navigating from tenant or unit detail page
- Display selected item with full info card

---

## 6. Database Foreign Key Constraints

### Decision
Use `ON DELETE RESTRICT` for tenant and unit references in leases.

### Rationale
- **Data integrity**: Cannot delete a tenant with active leases
- **Business rule**: Lease records are legal documents, must be preserved
- **Existing pattern**: Similar to units referencing buildings

### Schema
```sql
tenant_id UUID REFERENCES tenants(id) ON DELETE RESTRICT,
unit_id UUID REFERENCES units(id) ON DELETE RESTRICT
```

### Implementation Notes
- Check for active leases before allowing tenant/unit deletion
- Provide clear error message: "Ce locataire a des baux actifs"
- Terminated leases still prevent deletion (historical records)

---

## 7. Rent Schedule Status Management

### Decision
Schedule statuses derived from payment data, stored in column for query efficiency.

### Statuses
| Status | Condition |
|--------|-----------|
| `pending` | `amount_paid = 0` AND `due_date > today` |
| `partial` | `0 < amount_paid < amount_due` |
| `paid` | `amount_paid >= amount_due` |
| `overdue` | `amount_paid < amount_due` AND `due_date < today` |

### Rationale
- **Query efficiency**: Can filter by status without calculating
- **Real-time updates**: Trigger updates status when payment recorded (Phase 8)
- **Dashboard needs**: Must quickly identify overdue schedules

### Implementation Notes
- Status column with CHECK constraint
- Trigger to update status when payment added (Phase 8)
- Initial status is `pending` for all generated schedules
- Batch job (or app launch) to mark `overdue` for past-due unpaid schedules

---

## 8. Lease Termination Workflow

### Decision
Two-step process: termination modal → confirmation → process termination.

### Workflow
1. User clicks "Résilier le bail" button
2. Modal appears with:
   - Termination date picker (default: today, cannot be in future)
   - Termination reason dropdown (départ locataire, impayés, fin de bail, autre)
   - Optional notes text field
3. User confirms → system:
   - Updates lease status to `terminated`
   - Sets `termination_date` and `termination_reason`
   - Updates unit status to `vacant`
   - Cancels future unpaid rent schedules (set status to `cancelled`)

### Rationale
- **Confirmation required**: Termination is irreversible
- **Audit trail**: Date and reason preserved for records
- **Clean data**: Future schedules cancelled to avoid confusion

### Implementation Notes
- Modal as separate widget (`termination_modal.dart`)
- Use existing confirmation dialog pattern from delete actions
- Navigate back to leases list after successful termination

---

## 9. Integration Points

### Tenant Detail Page
- Add "Baux" section showing all leases for tenant
- Show active lease prominently at top
- Historical leases in collapsible list
- Quick action: "Nouveau bail" button (navigates to lease form with tenant pre-selected)

### Unit Detail Page
- Add "Bail actif" section (if occupied)
- Show current lease summary: tenant name, rent, start date, end date
- Historical leases in collapsible list
- Quick action: "Créer un bail" button (only if vacant)

### Building Detail Page
- Show count of active leases vs total units
- Optional: list of units with lease status

---

## 10. Search and Filtering

### Decision
Implement client-side filtering with server-side search fallback for large datasets.

### Filters
| Filter | Type | Values |
|--------|------|--------|
| Status | Multi-select | pending, active, terminated, expired |
| Building | Dropdown | All buildings |
| Date range | Date picker | Start date range |

### Search
- Search by tenant name (first + last)
- Search by unit reference
- Full-text search via PostgreSQL `to_tsvector`

### Implementation Notes
- Initial load: all leases (paginated)
- Client-side filter for status (fast, small dataset)
- Server-side search for text queries
- Reset filters shows all leases

---

## Summary of Key Decisions

| Topic | Decision |
|-------|----------|
| Schedule generation | Dart code at lease creation |
| Unit status update | Explicit repository call |
| Lease statuses | pending → active → terminated/expired |
| Pro-rata calculation | 30-day month basis |
| Tenant/Unit selection | Searchable dropdown pickers |
| Foreign keys | ON DELETE RESTRICT |
| Schedule statuses | Stored column, trigger-updated |
| Termination | Two-step modal with confirmation |
| Integration | Sections in tenant/unit detail pages |
| Search/Filter | Client-side filter, server-side search |
