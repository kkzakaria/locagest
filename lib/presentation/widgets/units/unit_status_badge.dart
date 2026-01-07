import 'package:flutter/material.dart';
import '../../../domain/entities/unit.dart';

/// Status badge widget for displaying unit status with Constitution-compliant colors
/// Colors per Constitution II:
/// - Vacant (Disponible): Red - unit is available for rent
/// - Occupied (Occupé): Green - unit has an active tenant
/// - Maintenance (En maintenance): Orange - unit is temporarily unavailable
class UnitStatusBadge extends StatelessWidget {
  final UnitStatus status;
  final bool compact;

  const UnitStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(compact ? 4 : 8),
        border: Border.all(
          color: status.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 8,
            height: compact ? 6 : 8,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
