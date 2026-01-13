import 'package:flutter/material.dart';
import '../../../domain/entities/expiring_lease.dart';

/// Card widget displaying a single expiring lease item
class ExpiringLeaseCard extends StatelessWidget {
  final ExpiringLease expiringLease;
  final VoidCallback? onTap;

  const ExpiringLeaseCard({
    super.key,
    required this.expiringLease,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Calendar icon with urgency color
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: expiringLease.urgencyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  expiringLease.urgencyIcon,
                  color: expiringLease.urgencyColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Tenant and location info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expiringLease.tenantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expiringLease.locationLabel,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // End date and days remaining
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    expiringLease.endDateFormatted,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: expiringLease.isUrgent
                          ? Colors.red
                          : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: expiringLease.urgencyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      expiringLease.daysRemainingShort,
                      style: TextStyle(
                        color: expiringLease.urgencyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for expiring lease card
class ExpiringLeaseCardShimmer extends StatelessWidget {
  const ExpiringLeaseCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Date placeholder
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 70,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 30,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
