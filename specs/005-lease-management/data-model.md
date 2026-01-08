# Data Model: Module Baux (Lease Management)

**Feature**: 005-lease-management
**Date**: 2026-01-08

## Entity Overview

```
┌─────────────────┐       ┌─────────────────┐
│     Tenant      │       │      Unit       │
│   (locataire)   │       │      (lot)      │
└────────┬────────┘       └────────┬────────┘
         │                         │
         │    ┌─────────────┐      │
         └───►│    Lease    │◄─────┘
              │    (bail)   │
              └──────┬──────┘
                     │
                     │ 1:N
                     ▼
            ┌────────────────┐
            │ RentSchedule   │
            │  (échéance)    │
            └────────────────┘
```

---

## 1. Lease (Bail)

### Description
Represents a rental contract between exactly one tenant and exactly one unit. Contains all lease terms including rent amount, duration, and termination information.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | Yes (auto) | Primary key, auto-generated |
| `unit_id` | UUID | Yes | Reference to the rented unit |
| `tenant_id` | UUID | Yes | Reference to the tenant |
| `start_date` | Date | Yes | Lease start date |
| `end_date` | Date | No | Lease end date (null = open-ended) |
| `duration_months` | Integer | No | Contract duration in months |
| `rent_amount` | Decimal(12,2) | Yes | Monthly rent in FCFA |
| `charges_amount` | Decimal(12,2) | No | Monthly charges in FCFA (default 0) |
| `deposit_amount` | Decimal(12,2) | No | Security deposit in FCFA |
| `deposit_paid` | Boolean | No | Whether deposit has been paid (default false) |
| `payment_day` | Integer | No | Day of month rent is due (1-28, default 1) |
| `annual_revision` | Boolean | No | Whether annual rent revision applies (default false) |
| `revision_rate` | Decimal(5,2) | No | Annual revision percentage |
| `status` | Enum | Yes | Current lease status |
| `termination_date` | Date | No | Date lease was terminated |
| `termination_reason` | String | No | Reason for termination |
| `document_url` | String | No | URL to signed lease document |
| `notes` | Text | No | Additional notes |
| `created_by` | UUID | No | User who created the lease |
| `created_at` | Timestamp | Yes (auto) | Creation timestamp |
| `updated_at` | Timestamp | Yes (auto) | Last update timestamp |

### Status Enum (LeaseStatus)

| Value | French Label | Color | Description |
|-------|-------------|-------|-------------|
| `pending` | En attente | 🟡 Orange | Future lease, not yet active |
| `active` | Actif | 🟢 Green | Currently running lease |
| `terminated` | Résilié | 🔴 Red | Ended early by user |
| `expired` | Expiré | ⚫ Grey | End date passed naturally |

### Validation Rules

| Rule | Constraint |
|------|------------|
| rent_amount | Must be > 0 |
| charges_amount | Must be >= 0 |
| deposit_amount | Must be >= 0 |
| payment_day | Must be between 1 and 28 |
| start_date | Cannot be more than 1 year in the past |
| end_date | Must be >= start_date (if provided) |
| status | Must be valid enum value |
| revision_rate | Must be between 0 and 100 (if provided) |
| termination_date | Required if status = terminated |
| unit_id | Unit must exist and not have active lease |
| tenant_id | Tenant must exist |

### Relationships

| Relation | Type | Target | On Delete |
|----------|------|--------|-----------|
| unit | Many-to-One | Unit | RESTRICT |
| tenant | Many-to-One | Tenant | RESTRICT |
| rent_schedules | One-to-Many | RentSchedule | CASCADE |
| created_by_user | Many-to-One | Profile | SET NULL |

### Indexes

