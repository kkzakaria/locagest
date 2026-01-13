// Dashboard Repository Interface
//
// Defines the contract for dashboard data operations.
// This is the Domain layer interface - implementations in Data layer.
//
// Feature: 008-dashboard
// Date: 2026-01-09

import 'package:locagest/domain/entities/dashboard_stats.dart';
import 'package:locagest/domain/entities/overdue_rent.dart';
import 'package:locagest/domain/entities/expiring_lease.dart';

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
  /// Used for "Voir tous les impayés (X)" link on dashboard
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

  // ===========================================================================
  // OCCUPANCY STATISTICS
  // ===========================================================================

  /// Get unit occupancy statistics
  ///
  /// Returns a record with:
  /// - totalUnits: Total count of all units
  /// - occupiedUnits: Count of units with status='occupied'
  /// - vacantUnits: Count of units with status='vacant'
  /// - maintenanceUnits: Count of units with status='maintenance'
  ///
  /// Throws [DashboardException] on query failure
  Future<OccupancyStats> getOccupancyStats();

  // ===========================================================================
  // FINANCIAL SUMMARY
  // ===========================================================================

  /// Get financial summary for the current month
  ///
  /// Returns:
  /// - totalDue: Sum of rent_schedules.amount_due for current month
  /// - totalCollected: Sum of payments.amount for current month
  /// - collectionRate: (totalCollected / totalDue) * 100
  ///
  /// Throws [DashboardException] on query failure
  Future<FinancialSummary> getCurrentMonthFinancials();
}

// ===========================================================================
// SUPPORTING TYPES
// ===========================================================================

/// Occupancy statistics for units
class OccupancyStats {
  final int totalUnits;
  final int occupiedUnits;
  final int vacantUnits;
  final int maintenanceUnits;

  const OccupancyStats({
    required this.totalUnits,
    required this.occupiedUnits,
    required this.vacantUnits,
    required this.maintenanceUnits,
  });

  /// Occupancy rate as percentage (0-100)
  double get occupancyRate =>
      totalUnits > 0 ? (occupiedUnits / totalUnits) * 100 : 0;

  /// Vacancy rate as percentage (0-100)
  double get vacancyRate =>
      totalUnits > 0 ? (vacantUnits / totalUnits) * 100 : 0;
}

/// Financial summary for a period
class FinancialSummary {
  final double totalDue;
  final double totalCollected;

  const FinancialSummary({
    required this.totalDue,
    required this.totalCollected,
  });

  /// Collection rate as percentage (0-100)
  double get collectionRate =>
      totalDue > 0 ? (totalCollected / totalDue) * 100 : 0;

  /// Outstanding balance
  double get outstanding => totalDue - totalCollected;
}

// ===========================================================================
// EXCEPTIONS
// ===========================================================================

/// Base exception for dashboard operations
class DashboardException implements Exception {
  final String message;
  final dynamic originalError;

  const DashboardException(this.message, [this.originalError]);

  @override
  String toString() => 'DashboardException: $message';
}

/// Exception when dashboard data fails to load
class DashboardLoadException extends DashboardException {
  const DashboardLoadException(super.message, [super.originalError]);
}
