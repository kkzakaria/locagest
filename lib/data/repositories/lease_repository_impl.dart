import '../../domain/entities/lease.dart';
import '../../domain/entities/rent_schedule.dart';
import '../../domain/repositories/lease_repository.dart';
import '../datasources/lease_remote_datasource.dart';
import '../models/lease_model.dart';

/// Implementation of LeaseRepository using remote datasource
class LeaseRepositoryImpl implements LeaseRepository {
  final LeaseRemoteDatasource _datasource;

  LeaseRepositoryImpl(this._datasource);

  // ============================================================================
  // LEASE OPERATIONS
  // ============================================================================

  @override
  Future<Lease> createLease({
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
    // Calculate status based on start date
    final now = DateTime.now();
    final isInFuture = startDate.isAfter(now);
    final status = isInFuture ? 'pending' : 'active';

    final input = CreateLeaseInput(
      unitId: unitId,
      tenantId: tenantId,
      startDate: startDate.toIso8601String().split('T')[0],
      endDate: endDate?.toIso8601String().split('T')[0],
      durationMonths: durationMonths,
      rentAmount: rentAmount,
      chargesAmount: chargesAmount,
      depositAmount: depositAmount,
      depositPaid: depositPaid,
      paymentDay: paymentDay,
      annualRevision: annualRevision,
      revisionRate: revisionRate,
      status: status,
      notes: notes,
    );

    final model = await _datasource.createLease(input);
    final lease = model.toEntity();

    // Generate rent schedules
    await generateRentSchedules(
      leaseId: lease.id,
      startDate: startDate,
      endDate: endDate,
      amountDue: rentAmount + chargesAmount,
      paymentDay: paymentDay,
    );

    // Update unit status to occupied (if lease is active)
    if (status == 'active') {
      await _datasource.updateUnitStatus(unitId, 'occupied');
    }

    return lease;
  }

  @override
  Future<List<Lease>> getLeases({
    int page = 1,
    int limit = 20,
    LeaseStatus? status,
    String? unitId,
    String? tenantId,
  }) async {
    final models = await _datasource.getLeases(
      page: page,
      limit: limit,
      status: status,
      unitId: unitId,
      tenantId: tenantId,
    );

    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Lease> getLeaseById(String id) async {
    final model = await _datasource.getLeaseById(id);
    return model.toEntity();
  }

  @override
  Future<Lease> updateLease({
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
    final input = UpdateLeaseInput(
      endDate: endDate?.toIso8601String().split('T')[0],
      rentAmount: rentAmount,
      chargesAmount: chargesAmount,
      depositAmount: depositAmount,
      depositPaid: depositPaid,
      annualRevision: annualRevision,
      revisionRate: revisionRate,
      notes: notes,
    );

    final model = await _datasource.updateLease(id: id, input: input);
    return model.toEntity();
  }

  @override
  Future<Lease> terminateLease({
    required String id,
    required DateTime terminationDate,
    required String terminationReason,
  }) async {
    final input = TerminateLeaseInput(
      terminationDate: terminationDate.toIso8601String().split('T')[0],
      terminationReason: terminationReason,
    );

    // Get current lease to access unitId
    final currentLease = await _datasource.getLeaseById(id);

    final model = await _datasource.terminateLease(id: id, input: input);

    // Cancel future rent schedules
    await cancelFutureSchedules(
      leaseId: id,
      fromDate: terminationDate,
    );

    // Update unit status to available
    await _datasource.updateUnitStatus(currentLease.unitId, 'available');

    return model.toEntity();
  }

  @override
  Future<void> deleteLease(String id) async {
    // Get lease to check status and get unitId
    final lease = await _datasource.getLeaseById(id);

    // Delete rent schedules first
    await _datasource.deleteSchedulesForLease(id);

    // Delete the lease
    await _datasource.deleteLease(id);

    // If lease was pending but unit was marked, reset it
    await _datasource.updateUnitStatus(lease.unitId, 'available');
  }

  @override
  Future<int> getLeasesCount({
    LeaseStatus? status,
    String? unitId,
    String? tenantId,
  }) async {
    return _datasource.getLeasesCount(
      status: status,
      unitId: unitId,
      tenantId: tenantId,
    );
  }

  @override
  Future<Lease?> getActiveLeaseForUnit(String unitId) async {
    final model = await _datasource.getActiveLeaseForUnit(unitId);
    return model?.toEntity();
  }

  @override
  Future<List<Lease>> getActiveLeasesForTenant(String tenantId) async {
    final models = await _datasource.getActiveLeasesForTenant(tenantId);
    return models.map((model) => model.toEntity()).toList();
  }

  // ============================================================================
  // RENT SCHEDULE OPERATIONS
  // ============================================================================

  @override
  Future<List<RentSchedule>> getRentSchedulesForLease(String leaseId) async {
    final models = await _datasource.getRentSchedulesForLease(leaseId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<RentSchedule> getRentScheduleById(String id) async {
    final model = await _datasource.getRentScheduleById(id);
    return model.toEntity();
  }

  @override
  Future<RentSchedule> recordPayment({
    required String scheduleId,
    required double amount,
    required DateTime paymentDate,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) async {
    // For now, we just update the schedule amounts
    // Payment details would go to a separate payments table in the future
    final model = await _datasource.recordPayment(
      scheduleId: scheduleId,
      amount: amount,
    );
    return model.toEntity();
  }

  @override
  Future<List<RentSchedule>> getOverdueSchedules() async {
    final models = await _datasource.getOverdueSchedules();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<RentSchedule>> getUpcomingSchedules({int daysAhead = 30}) async {
    final models = await _datasource.getUpcomingSchedules(daysAhead: daysAhead);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<RentSchedulesSummary> getRentSchedulesSummary(String leaseId) async {
    final schedules = await getRentSchedulesForLease(leaseId);
    return RentSchedulesSummary.fromSchedules(schedules);
  }

  @override
  Future<List<RentSchedule>> generateRentSchedules({
    required String leaseId,
    required DateTime startDate,
    DateTime? endDate,
    required double amountDue,
    required int paymentDay,
  }) async {
    final schedules = <Map<String, dynamic>>[];

    // Calculate end date for schedule generation
    // If no end date, generate 12 months ahead
    final effectiveEndDate = endDate ?? startDate.add(const Duration(days: 365));

    // Start from the first payment period
    var currentDate = DateTime(startDate.year, startDate.month, 1);

    // If start date is after payment day, first period is next month
    if (startDate.day > paymentDay) {
      currentDate = DateTime(startDate.year, startDate.month + 1, 1);
    }

    while (currentDate.isBefore(effectiveEndDate) ||
        (currentDate.year == effectiveEndDate.year &&
            currentDate.month == effectiveEndDate.month)) {
      // Calculate period start and end
      final periodStart = DateTime(currentDate.year, currentDate.month, 1);
      final periodEnd = DateTime(currentDate.year, currentDate.month + 1, 0);

      // Due date is the payment day of the month
      final dueDay = paymentDay > periodEnd.day ? periodEnd.day : paymentDay;
      final dueDate = DateTime(currentDate.year, currentDate.month, dueDay);

      // Determine initial status
      final now = DateTime.now();
      String status;
      if (dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
        status = 'overdue';
      } else {
        status = 'pending';
      }

      schedules.add({
        'lease_id': leaseId,
        'due_date': dueDate.toIso8601String().split('T')[0],
        'period_start': periodStart.toIso8601String().split('T')[0],
        'period_end': periodEnd.toIso8601String().split('T')[0],
        'amount_due': amountDue,
        'amount_paid': 0,
        // Note: 'balance' is a computed column in PostgreSQL (GENERATED ALWAYS AS)
        'status': status,
      });

      // Move to next month
      currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
    }

    final models = await _datasource.insertRentSchedules(schedules);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> cancelFutureSchedules({
    required String leaseId,
    required DateTime fromDate,
  }) async {
    await _datasource.cancelFutureSchedules(
      leaseId: leaseId,
      fromDate: fromDate,
    );
  }

  // ============================================================================
  // PERMISSION CHECKS
  // ============================================================================

  @override
  Future<bool> canManageLeases() async {
    return _datasource.canManageLeases();
  }
}
