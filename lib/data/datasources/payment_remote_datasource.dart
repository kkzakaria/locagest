import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/payment_exceptions.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/payment_model.dart';
import '../models/rent_schedule_model.dart';

/// Remote datasource for payment operations via Supabase
class PaymentRemoteDatasource {
  final SupabaseClient _supabase;

  PaymentRemoteDatasource(this._supabase);

  // ============================================================================
  // CRUD OPERATIONS
  // ============================================================================

  /// Create a new payment for a rent schedule
  Future<PaymentModel> createPayment(CreatePaymentInput input) async {
    try {
      final response = await _supabase
          .from('payments')
          .insert(input.toJson())
          .select()
          .single();

      return PaymentModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        // Foreign key violation - schedule not found
        throw PaymentValidationException.scheduleNotFound();
      } else if (e.code == '23514') {
        // Check constraint violation
        if (e.message.contains('amount_positive')) {
          throw PaymentValidationException.invalidAmount();
        } else if (e.message.contains('check_fields')) {
          throw PaymentValidationException.missingCheckNumber();
        }
        throw PaymentValidationException(e.message);
      } else if (e.code == '42501') {
        throw const PaymentUnauthorizedException();
      }
      throw PaymentValidationException(e.message);
    }
  }

  /// Get a payment by ID
  Future<PaymentModel> getPaymentById(String id) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('id', id)
          .single();

      return PaymentModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const PaymentNotFoundException();
      } else if (e.code == '42501') {
        throw const PaymentUnauthorizedException();
      }
      throw PaymentValidationException(e.message);
    }
  }

  /// Get a rent schedule by ID
  Future<RentScheduleModel> getRentScheduleById(String id) async {
    try {
      final response = await _supabase
          .from('rent_schedules')
          .select()
          .eq('id', id)
          .single();

      return RentScheduleModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const PaymentNotFoundException();
      } else if (e.code == '42501') {
        throw const PaymentUnauthorizedException();
      }
      throw PaymentValidationException(e.message);
    }
  }

  /// Update an existing payment
  Future<PaymentModel> updatePayment(String id, UpdatePaymentInput input) async {
    try {
      final updateMap = input.toUpdateMap();
      if (updateMap.isEmpty) {
        return getPaymentById(id);
      }

      final response = await _supabase
          .from('payments')
          .update(updateMap)
          .eq('id', id)
          .select()
          .single();

      return PaymentModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const PaymentNotFoundException();
      } else if (e.code == '23514') {
        if (e.message.contains('amount_positive')) {
          throw PaymentValidationException.invalidAmount();
        }
        throw PaymentValidationException(e.message);
      } else if (e.code == '42501') {
        throw const PaymentUnauthorizedException();
      }
      throw PaymentValidationException(e.message);
    }
  }

  /// Delete a payment
  Future<void> deletePayment(String id) async {
    try {
      await _supabase.from('payments').delete().eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const PaymentNotFoundException();
      } else if (e.code == '42501') {
        throw const PaymentUnauthorizedException();
      }
      throw PaymentValidationException(e.message);
    }
  }

  // ============================================================================
  // QUERY OPERATIONS
  // ============================================================================

  /// Get all payments for a rent schedule
  Future<List<PaymentModel>> getPaymentsForSchedule(String rentScheduleId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('rent_schedule_id', rentScheduleId)
          .order('payment_date', ascending: false);

      return (response as List)
          .map((json) => PaymentModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw PaymentValidationException(e.message);
    }
  }

  /// Get all payments for a lease (across all schedules)
  Future<List<PaymentModel>> getPaymentsForLease(String leaseId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('*, rent_schedules!inner(lease_id)')
          .eq('rent_schedules.lease_id', leaseId)
          .order('payment_date', ascending: false);

      return (response as List)
          .map((json) => PaymentModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw PaymentValidationException(e.message);
    }
  }

  /// Get all payments for a tenant (across all leases)
  Future<List<PaymentModel>> getPaymentsForTenant(String tenantId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('*, rent_schedules!inner(lease_id, leases!inner(tenant_id))')
          .eq('rent_schedules.leases.tenant_id', tenantId)
          .order('payment_date', ascending: false);

      return (response as List)
          .map((json) => PaymentModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw PaymentValidationException(e.message);
    }
  }

  /// Get recent payments (last N payments)
  Future<List<PaymentModel>> getRecentPayments({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => PaymentModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw PaymentValidationException(e.message);
    }
  }

  /// Get payments by date range
  Future<List<PaymentModel>> getPaymentsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final start = startDate.toIso8601String().split('T')[0];
      final end = endDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('payments')
          .select()
          .gte('payment_date', start)
          .lte('payment_date', end)
          .order('payment_date', ascending: false);

      return (response as List)
          .map((json) => PaymentModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw PaymentValidationException(e.message);
    }
  }

  // ============================================================================
  // SCHEDULE QUERIES
  // ============================================================================

  /// Get all rent schedules with optional filters and joined details
  Future<List<Map<String, dynamic>>> getAllSchedulesWithDetails({
    String? status,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? tenantId,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final offset = (page - 1) * limit;

      var query = _supabase
          .from('rent_schedules')
          .select('''
            *,
            leases!inner(
              id,
              tenant:tenants(id, first_name, last_name),
              unit:units(id, reference, building:buildings(id, name))
            )
          ''');

      // Apply filters
      if (status != null) {
        query = query.eq('status', status);
      }
      if (periodStart != null) {
        query = query.gte('period_start', periodStart.toIso8601String().split('T')[0]);
      }
      if (periodEnd != null) {
        query = query.lte('period_end', periodEnd.toIso8601String().split('T')[0]);
      }
      if (tenantId != null) {
        query = query.eq('leases.tenant_id', tenantId);
      }

      final response = await query
          .order('due_date', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw PaymentValidationException(e.message);
    }
  }

  /// Get overdue schedules
  Future<List<Map<String, dynamic>>> getOverdueSchedulesWithDetails() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase
          .from('rent_schedules')
          .select('''
            *,
            leases!inner(
              id,
              tenant:tenants(id, first_name, last_name),
              unit:units(id, reference, building:buildings(id, name))
            )
          ''')
          .lt('due_date', today)
          .inFilter('status', ['pending', 'partial'])
          .order('due_date', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw PaymentValidationException(e.message);
    }
  }

  /// Get schedule count by status
  Future<Map<String, int>> getScheduleCountsByStatus() async {
    try {
      final response = await _supabase
          .from('rent_schedules')
          .select('status');

      final counts = <String, int>{
        'pending': 0,
        'partial': 0,
        'paid': 0,
        'overdue': 0,
        'cancelled': 0,
      };

      for (final row in response as List) {
        final status = row['status'] as String?;
        if (status != null && counts.containsKey(status)) {
          counts[status] = counts[status]! + 1;
        }
      }

      return counts;
    } on PostgrestException {
      return {
        'pending': 0,
        'partial': 0,
        'paid': 0,
        'overdue': 0,
        'cancelled': 0,
      };
    }
  }

  // ============================================================================
  // AGGREGATES
  // ============================================================================

  /// Get payment summary for a tenant
  Future<Map<String, dynamic>> getTenantPaymentSummaryData(String tenantId) async {
    try {
      // Get all payments for tenant
      final payments = await getPaymentsForTenant(tenantId);

      // Get current month schedules
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      final currentMonthSchedules = await _supabase
          .from('rent_schedules')
          .select('*, leases!inner(tenant_id)')
          .eq('leases.tenant_id', tenantId)
          .gte('period_start', monthStart.toIso8601String().split('T')[0])
          .lte('period_start', monthEnd.toIso8601String().split('T')[0]);

      // Get overdue schedules
      final today = now.toIso8601String().split('T')[0];
      final overdueSchedules = await _supabase
          .from('rent_schedules')
          .select('*, leases!inner(tenant_id)')
          .eq('leases.tenant_id', tenantId)
          .lt('due_date', today)
          .inFilter('status', ['pending', 'partial']);

      // Calculate totals
      double totalPaidAllTime = 0;
      for (final payment in payments) {
        totalPaidAllTime += payment.amount;
      }

      double currentMonthDue = 0;
      double currentMonthPaid = 0;
      for (final schedule in currentMonthSchedules as List) {
        currentMonthDue += (schedule['amount_due'] as num).toDouble();
        currentMonthPaid += (schedule['amount_paid'] as num).toDouble();
      }

      double overdueTotal = 0;
      for (final schedule in overdueSchedules as List) {
        final due = (schedule['amount_due'] as num).toDouble();
        final paid = (schedule['amount_paid'] as num).toDouble();
        overdueTotal += (due - paid);
      }

      return {
        'tenant_id': tenantId,
        'total_paid_all_time': totalPaidAllTime,
        'current_month_due': currentMonthDue,
        'current_month_paid': currentMonthPaid,
        'overdue_count': (overdueSchedules as List).length,
        'overdue_total': overdueTotal,
        'recent_payments': payments.take(10).toList(),
      };
    } on PostgrestException catch (e) {
      throw PaymentValidationException(e.message);
    }
  }

  /// Get total collected for a period
  Future<double> getTotalCollected({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final start = startDate.toIso8601String().split('T')[0];
      final end = endDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('payments')
          .select('amount')
          .gte('payment_date', start)
          .lte('payment_date', end);

      double total = 0;
      for (final row in response as List) {
        total += (row['amount'] as num).toDouble();
      }

      return total;
    } on PostgrestException {
      return 0;
    }
  }

  /// Get total overdue amount
  Future<double> getTotalOverdue() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase
          .from('rent_schedules')
          .select('amount_due, amount_paid')
          .lt('due_date', today)
          .inFilter('status', ['pending', 'partial']);

      double total = 0;
      for (final row in response as List) {
        final due = (row['amount_due'] as num).toDouble();
        final paid = (row['amount_paid'] as num).toDouble();
        total += (due - paid);
      }

      return total;
    } on PostgrestException {
      return 0;
    }
  }

  /// Get summary statistics for payments page
  Future<Map<String, dynamic>> getPaymentsSummaryData() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      final today = now.toIso8601String().split('T')[0];

      // Current month schedules
      final monthSchedules = await _supabase
          .from('rent_schedules')
          .select('amount_due, amount_paid, status')
          .gte('period_start', monthStart.toIso8601String().split('T')[0])
          .lte('period_start', monthEnd.toIso8601String().split('T')[0])
          .neq('status', 'cancelled');

      double totalDueThisMonth = 0;
      double totalPaidThisMonth = 0;
      for (final row in monthSchedules as List) {
        totalDueThisMonth += (row['amount_due'] as num).toDouble();
        totalPaidThisMonth += (row['amount_paid'] as num).toDouble();
      }

      // Overdue schedules
      final overdueSchedules = await _supabase
          .from('rent_schedules')
          .select('amount_due, amount_paid')
          .lt('due_date', today)
          .inFilter('status', ['pending', 'partial']);

      double totalOverdue = 0;
      int overdueCount = 0;
      for (final row in overdueSchedules as List) {
        final due = (row['amount_due'] as num).toDouble();
        final paid = (row['amount_paid'] as num).toDouble();
        totalOverdue += (due - paid);
        overdueCount++;
      }

      return {
        'total_due_this_month': totalDueThisMonth,
        'total_paid_this_month': totalPaidThisMonth,
        'total_overdue': totalOverdue,
        'overdue_count': overdueCount,
      };
    } on PostgrestException {
      return {
        'total_due_this_month': 0.0,
        'total_paid_this_month': 0.0,
        'total_overdue': 0.0,
        'overdue_count': 0,
      };
    }
  }

  // ============================================================================
  // PERMISSIONS
  // ============================================================================

  /// Check if current user can manage payments (update, delete)
  Future<bool> canManagePayments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      final role = response['role'] as String?;
      return role == 'admin' || role == 'gestionnaire';
    } catch (e) {
      return false;
    }
  }

  /// Check if current user can record new payments
  Future<bool> canRecordPayments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      final role = response['role'] as String?;
      // All roles can record payments
      return role == 'admin' || role == 'gestionnaire' || role == 'assistant';
    } catch (e) {
      return false;
    }
  }
}
