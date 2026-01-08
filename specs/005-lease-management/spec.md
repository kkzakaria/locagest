# Feature Specification: Module Baux (Lease Management)

**Feature Branch**: `005-lease-management`
**Created**: 2026-01-08
**Status**: Draft
**Input**: User description: "Implement lease module (Phase 7) from PLAN-DEV-LocaGest.md - managing rental contracts between tenants and units with automatic schedule generation"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create a New Lease (Priority: P1)

As a property manager (gestionnaire), I need to create a lease contract linking a tenant to a rental unit, specifying rent amount, duration, and payment terms, so that I can formalize the rental agreement and track payment obligations.

**Why this priority**: This is the core functionality of the lease module. Without the ability to create leases, no other lease-related features can work. A lease is the fundamental link between a tenant and a unit.

**Independent Test**: Can be fully tested by creating a lease for an existing tenant and vacant unit, verifying the lease appears in both tenant and unit details, and confirming the unit status changes to "occupied".

**Acceptance Scenarios**:

1. **Given** a vacant unit and an existing tenant, **When** I fill in the lease form with start date, rent amount, deposit, and payment day, **Then** a new lease is created, the unit status becomes "occupied", and the lease appears in both tenant and unit views.

2. **Given** a unit that is already occupied (has an active lease), **When** I attempt to create a new lease for that unit, **Then** the system prevents the creation and displays an error message "Ce lot a déjà un bail actif".

3. **Given** a lease creation form, **When** I submit without required fields (start date, rent amount, tenant, unit), **Then** the system displays validation errors for each missing field.

4. **Given** a lease with an end date, **When** the lease is created, **Then** monthly rent schedules (échéances) are automatically generated from start date to end date.

5. **Given** a lease without an end date (open-ended), **When** the lease is created, **Then** rent schedules are generated for the next 12 months, with ability to generate more later.

---

### User Story 2 - View Lease Details (Priority: P1)

As a property manager, I need to view all details of a lease including payment history, current balance, and lease terms, so that I can monitor the rental relationship and make informed decisions.

**Why this priority**: Viewing lease information is essential for day-to-day property management operations. Managers need quick access to lease terms and payment status.

**Independent Test**: Can be fully tested by navigating to a lease from a unit or tenant detail page and verifying all lease information is displayed correctly.

**Acceptance Scenarios**:

1. **Given** an existing active lease, **When** I navigate to the lease detail page, **Then** I see: tenant name, unit reference, start/end dates, rent amount, charges, deposit status, payment day, and current balance.

2. **Given** a lease with payment history, **When** I view the lease detail, **Then** I see a summary of paid/unpaid schedules and total amounts.

3. **Given** I am on a tenant detail page, **When** I look at the lease section, **Then** I see all current and past leases for that tenant with quick navigation.

4. **Given** I am on a unit detail page, **When** I look at the lease section, **Then** I see the current active lease (if any) and lease history.

---

### User Story 3 - Edit Lease Information (Priority: P2)

As a property manager, I need to modify lease terms (such as rent amount during annual revision), so that I can keep the lease information current and accurate.

**Why this priority**: Lease modifications are common (annual rent increases, contract extensions) but secondary to initial creation and viewing.

**Independent Test**: Can be fully tested by editing a lease's rent amount and verifying the change reflects in future schedules.

**Acceptance Scenarios**:

1. **Given** an active lease, **When** I edit the rent amount and save, **Then** the new amount applies to future rent schedules (existing unpaid schedules can optionally be updated).

2. **Given** an active lease, **When** I modify the end date to extend the lease, **Then** additional rent schedules are generated for the extension period.

3. **Given** a lease with paid rent schedules, **When** I try to modify past payment dates, **Then** the system prevents modification of historical payment records.

---

### User Story 4 - Terminate a Lease (Priority: P2)

As a property manager, I need to formally terminate a lease when a tenant moves out, recording the termination date and reason, so that the unit becomes available for new rentals and proper records are maintained.

**Why this priority**: Lease termination is a critical business process that affects unit availability and tenant records. Required for proper lifecycle management.

**Independent Test**: Can be fully tested by terminating an active lease and verifying the unit becomes "vacant" and the lease status changes to "terminated".

**Acceptance Scenarios**:

1. **Given** an active lease, **When** I initiate termination with a date and reason, **Then** a confirmation modal appears asking to confirm the action.

2. **Given** I confirm the lease termination, **When** the termination is processed, **Then**: the lease status becomes "terminated", the termination date and reason are recorded, the unit status becomes "vacant", and any future unpaid schedules are cancelled.

3. **Given** a terminated lease, **When** I view it in the system, **Then** I can see the full history including when and why it was terminated.

4. **Given** a lease with unpaid past rent schedules, **When** I terminate the lease, **Then** the outstanding balances remain on record for collection purposes.

---

### User Story 5 - List and Filter Leases (Priority: P2)

As a property manager, I need to see all leases with filtering and search capabilities, so that I can quickly find specific contracts and monitor my portfolio.

**Why this priority**: Important for managing a portfolio with many properties, but managers can initially navigate via tenants or units.

**Independent Test**: Can be fully tested by creating multiple leases and using filters to find specific ones.

**Acceptance Scenarios**:

1. **Given** multiple leases exist, **When** I access the leases list page, **Then** I see all leases with key information (tenant, unit, status, rent, balance).

2. **Given** the leases list, **When** I filter by status (active, terminated, expired, pending), **Then** only matching leases are displayed.

3. **Given** the leases list, **When** I search by tenant name or unit reference, **Then** matching leases are displayed.

