# Research: Module Echeances et Paiements

**Feature**: 006-payment-management
**Date**: 2026-01-08
**Status**: Complete

## Overview

This research document consolidates findings from analyzing the existing LocaGest codebase and best practices for implementing the payment management module.

---

## 1. Payment Recording Architecture

### Decision: Dedicated `payments` table with FK to `rent_schedules`

**Rationale**: The existing `rent_schedules` table tracks `amount_paid` as a running total, but lacks individual payment transaction history. A dedicated payments table enables:
- Multiple partial payments per schedule
- Full audit trail with payment method, reference, and timestamps
- Ability to modify/delete individual payments and recalculate totals
- Receipt number generation per payment

**Alternatives Considered**:
| Alternative | Rejected Because |
|-------------|-----------------|
| Store payments as JSONB array in rent_schedules | No FK constraints, harder to query, no RLS per payment |
| Update only amount_paid without history | Cannot track partial payments, no audit trail, cannot correct errors |

**Implementation**:
```sql
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rent_schedule_id UUID NOT NULL REFERENCES rent_schedules(id) ON DELETE CASCADE,
    amount DECIMAL(12,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'check', 'transfer', 'mobile_money')),
    reference TEXT,
    check_number TEXT,
    bank_name TEXT,
    receipt_number TEXT NOT NULL,
    notes TEXT,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT now()
);
```

---

## 2. Receipt Number Generation

### Decision: Format `QUI-AAAAMM-XXXX` generated server-side

**Rationale**:
- Prefix "QUI" (from "quittance") identifies payment receipts
- Year-month (AAAAMM) groups receipts chronologically
- Sequential 4-digit number within month ensures uniqueness
- Server-side generation via PostgreSQL function prevents race conditions

**Alternatives Considered**:
| Alternative | Rejected Because |
|-------------|-----------------|
| UUID-based receipt | Not human-readable, hard to communicate to tenants |
| Client-side generation | Race conditions, potential duplicates |
| Simple auto-increment | No semantic meaning, resets on database restore |

**Implementation**:
```sql
CREATE OR REPLACE FUNCTION generate_receipt_number()
RETURNS TEXT AS $$
DECLARE
    current_prefix TEXT;
    next_seq INTEGER;
BEGIN
    current_prefix := 'QUI-' || TO_CHAR(NOW(), 'YYYYMM') || '-';

    SELECT COALESCE(MAX(CAST(SUBSTRING(receipt_number FROM 13) AS INTEGER)), 0) + 1
    INTO next_seq
    FROM payments
    WHERE receipt_number LIKE current_prefix || '%';

    RETURN current_prefix || LPAD(next_seq::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;
```

---

## 3. Payment Status Update Logic

### Decision: Database trigger updates `rent_schedules.amount_paid` and `status`

**Rationale**:
- Single source of truth for payment totals
- Automatic consistency - no client-side calculation drift
- Works correctly even if multiple clients insert payments simultaneously
- `balance` column already computed as `amount_due - amount_paid` (STORED)

**Status Calculation Logic**:
```
IF amount_paid = 0 AND due_date > today THEN 'pending'
ELSE IF amount_paid = 0 AND due_date <= today THEN 'overdue'
ELSE IF amount_paid < amount_due THEN 'partial'
ELSE 'paid'
```

**Implementation**: PostgreSQL trigger on payments INSERT/UPDATE/DELETE that recalculates `amount_paid` and updates status.

---

## 4. RLS Policies for Payments

### Decision: Chain through rent_schedules → leases for ownership

**Rationale**: Payments don't have `created_by` on the lease; ownership is inherited through the schedule's parent lease. This matches the existing pattern for rent_schedules.

**Policies**:
| Role | Access |
|------|--------|
| admin | Full access to all payments |
| gestionnaire | Full access to payments on their leases (via lease.created_by chain) |
| assistant | Read all + Insert new (cannot update/delete) |

