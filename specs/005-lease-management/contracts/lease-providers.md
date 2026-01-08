# Lease Providers Contract

**Feature**: 005-lease-management
**Type**: Riverpod State Management
**Date**: 2026-01-08

## Overview

Defines the Riverpod providers for lease state management following patterns established in tenant/unit modules.

---

## Provider Definitions

### Dependency Providers

```dart
/// Provides the lease datasource (Supabase client wrapper).
final leaseDatasourceProvider = Provider<LeaseRemoteDatasource>((ref) {
  return LeaseRemoteDatasource(Supabase.instance.client);
});

/// Provides the lease repository implementation.
final leaseRepositoryProvider = Provider<LeaseRepository>((ref) {
  return LeaseRepositoryImpl(ref.read(leaseDatasourceProvider));
});
```

---

### List Provider (with Pagination)

```dart
/// State class for leases list.
class LeasesState {
  final List<Lease> leases;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String searchQuery;
  final LeaseStatus? statusFilter;
  final String? buildingFilter;

  const LeasesState({
    this.leases = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
    this.searchQuery = '',
    this.statusFilter,
    this.buildingFilter,
  });

  LeasesState copyWith({...});
}

/// Notifier for managing leases list state.
class LeasesNotifier extends StateNotifier<LeasesState> {
  final LeaseRepository _repository;

  LeasesNotifier(this._repository);

  /// Load initial leases.
  Future<void> loadLeases();

  /// Load more leases (pagination).
  Future<void> loadMore();

  /// Search leases by tenant name or unit reference.
  Future<void> searchLeases(String query);

  /// Filter by status.
  void setStatusFilter(LeaseStatus? status);

  /// Filter by building.
  void setBuildingFilter(String? buildingId);

  /// Refresh list (reset and reload).
  Future<void> refresh();

  /// Add lease to list (after creation).
  void addLease(Lease lease);

  /// Update lease in list (after edit).
  void updateLease(Lease lease);

  /// Remove lease from list (after deletion/termination).
  void removeLease(String id);
}

/// Provider for leases list.
final leasesProvider = StateNotifierProvider<LeasesNotifier, LeasesState>((ref) {
  return LeasesNotifier(ref.read(leaseRepositoryProvider));
});
```

---

### Single Lease Provider

```dart
/// Provides a single lease by ID with joined data.
final leaseByIdProvider = FutureProvider.family<Lease, String>((ref, id) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getLeaseById(id);
});
```

---

### Create Lease Provider

```dart
/// State for lease creation.
class CreateLeaseState {
  final bool isLoading;
  final bool isSuccess;
  final Lease? createdLease;
  final String? error;

  const CreateLeaseState({
    this.isLoading = false,
    this.isSuccess = false,
    this.createdLease,
    this.error,
  });

  CreateLeaseState copyWith({...});
}

/// Notifier for creating a new lease.
class CreateLeaseNotifier extends StateNotifier<CreateLeaseState> {
  final LeaseRepository _repository;

  CreateLeaseNotifier(this._repository);

  /// Create a new lease.
  Future<void> createLease({
    required String unitId,
    required String tenantId,
    required DateTime startDate,
    DateTime? endDate,
    int? durationMonths,
    required double rentAmount,
    double chargesAmount = 0,
    double? depositAmount,
    bool depositPaid = false,
    int paymentDay = 1,
    bool annualRevision = false,
    double? revisionRate,
    String? notes,
  });

  /// Reset state for new creation.
  void reset();
}

/// Provider for creating leases.
final createLeaseProvider =
    StateNotifierProvider<CreateLeaseNotifier, CreateLeaseState>((ref) {
  return CreateLeaseNotifier(ref.read(leaseRepositoryProvider));
});
```

---

### Edit Lease Provider

```dart
/// State for lease editing.
class EditLeaseState {
  final bool isLoading;
  final bool isSuccess;
  final Lease? updatedLease;
  final String? error;

  const EditLeaseState({
    this.isLoading = false,
    this.isSuccess = false,
    this.updatedLease,
    this.error,
  });

  EditLeaseState copyWith({...});
}

/// Notifier for editing an existing lease.
class EditLeaseNotifier extends StateNotifier<EditLeaseState> {
  final LeaseRepository _repository;

  EditLeaseNotifier(this._repository);

  /// Update lease fields.
  Future<void> updateLease({
    required String id,
    DateTime? endDate,
    double? rentAmount,
    double? chargesAmount,
    bool? depositPaid,
    bool? annualRevision,
    double? revisionRate,
    String? notes,
  });

  /// Reset state.
  void reset();
}

/// Provider for editing leases.
final editLeaseProvider =
    StateNotifierProvider<EditLeaseNotifier, EditLeaseState>((ref) {
  return EditLeaseNotifier(ref.read(leaseRepositoryProvider));
});
```

