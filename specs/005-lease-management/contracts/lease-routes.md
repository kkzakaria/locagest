# Lease Routes Contract

**Feature**: 005-lease-management
**Type**: Navigation (GoRouter)
**Date**: 2026-01-08

## Overview

Defines the routes for the lease module following GoRouter patterns established in tenant/unit modules.

---

## Route Definitions

### Route Constants

```dart
class AppRoutes {
  // ... existing routes ...

  // Leases
  static const String leases = '/leases';
  static const String leaseNew = '/leases/new';
  static const String leaseDetail = '/leases/:id';
  static const String leaseEdit = '/leases/:id/edit';

  // Contextual lease creation (from unit or tenant)
  static const String unitLeaseNew = '/units/:unitId/leases/new';
  static const String tenantLeaseNew = '/tenants/:tenantId/leases/new';
}
```

---

### Route Configurations

```dart
// Leases list
GoRoute(
  path: AppRoutes.leases,
  name: 'leases',
  builder: (context, state) => const LeasesListPage(),
),

// Create new lease
GoRoute(
  path: AppRoutes.leaseNew,
  name: 'lease-new',
  builder: (context, state) => const LeaseFormPage(),
),

// Lease detail
GoRoute(
  path: AppRoutes.leaseDetail,
  name: 'lease-detail',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return LeaseDetailPage(leaseId: id);
  },
),

// Edit lease
GoRoute(
  path: AppRoutes.leaseEdit,
  name: 'lease-edit',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return LeaseEditPage(leaseId: id);
  },
),

// Create lease from unit (pre-selects unit)
GoRoute(
  path: AppRoutes.unitLeaseNew,
  name: 'unit-lease-new',
  builder: (context, state) {
    final unitId = state.pathParameters['unitId']!;
    return LeaseFormPage(preselectedUnitId: unitId);
  },
),

// Create lease from tenant (pre-selects tenant)
GoRoute(
  path: AppRoutes.tenantLeaseNew,
  name: 'tenant-lease-new',
  builder: (context, state) {
    final tenantId = state.pathParameters['tenantId']!;
    return LeaseFormPage(preselectedTenantId: tenantId);
  },
),
```

---

## Navigation Extensions

```dart
extension LeaseNavigationExtension on BuildContext {
  /// Navigate to leases list.
  void goToLeases() => go(AppRoutes.leases);

  /// Navigate to create new lease.
  void goToNewLease() => go(AppRoutes.leaseNew);

  /// Navigate to create lease for specific unit.
  void goToNewLeaseForUnit(String unitId) =>
      go('/units/$unitId/leases/new');

  /// Navigate to create lease for specific tenant.
  void goToNewLeaseForTenant(String tenantId) =>
      go('/tenants/$tenantId/leases/new');

  /// Navigate to lease detail.
  void goToLeaseDetail(String leaseId) =>
      go('/leases/$leaseId');

  /// Navigate to edit lease.
  void goToEditLease(String leaseId) =>
      go('/leases/$leaseId/edit');
}
```

---

## Navigation Flow

```
┌────────────────────────────────────────────────────────────────────┐
│                           MAIN NAVIGATION                          │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  Dashboard ──► Leases List ──► Lease Detail ──► Edit Lease        │
│      │              │                │                             │
│      │              └── New Lease ◄──┘                             │
│      │                    ▲                                        │
│      │                    │                                        │
│      ▼                    │                                        │
│  Units List ──► Unit Detail ──► New Lease (unit pre-selected)     │
│      │                                                             │
│      │                                                             │
│  Tenants List ──► Tenant Detail ──► New Lease (tenant pre-selected)│
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

---

## Route Parameters

### Lease Detail / Edit

| Parameter | Type | Source | Description |
|-----------|------|--------|-------------|
| `id` | String (UUID) | Path | Lease ID |

### Unit Lease New

| Parameter | Type | Source | Description |
|-----------|------|--------|-------------|
| `unitId` | String (UUID) | Path | Pre-selected unit ID |

### Tenant Lease New

| Parameter | Type | Source | Description |
|-----------|------|--------|-------------|
| `tenantId` | String (UUID) | Path | Pre-selected tenant ID |

---

## Access Control

All lease routes require authentication (handled by global auth guard).

| Route | Admin | Gestionnaire | Assistant |
|-------|-------|--------------|-----------|
| `/leases` | ✅ View | ✅ View | ✅ View |
| `/leases/new` | ✅ Create | ✅ Create | ❌ Hidden |
| `/leases/:id` | ✅ View | ✅ View | ✅ View |
| `/leases/:id/edit` | ✅ Edit | ✅ Edit | ❌ Hidden |

**Note**: Role-based UI hiding is implemented in the presentation layer using `canManageLeasesProvider`.

---

## Usage Examples

### From Unit Detail Page

```dart
// Unit detail page - "Créer un bail" button
ElevatedButton(
  onPressed: unit.status == 'vacant'
      ? () => context.goToNewLeaseForUnit(unit.id)
      : null,
  child: const Text('Créer un bail'),
),
```

### From Tenant Detail Page

```dart
// Tenant detail page - "Nouveau bail" button
ElevatedButton(
  onPressed: () => context.goToNewLeaseForTenant(tenant.id),
  child: const Text('Nouveau bail'),
),
```

### From Leases List

```dart
// Leases list - FAB for new lease
FloatingActionButton(
  onPressed: () => context.goToNewLease(),
  child: const Icon(Icons.add),
),

// Lease card tap
LeaseCard(
  lease: lease,
  onTap: () => context.goToLeaseDetail(lease.id),
),
```

### From Lease Detail

```dart
// Lease detail - Edit button
IconButton(
  onPressed: () => context.goToEditLease(lease.id),
  icon: const Icon(Icons.edit),
),
```
