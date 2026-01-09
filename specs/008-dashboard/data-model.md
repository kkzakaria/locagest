# Data Model: Dashboard avec KPIs

**Feature**: 008-dashboard
**Date**: 2026-01-09

## Overview

The Dashboard feature introduces three new domain entities for aggregated data display. These entities are **read-only** and derived from existing tables (no new database tables required).

## Entities

### 1. DashboardStats

Represents the aggregated statistics displayed on the dashboard.

**Purpose**: Hold all KPI values in a single object for efficient state management.

```dart
// lib/domain/entities/dashboard_stats.dart

/// Aggregated dashboard statistics entity
class DashboardStats {
  // KPI counts
  final int buildingsCount;
  final int activeTenantsCount;
  final int totalUnitsCount;
  final int occupiedUnitsCount;

  // Financial metrics (current month)
  final double monthlyRevenueCollected;
  final double monthlyRevenueDue;

  // Overdue metrics
  final int overdueCount;
  final double overdueAmount;

  // Expiring leases
  final int expiringLeasesCount;

  const DashboardStats({
    required this.buildingsCount,
    required this.activeTenantsCount,
    required this.totalUnitsCount,
    required this.occupiedUnitsCount,
    required this.monthlyRevenueCollected,
    required this.monthlyRevenueDue,
    required this.overdueCount,
    required this.overdueAmount,
    required this.expiringLeasesCount,
  });

  // Computed properties
  double get occupancyRate =>
    totalUnitsCount > 0 ? (occupiedUnitsCount / totalUnitsCount) * 100 : 0;

  double get collectionRate =>
    monthlyRevenueDue > 0 ? (monthlyRevenueCollected / monthlyRevenueDue) * 100 : 0;

  bool get hasOverdue => overdueCount > 0;

  bool get hasExpiringLeases => expiringLeasesCount > 0;
}
```

**Fields**:

| Field | Type | Description | Source |
|-------|------|-------------|--------|
| buildingsCount | int | Total number of buildings | COUNT(buildings) |
| activeTenantsCount | int | Tenants with active leases | COUNT(DISTINCT tenants via active leases) |
| totalUnitsCount | int | Total units across all buildings | COUNT(units) |
| occupiedUnitsCount | int | Units with status='occupied' | COUNT(units WHERE status='occupied') |
| monthlyRevenueCollected | double | Payments received this month | SUM(payments.amount WHERE month=current) |
| monthlyRevenueDue | double | Total rent due this month | SUM(rent_schedules.amount_due WHERE month=current) |
| overdueCount | int | Overdue rent schedules | COUNT(rent_schedules WHERE overdue) |
| overdueAmount | double | Total overdue amount | SUM(rent_schedules.balance WHERE overdue) |
| expiringLeasesCount | int | Leases ending within 30 days | COUNT(leases WHERE end_date within 30 days) |

**Computed Properties**:

| Property | Formula | Color Logic |
|----------|---------|-------------|
| occupancyRate | (occupiedUnits / totalUnits) * 100 | >85% green, 70-85% orange, <70% red |
| collectionRate | (collected / due) * 100 | >90% green, 70-90% orange, <70% red |

---

### 2. OverdueRent

Represents an overdue rent schedule with minimal display data.

**Purpose**: Display overdue payments list on dashboard (top 5).

```dart
// lib/domain/entities/overdue_rent.dart

/// Overdue rent schedule for dashboard display
class OverdueRent {
  final String scheduleId;
  final String leaseId;
  final String tenantName;
  final String unitReference;
  final String buildingName;
  final DateTime dueDate;
  final double amountDue;
  final double amountPaid;
  final int daysOverdue;

  const OverdueRent({
    required this.scheduleId,
    required this.leaseId,
    required this.tenantName,
    required this.unitReference,
    required this.buildingName,
    required this.dueDate,
    required this.amountDue,
    required this.amountPaid,
    required this.daysOverdue,
  });

  // Computed properties
  double get balance => amountDue - amountPaid;

  String get locationLabel => '$buildingName - $unitReference';

  bool get isPartiallyPaid => amountPaid > 0 && amountPaid < amountDue;
}
```

**Fields**:

| Field | Type | Description | Source |
|-------|------|-------------|--------|
| scheduleId | String | Rent schedule UUID | rent_schedules.id |
| leaseId | String | Associated lease UUID | rent_schedules.lease_id |
| tenantName | String | Tenant full name | tenants.first_name + ' ' + tenants.last_name |
| unitReference | String | Unit reference code | units.reference |
| buildingName | String | Building name | buildings.name |
| dueDate | DateTime | Payment due date | rent_schedules.due_date |
| amountDue | double | Total amount due | rent_schedules.amount_due |
| amountPaid | double | Amount already paid | rent_schedules.amount_paid |
| daysOverdue | int | Days since due date | NOW() - due_date |

