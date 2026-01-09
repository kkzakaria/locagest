import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/dashboard_stats.dart';

part 'dashboard_stats_model.freezed.dart';
part 'dashboard_stats_model.g.dart';

/// Dashboard stats model for data layer (Freezed)
/// Handles JSON serialization from Supabase queries
@freezed
class DashboardStatsModel with _$DashboardStatsModel {
  const factory DashboardStatsModel({
    @JsonKey(name: 'buildings_count') @Default(0) int buildingsCount,
    @JsonKey(name: 'active_tenants_count') @Default(0) int activeTenantsCount,
    @JsonKey(name: 'total_units_count') @Default(0) int totalUnitsCount,
    @JsonKey(name: 'occupied_units_count') @Default(0) int occupiedUnitsCount,
    @JsonKey(name: 'monthly_revenue_collected')
    @Default(0.0)
    double monthlyRevenueCollected,
    @JsonKey(name: 'monthly_revenue_due') @Default(0.0) double monthlyRevenueDue,
    @JsonKey(name: 'overdue_count') @Default(0) int overdueCount,
    @JsonKey(name: 'overdue_amount') @Default(0.0) double overdueAmount,
    @JsonKey(name: 'expiring_leases_count') @Default(0) int expiringLeasesCount,
  }) = _DashboardStatsModel;

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsModelFromJson(json);
}

/// Extension for converting model to domain entity
extension DashboardStatsModelX on DashboardStatsModel {
  DashboardStats toEntity() => DashboardStats(
        buildingsCount: buildingsCount,
        activeTenantsCount: activeTenantsCount,
        totalUnitsCount: totalUnitsCount,
        occupiedUnitsCount: occupiedUnitsCount,
        monthlyRevenueCollected: monthlyRevenueCollected,
        monthlyRevenueDue: monthlyRevenueDue,
        overdueCount: overdueCount,
        overdueAmount: overdueAmount,
        expiringLeasesCount: expiringLeasesCount,
      );
}
