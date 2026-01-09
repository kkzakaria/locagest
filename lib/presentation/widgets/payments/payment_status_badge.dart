import 'package:flutter/material.dart';

import '../../../domain/entities/rent_schedule.dart';

/// Badge widget displaying rent schedule payment status with appropriate color
class PaymentStatusBadge extends StatelessWidget {
  final RentScheduleStatus status;
  final bool compact;

  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color backgroundColor;
    final Color textColor;

    switch (status) {
      case RentScheduleStatus.pending:
        label = compact ? 'Attente' : 'En attente';
        backgroundColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange[700]!;
        break;
      case RentScheduleStatus.partial:
        label = 'Partiel';
        backgroundColor = Colors.amber.withValues(alpha: 0.15);
        textColor = Colors.amber[800]!;
        break;
      case RentScheduleStatus.paid:
        label = compact ? 'Paye' : 'Payé';
        backgroundColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green[700]!;
        break;
      case RentScheduleStatus.overdue:
        label = compact ? 'Retard' : 'En retard';
        backgroundColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.red[700]!;
        break;
      case RentScheduleStatus.cancelled:
        label = compact ? 'Annule' : 'Annulé';
        backgroundColor = Colors.grey.withValues(alpha: 0.15);
        textColor = Colors.grey[700]!;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Badge showing days overdue with warning styling
class DaysOverdueBadge extends StatelessWidget {
  final int daysOverdue;
  final bool compact;

  const DaysOverdueBadge({
    super.key,
    required this.daysOverdue,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (daysOverdue <= 0) return const SizedBox.shrink();

    final String label = compact
        ? '$daysOverdue j'
        : '$daysOverdue jour${daysOverdue > 1 ? 's' : ''} de retard';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: compact ? 12 : 14,
            color: Colors.red[700],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}