**Note**: Assistant can INSERT (record payments) but cannot UPDATE/DELETE (correct errors requires gestionnaire/admin).

---

## 5. Payments Page Design

### Decision: Combined rent_schedules + payments view with tabs

**Rationale**: Property managers need to see:
1. All schedules (with filter for overdue/pending/paid)
2. When clicking a schedule, see its payment history
3. Quick action to record payment from the list

**UI Pattern**:
- Top: Summary cards (total due, total overdue, total collected this month)
- Filters: Status dropdown, Period (month picker), Tenant search
- List: RentScheduleCard components with status badge, amount, tenant name
- On tap: Expand to show payment history inline OR navigate to lease detail
- FAB or inline button: "Enregistrer paiement" opens modal

**Navigation**: `/payments` route added to main app, accessible from dashboard

---

## 6. Payment Form Modal

### Decision: Bottom sheet modal with minimal required fields

**Rationale**: Speed of data entry is critical (SC-001: <30 seconds). Modal appears over current context, prefilled with remaining balance.

**Required Fields**:
1. Amount (prefilled with schedule balance)
2. Payment method (dropdown)
3. Payment date (defaults to today)

**Conditional Fields**:
- If method = 'check': Show check_number + bank_name fields
- If method = 'transfer' or 'mobile_money': Show reference field

**Validation**:
- Amount > 0
- Amount <= remaining balance (with warning if exceeded, not blocking)
- Payment date not empty

---

## 7. Overdue Detection

### Decision: Query-time calculation, no scheduled job

**Rationale**:
- Overdue status is determined by `due_date < today AND status IN ('pending', 'partial')`
- No need for background job to update statuses
- Query handles this dynamically

**Query Pattern**:
```sql
SELECT * FROM rent_schedules
WHERE due_date < CURRENT_DATE
  AND status IN ('pending', 'partial')
ORDER BY due_date ASC;
```

**Days Overdue**: Computed in Dart entity as `DateTime.now().difference(dueDate).inDays`

---

## 8. Tenant Payment Summary

### Decision: Aggregated view in tenant_detail_page

**Rationale**: FR-015 requires payment summary in tenant fiche. This aggregates across all leases for the tenant.

**Computed Metrics**:
- Total paid (all time)
- Current month: amount due vs paid
- Overdue count and total
- Payment history (last 10 payments)

**Query**: Join payments → rent_schedules → leases → tenants, filter by tenant_id

---

## 9. Integration with Existing Code

### Decision: Extend existing providers, add new payments_provider.dart

**Rationale**:
- Existing `recordPaymentProvider` in `leases_provider.dart` handles basic case
- New `payments_provider.dart` adds:
  - All schedules with filters
  - Overdue schedules
  - Payment history for schedule
  - Tenant payment summary

**Existing Code to Modify**:
| File | Change |
|------|--------|
| `lease_detail_page.dart` | Replace inline payment modal with reusable `PaymentFormModal` |
| `tenant_detail_page.dart` | Add payments summary section |
| `app_router.dart` | Add `/payments` route |
| `leases_provider.dart` | Refactor `recordPayment` to call new payment repository |

---

## 10. Testing Strategy

### Decision: Unit tests for entity logic, Playwright for E2E

**Rationale**: Follows established project pattern. Critical paths:
1. Payment amount calculation and status update
2. Overpayment handling
3. Partial payment sequence
4. Filter combinations

**Test Scenarios**:
- Create full payment → schedule status = 'paid'
- Create partial payment → schedule status = 'partial'
- Create second partial completing balance → schedule status = 'paid'
- Delete payment → amount_paid recalculated, status updated
- Overpayment → accepted with warning, status = 'paid'

---

## Summary

All technical decisions align with existing LocaGest patterns:
- Clean Architecture layers
- Freezed for models
- Riverpod for state
- Supabase RLS for security
- French localization

No external dependencies needed beyond existing stack.
