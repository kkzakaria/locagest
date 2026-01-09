import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../domain/entities/tenant.dart';
import '../../providers/tenants_provider.dart';
import '../../widgets/tenants/tenant_status_badge.dart';
import '../../widgets/tenants/lease_history_section.dart';
import '../../widgets/payments/tenant_payments_summary_card.dart';

/// Page displaying full tenant details including personal info, professional info,
/// ID documents, guarantor information, and lease history
class TenantDetailPage extends ConsumerWidget {
  final String tenantId;

  const TenantDetailPage({
    super.key,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantAsync = ref.watch(tenantByIdProvider(tenantId));
    final canManage = ref.watch(canManageTenantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail du locataire'),
        actions: canManage.maybeWhen(
          data: (canManage) => canManage
              ? [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => context.push('${AppRoutes.tenants}/$tenantId/edit'),
                    tooltip: 'Modifier',
                  ),
                ]
              : null,
          orElse: () => null,
        ),
      ),
      body: tenantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString(), ref),
        data: (tenant) => _buildContent(context, ref, tenant, canManage),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Tenant tenant,
    AsyncValue<bool> canManage,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card with name, status, and basic info
          _buildHeaderCard(context, tenant),

          const SizedBox(height: 24),

          // Contact information section
          _buildSection(
            context,
            title: 'Coordonnees',
            icon: Icons.contact_phone,
            children: [
              _buildInfoRow(context, Icons.phone, 'Telephone', tenant.phoneDisplay),
              if (tenant.hasSecondaryPhone)
                _buildInfoRow(context, Icons.phone_android, 'Tel. secondaire', tenant.phoneSecondaryDisplay!),
              if (tenant.hasEmail)
                _buildInfoRow(context, Icons.email_outlined, 'Email', tenant.email!),
            ],
          ),

          const SizedBox(height: 24),

          // Professional information section
          if (tenant.hasProfessionalInfo)
            ...[
              _buildSection(
                context,
                title: 'Informations professionnelles',
                icon: Icons.work_outline,
                children: [
                  if (tenant.profession != null && tenant.profession!.isNotEmpty)
                    _buildInfoRow(context, Icons.badge_outlined, 'Profession', tenant.profession!),
                  if (tenant.employer != null && tenant.employer!.isNotEmpty)
                    _buildInfoRow(context, Icons.business, 'Employeur', tenant.employer!),
                ],
              ),
              const SizedBox(height: 24),
            ],

          // Identity document section
          _buildSection(
            context,
            title: 'Piece d\'identite',
            icon: Icons.credit_card,
            children: [
              if (tenant.idType != null)
                _buildInfoRow(context, Icons.credit_card, 'Type', tenant.idTypeLabel),
              if (tenant.idNumber != null && tenant.idNumber!.isNotEmpty)
                _buildInfoRow(context, Icons.numbers, 'Numero', tenant.idNumber!),
              if (tenant.hasIdDocument)
                _buildDocumentRow(context, ref, 'Document', tenant.idDocumentUrl!),
              if (!tenant.hasIdDocument && tenant.idType == null)
                _buildEmptyRow(context, 'Aucune piece d\'identite enregistree'),
            ],
          ),

          const SizedBox(height: 24),

          // Guarantor section
          _buildSection(
            context,
            title: 'Garant',
            icon: Icons.person_outline,
            children: [
              if (tenant.hasGuarantor) ...[
                _buildInfoRow(context, Icons.person, 'Nom', tenant.guarantorName!),
                if (tenant.guarantorPhone != null && tenant.guarantorPhone!.isNotEmpty)
                  _buildInfoRow(context, Icons.phone, 'Telephone', tenant.guarantorPhoneDisplay!),
                if (tenant.hasGuarantorDocument)
                  _buildDocumentRow(context, ref, 'Piece d\'identite', tenant.guarantorIdUrl!),
              ] else
                _buildEmptyRow(context, 'Aucun garant enregistre'),
            ],
          ),

          const SizedBox(height: 24),

          // Notes section
          if (tenant.hasNotes)
            ...[
              _buildSection(
                context,
                title: 'Notes',
                icon: Icons.notes,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tenant.notes!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

          // Payment history section
          TenantPaymentsSummaryCard(
            tenantId: tenantId,
            tenantName: tenant.fullName,
          ),

          const SizedBox(height: 24),

          // Lease history section
          LeaseHistorySection(tenantId: tenantId),

          const SizedBox(height: 24),

          // Delete button (visible if can manage)
          canManage.maybeWhen(
            data: (canManage) => canManage
                ? _buildDeleteButton(context, ref, tenant)
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Tenant tenant) {
    final initials = '${tenant.firstName.isNotEmpty ? tenant.firstName[0] : ''}${tenant.lastName.isNotEmpty ? tenant.lastName[0] : ''}'.toUpperCase();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TenantStatusBadge(isActive: tenant.isActive),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(BuildContext context, WidgetRef ref, String label, String storagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.attachment, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () => _viewDocument(context, ref, storagePath),
                  child: Text(
                    'Voir le document',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility),
            color: Theme.of(context).primaryColor,
            onPressed: () => _viewDocument(context, ref, storagePath),
            tooltip: 'Voir',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRow(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, WidgetRef ref, Tenant tenant) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmDelete(context, ref, tenant),
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        label: const Text('Supprimer ce locataire'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(tenantByIdProvider(tenantId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewDocument(BuildContext context, WidgetRef ref, String storagePath) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chargement du document...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Get signed URL
      final url = await ref.read(documentUrlProvider(storagePath).future);

      // Open in external browser or viewer
      // For now, just show the URL (in production, use url_launcher)
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Document'),
            content: SelectableText(url),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Tenant tenant) async {
    // Check if can delete
    final canDelete = await ref.read(tenantRepositoryProvider).canDeleteTenant(tenant.id);

    if (!canDelete) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ce locataire ne peut pas etre supprime car il a des baux actifs'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    if (context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer le locataire'),
          content: Text('Voulez-vous vraiment supprimer ${tenant.fullName} ? Cette action est irreversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        // Perform deletion
        final success = await ref.read(deleteTenantProvider.notifier).deleteTenant(tenant.id);

        if (success && context.mounted) {
          // Remove from list
          ref.read(tenantsProvider.notifier).removeTenant(tenant.id);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Locataire supprime avec succes'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to list
          context.pop();
        } else if (context.mounted) {
          final error = ref.read(deleteTenantProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Erreur lors de la suppression'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
