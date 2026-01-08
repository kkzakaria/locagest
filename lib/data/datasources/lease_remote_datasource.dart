import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/lease_exceptions.dart';
import '../../domain/entities/lease.dart';
import '../models/lease_model.dart';
import '../models/rent_schedule_model.dart';

/// Remote datasource for lease operations via Supabase
class LeaseRemoteDatasource {
  final SupabaseClient _supabase;

  LeaseRemoteDatasource(this._supabase);

  // ============================================================================
  // LEASE OPERATIONS
  // ============================================================================

  /// Create a new lease
  Future<LeaseModel> createLease(CreateLeaseInput input) async {
    try {
      final response = await _supabase
          .from('leases')
          .insert(input.toJson())
          .select('*, tenant:tenants(*), unit:units(*)')
          .single();

      return LeaseModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique constraint violation - unit already has active lease
        throw const LeaseUnitOccupiedException();
      } else if (e.code == '23514') {
        // Check constraint violation
        throw LeaseValidationException('Les données saisies sont invalides: ${e.message}');
      } else if (e.code == '23503') {
        // Foreign key violation
        if (e.message.contains('tenant')) {
          throw LeaseValidationException.tenantNotFound();
        } else if (e.message.contains('unit')) {
          throw LeaseValidationException.unitNotFound();
        }
        throw LeaseValidationException(e.message);
      } else if (e.code == '42501') {
        throw const LeaseUnauthorizedException();
      }
      throw LeaseValidationException(e.message);
    }
  }

  /// Get all leases with pagination and filters
  Future<List<LeaseModel>> getLeases({
    int page = 1,
    int limit = 20,
    LeaseStatus? status,
    String? unitId,
    String? tenantId,
  }) async {
    final offset = (page - 1) * limit;

    try {
      var query = _supabase
          .from('leases')
          .select('*, tenant:tenants(*), unit:units(*, building:buildings(*))');

      if (status != null) {
        query = query.eq('status', status.toJson());
      }
      if (unitId != null) {
        query = query.eq('unit_id', unitId);
      }
      if (tenantId != null) {
        query = query.eq('tenant_id', tenantId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => LeaseModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw LeaseValidationException(e.message);
    }
  }

  /// Get lease by ID with joined data
  Future<LeaseModel> getLeaseById(String id) async {
    try {
      final response = await _supabase
          .from('leases')
          .select('*, tenant:tenants(*), unit:units(*, building:buildings(*))')
          .eq('id', id)
          .single();

      return LeaseModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const LeaseNotFoundException();
      } else if (e.code == '42501') {
        throw const LeaseUnauthorizedException();
      }
      throw LeaseValidationException(e.message);
    }
  }

  /// Update lease
  Future<LeaseModel> updateLease({
    required String id,
    required UpdateLeaseInput input,
  }) async {
    try {
      final updateMap = input.toUpdateMap();
      if (updateMap.isEmpty) {
        return getLeaseById(id);
      }

      final response = await _supabase
          .from('leases')
          .update(updateMap)
          .eq('id', id)
          .select('*, tenant:tenants(*), unit:units(*, building:buildings(*))')
          .single();

      return LeaseModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const LeaseNotFoundException();
      } else if (e.code == '23514') {
        throw LeaseValidationException('Les données saisies sont invalides: ${e.message}');
      } else if (e.code == '42501') {
        throw const LeaseUnauthorizedException();
      }
      throw LeaseValidationException(e.message);
    }
  }

  /// Terminate a lease
  Future<LeaseModel> terminateLease({
    required String id,
    required TerminateLeaseInput input,
  }) async {
    try {
      final response = await _supabase
          .from('leases')
          .update({
            'status': 'terminated',
            'termination_date': input.terminationDate,
            'termination_reason': input.terminationReason,
          })
          .eq('id', id)
          .select('*, tenant:tenants(*), unit:units(*, building:buildings(*))')
          .single();

      return LeaseModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const LeaseNotFoundException();
      } else if (e.code == '42501') {
        throw const LeaseUnauthorizedException();
      }
      throw LeaseValidationException(e.message);
    }
  }

  /// Delete lease
  Future<void> deleteLease(String id) async {
    try {
      // First check if lease can be deleted (only pending)
      final lease = await getLeaseById(id);
      if (lease.status != 'pending') {
        throw const LeaseCannotBeDeletedException();
      }

      await _supabase.from('leases').delete().eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const LeaseNotFoundException();
      } else if (e.code == '42501') {
        throw const LeaseUnauthorizedException();
      }
      throw LeaseValidationException(e.message);
    }
  }

  /// Get leases count
  Future<int> getLeasesCount({
    LeaseStatus? status,
    String? unitId,
    String? tenantId,
  }) async {
    try {
      var query = _supabase.from('leases').select('id');

      if (status != null) {
        query = query.eq('status', status.toJson());
      }
      if (unitId != null) {
        query = query.eq('unit_id', unitId);
      }
      if (tenantId != null) {
        query = query.eq('tenant_id', tenantId);
      }

      final response = await query;
      return (response as List).length;
    } on PostgrestException {
      return 0;
    }
  }

  /// Get active lease for a unit
  Future<LeaseModel?> getActiveLeaseForUnit(String unitId) async {
    try {
      final response = await _supabase
          .from('leases')
          .select('*, tenant:tenants(*), unit:units(*)')
          .eq('unit_id', unitId)
          .inFilter('status', ['active', 'pending'])
          .maybeSingle();

      if (response == null) return null;
      return LeaseModel.fromJson(response);
    } on PostgrestException {
      return null;
    }
  }

  /// Get active leases for tenant
  Future<List<LeaseModel>> getActiveLeasesForTenant(String tenantId) async {
    try {
      final response = await _supabase
          .from('leases')
          .select('*, tenant:tenants(*), unit:units(*)')
          .eq('tenant_id', tenantId)
          .eq('status', 'active');

      return (response as List)
          .map((json) => LeaseModel.fromJson(json))
          .toList();
    } on PostgrestException {
      return [];
    }
  }

  // ============================================================================
  // RENT SCHEDULE OPERATIONS
  // ============================================================================

  /// Get rent schedules for a lease
  Future<List<RentScheduleModel>> getRentSchedulesForLease(String leaseId) async {
    try {
      final response = await _supabase
          .from('rent_schedules')
          .select()
          .eq('lease_id', leaseId)
          .order('due_date', ascending: true);

      return (response as List)
          .map((json) => RentScheduleModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw LeaseValidationException(e.message);
    }
  }

  /// Get rent schedule by ID
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
        throw const RentScheduleNotFoundException();
      }
      throw LeaseValidationException(e.message);
    }
  }

  /// Record payment on a rent schedule
  Future<RentScheduleModel> recordPayment({
    required String scheduleId,
    required double amount,
  }) async {
    try {
      // Get current schedule
      final current = await getRentScheduleById(scheduleId);

      if (current.status == 'paid') {
        throw const RentScheduleAlreadyPaidException();
      }
      if (current.status == 'cancelled') {
        throw const RentScheduleAlreadyPaidException();
      }

      final newAmountPaid = current.amountPaid + amount;
      final newBalance = current.amountDue - newAmountPaid;

      // Determine new status
      String newStatus;
      if (newBalance <= 0) {
        newStatus = 'paid';
      } else if (newAmountPaid > 0) {
        newStatus = 'partial';
      } else {
        newStatus = current.status;
      }

      final response = await _supabase
          .from('rent_schedules')
          .update({
            'amount_paid': newAmountPaid,
            'balance': newBalance < 0 ? 0 : newBalance,
            'status': newStatus,
          })
          .eq('id', scheduleId)
          .select()
          .single();

      return RentScheduleModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const RentScheduleNotFoundException();
      }
      throw LeaseValidationException(e.message);
    }
  }

  /// Get overdue schedules
  Future<List<RentScheduleModel>> getOverdueSchedules() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _supabase
          .from('rent_schedules')
          .select()
          .lt('due_date', today)
          .not('status', 'in', '(paid,cancelled)')
          .order('due_date', ascending: true);

      return (response as List)
          .map((json) => RentScheduleModel.fromJson(json))
          .toList();
    } on PostgrestException {
      return [];
    }
  }

  /// Get upcoming schedules
  Future<List<RentScheduleModel>> getUpcomingSchedules({int daysAhead = 30}) async {
    try {
      final today = DateTime.now();
      final futureDate = today.add(Duration(days: daysAhead));

      final response = await _supabase
          .from('rent_schedules')
          .select()
          .gte('due_date', today.toIso8601String().split('T')[0])
          .lte('due_date', futureDate.toIso8601String().split('T')[0])
          .not('status', 'in', '(paid,cancelled)')
          .order('due_date', ascending: true);

      return (response as List)
          .map((json) => RentScheduleModel.fromJson(json))
          .toList();
    } on PostgrestException {
      return [];
    }
  }

  /// Insert rent schedules (batch)
  Future<List<RentScheduleModel>> insertRentSchedules(
    List<Map<String, dynamic>> schedules,
  ) async {
    if (schedules.isEmpty) return [];

    try {
      final response = await _supabase
          .from('rent_schedules')
          .insert(schedules)
          .select();

      return (response as List)
          .map((json) => RentScheduleModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw LeaseValidationException(e.message);
    }
  }

  /// Cancel future rent schedules
  Future<void> cancelFutureSchedules({
    required String leaseId,
    required DateTime fromDate,
  }) async {
    try {
      await _supabase
          .from('rent_schedules')
          .update({'status': 'cancelled'})
          .eq('lease_id', leaseId)
          .gte('due_date', fromDate.toIso8601String().split('T')[0])
          .neq('status', 'paid');
    } on PostgrestException catch (e) {
      throw LeaseValidationException(e.message);
    }
  }

  /// Delete all rent schedules for a lease (used when deleting pending lease)
  Future<void> deleteSchedulesForLease(String leaseId) async {
    try {
      await _supabase
          .from('rent_schedules')
          .delete()
          .eq('lease_id', leaseId);
    } on PostgrestException catch (e) {
      throw LeaseValidationException(e.message);
    }
  }

  // ============================================================================
  // UNIT STATUS OPERATIONS
  // ============================================================================

  /// Update unit status
  Future<void> updateUnitStatus(String unitId, String status) async {
    try {
      await _supabase
          .from('units')
          .update({'status': status})
          .eq('id', unitId);
    } on PostgrestException {
      // Ignore errors - unit status is best-effort
    }
  }

  // ============================================================================
  // PERMISSION CHECKS
  // ============================================================================

  /// Check if user can manage leases
  Future<bool> canManageLeases() async {
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
}
