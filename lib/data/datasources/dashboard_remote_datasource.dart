import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/dashboard_exceptions.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/overdue_rent.dart';
import '../../domain/entities/expiring_lease.dart';

/// Remote datasource for dashboard operations via Supabase
/// Implements optimized parallel queries for dashboard KPIs
class DashboardRemoteDatasource {
  final SupabaseClient _supabase;

  DashboardRemoteDatasource(this._supabase);

  // ===========================================================================
  // MAIN DASHBOARD STATS (T017)
  // ===========================================================================

  /// Get all dashboard statistics using parallel queries
  /// Performance target: <2 seconds
  Future<DashboardStats> getDashboardStats() async {
    try {
      // Execute all count queries in parallel for optimal performance
      final results = await Future.wait([
        _getBuildingsCount(), // 0
        _getActiveTenantsCount(), // 1
        _getTotalUnitsCount(), // 2
        _getOccupiedUnitsCount(), // 3
        _getMonthlyRevenueCollected(), // 4
        _getMonthlyRevenueDue(), // 5
        _getOverdueCount(), // 6
        _getOverdueAmount(), // 7
        _getExpiringLeasesCount(), // 8
      ]);

      return DashboardStats(
        buildingsCount: results[0] as int,
        activeTenantsCount: results[1] as int,
        totalUnitsCount: results[2] as int,
        occupiedUnitsCount: results[3] as int,
        monthlyRevenueCollected: results[4] as double,
        monthlyRevenueDue: results[5] as double,
        overdueCount: results[6] as int,
        overdueAmount: results[7] as double,
        expiringLeasesCount: results[8] as int,
      );
    } on PostgrestException catch (e) {
      throw DashboardLoadException.queryFailed(e);
    } catch (e) {
      if (e is DashboardException) rethrow;
      throw DashboardLoadException.queryFailed(e);
    }
  }

  // ===========================================================================
  // INDIVIDUAL COUNT QUERIES (T012-T016)
  // ===========================================================================

  /// Get total buildings count (T012)
  Future<int> _getBuildingsCount() async {
    final response = await _supabase
        .from('buildings')
        .select()
        .count(CountOption.exact);
    return response.count;
  }

  /// Get active tenants count (T013)
  /// Active tenant = tenant with at least one active lease
  Future<int> _getActiveTenantsCount() async {
    final response = await _supabase
        .from('leases')
        .select('tenant_id')
        .eq('status', 'active');

    // Get unique tenant IDs
    final tenantIds = <String>{};
    for (final row in response as List) {
      final tenantId = row['tenant_id'] as String?;
      if (tenantId != null) {
        tenantIds.add(tenantId);
      }
    }
    return tenantIds.length;
  }

  /// Get total units count (T014)
  Future<int> _getTotalUnitsCount() async {
    final response = await _supabase
        .from('units')
        .select()
        .count(CountOption.exact);
    return response.count;
  }

  /// Get occupied units count (T014)
  Future<int> _getOccupiedUnitsCount() async {
    final response = await _supabase
        .from('units')
        .select()
        .eq('status', 'occupied')
        .count(CountOption.exact);
    return response.count;
  }

