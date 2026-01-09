# Data Model: Module Echeances et Paiements

**Feature**: 006-payment-management
**Date**: 2026-01-08

## Entity Overview

```
┌─────────────┐     ┌────────────────┐     ┌───────────┐
│   leases    │────<│ rent_schedules │────<│ payments  │
│             │     │                │     │           │
│ (existing)  │     │ (existing)     │     │ (NEW)     │
└─────────────┘     └────────────────┘     └───────────┘
       │                    │
       │                    ├── amount_paid (updated by trigger)
       │                    └── status (updated by trigger)
       │
       └── tenant_id ──────> tenants (existing)
```

---

## Payment Entity (NEW)

### Attributes

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Unique identifier (auto-generated) |
| rentScheduleId | UUID | Yes | FK to rent_schedules |
| amount | Decimal(12,2) | Yes | Payment amount in FCFA |
| paymentDate | Date | Yes | Date payment was received |
| paymentMethod | PaymentMethod | Yes | Enum: cash, check, transfer, mobile_money |
| reference | String | No | Transaction reference (virement, mobile money) |
| checkNumber | String | No | Check number (if method = check) |
| bankName | String | No | Bank name (if method = check) |
| receiptNumber | String | Yes | Auto-generated: QUI-AAAAMM-XXXX |
| notes | String | No | Free-text notes |
| createdBy | UUID | No | FK to profiles (auto-set via trigger) |
| createdAt | DateTime | Yes | Creation timestamp (auto-set) |

### Relationships

| Relation | Target | Cardinality | Description |
|----------|--------|-------------|-------------|
| rentSchedule | RentSchedule | Many-to-One | Each payment belongs to one schedule |
| createdByUser | Profile | Many-to-One | User who recorded the payment |

### Validation Rules

| Rule | Description | Error Message (FR) |
|------|-------------|-------------------|
| amount_positive | amount > 0 | Le montant doit etre superieur a zero |
| payment_date_required | paymentDate not null | La date de paiement est obligatoire |
| method_required | paymentMethod not null | La methode de paiement est obligatoire |
| check_fields_required | If method=check, checkNumber required | Le numero de cheque est obligatoire |
| amount_warning | If amount > schedule.balance, show warning | Attention: ce paiement depasse le solde restant |

### Computed Properties

| Property | Calculation | Description |
|----------|-------------|-------------|
| methodLabel | French translation of paymentMethod | e.g., "Especes", "Cheque", "Virement", "Mobile Money" |
| amountFormatted | Format with FCFA and space separator | e.g., "150 000 FCFA" |
| paymentDateFormatted | DD/MM/YYYY format | e.g., "08/01/2026" |

---

## PaymentMethod Enum (NEW)

| Value | Database Value | French Label |
|-------|----------------|--------------|
| cash | 'cash' | Especes |
| check | 'check' | Cheque |
| transfer | 'transfer' | Virement bancaire |
| mobileMoney | 'mobile_money' | Mobile Money |

---

## RentSchedule Entity (EXTENDED)

### New Relationships

| Relation | Target | Cardinality | Description |
|----------|--------|-------------|-------------|
| payments | Payment | One-to-Many | All payments for this schedule |

### New Computed Properties

| Property | Calculation | Description |
|----------|-------------|-------------|
| daysOverdue | If overdue: today - dueDate in days | Number of days past due |
| hasPayments | payments.length > 0 | Whether any payment recorded |
| lastPaymentDate | Max(payments.paymentDate) | Most recent payment date |

---

## State Transitions

### RentSchedule Status

```
           ┌─────────────────────────────────────────┐
           │                                         │
           v                                         │
┌─────────────────┐                                  │
│     pending     │ ─── (payment recorded) ──────────┤
└─────────────────┘                                  │
           │                                         │
           │ (due_date passed)                       │
           v                                         │
┌─────────────────┐                                  │
│     overdue     │ ─── (payment recorded) ──────────┤
└─────────────────┘                                  │
           │                                         │
           │ (partial payment)     (full payment)    │
           v                            │            │
┌─────────────────┐                     │            │
│     partial     │ ─── (complete) ─────┼────────────┤
└─────────────────┘                     │            │
                                        v            │
                              ┌─────────────────┐    │
                              │      paid       │<───┘
                              └─────────────────┘

           ┌─────────────────┐
           │    cancelled    │  (lease terminated)
           └─────────────────┘
```

### Status Determination Logic

```
IF schedule.status = 'cancelled' THEN
    RETURN 'cancelled'  // Immutable once cancelled
ELSE IF amount_paid >= amount_due THEN
    RETURN 'paid'
ELSE IF amount_paid > 0 THEN
    RETURN 'partial'
ELSE IF due_date < today THEN
    RETURN 'overdue'
ELSE
    RETURN 'pending'
END IF
```

---

## Aggregate: TenantPaymentSummary (NEW)

For display in tenant detail page.

| Field | Type | Description |
|-------|------|-------------|
| tenantId | UUID | Target tenant |
| totalPaidAllTime | Decimal | Sum of all payments across all leases |
| currentMonthDue | Decimal | Amount due for current month |
| currentMonthPaid | Decimal | Amount paid for current month |
| overdueCount | Integer | Number of overdue schedules |
| overdueTotal | Decimal | Sum of overdue balances |
| recentPayments | List<Payment> | Last 10 payments |

---

## Database Indexes (Optimization)

| Index | Columns | Purpose |
|-------|---------|---------|
| idx_payments_schedule | rent_schedule_id | FK lookup for payment history |
| idx_payments_date | payment_date DESC | Sorting by date |
| idx_payments_receipt | receipt_number | Unique lookup by receipt |
| idx_payments_created_by | created_by | Audit queries |

---

## Cascade Rules

| Parent | Child | On Delete |
|--------|-------|-----------|
| rent_schedules | payments | CASCADE (delete payments when schedule deleted) |
| leases | rent_schedules | CASCADE (existing) |
| profiles | payments.created_by | SET NULL |
