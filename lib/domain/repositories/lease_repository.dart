import '../entities/lease.dart';
import '../entities/rent_schedule.dart';

/// Lease repository interface (Domain layer)
/// Defines the contract for lease and rent schedule operations
abstract class LeaseRepository {
  // ============================================================================
  // LEASE OPERATIONS
  // ============================================================================

  /// Create a new lease and generate initial rent schedules
  /// Throws [LeaseValidationException] if data is invalid
  /// Throws [LeaseUnitOccupiedException] if unit already has active lease
  /// Throws [LeaseUnauthorizedException] if user doesn't have permission
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
  });

  /// Get all leases (paginated) with optional filters
  /// [page] starts at 1
  /// [limit] defaults to 20 items per page
  /// [status] filters by lease status
  /// [unitId] filters by specific unit
  /// [tenantId] filters by specific tenant
  /// Returns empty list if no leases found
  Future<List<Lease>> getLeases({
    int page = 1,
    int limit = 20,
    LeaseStatus? status,
    String? unitId,
    String? tenantId,
  });

  /// Get lease by ID with joined tenant and unit data
  /// Throws [LeaseNotFoundException] if not found
  /// Throws [LeaseUnauthorizedException] if user doesn't have access
  Future<Lease> getLeaseById(String id);

  /// Update existing lease
  /// Only provided fields will be updated
  /// Throws [LeaseNotFoundException] if not found
  /// Throws [LeaseCannotBeEditedException] if lease is terminated/expired
  /// Throws [LeaseUnauthorizedException] if user doesn't have permission
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
  });

  /// Terminate a lease
  /// Updates status to 'terminated' and cancels future rent schedules
  /// Updates unit status to 'available'
  /// Throws [LeaseNotFoundException] if not found
  /// Throws [LeaseCannotBeTerminatedException] if already terminated/expired
  /// Throws [LeaseUnauthorizedException] if user doesn't have permission
  Future<Lease> terminateLease({
    required String id,
    required DateTime terminationDate,
    required String terminationReason,
  });

  /// Delete lease by ID (only pending leases)
  /// Throws [LeaseNotFoundException] if not found
  /// Throws [LeaseCannotBeDeletedException] if not in pending status
  /// Throws [LeaseUnauthorizedException] if user doesn't have permission
  Future<void> deleteLease(String id);

  /// Get total count of leases with optional filters
  Future<int> getLeasesCount({
    LeaseStatus? status,
    String? unitId,
    String? tenantId,
  });

  /// Check if unit has an active or pending lease
  /// Returns the active lease if found, null otherwise
  Future<Lease?> getActiveLeaseForUnit(String unitId);

  /// Check if tenant has any active leases
  Future<List<Lease>> getActiveLeasesForTenant(String tenantId);

  // ============================================================================
  // RENT SCHEDULE OPERATIONS
  // ============================================================================

  /// Get rent schedules for a lease
  /// Ordered by due_date ascending
  Future<List<RentSchedule>> getRentSchedulesForLease(String leaseId);

  /// Get rent schedule by ID
  /// Throws [RentScheduleNotFoundException] if not found
  Future<RentSchedule> getRentScheduleById(String id);

  /// Record a payment on a rent schedule
  /// Updates amount_paid, balance, and status
  /// Throws [RentScheduleNotFoundException] if not found
  /// Throws [RentScheduleAlreadyPaidException] if already fully paid
  Future<RentSchedule> recordPayment({
    required String scheduleId,
    required double amount,
    required DateTime paymentDate,
    String? paymentMethod,
    String? reference,
    String? notes,
  });

  /// Get overdue rent schedules across all leases
  /// Returns schedules with due_date < today and status not 'paid' or 'cancelled'
  Future<List<RentSchedule>> getOverdueSchedules();

  /// Get upcoming rent schedules (due within next X days)
  Future<List<RentSchedule>> getUpcomingSchedules({int daysAhead = 30});

  /// Get rent schedules summary for a lease
  Future<RentSchedulesSummary> getRentSchedulesSummary(String leaseId);

  /// Generate rent schedules for a lease
  /// Called internally when creating a lease
  /// Can be called to regenerate schedules (e.g., after rent amount update)
  Future<List<RentSchedule>> generateRentSchedules({
    required String leaseId,
    required DateTime startDate,
    DateTime? endDate,
    required double amountDue,
    required int paymentDay,
  });

  /// Cancel future rent schedules for a lease
  /// Called when terminating a lease
  Future<void> cancelFutureSchedules({
    required String leaseId,
    required DateTime fromDate,
  });

  // ============================================================================
  // PERMISSION CHECKS
  // ============================================================================

  /// Check if current user can manage leases (create/edit/delete/terminate)
  /// Returns false for assistant role (read-only)
  Future<bool> canManageLeases();
}