  /// Get monthly revenue collected (T015)
  /// Sum of payments received in current month
  Future<double> _getMonthlyRevenueCollected() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final start = monthStart.toIso8601String().split('T')[0];
    final end = monthEnd.toIso8601String().split('T')[0];

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
  }

  /// Get monthly revenue due (T015)
  /// Sum of rent_schedules.amount_due for current month
  Future<double> _getMonthlyRevenueDue() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final start = monthStart.toIso8601String().split('T')[0];
    final end = monthEnd.toIso8601String().split('T')[0];

    final response = await _supabase
        .from('rent_schedules')
        .select('amount_due')
        .gte('period_start', start)
        .lte('period_start', end)
        .neq('status', 'cancelled');

    double total = 0;
    for (final row in response as List) {
      total += (row['amount_due'] as num).toDouble();
    }
    return total;
  }

  /// Get overdue count (T016)
  Future<int> _getOverdueCount() async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _supabase
        .from('rent_schedules')
        .select()
        .lt('due_date', today)
        .inFilter('status', ['pending', 'partial'])
        .count(CountOption.exact);

    return response.count;
  }

  /// Get overdue amount (T016)
  /// Sum of (amount_due - amount_paid) for overdue schedules
  Future<double> _getOverdueAmount() async {
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
  }

  /// Get expiring leases count
  /// Count of active leases expiring within 30 days
  Future<int> _getExpiringLeasesCount() async {
    final today = DateTime.now();
    final futureDate = today.add(const Duration(days: 30));

    final todayStr = today.toIso8601String().split('T')[0];
    final futureStr = futureDate.toIso8601String().split('T')[0];

    final response = await _supabase
        .from('leases')
        .select()
        .eq('status', 'active')
        .not('end_date', 'is', null)
        .gte('end_date', todayStr)
        .lte('end_date', futureStr)
        .count(CountOption.exact);

    return response.count;
  }

  // ===========================================================================
  // OVERDUE RENTS QUERIES (US2)
  // ===========================================================================

  /// Get top N overdue rent schedules with full details
  Future<List<OverdueRent>> getOverdueRents({int limit = 5}) async {
    try {
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('rent_schedules')
          .select('''
            id,
            lease_id,
            due_date,
            amount_due,
            amount_paid,
            leases!inner(
              id,
              tenant:tenants(first_name, last_name),
              unit:units(reference, building:buildings(name))
            )
          ''')
          .lt('due_date', todayStr)
          .inFilter('status', ['pending', 'partial'])
          .order('due_date', ascending: true)
          .limit(limit);

      final List<OverdueRent> overdueRents = [];

      for (final row in response as List) {
        final lease = row['leases'] as Map<String, dynamic>;
        final tenant = lease['tenant'] as Map<String, dynamic>;
        final unit = lease['unit'] as Map<String, dynamic>;
        final building = unit['building'] as Map<String, dynamic>;

        final dueDate = DateTime.parse(row['due_date'] as String);
        final daysOverdue = today.difference(dueDate).inDays;

        overdueRents.add(OverdueRent(
          scheduleId: row['id'] as String,
          leaseId: row['lease_id'] as String,
          tenantName: '${tenant['first_name']} ${tenant['last_name']}',
          unitReference: unit['reference'] as String,
          buildingName: building['name'] as String,
          dueDate: dueDate,
          amountDue: (row['amount_due'] as num).toDouble(),
          amountPaid: (row['amount_paid'] as num).toDouble(),
          daysOverdue: daysOverdue,
        ));
      }

      return overdueRents;
    } on PostgrestException catch (e) {
      throw DashboardLoadException.queryFailed(e);
    }
  }

  /// Get total count of overdue rent schedules
  Future<int> getTotalOverdueCount() async {
    return _getOverdueCount();
  }

  // ===========================================================================
  // EXPIRING LEASES QUERIES (US3)
  // ===========================================================================

  /// Get leases expiring within specified days
  Future<List<ExpiringLease>> getExpiringLeases({int daysAhead = 30}) async {
    try {
      final today = DateTime.now();
      final futureDate = today.add(Duration(days: daysAhead));

      final todayStr = today.toIso8601String().split('T')[0];
      final futureStr = futureDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('leases')
          .select('''
            id,
            end_date,
            rent_amount,
            charges_amount,
            tenant:tenants(first_name, last_name),
            unit:units(reference, building:buildings(name))
          ''')
          .eq('status', 'active')
          .not('end_date', 'is', null)
          .gte('end_date', todayStr)
          .lte('end_date', futureStr)
          .order('end_date', ascending: true);

      final List<ExpiringLease> expiringLeases = [];

      for (final row in response as List) {
        final tenant = row['tenant'] as Map<String, dynamic>;
        final unit = row['unit'] as Map<String, dynamic>;
        final building = unit['building'] as Map<String, dynamic>;

        final endDate = DateTime.parse(row['end_date'] as String);
        final daysRemaining = endDate.difference(today).inDays;

        final rentAmount = (row['rent_amount'] as num).toDouble();
        final chargesAmount = (row['charges_amount'] as num?)?.toDouble() ?? 0;

        expiringLeases.add(ExpiringLease(
          leaseId: row['id'] as String,
          tenantName: '${tenant['first_name']} ${tenant['last_name']}',
          unitReference: unit['reference'] as String,
          buildingName: building['name'] as String,
          endDate: endDate,
          daysRemaining: daysRemaining,
          monthlyRent: rentAmount + chargesAmount,
        ));
      }

      return expiringLeases;
    } on PostgrestException catch (e) {
      throw DashboardLoadException.queryFailed(e);
    }
  }
}
