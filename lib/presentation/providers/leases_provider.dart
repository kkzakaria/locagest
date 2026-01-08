import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/lease_remote_datasource.dart';
import '../../data/repositories/lease_repository_impl.dart';
import '../../domain/entities/lease.dart';
import '../../domain/entities/rent_schedule.dart';
import '../../domain/repositories/lease_repository.dart';

// =============================================================================
// DEPENDENCY PROVIDERS
// =============================================================================

/// Provider for LeaseRemoteDatasource
final leaseDatasourceProvider = Provider<LeaseRemoteDatasource>((ref) {
  return LeaseRemoteDatasource(Supabase.instance.client);
});

/// Provider for LeaseRepository
final leaseRepositoryProvider = Provider<LeaseRepository>((ref) {
  return LeaseRepositoryImpl(ref.read(leaseDatasourceProvider));
});

// =============================================================================
// STATE CLASSES
// =============================================================================

/// State for the leases list
class LeasesState {
  final List<Lease> leases;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final LeaseStatus? statusFilter;
  final String? unitIdFilter;
  final String? tenantIdFilter;

  const LeasesState({
    this.leases = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
    this.statusFilter,
    this.unitIdFilter,
    this.tenantIdFilter,
  });

  LeasesState copyWith({
    List<Lease>? leases,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
    LeaseStatus? statusFilter,
    String? unitIdFilter,
    String? tenantIdFilter,
    bool clearStatusFilter = false,
    bool clearUnitIdFilter = false,
    bool clearTenantIdFilter = false,
  }) {
    return LeasesState(
      leases: leases ?? this.leases,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      unitIdFilter: clearUnitIdFilter ? null : (unitIdFilter ?? this.unitIdFilter),
      tenantIdFilter: clearTenantIdFilter ? null : (tenantIdFilter ?? this.tenantIdFilter),
    );
  }
}

// =============================================================================
// LEASES LIST PROVIDER
// =============================================================================

/// Provider for managing leases list
class LeasesNotifier extends StateNotifier<LeasesState> {
  final LeaseRepository _repository;
  static const int _pageSize = 20;

  LeasesNotifier(this._repository) : super(const LeasesState());

