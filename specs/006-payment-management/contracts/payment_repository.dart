// Payment Repository Interface Contract
//
// This file defines the contract for the payment repository.
// Implementation will be in lib/data/repositories/payment_repository_impl.dart
//
// Feature: 006-payment-management
// Date: 2026-01-08

// =============================================================================
// ENTITIES (Domain Layer)
// =============================================================================

/// Payment method enumeration
enum PaymentMethod {
  cash,
  check,
  transfer,
  mobileMoney;

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Especes';
      case PaymentMethod.check:
        return 'Cheque';
      case PaymentMethod.transfer:
        return 'Virement bancaire';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
    }
  }

  String toJson() {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.check:
        return 'check';
      case PaymentMethod.transfer:
        return 'transfer';
      case PaymentMethod.mobileMoney:
        return 'mobile_money';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'check':
        return PaymentMethod.check;
      case 'transfer':
        return PaymentMethod.transfer;
      case 'mobile_money':
        return PaymentMethod.mobileMoney;
      default:
        return PaymentMethod.cash;
    }
  }
}

/// Payment entity (Domain Layer)
class Payment {
  final String id;
  final String rentScheduleId;
  final double amount;
  final DateTime paymentDate;
  final PaymentMethod paymentMethod;
  final String? reference;
  final String? checkNumber;
  final String? bankName;
  final String receiptNumber;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.rentScheduleId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.reference,
    this.checkNumber,
    this.bankName,
    required this.receiptNumber,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  // Computed properties will be in actual entity
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
}

// =============================================================================
// REPOSITORY INTERFACE (Domain Layer)
// =============================================================================

/// Payment repository interface
abstract class PaymentRepository {
  // ---------------------------------------------------------------------------
  // CRUD Operations
  // ---------------------------------------------------------------------------

  /// Create a new payment for a rent schedule
  ///
  /// Throws: Exception if validation fails or DB error
  /// Returns: Created payment with generated receipt number
  Future<Payment> createPayment({
    required String rentScheduleId,
    required double amount,
    required DateTime paymentDate,
    required PaymentMethod paymentMethod,
    String? reference,
    String? checkNumber,
    String? bankName,
    String? notes,
  });

  /// Get a payment by ID
  ///
  /// Throws: Exception if not found
  Future<Payment> getPaymentById(String id);

  /// Update an existing payment
  ///
  /// Only amount, paymentDate, paymentMethod, reference, checkNumber,
  /// bankName, and notes can be updated
  ///
  /// Throws: Exception if not found or unauthorized
  Future<Payment> updatePayment({
    required String id,
    double? amount,
    DateTime? paymentDate,
    PaymentMethod? paymentMethod,
    String? reference,
    String? checkNumber,
    String? bankName,
    String? notes,
  });

  /// Delete a payment
  ///
  /// Triggers recalculation of rent_schedule amounts
  ///
  /// Throws: Exception if not found or unauthorized
  Future<void> deletePayment(String id);

  // ---------------------------------------------------------------------------
  // Query Operations
  // ---------------------------------------------------------------------------

  /// Get all payments for a rent schedule
  ///
  /// Returns: List of payments ordered by payment_date DESC
  Future<List<Payment>> getPaymentsForSchedule(String rentScheduleId);

  /// Get all payments for a lease (across all schedules)
  ///
  /// Returns: List of payments ordered by payment_date DESC
  Future<List<Payment>> getPaymentsForLease(String leaseId);

  /// Get all payments for a tenant (across all leases)
  ///
  /// Returns: List of payments ordered by payment_date DESC
  Future<List<Payment>> getPaymentsForTenant(String tenantId);

  /// Get recent payments (last N payments)
  ///
  /// Returns: List of payments with schedule/lease/tenant info
  Future<List<Payment>> getRecentPayments({int limit = 20});

  /// Get payments by date range
  ///
  /// Returns: Filtered list of payments
  Future<List<Payment>> getPaymentsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  // ---------------------------------------------------------------------------
  // Schedule Queries (Extended from existing)
  // ---------------------------------------------------------------------------

  /// Get all rent schedules with optional filters
  ///
  /// Filters: status, period (month/year), tenantId
  /// Returns: List with pagination support
  Future<List<dynamic>> getAllSchedules({
    String? status,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? tenantId,
    int page = 1,
    int limit = 20,
  });

  /// Get overdue schedules (due_date < today, status in [pending, partial])
  ///
  /// Returns: List ordered by due_date ASC (oldest first)
  Future<List<dynamic>> getOverdueSchedules();

  /// Get schedule count by status
  ///
  /// Returns: Map of status -> count
  Future<Map<String, int>> getScheduleCountsByStatus();

  // ---------------------------------------------------------------------------
  // Aggregates
  // ---------------------------------------------------------------------------

  /// Get payment summary for a tenant
  ///
  /// Returns: Aggregate with totals and recent payments
  Future<TenantPaymentSummary> getTenantPaymentSummary(String tenantId);

  /// Get total collected for a period
  ///
  /// Returns: Sum of all payments in date range
  Future<double> getTotalCollected({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get total overdue amount
  ///
  /// Returns: Sum of balance on all overdue schedules
  Future<double> getTotalOverdue();

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  /// Check if current user can manage payments (create, update, delete)
  ///
  /// Returns: true for admin and gestionnaire, false for assistant (read-only + insert)
  Future<bool> canManagePayments();

  /// Check if current user can record new payments
  ///
  /// Returns: true for all authenticated roles
  Future<bool> canRecordPayments();
}

// =============================================================================
// INPUT MODELS (Data Layer)
// =============================================================================

/// Input for creating a payment
class CreatePaymentInput {
  final String rentScheduleId;
  final double amount;
  final String paymentDate; // ISO date string
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
        'payment_date': paymentDate,
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
  final String? paymentDate;
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
    if (paymentDate != null) map['payment_date'] = paymentDate;
    if (paymentMethod != null) map['payment_method'] = paymentMethod;
    if (reference != null) map['reference'] = reference;
    if (checkNumber != null) map['check_number'] = checkNumber;
    if (bankName != null) map['bank_name'] = bankName;
    if (notes != null) map['notes'] = notes;
    return map;
  }
}
