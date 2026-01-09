import 'package:intl/intl.dart';

/// Overdue rent schedule for dashboard display
/// Represents an unpaid or partially paid rent schedule past its due date
class OverdueRent {
  final String scheduleId;
  final String leaseId;
  final String tenantName;
  final String unitReference;
  final String buildingName;
  final DateTime dueDate;
  final double amountDue;
  final double amountPaid;
  final int daysOverdue;

  const OverdueRent({
    required this.scheduleId,
    required this.leaseId,
    required this.tenantName,
    required this.unitReference,
    required this.buildingName,
    required this.dueDate,
    required this.amountDue,
    required this.amountPaid,
    required this.daysOverdue,
  });

  // ===========================================================================
  // COMPUTED PROPERTIES
  // ===========================================================================

  /// Outstanding balance
  double get balance => amountDue - amountPaid;

  /// Location label combining building and unit (e.g., "Immeuble A - Apt 101")
  String get locationLabel => '$buildingName - $unitReference';

  /// Whether this payment is partially paid
  bool get isPartiallyPaid => amountPaid > 0 && amountPaid < amountDue;

  /// Whether this is severely overdue (>30 days)
  bool get isSeverelyOverdue => daysOverdue > 30;

  /// Whether this is moderately overdue (15-30 days)
  bool get isModeratelyOverdue => daysOverdue >= 15 && daysOverdue <= 30;

  // ===========================================================================
  // FORMATTING HELPERS
  // ===========================================================================

  /// Format amount with FCFA currency (e.g., "150 000 FCFA")
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }

  /// Formatted due date (DD/MM/YYYY)
  String get dueDateFormatted => DateFormat('dd/MM/yyyy').format(dueDate);

  /// Formatted amount due
  String get amountDueFormatted => formatCurrency(amountDue);

  /// Formatted amount paid
  String get amountPaidFormatted => formatCurrency(amountPaid);

  /// Formatted outstanding balance
  String get balanceFormatted => formatCurrency(balance);

  /// Formatted days overdue label (e.g., "15 jours de retard")
  String get daysOverdueLabel {
    if (daysOverdue == 1) return '1 jour de retard';
    return '$daysOverdue jours de retard';
  }

  /// Short overdue label (e.g., "+15j")
  String get daysOverdueShort => '+${daysOverdue}j';

  // ===========================================================================
  // EQUALITY
  // ===========================================================================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverdueRent &&
          runtimeType == other.runtimeType &&
          scheduleId == other.scheduleId;

  @override
  int get hashCode => scheduleId.hashCode;
}
