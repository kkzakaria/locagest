import '../entities/payment.dart';
import '../entities/rent_schedule.dart';

/// Input for creating a payment
class CreatePaymentInput {
  final String rentScheduleId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? reference;
  final String? checkNumber;
  final String? bankName;
  final String? notes;

  const CreatePaymentInput({
    required this.rentScheduleId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.reference,
    this.checkNumber,
    this.bankName,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'rent_schedule_id': rentScheduleId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String().split('T')[0],
        'payment_method': paymentMethod,
        if (reference != null) 'reference': reference,
        if (checkNumber != null) 'check_number': checkNumber,
        if (bankName != null) 'bank_name': bankName,
        if (notes != null) 'notes': notes,
      };
}

/// Input for updating a payment
class UpdatePaymentInput {
  final double? amount;
  final DateTime? paymentDate;
  final String? paymentMethod;
  final String? reference;
  final String? checkNumber;
  final String? bankName;
  final String? notes;

  const UpdatePaymentInput({
    this.amount,
    this.paymentDate,
    this.paymentMethod,
    this.reference,
    this.checkNumber,
    this.bankName,
    this.notes,
  });

  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (amount != null) map['amount'] = amount;
    if (paymentDate != null) {
      map['payment_date'] = paymentDate!.toIso8601String().split('T')[0];
    }
    if (paymentMethod != null) map['payment_method'] = paymentMethod;
    if (reference != null) map['reference'] = reference;
    if (checkNumber != null) map['check_number'] = checkNumber;
    if (bankName != null) map['bank_name'] = bankName;
    if (notes != null) map['notes'] = notes;
    return map;
  }
}

/// Tenant payment summary aggregate
class TenantPaymentSummary {
  final String tenantId;
  final double totalPaidAllTime;
  final double currentMonthDue;
  final double currentMonthPaid;
  final int overdueCount;
  final double overdueTotal;
  final List<Payment> recentPayments;

  const TenantPaymentSummary({
    required this.tenantId,
    required this.totalPaidAllTime,
    required this.currentMonthDue,
    required this.currentMonthPaid,
    required this.overdueCount,
    required this.overdueTotal,
    required this.recentPayments,
  });

  /// Current month balance (due - paid)
  double get currentMonthBalance => currentMonthDue - currentMonthPaid;

  /// Whether tenant has overdue payments
  bool get hasOverdue => overdueCount > 0;
}

/// Extended rent schedule with lease and tenant info for display
class RentScheduleWithDetails {
  final RentSchedule schedule;
  final String? tenantName;
  final String? unitReference;
  final String? buildingName;
  final String? leaseId;

  const RentScheduleWithDetails({
    required this.schedule,
    this.tenantName,
    this.unitReference,
    this.buildingName,
    this.leaseId,
  });
}

/// Payment repository interface
abstract class PaymentRepository {
  // ---------------------------------------------------------------------------
  // CRUD Operations
  // ---------------------------------------------------------------------------

  /// Create a new payment for a rent schedule
  Future<Payment> createPayment(CreatePaymentInput input);

  /// Get a payment by ID
  Future<Payment> getPaymentById(String id);

  /// Update an existing payment
  Future<Payment> updatePayment(String id, UpdatePaymentInput input);

  /// Delete a payment
  Future<void> deletePayment(String id);

  // ---------------------------------------------------------------------------
  // Query Operations
  // ---------------------------------------------------------------------------

  /// Get all payments for a rent schedule
  Future<List<Payment>> getPaymentsForSchedule(String rentScheduleId);

  /// Get all payments for a lease (across all schedules)
  Future<List<Payment>> getPaymentsForLease(String leaseId);

  /// Get all payments for a tenant (across all leases)
  Future<List<Payment>> getPaymentsForTenant(String tenantId);

  /// Get recent payments (last N payments)
  Future<List<Payment>> getRecentPayments({int limit = 20});

  /// Get payments by date range
  Future<List<Payment>> getPaymentsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  // ---------------------------------------------------------------------------
  // Schedule Queries
  // ---------------------------------------------------------------------------

  /// Get all rent schedules with optional filters
  Future<List<RentScheduleWithDetails>> getAllSchedules({
    String? status,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? tenantId,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  });

  /// Get overdue schedules (due_date < today, status in [pending, partial])
  Future<List<RentScheduleWithDetails>> getOverdueSchedules();

  /// Get schedule count by status
  Future<Map<String, int>> getScheduleCountsByStatus();

  // ---------------------------------------------------------------------------
  // Aggregates
  // ---------------------------------------------------------------------------

  /// Get payment summary for a tenant
  Future<TenantPaymentSummary> getTenantPaymentSummary(String tenantId);

  /// Get total collected for a period
  Future<double> getTotalCollected({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get total overdue amount
  Future<double> getTotalOverdue();

  /// Get summary statistics for payments page
  Future<PaymentsSummary> getPaymentsSummary();

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  /// Check if current user can manage payments (update, delete)
  Future<bool> canManagePayments();

  /// Check if current user can record new payments
  Future<bool> canRecordPayments();
}

/// Summary statistics for the payments page header
class PaymentsSummary {
  final double totalDueThisMonth;
  final double totalPaidThisMonth;
  final double totalOverdue;
  final int overdueCount;

  const PaymentsSummary({
    required this.totalDueThisMonth,
    required this.totalPaidThisMonth,
    required this.totalOverdue,
    required this.overdueCount,
  });

  double get collectionRate {
    if (totalDueThisMonth == 0) return 0;
    return (totalPaidThisMonth / totalDueThisMonth) * 100;
  }
}