| Name | Columns | Purpose |
|------|---------|---------|
| `idx_leases_unit` | unit_id | Fast lookup by unit |
| `idx_leases_tenant` | tenant_id | Fast lookup by tenant |
| `idx_leases_status` | status | Filter by status |
| `idx_leases_start_date` | start_date DESC | Sort by start date |
| `idx_leases_created_by` | created_by | RLS policy queries |
| `idx_leases_active_unit` | unit_id, status (partial: WHERE status IN ('pending', 'active')) | Unique active lease per unit |

### Computed Properties (Entity)

| Property | Type | Computation |
|----------|------|-------------|
| `totalMonthlyAmount` | Decimal | `rent_amount + charges_amount` |
| `tenantFullName` | String | From joined tenant entity |
| `unitReference` | String | From joined unit entity |
| `buildingName` | String | From joined unit.building entity |
| `isActive` | Boolean | `status == 'active'` |
| `isPending` | Boolean | `status == 'pending'` |
| `canBeTerminated` | Boolean | `status IN ('pending', 'active')` |
| `durationLabel` | String | "12 mois" or "Durée indéterminée" |
| `statusLabel` | String | French label for status |
| `statusColor` | Color | Material color for status |

---

## 2. RentSchedule (Échéance)

### Description
Represents a single monthly rent obligation generated from a lease. Tracks amounts due, paid, and status for payment reconciliation.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | Yes (auto) | Primary key, auto-generated |
| `lease_id` | UUID | Yes | Reference to parent lease |
| `due_date` | Date | Yes | Date rent is due |
| `period_start` | Date | Yes | Start of rental period |
| `period_end` | Date | Yes | End of rental period |
| `amount_due` | Decimal(12,2) | Yes | Total amount due for this period |
| `amount_paid` | Decimal(12,2) | No | Total amount paid (default 0) |
| `balance` | Decimal(12,2) | Yes (computed) | `amount_due - amount_paid` (stored for query efficiency) |
| `status` | Enum | Yes | Payment status |
| `created_at` | Timestamp | Yes (auto) | Creation timestamp |
| `updated_at` | Timestamp | Yes (auto) | Last update timestamp |

### Status Enum (RentScheduleStatus)

| Value | French Label | Color | Description |
|-------|-------------|-------|-------------|
| `pending` | En attente | 🟡 Orange | Not yet due, no payment |
| `partial` | Partiel | 🟠 Amber | Some payment received |
| `paid` | Payé | 🟢 Green | Fully paid |
| `overdue` | En retard | 🔴 Red | Past due, not fully paid |
| `cancelled` | Annulé | ⚫ Grey | Cancelled (lease terminated) |

### Validation Rules

| Rule | Constraint |
|------|------------|
| amount_due | Must be > 0 |
| amount_paid | Must be >= 0 and <= amount_due × 2 (allow overpayment up to 2x) |
| due_date | Must be valid date |
| period_end | Must be >= period_start |
| lease_id | Must reference existing lease |
| status | Must be valid enum value |

### Relationships

| Relation | Type | Target | On Delete |
|----------|------|--------|-----------|
| lease | Many-to-One | Lease | CASCADE |
| payments | One-to-Many | Payment | RESTRICT |

### Indexes

| Name | Columns | Purpose |
|------|---------|---------|
| `idx_rent_schedules_lease` | lease_id | Fast lookup by lease |
| `idx_rent_schedules_status` | status | Filter by status |
| `idx_rent_schedules_due_date` | due_date | Sort and filter by due date |
| `idx_rent_schedules_overdue` | status, due_date (partial: WHERE status = 'overdue') | Dashboard overdue query |

### Computed Properties (Entity)

| Property | Type | Computation |
|----------|------|-------------|
| `isPaid` | Boolean | `status == 'paid'` |
| `isOverdue` | Boolean | `status == 'overdue'` |
| `remainingBalance` | Decimal | `amount_due - amount_paid` |
| `periodLabel` | String | "Février 2026" (month name + year) |
| `statusLabel` | String | French label for status |
| `statusColor` | Color | Material color for status |
| `amountDueFormatted` | String | "165 000 FCFA" |
| `amountPaidFormatted` | String | "150 000 FCFA" |

