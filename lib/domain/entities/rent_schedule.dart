import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Rent schedule status enum representing payment state.
enum RentScheduleStatus {
  /// Not yet due, no payment
  pending,
  /// Some payment received
  partial,
  /// Fully paid
  paid,
  /// Past due, not fully paid
  overdue,
  /// Cancelled (lease terminated)
  cancelled;

  /// Parse status from string (database value)
  static RentScheduleStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return RentScheduleStatus.pending;
      case 'partial':
        return RentScheduleStatus.partial;
      case 'paid':
        return RentScheduleStatus.paid;
      case 'overdue':
        return RentScheduleStatus.overdue;
      case 'cancelled':
        return RentScheduleStatus.cancelled;
      default:
        return RentScheduleStatus.pending;
    }
  }

  /// Convert to string for database
  String toJson() => name;
}

/// Represents a monthly rent obligation (échéance) generated from a lease.
class RentSchedule {
  final String id;
  final String leaseId;
  final DateTime dueDate;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double amountDue;
  final double amountPaid;
  final double balance;
  final RentScheduleStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RentSchedule({
    required this.id,
    required this.leaseId,
    required this.dueDate,
    required this.periodStart,
    required this.periodEnd,
    required this.amountDue,
    this.amountPaid = 0,
    required this.balance,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================================
  // COMPUTED PROPERTIES
  // ============================================================================

  /// Whether fully paid
  bool get isPaid => status == RentScheduleStatus.paid;

  /// Whether overdue
  bool get isOverdue => status == RentScheduleStatus.overdue;

  /// Whether pending (future)
  bool get isPending => status == RentScheduleStatus.pending;

  /// Whether cancelled
  bool get isCancelled => status == RentScheduleStatus.cancelled;

  /// Whether partially paid
  bool get isPartial => status == RentScheduleStatus.partial;

  /// Remaining balance to pay
  double get remainingBalance => amountDue - amountPaid;

  /// Payment progress (0.0 to 1.0)
  double get paymentProgress {
    if (amountDue <= 0) return 0;
    return (amountPaid / amountDue).clamp(0.0, 1.0);
  }

  /// Whether payment can be recorded (not cancelled, not fully paid)
  bool get canRecordPayment =>
      status != RentScheduleStatus.cancelled && status != RentScheduleStatus.paid;

  // ============================================================================
  // FRENCH LABELS
  // ============================================================================

  /// French label for status
  String get statusLabel {
    switch (status) {
      case RentScheduleStatus.pending:
        return 'En attente';
      case RentScheduleStatus.partial:
        return 'Partiel';
      case RentScheduleStatus.paid:
        return 'Payé';
      case RentScheduleStatus.overdue:
        return 'En retard';
      case RentScheduleStatus.cancelled:
        return 'Annulé';
    }
  }

  /// Material color for status
  Color get statusColor {
    switch (status) {
      case RentScheduleStatus.pending:
        return Colors.orange;
      case RentScheduleStatus.partial:
        return Colors.amber;
      case RentScheduleStatus.paid:
        return Colors.green;
      case RentScheduleStatus.overdue:
        return Colors.red;
      case RentScheduleStatus.cancelled:
        return Colors.grey;
    }
  }

  /// Period label in French (e.g., "Février 2026")
  String get periodLabel {
    final formatter = DateFormat('MMMM yyyy', 'fr_FR');
    return formatter.format(periodStart);
  }

  /// Due date formatted (DD/MM/YYYY)
  String get dueDateFormatted {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(dueDate);
  }

  /// Amount due formatted in FCFA
  String get amountDueFormatted => _formatFCFA(amountDue);

  /// Amount paid formatted in FCFA
  String get amountPaidFormatted => _formatFCFA(amountPaid);

  /// Balance formatted in FCFA
  String get balanceFormatted => _formatFCFA(balance);

  /// Remaining balance formatted in FCFA
  String get remainingBalanceFormatted => _formatFCFA(remainingBalance);

  /// Format amount in FCFA with space thousand separator
  static String _formatFCFA(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }

  // ============================================================================
  // COPY WITH
  // ============================================================================

  RentSchedule copyWith({
    String? id,
    String? leaseId,
    DateTime? dueDate,
    DateTime? periodStart,
    DateTime? periodEnd,
    double? amountDue,
    double? amountPaid,
    double? balance,
    RentScheduleStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RentSchedule(
      id: id ?? this.id,
      leaseId: leaseId ?? this.leaseId,
      dueDate: dueDate ?? this.dueDate,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      amountDue: amountDue ?? this.amountDue,
      amountPaid: amountPaid ?? this.amountPaid,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================================
  // EQUALITY
  // ============================================================================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RentSchedule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          leaseId == other.leaseId &&
          dueDate == other.dueDate;

  @override
  int get hashCode => id.hashCode ^ leaseId.hashCode ^ dueDate.hashCode;

  @override
  String toString() =>
      'RentSchedule{id: $id, period: $periodLabel, status: $statusLabel, balance: $balanceFormatted}';
}

/// Summary of rent schedules for a lease (for dashboard display).
class RentSchedulesSummary {
  final int totalSchedules;
  final int paidCount;
  final int pendingCount;
  final int overdueCount;
  final int partialCount;
  final int cancelledCount;
  final double totalDue;
  final double totalPaid;
  final double totalBalance;

  const RentSchedulesSummary({
    required this.totalSchedules,
    required this.paidCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.partialCount,
    required this.cancelledCount,
    required this.totalDue,
    required this.totalPaid,
    required this.totalBalance,
  });

  /// Create empty summary
  factory RentSchedulesSummary.empty() => const RentSchedulesSummary(
        totalSchedules: 0,
        paidCount: 0,
        pendingCount: 0,
        overdueCount: 0,
        partialCount: 0,
        cancelledCount: 0,
        totalDue: 0,
        totalPaid: 0,
        totalBalance: 0,
      );

  /// Create summary from list of schedules
  factory RentSchedulesSummary.fromSchedules(List<RentSchedule> schedules) {
    int paidCount = 0;
    int pendingCount = 0;
    int overdueCount = 0;
    int partialCount = 0;
    int cancelledCount = 0;
    double totalDue = 0;
    double totalPaid = 0;

    for (final schedule in schedules) {
      switch (schedule.status) {
        case RentScheduleStatus.paid:
          paidCount++;
          break;
        case RentScheduleStatus.pending:
          pendingCount++;
          break;
        case RentScheduleStatus.overdue:
          overdueCount++;
          break;
        case RentScheduleStatus.partial:
          partialCount++;
          break;
        case RentScheduleStatus.cancelled:
          cancelledCount++;
          break;
      }

      // Only count non-cancelled for totals
      if (schedule.status != RentScheduleStatus.cancelled) {
        totalDue += schedule.amountDue;
        totalPaid += schedule.amountPaid;
      }
    }

    return RentSchedulesSummary(
      totalSchedules: schedules.length,
      paidCount: paidCount,
      pendingCount: pendingCount,
      overdueCount: overdueCount,
      partialCount: partialCount,
      cancelledCount: cancelledCount,
      totalDue: totalDue,
      totalPaid: totalPaid,
      totalBalance: totalDue - totalPaid,
    );
  }

  /// Total due formatted in FCFA
  String get totalDueFormatted => RentSchedule._formatFCFA(totalDue);

  /// Total paid formatted in FCFA
  String get totalPaidFormatted => RentSchedule._formatFCFA(totalPaid);

  /// Total balance formatted in FCFA
  String get totalBalanceFormatted => RentSchedule._formatFCFA(totalBalance);

  /// Whether there are overdue schedules
  bool get hasOverdue => overdueCount > 0;

  /// Payment progress (0.0 to 1.0)
  double get paymentProgress {
    if (totalDue <= 0) return 0;
    return (totalPaid / totalDue).clamp(0.0, 1.0);
  }
}
