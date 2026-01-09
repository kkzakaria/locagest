import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/overdue_rent.dart';
import '../../domain/entities/expiring_lease.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

/// Implementation of DashboardRepository
/// Bridges domain layer with data layer via datasource
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDatasource _datasource;

  DashboardRepositoryImpl(this._datasource);

  @override
  Future<DashboardStats> getDashboardStats() async {
    return _datasource.getDashboardStats();
  }

  @override
  Future<List<OverdueRent>> getOverdueRents({int limit = 5}) async {
    return _datasource.getOverdueRents(limit: limit);
  }

  @override
  Future<int> getTotalOverdueCount() async {
    return _datasource.getTotalOverdueCount();
  }

  @override
  Future<List<ExpiringLease>> getExpiringLeases({int daysAhead = 30}) async {
    return _datasource.getExpiringLeases(daysAhead: daysAhead);
  }
}