**Query Source**:
```sql
SELECT
  rs.id as schedule_id,
  rs.lease_id,
  t.first_name || ' ' || t.last_name as tenant_name,
  u.reference as unit_reference,
  b.name as building_name,
  rs.due_date,
  rs.amount_due,
  rs.amount_paid,
  EXTRACT(DAY FROM NOW() - rs.due_date)::int as days_overdue
FROM rent_schedules rs
JOIN leases l ON rs.lease_id = l.id
JOIN tenants t ON l.tenant_id = t.id
JOIN units u ON l.unit_id = u.id
JOIN buildings b ON u.building_id = b.id
WHERE rs.due_date < CURRENT_DATE
  AND rs.status IN ('pending', 'partial')
ORDER BY rs.due_date ASC
LIMIT 5;
```

---

### 3. ExpiringLease

Represents a lease expiring soon with minimal display data.

**Purpose**: Display expiring leases list on dashboard.

```dart
// lib/domain/entities/expiring_lease.dart

/// Expiring lease for dashboard display
class ExpiringLease {
  final String leaseId;
  final String tenantName;
  final String unitReference;
  final String buildingName;
  final DateTime endDate;
  final int daysRemaining;
  final double monthlyRent;

  const ExpiringLease({
    required this.leaseId,
    required this.tenantName,
    required this.unitReference,
    required this.buildingName,
    required this.endDate,
    required this.daysRemaining,
    required this.monthlyRent,
  });

  // Computed properties
  String get locationLabel => '$buildingName - $unitReference';

  bool get isUrgent => daysRemaining <= 7;

  bool get isWarning => daysRemaining <= 14 && daysRemaining > 7;
}
```

**Fields**:

| Field | Type | Description | Source |
|-------|------|-------------|--------|
| leaseId | String | Lease UUID | leases.id |
| tenantName | String | Tenant full name | tenants.first_name + ' ' + tenants.last_name |
| unitReference | String | Unit reference code | units.reference |
| buildingName | String | Building name | buildings.name |
| endDate | DateTime | Lease end date | leases.end_date |
| daysRemaining | int | Days until end | end_date - NOW() |
| monthlyRent | double | Monthly rent amount | leases.rent_amount + leases.charges_amount |

**Query Source**:
```sql
SELECT
  l.id as lease_id,
  t.first_name || ' ' || t.last_name as tenant_name,
  u.reference as unit_reference,
  b.name as building_name,
  l.end_date,
  EXTRACT(DAY FROM l.end_date - NOW())::int as days_remaining,
  l.rent_amount + l.charges_amount as monthly_rent
FROM leases l
JOIN tenants t ON l.tenant_id = t.id
JOIN units u ON l.unit_id = u.id
JOIN buildings b ON u.building_id = b.id
WHERE l.status = 'active'
  AND l.end_date IS NOT NULL
  AND l.end_date >= CURRENT_DATE
  AND l.end_date <= CURRENT_DATE + INTERVAL '30 days'
ORDER BY l.end_date ASC;
```

---

## Entity Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                     DashboardStats                          │
│  (Aggregated KPIs - single object loaded on dashboard)      │
└─────────────────────────────────────────────────────────────┘
         │
         │ composed of data from:
         ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  buildings  │  │    units    │  │   leases    │  │  payments   │
│  (count)    │  │ (count,     │  │ (active,    │  │ (sum this   │
│             │  │  occupied)  │  │  expiring)  │  │   month)    │
└─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘
                                         │
                                         │
         ┌───────────────────────────────┴───────────────────────────────┐
         │                                                               │
         ▼                                                               ▼
┌─────────────────────────────────┐              ┌─────────────────────────────────┐
│         OverdueRent             │              │         ExpiringLease           │
│  (List - top 5 overdue)         │              │  (List - expiring in 30 days)   │
│                                 │              │                                 │
│  scheduleId                     │              │  leaseId                        │
│  leaseId ────────────────────┐  │              │  tenantName                     │
│  tenantName                  │  │              │  unitReference                  │
│  unitReference               │  │              │  buildingName                   │
│  buildingName                │  │              │  endDate                        │
│  dueDate                     │  │              │  daysRemaining                  │
│  amountDue                   │  │              │  monthlyRent                    │
│  amountPaid                  │  │              │                                 │
│  daysOverdue                 │  │              └─────────────────────────────────┘
│                              │  │
└──────────────────────────────│──┘
                               │
                               │ navigates to
                               ▼
                    ┌─────────────────────┐
                    │  LeaseDetailPage    │
                    │  (existing page)    │
                    └─────────────────────┘
```

---

## Data Layer Models (Freezed)

### DashboardStatsModel

```dart
// lib/data/models/dashboard_stats_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/dashboard_stats.dart';

part 'dashboard_stats_model.freezed.dart';
part 'dashboard_stats_model.g.dart';

