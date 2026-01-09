import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/rent_schedule.dart';
import '../../../domain/repositories/payment_repository.dart';
import 'payment_status_badge.dart';

/// Card widget displaying a rent schedule with details
class RentScheduleCard extends StatelessWidget {
  final RentScheduleWithDetails scheduleWithDetails;
  final VoidCallback? onTap;
  final VoidCallback? onRecordPayment;

  const RentScheduleCard({
    super.key,
    required this.scheduleWithDetails,
    this.onTap,
    this.onRecordPayment,
  });

  RentSchedule get schedule => scheduleWithDetails.schedule;

  @override
  Widget build(BuildContext context) {
    final isOverdue = schedule.isOverdue;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? BorderSide(color: Colors.red.withValues(alpha: 0.3), width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Period and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.periodLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Échéance: ${schedule.dueDateFormatted}',
                          style: TextStyle(
                            color: isOverdue ? Colors.red[700] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PaymentStatusBadge(status: schedule.status),
                ],
              ),

              const SizedBox(height: 12),

              // Tenant and unit info
              if (scheduleWithDetails.tenantName != null ||
                  scheduleWithDetails.unitReference != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (scheduleWithDetails.tenantName != null) ...[
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            scheduleWithDetails.tenantName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (scheduleWithDetails.unitReference != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.home, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          scheduleWithDetails.unitReference!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Amounts row
              Row(
                children: [
                  // Amount due
                  Expanded(
                    child: _buildAmountColumn(
                      label: 'Montant dû',
                      amount: schedule.amountDueFormatted,
                      color: Colors.grey[700]!,
                    ),
                  ),
                  // Amount paid
                  Expanded(
                    child: _buildAmountColumn(
                      label: 'Payé',
                      amount: schedule.amountPaidFormatted,
                      color: Colors.green[700]!,
                    ),
                  ),
                  // Balance
                  Expanded(
                    child: _buildAmountColumn(
                      label: 'Solde',
                      amount: schedule.balanceFormatted,
                      color: schedule.balance > 0 ? Colors.orange[700]! : Colors.green[700]!,
                      bold: true,
                    ),
                  ),
                ],
              ),

              // Progress bar
              if (schedule.amountPaid > 0 && schedule.balance > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: schedule.paymentProgress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(Colors.green[600]),
                    minHeight: 6,
                  ),
                ),
              ],

              // Days overdue warning
              if (isOverdue) ...[
                const SizedBox(height: 12),
                DaysOverdueBadge(daysOverdue: _calculateDaysOverdue()),
              ],

              // Record payment button
              if (onRecordPayment != null && schedule.canRecordPayment) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRecordPayment,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Enregistrer un paiement'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountColumn({
    required String label,
    required String amount,
    required Color color,
    bool bold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  int _calculateDaysOverdue() {
    if (!schedule.isOverdue) return 0;
    final today = DateTime.now();
    return today.difference(schedule.dueDate).inDays;
  }
}

/// Compact list item version of schedule card
class RentScheduleListTile extends StatelessWidget {
  final RentScheduleWithDetails scheduleWithDetails;
  final VoidCallback? onTap;

  const RentScheduleListTile({
    super.key,
    required this.scheduleWithDetails,
    this.onTap,
  });

  RentSchedule get schedule => scheduleWithDetails.schedule;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: schedule.statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            DateFormat('MMM', 'fr_FR').format(schedule.periodStart).substring(0, 3).toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: schedule.statusColor,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              scheduleWithDetails.tenantName ?? 'Locataire inconnu',
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            schedule.balanceFormatted,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: schedule.isPaid ? Colors.green[700] : null,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          if (scheduleWithDetails.unitReference != null) ...[
            Text(
              scheduleWithDetails.unitReference!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(width: 8),
          ],
          PaymentStatusBadge(status: schedule.status, compact: true),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