---

### Terminate Lease Provider

```dart
/// State for lease termination.
class TerminateLeaseState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  const TerminateLeaseState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  TerminateLeaseState copyWith({...});
}

/// Notifier for terminating leases.
class TerminateLeaseNotifier extends StateNotifier<TerminateLeaseState> {
  final LeaseRepository _repository;

  TerminateLeaseNotifier(this._repository);

  /// Terminate a lease.
  Future<void> terminateLease({
    required String id,
    DateTime? terminationDate,
    required String terminationReason,
  });

  /// Reset state.
  void reset();
}

/// Provider for terminating leases.
final terminateLeaseProvider =
    StateNotifierProvider<TerminateLeaseNotifier, TerminateLeaseState>((ref) {
  return TerminateLeaseNotifier(ref.read(leaseRepositoryProvider));
});
```

---

### Query Providers

```dart
/// Get leases for a specific tenant.
final leasesForTenantProvider =
    FutureProvider.family<List<Lease>, String>((ref, tenantId) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getLeasesForTenant(tenantId);
});

/// Get leases for a specific unit.
final leasesForUnitProvider =
    FutureProvider.family<List<Lease>, String>((ref, unitId) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getLeasesForUnit(unitId);
});

/// Get active lease for a unit (null if vacant).
final activeLeaseForUnitProvider =
    FutureProvider.family<Lease?, String>((ref, unitId) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getActiveLeaseForUnit(unitId);
});

/// Check if unit can have a new lease.
final canCreateLeaseForUnitProvider =
    FutureProvider.family<bool, String>((ref, unitId) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.canCreateLeaseForUnit(unitId);
});

/// Get lease counts by status (for dashboard).
final leaseCountsByStatusProvider =
    FutureProvider<Map<LeaseStatus, int>>((ref) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getLeaseCountsByStatus();
});

/// Search leases.
final leaseSearchProvider =
    FutureProvider.family<List<Lease>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repository = ref.read(leaseRepositoryProvider);
  return repository.searchLeases(query);
});
```

---

### Rent Schedules Providers

```dart
/// Get rent schedules for a lease.
final rentSchedulesForLeaseProvider =
    FutureProvider.family<List<RentSchedule>, String>((ref, leaseId) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getRentSchedulesForLease(leaseId);
});

/// Get rent schedules summary for a lease.
final rentSchedulesSummaryProvider =
    FutureProvider.family<RentSchedulesSummary, String>((ref, leaseId) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getRentSchedulesSummary(leaseId);
});
```

---

### Permission Provider

```dart
/// Check if current user can manage (create/edit/terminate) leases.
final canManageLeasesProvider = FutureProvider<bool>((ref) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.canManageLeases();
});
```

---

## Usage Examples

### Loading Leases List

```dart
class LeasesListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leasesProvider);

    if (state.isLoading && state.leases.isEmpty) {
      return const LoadingIndicator();
    }

    if (state.error != null) {
      return ErrorMessage(state.error!);
    }

    return ListView.builder(
      itemCount: state.leases.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.leases.length) {
          // Load more trigger
          ref.read(leasesProvider.notifier).loadMore();
          return const LoadingIndicator();
        }
        return LeaseCard(lease: state.leases[index]);
      },
    );
  }
}
```

### Creating a Lease

```dart
void _onSubmit() async {
  await ref.read(createLeaseProvider.notifier).createLease(
    unitId: selectedUnitId,
    tenantId: selectedTenantId,
    startDate: startDate,
    endDate: endDate,
    rentAmount: rentAmount,
    chargesAmount: chargesAmount,
  );

  final state = ref.read(createLeaseProvider);
  if (state.isSuccess) {
    // Add to list and navigate
    ref.read(leasesProvider.notifier).addLease(state.createdLease!);
    context.pop();
  } else if (state.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(state.error!)),
    );
  }
}
```

### Terminating a Lease

```dart
void _confirmTermination() async {
  await ref.read(terminateLeaseProvider.notifier).terminateLease(
    id: lease.id,
    terminationDate: selectedDate,
    terminationReason: selectedReason,
  );

  final state = ref.read(terminateLeaseProvider);
  if (state.isSuccess) {
    ref.invalidate(leaseByIdProvider(lease.id));
    ref.invalidate(leasesForUnitProvider(lease.unitId));
    context.pop();
  }
}
```
