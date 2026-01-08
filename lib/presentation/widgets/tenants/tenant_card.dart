import 'package:flutter/material.dart';

import '../../../domain/entities/tenant.dart';
import 'tenant_status_badge.dart';

/// Card widget displaying tenant summary in a list
/// Shows: full name, phone, status badge
class TenantCard extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback? onTap;

  const TenantCard({
    super.key,
    required this.tenant,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with initials
              _buildAvatar(context),

              const SizedBox(width: 12),

              // Tenant info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            tenant.fullName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TenantStatusBadge(isActive: tenant.isActive, compact: true),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Phone and secondary info
                    Row(
                      children: [
                        _buildInfoChip(
                          context,
                          icon: Icons.phone_outlined,
                          label: tenant.phoneDisplay,
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Additional info row
                    Row(
                      children: [
                        if (tenant.hasProfessionalInfo) ...[
                          _buildInfoChip(
                            context,
                            icon: Icons.work_outline,
                            label: tenant.profession ?? tenant.employer ?? '',
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (tenant.hasGuarantor) ...[
                          _buildInfoChip(
                            context,
                            icon: Icons.person_outline,
                            label: 'Garant',
                            isTag: true,
                          ),
                        ],
                        if (tenant.hasIdDocument) ...[
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            context,
                            icon: Icons.badge_outlined,
                            label: tenant.idTypeLabel,
                            isTag: true,
                          ),
                        ],
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

  Widget _buildAvatar(BuildContext context) {
    final initials = '${tenant.firstName.isNotEmpty ? tenant.firstName[0] : ''}${tenant.lastName.isNotEmpty ? tenant.lastName[0] : ''}'.toUpperCase();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isTag = false,
  }) {
    if (label.isEmpty) return const SizedBox.shrink();

    if (isTag) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: Colors.blue,
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
