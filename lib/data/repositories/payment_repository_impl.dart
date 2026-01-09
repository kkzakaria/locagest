import '../../domain/entities/payment.dart';
import '../../domain/entities/rent_schedule.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

/// Implementation of PaymentRepository using remote datasource
class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDatasource _datasource;

  PaymentRepositoryImpl(this._datasource);

  // ============================================================================
  // CRUD OPERATIONS
  // ============================================================================

  @override
  Future<Payment> createPayment(CreatePaymentInput input) async {
    final model = await _datasource.createPayment(input);
    return model.toEntity();
  }

  @override
  Future<Payment> getPaymentById(String id) async {
    final model = await _datasource.getPaymentById(id);
    return model.toEntity();
  }

  @override
  Future<Payment> updatePayment(String id, UpdatePaymentInput input) async {
    final model = await _datasource.updatePayment(id, input);
    return model.toEntity();
  }

  @override
  Future<void> deletePayment(String id) async {
    await _datasource.deletePayment(id);
  }

  // ============================================================================
  // QUERY OPERATIONS
  // ============================================================================

  @override
  Future<List<Payment>> getPaymentsForSchedule(String rentScheduleId) async {
    final models = await _datasource.getPaymentsForSchedule(rentScheduleId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Payment>> getPaymentsForLease(String leaseId) async {
    final models = await _datasource.getPaymentsForLease(leaseId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Payment>> getPaymentsForTenant(String tenantId) async {
    final models = await _datasource.getPaymentsForTenant(tenantId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Payment>> getRecentPayments({int limit = 20}) async {
    final models = await _datasource.getRecentPayments(limit: limit);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Payment>> getPaymentsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final models = await _datasource.getPaymentsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  // ============================================================================
  // SCHEDULE QUERIES
  // ============================================================================

  @override
  Future<List<RentScheduleWithDetails>> getAllSchedules({
    String? status,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? tenantId,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _datasource.getAllSchedulesWithDetails(
      status: status,
      periodStart: periodStart,
      periodEnd: periodEnd,
      tenantId: tenantId,
      searchQuery: searchQuery,
      page: page,
      limit: limit,
    );

    return data.map((row) => _mapToRentScheduleWithDetails(row)).toList();
  }

  @override
  Future<List<RentScheduleWithDetails>> getOverdueSchedules() async {
    final data = await _datasource.getOverdueSchedulesWithDetails();
    return data.map((row) => _mapToRentScheduleWithDetails(row)).toList();
  }

  @override
  Future<Map<String, int>> getScheduleCountsByStatus() async {
    return _datasource.getScheduleCountsByStatus();
  }

  /// Helper to map raw data to RentScheduleWithDetails
  RentScheduleWithDetails _mapToRentScheduleWithDetails(Map<String, dynamic> row) {
    // Extract schedule data
    final schedule = RentSchedule(
      id: row['id'] as String,
      leaseId: row['lease_id'] as String,
      dueDate: DateTime.parse(row['due_date'] as String),
      periodStart: DateTime.parse(row['period_start'] as String),
      periodEnd: DateTime.parse(row['period_end'] as String),
      amountDue: (row['amount_due'] as num).toDouble(),
      amountPaid: (row['amount_paid'] as num?)?.toDouble() ?? 0,
      balance: (row['balance'] as num?)?.toDouble() ??
          (row['amount_due'] as num).toDouble() - ((row['amount_paid'] as num?)?.toDouble() ?? 0),
      status: RentScheduleStatus.fromString(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );

    // Extract joined data
    String? tenantName;
    String? unitReference;
    String? buildingName;
    String? leaseId;

    final leaseData = row['leases'] as Map<String, dynamic>?;
    if (leaseData != null) {
      leaseId = leaseData['id'] as String?;

      final tenantData = leaseData['tenant'] as Map<String, dynamic>?;
      if (tenantData != null) {
        final firstName = tenantData['first_name'] as String? ?? '';
        final lastName = tenantData['last_name'] as String? ?? '';
        tenantName = '$firstName $lastName'.trim();
      }

      final unitData = leaseData['unit'] as Map<String, dynamic>?;
      if (unitData != null) {
        unitReference = unitData['reference'] as String?;

        final buildingData = unitData['building'] as Map<String, dynamic>?;
        if (buildingData != null) {
          buildingName = buildingData['name'] as String?;
        }
      }
    }

    return RentScheduleWithDetails(
      schedule: schedule,
      tenantName: tenantName,
      unitReference: unitReference,
      buildingName: buildingName,
      leaseId: leaseId,
    );
  }

  // ============================================================================
  // AGGREGATES
  // ============================================================================

  @override
  Future<TenantPaymentSummary> getTenantPaymentSummary(String tenantId) async {
    final data = await _datasource.getTenantPaymentSummaryData(tenantId);

    final recentPaymentModels = data['recent_payments'] as List;
    final recentPayments = recentPaymentModels
        .map((model) => model.toEntity() as Payment)
        .toList();

    return TenantPaymentSummary(
      tenantId: data['tenant_id'] as String,
      totalPaidAllTime: (data['total_paid_all_time'] as num).toDouble(),
      currentMonthDue: (data['current_month_due'] as num).toDouble(),
      currentMonthPaid: (data['current_month_paid'] as num).toDouble(),
      overdueCount: data['overdue_count'] as int,
      overdueTotal: (data['overdue_total'] as num).toDouble(),
      recentPayments: recentPayments,
    );
  }

  @override
  Future<double> getTotalCollected({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _datasource.getTotalCollected(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<double> getTotalOverdue() async {
    return _datasource.getTotalOverdue();
  }

  @override
  Future<PaymentsSummary> getPaymentsSummary() async {
    final data = await _datasource.getPaymentsSummaryData();

    return PaymentsSummary(
      totalDueThisMonth: (data['total_due_this_month'] as num).toDouble(),
      totalPaidThisMonth: (data['total_paid_this_month'] as num).toDouble(),
      totalOverdue: (data['total_overdue'] as num).toDouble(),
      overdueCount: data['overdue_count'] as int,
    );
  }

  // ============================================================================
  // PERMISSIONS
  // ============================================================================

  @override
  Future<bool> canManagePayments() async {
    return _datasource.canManagePayments();
  }

  @override
  Future<bool> canRecordPayments() async {
    return _datasource.canRecordPayments();
  }
}