---

## 3. Database Schema (SQL)

```sql
-- ============================================================================
-- ENUMS
-- ============================================================================

-- Lease status enum
CREATE TYPE lease_status AS ENUM ('pending', 'active', 'terminated', 'expired');

-- Rent schedule status enum
CREATE TYPE rent_schedule_status AS ENUM ('pending', 'partial', 'paid', 'overdue', 'cancelled');

-- ============================================================================
-- LEASES TABLE
-- ============================================================================

CREATE TABLE public.leases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- References
    unit_id UUID NOT NULL REFERENCES public.units(id) ON DELETE RESTRICT,
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE RESTRICT,

    -- Contract terms
    start_date DATE NOT NULL,
    end_date DATE,
    duration_months INTEGER,
    rent_amount DECIMAL(12,2) NOT NULL,
    charges_amount DECIMAL(12,2) DEFAULT 0,
    deposit_amount DECIMAL(12,2),
    deposit_paid BOOLEAN DEFAULT false,
    payment_day INTEGER DEFAULT 1,
    annual_revision BOOLEAN DEFAULT false,
    revision_rate DECIMAL(5,2),

    -- Status
    status lease_status DEFAULT 'active' NOT NULL,
    termination_date DATE,
    termination_reason TEXT,

    -- Documents
    document_url TEXT,
    notes TEXT,

    -- Audit
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,

    -- Constraints
    CONSTRAINT leases_rent_amount_positive CHECK (rent_amount > 0),
    CONSTRAINT leases_charges_amount_non_negative CHECK (charges_amount >= 0),
    CONSTRAINT leases_deposit_amount_non_negative CHECK (deposit_amount IS NULL OR deposit_amount >= 0),
    CONSTRAINT leases_payment_day_valid CHECK (payment_day BETWEEN 1 AND 28),
    CONSTRAINT leases_dates_valid CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT leases_revision_rate_valid CHECK (revision_rate IS NULL OR revision_rate BETWEEN 0 AND 100),
    CONSTRAINT leases_termination_date_required CHECK (
        (status != 'terminated') OR (termination_date IS NOT NULL)
    )
);

-- ============================================================================
-- RENT_SCHEDULES TABLE
-- ============================================================================

CREATE TABLE public.rent_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Reference
    lease_id UUID NOT NULL REFERENCES public.leases(id) ON DELETE CASCADE,

    -- Period
    due_date DATE NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,

    -- Amounts
    amount_due DECIMAL(12,2) NOT NULL,
    amount_paid DECIMAL(12,2) DEFAULT 0,
    balance DECIMAL(12,2) GENERATED ALWAYS AS (amount_due - amount_paid) STORED,

    -- Status
    status rent_schedule_status DEFAULT 'pending' NOT NULL,

    -- Audit
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,

    -- Constraints
    CONSTRAINT rent_schedules_amount_due_positive CHECK (amount_due > 0),
    CONSTRAINT rent_schedules_amount_paid_non_negative CHECK (amount_paid >= 0),
    CONSTRAINT rent_schedules_period_valid CHECK (period_end >= period_start)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Leases
CREATE INDEX idx_leases_unit ON leases(unit_id);
CREATE INDEX idx_leases_tenant ON leases(tenant_id);
CREATE INDEX idx_leases_status ON leases(status);
CREATE INDEX idx_leases_start_date ON leases(start_date DESC);
CREATE INDEX idx_leases_created_by ON leases(created_by);

-- Unique constraint: only one active/pending lease per unit
CREATE UNIQUE INDEX idx_leases_active_unit ON leases(unit_id)
    WHERE status IN ('pending', 'active');

-- Rent schedules
CREATE INDEX idx_rent_schedules_lease ON rent_schedules(lease_id);
CREATE INDEX idx_rent_schedules_status ON rent_schedules(status);
CREATE INDEX idx_rent_schedules_due_date ON rent_schedules(due_date);

-- Full-text search on leases (via tenant/unit joins in application)
-- Note: Search implemented in application layer joining with tenants/units tables
```

