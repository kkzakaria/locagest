import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

// =============================================================================
// DEPENDENCY PROVIDERS
// =============================================================================

/// Provider for PaymentRemoteDatasource
final paymentDatasourceProvider = Provider<PaymentRemoteDatasource>((ref) {
  return PaymentRemoteDatasource(Supabase.instance.client);
});

/// Provider for PaymentRepository
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.read(paymentDatasourceProvider));
});

// =============================================================================
// CREATE PAYMENT PROVIDER
// =============================================================================

/// State for payment creation
class CreatePaymentState {
  final bool isLoading;
  final String? error;
  final Payment? createdPayment;

  const CreatePaymentState({
    this.isLoading = false,
    this.error,
    this.createdPayment,
  });

  CreatePaymentState copyWith({
    bool? isLoading,
    String? error,
    Payment? createdPayment,
  }) {
    return CreatePaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdPayment: createdPayment ?? this.createdPayment,
    );
  }
}

/// Notifier for payment creation
class CreatePaymentNotifier extends StateNotifier<CreatePaymentState> {
  final PaymentRepository _repository;

  CreatePaymentNotifier(this._repository) : super(const CreatePaymentState());

  /// Create a new payment
  Future<Payment?> createPayment({
    required String rentScheduleId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? reference,
    String? checkNumber,
    String? bankName,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final input = CreatePaymentInput(
        rentScheduleId: rentScheduleId,
        amount: amount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        reference: reference,
        checkNumber: checkNumber,
        bankName: bankName,
        notes: notes,
      );

      final payment = await _repository.createPayment(input);

      state = state.copyWith(
        isLoading: false,
        createdPayment: payment,
      );

      return payment;
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
    state = const CreatePaymentState();
  }
}

/// Provider for CreatePaymentNotifier
final createPaymentProvider =
    StateNotifierProvider<CreatePaymentNotifier, CreatePaymentState>((ref) {
  return CreatePaymentNotifier(ref.read(paymentRepositoryProvider));
});

// =============================================================================
// UPDATE PAYMENT PROVIDER
// =============================================================================

/// State for payment update
class UpdatePaymentState {
  final bool isLoading;
  final String? error;
  final Payment? updatedPayment;

  const UpdatePaymentState({
    this.isLoading = false,
    this.error,
    this.updatedPayment,
  });

  UpdatePaymentState copyWith({
    bool? isLoading,
    String? error,
    Payment? updatedPayment,
  }) {
    return UpdatePaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      updatedPayment: updatedPayment ?? this.updatedPayment,
    );
  }
}

/// Notifier for payment update
class UpdatePaymentNotifier extends StateNotifier<UpdatePaymentState> {
  final PaymentRepository _repository;

  UpdatePaymentNotifier(this._repository) : super(const UpdatePaymentState());

  /// Update an existing payment
  Future<Payment?> updatePayment({
    required String id,
    double? amount,
    DateTime? paymentDate,
    String? paymentMethod,
    String? reference,
    String? checkNumber,
    String? bankName,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final input = UpdatePaymentInput(
        amount: amount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        reference: reference,
        checkNumber: checkNumber,
        bankName: bankName,
        notes: notes,
      );

      final payment = await _repository.updatePayment(id, input);

      state = state.copyWith(
        isLoading: false,
        updatedPayment: payment,
      );

      return payment;
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
    state = const UpdatePaymentState();
  }
}

/// Provider for UpdatePaymentNotifier
final updatePaymentProvider =
    StateNotifierProvider<UpdatePaymentNotifier, UpdatePaymentState>((ref) {
  return UpdatePaymentNotifier(ref.read(paymentRepositoryProvider));
});

// =============================================================================
// DELETE PAYMENT PROVIDER
// =============================================================================

/// State for payment deletion
class DeletePaymentState {
  final bool isLoading;
  final String? error;
  final bool isDeleted;

  const DeletePaymentState({
    this.isLoading = false,
    this.error,
    this.isDeleted = false,
  });

