import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/overdue_rent.dart';
import '../../domain/entities/expiring_lease.dart';
import '../../domain/repositories/dashboard_repository.dart';

// =============================================================================
// DEPENDENCY PROVIDERS
// =============================================================================

/// Provider for DashboardRemoteDatasource
final dashboardDatasourceProvider = Provider<DashboardRemoteDatasource>((ref) {
  return DashboardRemoteDatasource(Supabase.instance.client);
});

/// Provider for DashboardRepository
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.read(dashboardDatasourceProvider));
});

// =============================================================================
// DASHBOARD STATS PROVIDER (US1)
// =============================================================================

/// Provider for fetching dashboard statistics
/// Use ref.invalidate(dashboardStatsProvider) to refresh
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repository = ref.read(dashboardRepositoryProvider);
  return repository.getDashboardStats();
});

// =============================================================================
// OVERDUE RENTS PROVIDER (US2)
// =============================================================================

/// Provider for fetching overdue rents (top 5 by default)
/// Use ref.invalidate(overdueRentsProvider) to refresh
final overdueRentsProvider = FutureProvider<List<OverdueRent>>((ref) async {
  final repository = ref.read(dashboardRepositoryProvider);
  return repository.getOverdueRents(limit: 5);
});

/// Provider for total overdue count
/// Used for "Voir tous les impayes (X)" link
final totalOverdueCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(dashboardRepositoryProvider);
  return repository.getTotalOverdueCount();
});

// =============================================================================
// EXPIRING LEASES PROVIDER (US3)
// =============================================================================

/// Provider for fetching expiring leases (within 30 days)
/// Use ref.invalidate(expiringLeasesProvider) to refresh
final expiringLeasesProvider = FutureProvider<List<ExpiringLease>>((ref) async {
  final repository = ref.read(dashboardRepositoryProvider);
  return repository.getExpiringLeases(daysAhead: 30);
});

// =============================================================================
// COMBINED DASHBOARD DATA PROVIDER
// =============================================================================

/// Combined state for all dashboard data
class DashboardData {
  final DashboardStats stats;
  final List<OverdueRent> overdueRents;
  final List<ExpiringLease> expiringLeases;
  final int totalOverdueCount;

  const DashboardData({
    required this.stats,
    required this.overdueRents,
    required this.expiringLeases,
    required this.totalOverdueCount,
  });
}

/// Provider for fetching all dashboard data at once
/// This is useful for initial load to show a unified loading state
final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final repository = ref.read(dashboardRepositoryProvider);

  // Execute all queries in parallel
  final results = await Future.wait([
    repository.getDashboardStats(),
    repository.getOverdueRents(limit: 5),
    repository.getExpiringLeases(daysAhead: 30),
    repository.getTotalOverdueCount(),
  ]);

  return DashboardData(
    stats: results[0] as DashboardStats,
    overdueRents: results[1] as List<OverdueRent>,
    expiringLeases: results[2] as List<ExpiringLease>,
    totalOverdueCount: results[3] as int,
  );
});

// =============================================================================
// REFRESH HELPER
// =============================================================================

/// Extension on WidgetRef to invalidate all dashboard providers at once
extension DashboardRefreshX on Ref {
  /// Invalidate all dashboard-related providers
  void invalidateDashboard() {
    invalidate(dashboardStatsProvider);
    invalidate(overdueRentsProvider);
    invalidate(expiringLeasesProvider);
    invalidate(totalOverdueCountProvider);
    invalidate(dashboardDataProvider);
  }
}