4. **Given** the leases list, **When** I sort by start date, end date, or rent amount, **Then** the list reorders accordingly.

---

### User Story 6 - Automatic Rent Schedule Generation (Priority: P1)

As a property manager, I need the system to automatically generate monthly rent schedules when a lease is created, so that I can track payment obligations without manual entry.

**Why this priority**: Core business logic that enables the payment tracking module (Phase 8). Essential for MVP functionality.

**Independent Test**: Can be fully tested by creating a lease and verifying the correct number of rent schedules are generated with proper amounts and due dates.

**Acceptance Scenarios**:

1. **Given** a new lease with start date 01/02/2026 and end date 31/01/2027, **When** the lease is saved, **Then** 12 monthly rent schedules are created with due dates on the payment day of each month.

2. **Given** a lease with rent 150,000 FCFA and charges 15,000 FCFA, **When** schedules are generated, **Then** each schedule has amount_due = 165,000 FCFA.

3. **Given** a lease starting mid-month (15/02/2026), **When** schedules are generated, **Then** the first schedule is prorated for the partial month (half month).

4. **Given** a lease with payment_day = 5, **When** schedules are generated, **Then** each due_date is set to the 5th of each month.

---

### Edge Cases

- What happens when a tenant already has an active lease for a different unit? **Answer**: Allowed - one tenant can have multiple active leases (e.g., renting apartment + parking space).
- How does the system handle lease creation for a unit under maintenance? **Answer**: Allowed with warning - the unit will transition to "occupied" when lease becomes active.
- What happens when lease end date is in the past during creation? **Answer**: System prevents creation and displays validation error.
- How does the system handle leap years for February rent schedules? **Answer**: Due date adjusts to last day of month if payment_day exceeds month length.
- What happens if a lease is created with start_date > end_date? **Answer**: Validation error prevents creation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow creation of a lease linking exactly one tenant to exactly one unit.
- **FR-002**: System MUST require start_date, rent_amount, tenant_id, and unit_id for lease creation.
- **FR-003**: System MUST prevent creating a new active lease for a unit that already has an active lease.
- **FR-004**: System MUST automatically update unit status to "occupied" when an active lease is created.
- **FR-005**: System MUST automatically update unit status to "vacant" when a lease is terminated.
- **FR-006**: System MUST automatically generate monthly rent schedules when a lease is created.
- **FR-007**: System MUST calculate rent schedule amount as rent_amount + charges_amount.
- **FR-008**: System MUST allow lease termination with termination_date and termination_reason.
- **FR-009**: System MUST display leases in both tenant detail and unit detail views.
- **FR-010**: System MUST support lease statuses: pending, active, terminated, expired.
- **FR-011**: System MUST allow editing of lease terms (rent amount, end date, charges) with proper validation.
- **FR-012**: System MUST persist all lease changes with audit timestamps (created_at, updated_at).
- **FR-013**: System MUST enforce role-based access: admin and gestionnaire can create/edit/terminate; assistant can only view.
- **FR-014**: System MUST support deposit tracking (deposit_amount, deposit_paid boolean).
- **FR-015**: System MUST allow specifying payment_day (1-28) for rent due dates.
- **FR-016**: System MUST cancel future unpaid rent schedules when a lease is terminated.
- **FR-017**: System MUST provide lease list with filtering by status and searching by tenant/unit.
- **FR-018**: System MUST display all amounts in FCFA format (e.g., "165 000 FCFA").
- **FR-019**: System MUST display all dates in French format (DD/MM/YYYY).
- **FR-020**: System MUST show confirmation modal before lease termination.

### Key Entities

- **Lease (Bail)**: Represents a rental contract between a tenant and a unit. Key attributes: tenant reference, unit reference, start date, end date, rent amount, charges, deposit, payment day, status, termination info.
- **Rent Schedule (Échéance)**: Represents a monthly rent obligation generated from a lease. Key attributes: lease reference, due date, period covered, amount due, amount paid, balance, status.
- **Tenant (Locataire)**: Existing entity - person renting the unit.
- **Unit (Lot)**: Existing entity - the rental property being leased.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Property managers can create a complete lease in under 3 minutes, including automatic schedule generation.
- **SC-002**: Unit status updates within 1 second of lease creation or termination.
- **SC-003**: 100% of active leases have corresponding rent schedules generated automatically.
- **SC-004**: Lease termination workflow completes in under 30 seconds including confirmation.
- **SC-005**: Users can find any lease by tenant name or unit reference within 10 seconds using search.
- **SC-006**: System correctly prevents duplicate active leases on the same unit (0 violations).
- **SC-007**: All lease amounts display correctly in FCFA format with proper thousand separators.
- **SC-008**: Role-based access is enforced: assistants cannot create, edit, or terminate leases.

## Assumptions

- The tenants module (Phase 6) is complete and functional.
- The units module (Phase 5) is complete with proper status management.
- Supabase backend is configured with proper RLS policies.
- Currency is FCFA (CFA Franc) for all monetary values.
- Locale is French for all date and number formatting.
- Payment day must be between 1-28 to avoid end-of-month issues.
- One tenant can have multiple active leases (for different units).
- Rent schedules are generated monthly (not weekly, quarterly, etc.).
- Pro-rata calculation for partial months uses simple daily rate (rent/30).

## Out of Scope

- Payment recording and tracking (covered in Phase 8).
- Rent receipt/quittance PDF generation (covered in Phase 9).
- Automatic lease expiration notifications (covered in Phase 15).
- Annual rent revision automation (covered in Phase 17).
- Multi-tenant leases (co-tenants sharing one lease).
- Lease document upload and e-signature.
