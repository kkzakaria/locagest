import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Expiring lease for dashboard display
/// Represents a lease that will end within the specified period (default 30 days)
class ExpiringLease {
  final String leaseId;
  final String tenantName;
  final String unitReference;
  final String buildingName;
  final DateTime endDate;
  final int daysRemaining;
  final double monthlyRent;

  const ExpiringLease({
    required this.leaseId,
    required this.tenantName,
    required this.unitReference,
    required this.buildingName,
    required this.endDate,
    required this.daysRemaining,
    required this.monthlyRent,
  });

  // ===========================================================================
  // COMPUTED PROPERTIES
  // ===========================================================================

  /// Location label combining building and unit (e.g., "Immeuble A - Apt 101")
  String get locationLabel => '$buildingName - $unitReference';

  /// Whether this lease is urgent (expiring within 7 days)
  bool get isUrgent => daysRemaining <= 7;

  /// Whether this lease is warning (expiring within 14 days but more than 7)
  bool get isWarning => daysRemaining > 7 && daysRemaining <= 14;

  /// Whether this lease expires today
  bool get expiresToday => daysRemaining == 0;

  // ===========================================================================
  // FORMATTING HELPERS
  // ===========================================================================

  /// Format amount with FCFA currency (e.g., "150 000 FCFA")
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }

  /// Formatted end date (DD/MM/YYYY)
  String get endDateFormatted => DateFormat('dd/MM/yyyy').format(endDate);

  /// Formatted monthly rent
  String get monthlyRentFormatted => formatCurrency(monthlyRent);

  /// Formatted days remaining label
  String get daysRemainingLabel {
    if (daysRemaining == 0) return "Expire aujourd'hui";
    if (daysRemaining == 1) return '1 jour restant';
    return '$daysRemaining jours restants';
  }

  /// Short days remaining label (e.g., "7j")
  String get daysRemainingShort {
    if (daysRemaining == 0) return "Aujourd'hui";
    return '${daysRemaining}j';
  }

  // ===========================================================================
  // COLOR CODING
  // ===========================================================================

  /// Color for urgency indication
  /// - Red: <= 7 days (urgent)
  /// - Orange: 8-14 days (warning)
  /// - Default text color: > 14 days
  Color get urgencyColor {
    if (isUrgent) return Colors.red;
    if (isWarning) return Colors.orange;
    return Colors.grey.shade700;
  }

  /// Icon for urgency indication
  IconData get urgencyIcon {
    if (isUrgent) return Icons.warning;
    if (isWarning) return Icons.schedule;
    return Icons.event;
  }

  // ===========================================================================
  // EQUALITY
  // ===========================================================================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpiringLease &&
          runtimeType == other.runtimeType &&
          leaseId == other.leaseId;

  @override
  int get hashCode => leaseId.hashCode;
}
