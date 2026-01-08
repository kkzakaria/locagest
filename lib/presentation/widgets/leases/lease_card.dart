import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/lease.dart';
import 'lease_status_badge.dart';

/// Card widget displaying lease summary in a list
/// Shows: tenant name, unit reference, rent amount, status, dates
class LeaseCard extends StatelessWidget {
  final Lease lease;
  final VoidCallback? onTap;

  const LeaseCard({
    super.key,
    required this.lease,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              _buildIcon(context),

              const SizedBox(width: 12),

              // Lease info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tenant name and status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lease.tenantFullName.isNotEmpty
                                ? lease.tenantFullName
                                : 'Locataire',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        LeaseStatusBadge(status: lease.status, compact: true),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Unit reference and building
                    if (lease.fullAddress.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.home_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lease.fullAddress,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 6),

                    // Rent amount and dates
                    Row(
                      children: [
                        // Rent amount
                        _buildInfoChip(
                          context,
                          icon: Icons.payments_outlined,
                          label: _formatFCFA(lease.totalMonthlyAmount),
                          isHighlighted: true,
                        ),

                        const SizedBox(width: 12),

                        // Start date
                        _buildInfoChip(
                          context,
                          icon: Icons.calendar_today_outlined,
                          label: _formatDate(lease.startDate),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Duration and deposit info
                    Row(
                      children: [
                        _buildInfoChip(
                          context,
                          icon: Icons.schedule_outlined,
                          label: lease.durationLabel,
                        ),

                        const SizedBox(width: 8),

                        if (lease.depositAmount != null && lease.depositAmount! > 0)
                          _buildTag(
                            context,
                            label: lease.depositStatusLabel,
                            color: lease.depositPaid ? Colors.green : Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
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

  Widget _buildIcon(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: lease.statusColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.description_outlined,
          color: lease.statusColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isHighlighted ? Theme.of(context).primaryColor : Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isHighlighted ? Theme.of(context).primaryColor : Colors.grey[700],
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(
    BuildContext context, {
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _formatFCFA(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
