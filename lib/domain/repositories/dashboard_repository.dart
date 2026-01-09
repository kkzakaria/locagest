import '../entities/dashboard_stats.dart';
import '../entities/overdue_rent.dart';
import '../entities/expiring_lease.dart';

/// Dashboard repository interface (Domain layer)
/// Defines the contract for dashboard aggregate queries
abstract class DashboardRepository {
  // ===========================================================================
  // AGGREGATE STATISTICS
  // ===========================================================================

  /// Get all dashboard statistics in a single call
  ///
  /// Returns aggregated KPIs:
  /// - Building count
  /// - Active tenant count (tenants with active leases)
  /// - Unit counts (total and occupied)
  /// - Monthly revenue (collected and due)
  /// - Overdue count and amount
  /// - Expiring leases count
  ///
  /// Performance: Target <2 seconds (Constitution requirement)
  /// Uses parallel queries via Future.wait() for optimal performance
  ///
  /// Throws [DashboardException] on query failure
  Future<DashboardStats> getDashboardStats();

  // ===========================================================================
  // OVERDUE RENT SCHEDULES
  // ===========================================================================

  /// Get top N overdue rent schedules for dashboard display
  ///
  /// [limit] - Maximum number of results (default 5 for dashboard)
  ///
  /// Returns list sorted by due_date ascending (oldest first)
  /// Each item includes:
  /// - Schedule ID and lease ID (for navigation)
  /// - Tenant name
  /// - Unit reference and building name
  /// - Amount due, paid, and days overdue
  ///
  /// Overdue criteria:
  /// - due_date < today
  /// - status IN ('pending', 'partial')
  ///
  /// Throws [DashboardException] on query failure
  Future<List<OverdueRent>> getOverdueRents({int limit = 5});

  /// Get total count of overdue rent schedules
  ///
  /// Used for "Voir tous les impayes (X)" link on dashboard
  Future<int> getTotalOverdueCount();

  // ===========================================================================
  // EXPIRING LEASES
  // ===========================================================================

  /// Get leases expiring within the specified number of days
  ///
  /// [daysAhead] - Number of days to look ahead (default 30)
  ///
  /// Returns list sorted by end_date ascending (soonest first)
  /// Each item includes:
  /// - Lease ID (for navigation)
  /// - Tenant name
  /// - Unit reference and building name
  /// - End date and days remaining
  /// - Monthly rent amount
  ///
  /// Criteria:
  /// - status = 'active'
  /// - end_date IS NOT NULL
  /// - end_date >= today AND end_date <= today + daysAhead
  ///
  /// Throws [DashboardException] on query failure
  Future<List<ExpiringLease>> getExpiringLeases({int daysAhead = 30});
}