---

## 4. State Transitions

### Lease Status Transitions

```
                    ┌──────────────┐
                    │   pending    │ (created with future start_date)
                    └──────┬───────┘
                           │
            ┌──────────────┴──────────────┐
            │                             │
            ▼                             ▼
    ┌──────────────┐              ┌──────────────┐
    │    active    │              │  terminated  │ (early termination)
    └──────┬───────┘              └──────────────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌──────────┐  ┌──────────────┐
│ expired  │  │  terminated  │
└──────────┘  └──────────────┘
```

### Valid Transitions

| From | To | Trigger |
|------|-----|---------|
| (new) | pending | Create with start_date > today |
| (new) | active | Create with start_date <= today |
| pending | active | start_date reached (automatic) |
| pending | terminated | User terminates |
| active | expired | end_date reached (automatic) |
| active | terminated | User terminates |

### Rent Schedule Status Transitions

```
┌──────────┐
│ pending  │ (initial state)
└────┬─────┘
     │
     ├─────────────────────────┐
     │                         │
     ▼                         ▼
┌──────────┐              ┌──────────┐
│ overdue  │◄─────────────│ partial  │
└────┬─────┘              └────┬─────┘
     │                         │
     │                         │
     ▼                         ▼
┌──────────┐              ┌──────────┐
│   paid   │              │   paid   │
└──────────┘              └──────────┘

                          ┌───────────┐
                          │ cancelled │ (lease terminated)
                          └───────────┘
```

---

## 5. Model Classes (Dart)

### LeaseModel (Freezed)

```dart
@freezed
class LeaseModel with _$LeaseModel {
  const LeaseModel._();

  const factory LeaseModel({
    required String id,
    @JsonKey(name: 'unit_id') required String unitId,
    @JsonKey(name: 'tenant_id') required String tenantId,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'duration_months') int? durationMonths,
    @JsonKey(name: 'rent_amount') required double rentAmount,
    @JsonKey(name: 'charges_amount') @Default(0) double chargesAmount,
    @JsonKey(name: 'deposit_amount') double? depositAmount,
    @JsonKey(name: 'deposit_paid') @Default(false) bool depositPaid,
    @JsonKey(name: 'payment_day') @Default(1) int paymentDay,
    @JsonKey(name: 'annual_revision') @Default(false) bool annualRevision,
    @JsonKey(name: 'revision_rate') double? revisionRate,
    required String status,
    @JsonKey(name: 'termination_date') DateTime? terminationDate,
    @JsonKey(name: 'termination_reason') String? terminationReason,
    @JsonKey(name: 'document_url') String? documentUrl,
    String? notes,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    // Joined data
    TenantModel? tenant,
    UnitModel? unit,
  }) = _LeaseModel;

  factory LeaseModel.fromJson(Map<String, dynamic> json) => _$LeaseModelFromJson(json);

  Lease toEntity() => Lease(
    id: id,
    unitId: unitId,
    tenantId: tenantId,
    // ... map all fields
    tenant: tenant?.toEntity(),
    unit: unit?.toEntity(),
  );
}

@freezed
class CreateLeaseInput with _$CreateLeaseInput {
  const factory CreateLeaseInput({
    @JsonKey(name: 'unit_id') required String unitId,
    @JsonKey(name: 'tenant_id') required String tenantId,
    @JsonKey(name: 'start_date') required String startDate,  // ISO date string
    @JsonKey(name: 'end_date') String? endDate,
    @JsonKey(name: 'duration_months') int? durationMonths,
    @JsonKey(name: 'rent_amount') required double rentAmount,
    @JsonKey(name: 'charges_amount') double? chargesAmount,
    @JsonKey(name: 'deposit_amount') double? depositAmount,
    @JsonKey(name: 'deposit_paid') bool? depositPaid,
    @JsonKey(name: 'payment_day') int? paymentDay,
    @JsonKey(name: 'annual_revision') bool? annualRevision,
    @JsonKey(name: 'revision_rate') double? revisionRate,
    String? notes,
  }) = _CreateLeaseInput;

  factory CreateLeaseInput.fromJson(Map<String, dynamic> json) =>
      _$CreateLeaseInputFromJson(json);
}

@freezed
class UpdateLeaseInput with _$UpdateLeaseInput {
  const UpdateLeaseInput._();

  const factory UpdateLeaseInput({
    @JsonKey(name: 'end_date') String? endDate,
    @JsonKey(name: 'rent_amount') double? rentAmount,
    @JsonKey(name: 'charges_amount') double? chargesAmount,
    @JsonKey(name: 'deposit_paid') bool? depositPaid,
    @JsonKey(name: 'annual_revision') bool? annualRevision,
    @JsonKey(name: 'revision_rate') double? revisionRate,
    String? notes,
  }) = _UpdateLeaseInput;

  factory UpdateLeaseInput.fromJson(Map<String, dynamic> json) =>
      _$UpdateLeaseInputFromJson(json);

  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (endDate != null) map['end_date'] = endDate;
    if (rentAmount != null) map['rent_amount'] = rentAmount;
    if (chargesAmount != null) map['charges_amount'] = chargesAmount;
    if (depositPaid != null) map['deposit_paid'] = depositPaid;
    if (annualRevision != null) map['annual_revision'] = annualRevision;
    if (revisionRate != null) map['revision_rate'] = revisionRate;
    if (notes != null) map['notes'] = notes;
    return map;
  }
}
```