  DeletePaymentState copyWith({
    bool? isLoading,
    String? error,
    bool? isDeleted,
  }) {
    return DeletePaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

/// Notifier for payment deletion
class DeletePaymentNotifier extends StateNotifier<DeletePaymentState> {
  final PaymentRepository _repository;

  DeletePaymentNotifier(this._repository) : super(const DeletePaymentState());

  /// Delete a payment by ID
  Future<bool> deletePayment(String id) async {
    state = state.copyWith(isLoading: true, error: null, isDeleted: false);

    try {
      await _repository.deletePayment(id);

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
    state = const DeletePaymentState();
  }
}

/// Provider for DeletePaymentNotifier
final deletePaymentProvider =
    StateNotifierProvider<DeletePaymentNotifier, DeletePaymentState>((ref) {
  return DeletePaymentNotifier(ref.read(paymentRepositoryProvider));
});

// =============================================================================
// PAYMENTS FOR SCHEDULE PROVIDER
// =============================================================================

/// Provider for fetching payments for a rent schedule
final paymentsForScheduleProvider =
    FutureProvider.family<List<Payment>, String>((ref, rentScheduleId) async {
  final repository = ref.read(paymentRepositoryProvider);
  return repository.getPaymentsForSchedule(rentScheduleId);
});

// =============================================================================
// PAYMENTS FOR LEASE PROVIDER
// =============================================================================

/// Provider for fetching payments for a lease
final paymentsForLeaseProvider =
    FutureProvider.family<List<Payment>, String>((ref, leaseId) async {
  final repository = ref.read(paymentRepositoryProvider);
  return repository.getPaymentsForLease(leaseId);
});

// =============================================================================
// PAYMENTS FOR TENANT PROVIDER
// =============================================================================

/// Provider for fetching payments for a tenant
final paymentsForTenantProvider =
    FutureProvider.family<List<Payment>, String>((ref, tenantId) async {
  final repository = ref.read(paymentRepositoryProvider);
  return repository.getPaymentsForTenant(tenantId);
});

// =============================================================================
// RECENT PAYMENTS PROVIDER
// =============================================================================

/// Provider for fetching recent payments
final recentPaymentsProvider =
    FutureProvider.family<List<Payment>, int>((ref, limit) async {
  final repository = ref.read(paymentRepositoryProvider);
  return repository.getRecentPayments(limit: limit);
});

// =============================================================================
// ALL SCHEDULES PROVIDER
// =============================================================================

/// Parameters for fetching all schedules
class SchedulesFilterParams {
  final String? status;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? tenantId;
  final String? searchQuery;
  final int page;
  final int limit;

  const SchedulesFilterParams({
    this.status,
    this.periodStart,
    this.periodEnd,
    this.tenantId,
    this.searchQuery,
    this.page = 1,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchedulesFilterParams &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          periodStart == other.periodStart &&
          periodEnd == other.periodEnd &&
          tenantId == other.tenantId &&
          searchQuery == other.searchQuery &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode =>
      status.hashCode ^
      periodStart.hashCode ^
      periodEnd.hashCode ^
      tenantId.hashCode ^
      searchQuery.hashCode ^
      page.hashCode ^
      limit.hashCode;
}

/// State for the schedules list with filters
class AllSchedulesState {
  final List<RentScheduleWithDetails> schedules;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String? statusFilter;
  final DateTime? periodStartFilter;
  final DateTime? periodEndFilter;
  final String? tenantIdFilter;
  final String? searchQuery;

  const AllSchedulesState({
    this.schedules = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
    this.statusFilter,
    this.periodStartFilter,
    this.periodEndFilter,
    this.tenantIdFilter,
    this.searchQuery,
  });

  AllSchedulesState copyWith({
    List<RentScheduleWithDetails>? schedules,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? statusFilter,
    DateTime? periodStartFilter,
    DateTime? periodEndFilter,
    String? tenantIdFilter,
    String? searchQuery,
    bool clearStatusFilter = false,
    bool clearPeriodStartFilter = false,
    bool clearPeriodEndFilter = false,
    bool clearTenantIdFilter = false,
    bool clearSearchQuery = false,
  }) {
    return AllSchedulesState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      periodStartFilter: clearPeriodStartFilter
          ? null
          : (periodStartFilter ?? this.periodStartFilter),
      periodEndFilter: clearPeriodEndFilter
          ? null
          : (periodEndFilter ?? this.periodEndFilter),
      tenantIdFilter:
          clearTenantIdFilter ? null : (tenantIdFilter ?? this.tenantIdFilter),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }
}

/// Notifier for managing all schedules list
class AllSchedulesNotifier extends StateNotifier<AllSchedulesState> {
  final PaymentRepository _repository;
  static const int _pageSize = 20;

  AllSchedulesNotifier(this._repository) : super(const AllSchedulesState());

  /// Load initial schedules
  Future<void> loadSchedules() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final schedules = await _repository.getAllSchedules(
        status: state.statusFilter,
        periodStart: state.periodStartFilter,
        periodEnd: state.periodEndFilter,
        tenantId: state.tenantIdFilter,
        searchQuery: state.searchQuery,
        page: 1,
        limit: _pageSize,
      );

      state = AllSchedulesState(
        schedules: schedules,
        isLoading: false,
        hasMore: schedules.length >= _pageSize,
        currentPage: 1,
        statusFilter: state.statusFilter,
        periodStartFilter: state.periodStartFilter,
        periodEndFilter: state.periodEndFilter,
        tenantIdFilter: state.tenantIdFilter,
        searchQuery: state.searchQuery,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more schedules (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final newSchedules = await _repository.getAllSchedules(
        status: state.statusFilter,
        periodStart: state.periodStartFilter,
        periodEnd: state.periodEndFilter,
        tenantId: state.tenantIdFilter,
        searchQuery: state.searchQuery,
        page: nextPage,
        limit: _pageSize,
      );

      state = state.copyWith(
        schedules: [...state.schedules, ...newSchedules],
        isLoading: false,
        hasMore: newSchedules.length >= _pageSize,
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
  Future<void> setStatusFilter(String? status) async {
    if (status == null) {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
    await loadSchedules();
  }

  /// Set period filter and reload
  Future<void> setPeriodFilter(DateTime? start, DateTime? end) async {
    state = state.copyWith(
      periodStartFilter: start,
      periodEndFilter: end,
      clearPeriodStartFilter: start == null,
      clearPeriodEndFilter: end == null,
    );
    await loadSchedules();
  }

  /// Set tenant ID filter and reload
  Future<void> setTenantIdFilter(String? tenantId) async {
    if (tenantId == null) {
      state = state.copyWith(clearTenantIdFilter: true);
    } else {
      state = state.copyWith(tenantIdFilter: tenantId);
    }
    await loadSchedules();
  }

  /// Set search query and reload
  Future<void> setSearchQuery(String? query) async {
    if (query == null || query.isEmpty) {
      state = state.copyWith(clearSearchQuery: true);
    } else {
      state = state.copyWith(searchQuery: query);
    }
    await loadSchedules();
  }

  /// Clear all filters and reload
  Future<void> clearFilters() async {
    state = state.copyWith(
      clearStatusFilter: true,
      clearPeriodStartFilter: true,
      clearPeriodEndFilter: true,
      clearTenantIdFilter: true,
      clearSearchQuery: true,
    );
    await loadSchedules();
  }

  /// Refresh the schedules list
  Future<void> refresh() async {
    state = AllSchedulesState(
      statusFilter: state.statusFilter,
      periodStartFilter: state.periodStartFilter,
      periodEndFilter: state.periodEndFilter,
      tenantIdFilter: state.tenantIdFilter,
      searchQuery: state.searchQuery,
    );
    await loadSchedules();
  }
}

/// Provider for AllSchedulesNotifier
final allSchedulesProvider =
    StateNotifierProvider<AllSchedulesNotifier, AllSchedulesState>((ref) {
  return AllSchedulesNotifier(ref.read(paymentRepositoryProvider));
});

// =============================================================================
// OVERDUE SCHEDULES PROVIDER
// =============================================================================

/// Provider for fetching overdue schedules with details
final overdueSchedulesWithDetailsProvider =
    FutureProvider<List<RentScheduleWithDetails>>((ref) async {
  final repository = ref.read(paymentRepositoryProvider);
  return repository.getOverdueSchedules();
});

// =============================================================================
// SCHEDULE COUNTS PROVIDER
// =============================================================================

/// Provider for fetching schedule counts by status
final scheduleCountsByStatusProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.read(paymentRepositoryProvider);
  return repository.getScheduleCountsByStatus();
});

// =============================================================================
// PAYMENTS SUMMARY PROVIDER
// =============================================================================

/// Provider for fetching payments summary for the payments page header
final paymentsSummaryProvider = FutureProvider<PaymentsSummary>((ref) async {
  final repository = ref.read(paymentRepositoryProvider);
  return repository.getPaymentsSummary();
});

// =============================================================================
// TENANT PAYMENT SUMMARY PROVIDER
// =============================================================================

/// Provider for fetching payment summary for a tenant
final tenantPaymentSummaryProvider =
    FutureProvider.family<TenantPaymentSummary, String>((ref, tenantId) async {
  final repository = ref.read(paymentRepositoryProvider);
  return repository.getTenantPaymentSummary(tenantId);
});

// =============================================================================
// TOTAL OVERDUE PROVIDER
// =============================================================================

/// Provider for fetching total overdue amount
final totalOverdueProvider = FutureProvider<double>((ref) async {
  final repository = ref.read(paymentRepositoryProvider);
  return repository.getTotalOverdue();
});

// =============================================================================
// PERMISSION PROVIDERS
// =============================================================================

/// Provider for checking if user can manage payments (update, delete)
final canManagePaymentsProvider = FutureProvider<bool>((ref) async {
  final repository = ref.read(paymentRepositoryProvider);
  return repository.canManagePayments();
});

/// Provider for checking if user can record new payments
final canRecordPaymentsProvider = FutureProvider<bool>((ref) async {
  final repository = ref.read(paymentRepositoryProvider);
  return repository.canRecordPayments();
});