  /// Load initial leases
  Future<void> loadLeases() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final leases = await _repository.getLeases(
        page: 1,
        limit: _pageSize,
        status: state.statusFilter,
        unitId: state.unitIdFilter,
        tenantId: state.tenantIdFilter,
      );
      state = LeasesState(
        leases: leases,
        isLoading: false,
        hasMore: leases.length >= _pageSize,
        currentPage: 1,
        statusFilter: state.statusFilter,
        unitIdFilter: state.unitIdFilter,
        tenantIdFilter: state.tenantIdFilter,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more leases (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final newLeases = await _repository.getLeases(
        page: nextPage,
        limit: _pageSize,
        status: state.statusFilter,
        unitId: state.unitIdFilter,
        tenantId: state.tenantIdFilter,
      );

      state = state.copyWith(
        leases: [...state.leases, ...newLeases],
        isLoading: false,
        hasMore: newLeases.length >= _pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Set status filter and reload
  Future<void> setStatusFilter(LeaseStatus? status) async {
    if (status == null) {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
    await loadLeases();
  }

  /// Set unit ID filter and reload
  Future<void> setUnitIdFilter(String? unitId) async {
    if (unitId == null) {
      state = state.copyWith(clearUnitIdFilter: true);
    } else {
      state = state.copyWith(unitIdFilter: unitId);
    }
    await loadLeases();
  }

  /// Set tenant ID filter and reload
  Future<void> setTenantIdFilter(String? tenantId) async {
    if (tenantId == null) {
      state = state.copyWith(clearTenantIdFilter: true);
    } else {
      state = state.copyWith(tenantIdFilter: tenantId);
    }
    await loadLeases();
  }

  /// Clear all filters and reload
  Future<void> clearFilters() async {
    state = state.copyWith(
      clearStatusFilter: true,
      clearUnitIdFilter: true,
      clearTenantIdFilter: true,
    );
    await loadLeases();
  }

  /// Refresh the leases list
  Future<void> refresh() async {
    state = LeasesState(
      statusFilter: state.statusFilter,
      unitIdFilter: state.unitIdFilter,
      tenantIdFilter: state.tenantIdFilter,
    );
    await loadLeases();
  }

  /// Add a newly created lease to the list
  void addLease(Lease lease) {
    state = state.copyWith(
      leases: [lease, ...state.leases],
    );
  }

  /// Update a lease in the list
  void updateLease(Lease lease) {
    final index = state.leases.indexWhere((l) => l.id == lease.id);
    if (index != -1) {
      final updatedList = List<Lease>.from(state.leases);
      updatedList[index] = lease;
      state = state.copyWith(leases: updatedList);
    }
  }

  /// Remove a lease from the list
  void removeLease(String id) {
    state = state.copyWith(
      leases: state.leases.where((l) => l.id != id).toList(),
    );
  }
}

/// Provider for LeasesNotifier
final leasesProvider = StateNotifierProvider<LeasesNotifier, LeasesState>((ref) {
  return LeasesNotifier(ref.read(leaseRepositoryProvider));
});

// =============================================================================
// SINGLE LEASE PROVIDER
// =============================================================================

/// Provider for fetching a single lease by ID
final leaseByIdProvider = FutureProvider.family<Lease, String>((ref, id) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getLeaseById(id);
});

// =============================================================================
// CREATE LEASE PROVIDER
// =============================================================================

/// State for lease creation
class CreateLeaseState {
  final bool isLoading;
  final String? error;
  final Lease? createdLease;

  const CreateLeaseState({
    this.isLoading = false,
    this.error,
    this.createdLease,
  });

  CreateLeaseState copyWith({
    bool? isLoading,
    String? error,
    Lease? createdLease,
  }) {
    return CreateLeaseState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdLease: createdLease ?? this.createdLease,
    );
  }
}

/// Notifier for lease creation
class CreateLeaseNotifier extends StateNotifier<CreateLeaseState> {
  final LeaseRepository _repository;

  CreateLeaseNotifier(this._repository) : super(const CreateLeaseState());

  /// Create a new lease
  Future<Lease?> createLease({
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
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final lease = await _repository.createLease(
        unitId: unitId,
        tenantId: tenantId,
        startDate: startDate,
        endDate: endDate,
        durationMonths: durationMonths,
        rentAmount: rentAmount,
        chargesAmount: chargesAmount,
        depositAmount: depositAmount,
        depositPaid: depositPaid,
        paymentDay: paymentDay,
        annualRevision: annualRevision,
        revisionRate: revisionRate,
        notes: notes,
      );

      state = state.copyWith(
        isLoading: false,
        createdLease: lease,
      );

      return lease;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Check if unit already has an active lease
  Future<Lease?> checkUnitAvailability(String unitId) async {
    try {
      return await _repository.getActiveLeaseForUnit(unitId);
    } catch (e) {
      return null;
    }
  }

  /// Reset the state
  void reset() {
    state = const CreateLeaseState();
  }
}

/// Provider for CreateLeaseNotifier
final createLeaseProvider =
    StateNotifierProvider<CreateLeaseNotifier, CreateLeaseState>((ref) {
  return CreateLeaseNotifier(ref.read(leaseRepositoryProvider));
});

// =============================================================================
// EDIT LEASE PROVIDER
// =============================================================================

/// State for lease editing
class EditLeaseState {
  final bool isLoading;
  final String? error;
  final Lease? updatedLease;

  const EditLeaseState({
    this.isLoading = false,
    this.error,
    this.updatedLease,
  });

  EditLeaseState copyWith({
    bool? isLoading,
    String? error,
    Lease? updatedLease,
  }) {
    return EditLeaseState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      updatedLease: updatedLease ?? this.updatedLease,
    );
  }
}

/// Notifier for lease editing
class EditLeaseNotifier extends StateNotifier<EditLeaseState> {
  final LeaseRepository _repository;

  EditLeaseNotifier(this._repository) : super(const EditLeaseState());

  /// Update an existing lease
  Future<Lease?> updateLease({
    required String id,
    DateTime? endDate,
    double? rentAmount,
    double? chargesAmount,
    double? depositAmount,
    bool? depositPaid,
    bool? annualRevision,
    double? revisionRate,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final lease = await _repository.updateLease(
        id: id,
        endDate: endDate,
        rentAmount: rentAmount,
        chargesAmount: chargesAmount,
        depositAmount: depositAmount,
        depositPaid: depositPaid,
        annualRevision: annualRevision,
        revisionRate: revisionRate,
        notes: notes,
      );

      state = state.copyWith(
        isLoading: false,
        updatedLease: lease,
      );

      return lease;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Reset the state
  void reset() {
    state = const EditLeaseState();
  }
}

/// Provider for EditLeaseNotifier
final editLeaseProvider =
    StateNotifierProvider<EditLeaseNotifier, EditLeaseState>((ref) {
  return EditLeaseNotifier(ref.read(leaseRepositoryProvider));
});

// =============================================================================
// TERMINATE LEASE PROVIDER
// =============================================================================

/// State for lease termination
class TerminateLeaseState {
  final bool isLoading;
  final String? error;
  final Lease? terminatedLease;

  const TerminateLeaseState({
    this.isLoading = false,
    this.error,
    this.terminatedLease,
  });

  TerminateLeaseState copyWith({
    bool? isLoading,
    String? error,
    Lease? terminatedLease,
  }) {
    return TerminateLeaseState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      terminatedLease: terminatedLease ?? this.terminatedLease,
    );
  }
}

/// Notifier for lease termination
class TerminateLeaseNotifier extends StateNotifier<TerminateLeaseState> {
  final LeaseRepository _repository;

  TerminateLeaseNotifier(this._repository) : super(const TerminateLeaseState());

  /// Terminate a lease
  Future<Lease?> terminateLease({
    required String id,
    required DateTime terminationDate,
    required String terminationReason,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final lease = await _repository.terminateLease(
        id: id,
        terminationDate: terminationDate,
        terminationReason: terminationReason,
      );

      state = state.copyWith(
        isLoading: false,
        terminatedLease: lease,
      );

      return lease;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Reset the state
  void reset() {
    state = const TerminateLeaseState();
  }
}

/// Provider for TerminateLeaseNotifier
final terminateLeaseProvider =
    StateNotifierProvider<TerminateLeaseNotifier, TerminateLeaseState>((ref) {
  return TerminateLeaseNotifier(ref.read(leaseRepositoryProvider));
});

// =============================================================================
// DELETE LEASE PROVIDER
// =============================================================================

/// State for lease deletion
class DeleteLeaseState {
  final bool isLoading;
  final String? error;
  final bool isDeleted;

  const DeleteLeaseState({
    this.isLoading = false,
    this.error,
    this.isDeleted = false,
  });

  DeleteLeaseState copyWith({
    bool? isLoading,
    String? error,
    bool? isDeleted,
  }) {
    return DeleteLeaseState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

/// Notifier for lease deletion
class DeleteLeaseNotifier extends StateNotifier<DeleteLeaseState> {
  final LeaseRepository _repository;

  DeleteLeaseNotifier(this._repository) : super(const DeleteLeaseState());

  /// Delete a lease by ID (only pending leases)
  Future<bool> deleteLease(String id) async {
    state = state.copyWith(isLoading: true, error: null, isDeleted: false);

    try {
      await _repository.deleteLease(id);

      state = state.copyWith(
        isLoading: false,
        isDeleted: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Reset the state
  void reset() {
    state = const DeleteLeaseState();
  }
}

/// Provider for DeleteLeaseNotifier
final deleteLeaseProvider =
    StateNotifierProvider<DeleteLeaseNotifier, DeleteLeaseState>((ref) {
  return DeleteLeaseNotifier(ref.read(leaseRepositoryProvider));
});

// =============================================================================
// RENT SCHEDULES PROVIDER
// =============================================================================

/// Provider for fetching rent schedules for a lease
final rentSchedulesProvider =
    FutureProvider.family<List<RentSchedule>, String>((ref, leaseId) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getRentSchedulesForLease(leaseId);
});

/// Provider for fetching rent schedules summary for a lease
final rentSchedulesSummaryProvider =
    FutureProvider.family<RentSchedulesSummary, String>((ref, leaseId) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getRentSchedulesSummary(leaseId);
});

/// Provider for fetching overdue schedules
final overdueSchedulesProvider = FutureProvider<List<RentSchedule>>((ref) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getOverdueSchedules();
});

/// Provider for fetching upcoming schedules
final upcomingSchedulesProvider =
    FutureProvider.family<List<RentSchedule>, int>((ref, daysAhead) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getUpcomingSchedules(daysAhead: daysAhead);
});

// =============================================================================
// RECORD PAYMENT PROVIDER
// =============================================================================

/// State for recording payment
class RecordPaymentState {
  final bool isLoading;
  final String? error;
  final RentSchedule? updatedSchedule;

  const RecordPaymentState({
    this.isLoading = false,
    this.error,
    this.updatedSchedule,
  });

  RecordPaymentState copyWith({
    bool? isLoading,
    String? error,
    RentSchedule? updatedSchedule,
  }) {
    return RecordPaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      updatedSchedule: updatedSchedule ?? this.updatedSchedule,
    );
  }
}

/// Notifier for recording payments
class RecordPaymentNotifier extends StateNotifier<RecordPaymentState> {
  final LeaseRepository _repository;

  RecordPaymentNotifier(this._repository) : super(const RecordPaymentState());

  /// Record a payment on a rent schedule
  Future<RentSchedule?> recordPayment({
    required String scheduleId,
    required double amount,
    required DateTime paymentDate,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final schedule = await _repository.recordPayment(
        scheduleId: scheduleId,
        amount: amount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        reference: reference,
        notes: notes,
      );

      state = state.copyWith(
        isLoading: false,
        updatedSchedule: schedule,
      );

      return schedule;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Reset the state
  void reset() {
    state = const RecordPaymentState();
  }
}

/// Provider for RecordPaymentNotifier
final recordPaymentProvider =
    StateNotifierProvider<RecordPaymentNotifier, RecordPaymentState>((ref) {
  return RecordPaymentNotifier(ref.read(leaseRepositoryProvider));
});

// =============================================================================
// UNIT LEASE CHECK PROVIDER
// =============================================================================

/// Provider for checking if a unit has an active lease
final unitActiveLeaseProvider =
    FutureProvider.family<Lease?, String>((ref, unitId) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getActiveLeaseForUnit(unitId);
});

// =============================================================================
// TENANT LEASES PROVIDER
// =============================================================================

/// Provider for getting active leases for a tenant
final tenantActiveLeasesProvider =
    FutureProvider.family<List<Lease>, String>((ref, tenantId) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getActiveLeasesForTenant(tenantId);
});

// =============================================================================
// PERMISSION PROVIDER
// =============================================================================

/// Provider for checking if user can manage leases
final canManageLeasesProvider = FutureProvider<bool>((ref) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.canManageLeases();
});

// =============================================================================
// LEASES COUNT PROVIDER
// =============================================================================

/// Provider for getting total leases count with optional filters
class LeasesCountParams {
  final LeaseStatus? status;
  final String? unitId;
  final String? tenantId;

  const LeasesCountParams({
    this.status,
    this.unitId,
    this.tenantId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeasesCountParams &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          unitId == other.unitId &&
          tenantId == other.tenantId;

  @override
  int get hashCode => status.hashCode ^ unitId.hashCode ^ tenantId.hashCode;
}

/// Provider for getting leases count with filters
final leasesCountProvider =
    FutureProvider.family<int, LeasesCountParams>((ref, params) async {
  final repository = ref.read(leaseRepositoryProvider);
  return repository.getLeasesCount(
    status: params.status,
    unitId: params.unitId,
    tenantId: params.tenantId,
  );
});