### RentScheduleModel (Freezed)

```dart
@freezed
class RentScheduleModel with _$RentScheduleModel {
  const RentScheduleModel._();

  const factory RentScheduleModel({
    required String id,
    @JsonKey(name: 'lease_id') required String leaseId,
    @JsonKey(name: 'due_date') required DateTime dueDate,
    @JsonKey(name: 'period_start') required DateTime periodStart,
    @JsonKey(name: 'period_end') required DateTime periodEnd,
    @JsonKey(name: 'amount_due') required double amountDue,
    @JsonKey(name: 'amount_paid') @Default(0) double amountPaid,
    required double balance,
    required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _RentScheduleModel;

  factory RentScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$RentScheduleModelFromJson(json);

  RentSchedule toEntity() => RentSchedule(
    id: id,
    leaseId: leaseId,
    dueDate: dueDate,
    periodStart: periodStart,
    periodEnd: periodEnd,
    amountDue: amountDue,
    amountPaid: amountPaid,
    balance: balance,
    status: RentScheduleStatus.fromString(status),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
```

---

## 6. Query Patterns

### Get Active Lease for Unit
```dart
await _supabase
    .from('leases')
    .select('*, tenant:tenants(*), unit:units(*)')
    .eq('unit_id', unitId)
    .inFilter('status', ['pending', 'active'])
    .single();
```

### Get All Leases for Tenant
```dart
await _supabase
    .from('leases')
    .select('*, unit:units(*, building:buildings(name))')
    .eq('tenant_id', tenantId)
    .order('start_date', ascending: false);
```

### Get Overdue Rent Schedules
```dart
await _supabase
    .from('rent_schedules')
    .select('*, lease:leases(*, tenant:tenants(*), unit:units(*))')
    .eq('status', 'overdue')
    .order('due_date', ascending: true);
```

### Check Unit Has Active Lease
```dart
final response = await _supabase
    .from('leases')
    .select('id')
    .eq('unit_id', unitId)
    .inFilter('status', ['pending', 'active'])
    .limit(1);
return response.isNotEmpty;
```