@freezed
class DashboardStatsModel with _$DashboardStatsModel {
  const factory DashboardStatsModel({
    @JsonKey(name: 'buildings_count') required int buildingsCount,
    @JsonKey(name: 'active_tenants_count') required int activeTenantsCount,
    @JsonKey(name: 'total_units_count') required int totalUnitsCount,
    @JsonKey(name: 'occupied_units_count') required int occupiedUnitsCount,
    @JsonKey(name: 'monthly_revenue_collected') required double monthlyRevenueCollected,
    @JsonKey(name: 'monthly_revenue_due') required double monthlyRevenueDue,
    @JsonKey(name: 'overdue_count') required int overdueCount,
    @JsonKey(name: 'overdue_amount') required double overdueAmount,
    @JsonKey(name: 'expiring_leases_count') required int expiringLeasesCount,
  }) = _DashboardStatsModel;

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsModelFromJson(json);
}

extension DashboardStatsModelX on DashboardStatsModel {
  DashboardStats toEntity() => DashboardStats(
    buildingsCount: buildingsCount,
    activeTenantsCount: activeTenantsCount,
    totalUnitsCount: totalUnitsCount,
    occupiedUnitsCount: occupiedUnitsCount,
    monthlyRevenueCollected: monthlyRevenueCollected,
    monthlyRevenueDue: monthlyRevenueDue,
    overdueCount: overdueCount,
    overdueAmount: overdueAmount,
    expiringLeasesCount: expiringLeasesCount,
  );
}
```

### OverdueRentModel

```dart
// lib/data/models/overdue_rent_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/overdue_rent.dart';

part 'overdue_rent_model.freezed.dart';
part 'overdue_rent_model.g.dart';

@freezed
class OverdueRentModel with _$OverdueRentModel {
  const factory OverdueRentModel({
    @JsonKey(name: 'schedule_id') required String scheduleId,
    @JsonKey(name: 'lease_id') required String leaseId,
    @JsonKey(name: 'tenant_name') required String tenantName,
    @JsonKey(name: 'unit_reference') required String unitReference,
    @JsonKey(name: 'building_name') required String buildingName,
    @JsonKey(name: 'due_date') required DateTime dueDate,
    @JsonKey(name: 'amount_due') required double amountDue,
    @JsonKey(name: 'amount_paid') required double amountPaid,
    @JsonKey(name: 'days_overdue') required int daysOverdue,
  }) = _OverdueRentModel;

  factory OverdueRentModel.fromJson(Map<String, dynamic> json) =>
      _$OverdueRentModelFromJson(json);
}

extension OverdueRentModelX on OverdueRentModel {
  OverdueRent toEntity() => OverdueRent(
    scheduleId: scheduleId,
    leaseId: leaseId,
    tenantName: tenantName,
    unitReference: unitReference,
    buildingName: buildingName,
    dueDate: dueDate,
    amountDue: amountDue,
    amountPaid: amountPaid,
    daysOverdue: daysOverdue,
  );
}
```

### ExpiringLeaseModel

```dart
// lib/data/models/expiring_lease_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/expiring_lease.dart';

part 'expiring_lease_model.freezed.dart';
part 'expiring_lease_model.g.dart';

@freezed
class ExpiringLeaseModel with _$ExpiringLeaseModel {
  const factory ExpiringLeaseModel({
    @JsonKey(name: 'lease_id') required String leaseId,
    @JsonKey(name: 'tenant_name') required String tenantName,
    @JsonKey(name: 'unit_reference') required String unitReference,
    @JsonKey(name: 'building_name') required String buildingName,
    @JsonKey(name: 'end_date') required DateTime endDate,
    @JsonKey(name: 'days_remaining') required int daysRemaining,
    @JsonKey(name: 'monthly_rent') required double monthlyRent,
  }) = _ExpiringLeaseModel;

  factory ExpiringLeaseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpiringLeaseModelFromJson(json);
}

extension ExpiringLeaseModelX on ExpiringLeaseModel {
  ExpiringLease toEntity() => ExpiringLease(
    leaseId: leaseId,
    tenantName: tenantName,
    unitReference: unitReference,
    buildingName: buildingName,
    endDate: endDate,
    daysRemaining: daysRemaining,
    monthlyRent: monthlyRent,
  );
}
```

---

## Validation Rules

### DashboardStats
- All count fields MUST be >= 0
- All amount fields MUST be >= 0
- occupiedUnitsCount MUST be <= totalUnitsCount

### OverdueRent
- daysOverdue MUST be > 0 (by definition of overdue)
- amountDue MUST be > 0
- amountPaid MUST be >= 0 and < amountDue

### ExpiringLease
- daysRemaining MUST be >= 0 and <= 30 (30-day window)
- monthlyRent MUST be > 0

---

## State Transitions

These entities are **read-only snapshots** - no state transitions. The underlying data (leases, rent_schedules, payments) has its own state management defined in their respective modules.

**Dashboard refresh triggers**:
1. Manual pull-to-refresh
2. Navigation to dashboard page
3. After payment recorded (invalidate provider)
4. After lease created/terminated (invalidate provider)
