import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Aggregated dashboard statistics entity
/// Contains all KPI values for the dashboard display
class DashboardStats {
  // KPI counts
  final int buildingsCount;
  final int activeTenantsCount;
  final int totalUnitsCount;
  final int occupiedUnitsCount;

  // Financial metrics (current month)
  final double monthlyRevenueCollected;
  final double monthlyRevenueDue;

  // Overdue metrics
  final int overdueCount;
  final double overdueAmount;

  // Expiring leases
  final int expiringLeasesCount;

  const DashboardStats({
    required this.buildingsCount,
    required this.activeTenantsCount,
    required this.totalUnitsCount,
    required this.occupiedUnitsCount,
    required this.monthlyRevenueCollected,
    required this.monthlyRevenueDue,
    required this.overdueCount,
    required this.overdueAmount,
    required this.expiringLeasesCount,
  });

  /// Factory constructor for empty/initial state
  factory DashboardStats.empty() => const DashboardStats(
        buildingsCount: 0,
        activeTenantsCount: 0,
        totalUnitsCount: 0,
        occupiedUnitsCount: 0,
        monthlyRevenueCollected: 0,
        monthlyRevenueDue: 0,
        overdueCount: 0,
        overdueAmount: 0,
        expiringLeasesCount: 0,
      );

  // ===========================================================================
  // COMPUTED PROPERTIES
  // ===========================================================================

  /// Occupancy rate as percentage (0-100)
  double get occupancyRate =>
      totalUnitsCount > 0 ? (occupiedUnitsCount / totalUnitsCount) * 100 : 0;

  /// Collection rate as percentage (0-100)
  double get collectionRate => monthlyRevenueDue > 0
      ? (monthlyRevenueCollected / monthlyRevenueDue) * 100
      : 0;

  /// Whether there are overdue payments
  bool get hasOverdue => overdueCount > 0;

  /// Whether there are expiring leases
  bool get hasExpiringLeases => expiringLeasesCount > 0;

  /// Vacant units count
  int get vacantUnitsCount => totalUnitsCount - occupiedUnitsCount;

  /// Outstanding amount for current month
  double get monthlyOutstanding => monthlyRevenueDue - monthlyRevenueCollected;

  // ===========================================================================
  // FORMATTING HELPERS
  // ===========================================================================

  /// Format amount with FCFA currency (e.g., "150 000 FCFA")
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }

  /// Formatted monthly revenue collected
  String get monthlyRevenueCollectedFormatted =>
      formatCurrency(monthlyRevenueCollected);

  /// Formatted monthly revenue due
  String get monthlyRevenueDueFormatted => formatCurrency(monthlyRevenueDue);

  /// Formatted overdue amount
  String get overdueAmountFormatted => formatCurrency(overdueAmount);

  /// Formatted occupancy rate (e.g., "85%")
  String get occupancyRateFormatted => '${occupancyRate.toStringAsFixed(0)}%';

  /// Formatted collection rate (e.g., "92%")
  String get collectionRateFormatted => '${collectionRate.toStringAsFixed(0)}%';

  // ===========================================================================
  // COLOR CODING
  // ===========================================================================

  /// Color for occupancy rate based on thresholds
  /// - Green: >85%
  /// - Orange: 70-85%
  /// - Red: <70%
  Color get occupancyRateColor {
    if (occupancyRate > 85) return Colors.green;
    if (occupancyRate >= 70) return Colors.orange;
    return Colors.red;
  }

  /// Color for collection rate based on thresholds
  /// - Green: >90%
  /// - Orange: 70-90%
  /// - Red: <70%
  Color get collectionRateColor {
    if (collectionRate > 90) return Colors.green;
    if (collectionRate >= 70) return Colors.orange;
    return Colors.red;
  }

  // ===========================================================================
  // EQUALITY
  // ===========================================================================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardStats &&
          runtimeType == other.runtimeType &&
          buildingsCount == other.buildingsCount &&
          activeTenantsCount == other.activeTenantsCount &&
          totalUnitsCount == other.totalUnitsCount &&
          occupiedUnitsCount == other.occupiedUnitsCount &&
          monthlyRevenueCollected == other.monthlyRevenueCollected &&
          monthlyRevenueDue == other.monthlyRevenueDue &&
          overdueCount == other.overdueCount &&
          overdueAmount == other.overdueAmount &&
          expiringLeasesCount == other.expiringLeasesCount;

  @override
  int get hashCode =>
      buildingsCount.hashCode ^
      activeTenantsCount.hashCode ^
      totalUnitsCount.hashCode ^
      occupiedUnitsCount.hashCode ^
      monthlyRevenueCollected.hashCode ^
      monthlyRevenueDue.hashCode ^
      overdueCount.hashCode ^
      overdueAmount.hashCode ^
      expiringLeasesCount.hashCode;
}
