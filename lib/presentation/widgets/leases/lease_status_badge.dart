import 'package:flutter/material.dart';

import '../../../domain/entities/lease.dart';

/// Badge widget displaying lease status with appropriate color
class LeaseStatusBadge extends StatelessWidget {
  final LeaseStatus status;
  final bool compact;

  const LeaseStatusBadge({
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
      case LeaseStatus.pending:
        label = compact ? 'Attente' : 'En attente';
        backgroundColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange[700]!;
        break;
      case LeaseStatus.active:
        label = 'Actif';
        backgroundColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green[700]!;
        break;
      case LeaseStatus.terminated:
        label = compact ? 'Resilié' : 'Résilié';
        backgroundColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.red[700]!;
        break;
      case LeaseStatus.expired:
        label = compact ? 'Expire' : 'Expiré';
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
