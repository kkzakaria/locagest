import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/building.dart';
import '../../providers/buildings_provider.dart';
import '../../widgets/units/units_list_section.dart';

/// Page displaying detailed information about a building
class BuildingDetailPage extends ConsumerWidget {
  final String buildingId;

  const BuildingDetailPage({
    super.key,
    required this.buildingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildingAsync = ref.watch(buildingByIdProvider(buildingId));
    final canManage = ref.watch(canManageBuildingsProvider);

    return Scaffold(
      body: buildingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
        data: (building) => _buildContent(context, ref, building, canManage),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Building building,
    AsyncValue<bool> canManage,
  ) {
    return CustomScrollView(
      slivers: [
        // App bar with photo
        _buildSliverAppBar(context, ref, building, canManage),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Building name
              Text(
                building.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 24),

              // Address section
              _buildSection(
                context,
                title: 'Adresse',
                icon: Icons.location_on,
                children: [
                  _buildInfoRow(context, 'Adresse', building.address),
                  _buildInfoRow(context, 'Ville', building.city),
                  if (building.postalCode != null)
                    _buildInfoRow(context, 'Code postal', building.postalCode!),
                  _buildInfoRow(context, 'Pays', building.country),
                ],
              ),

              const SizedBox(height: 16),

              // Units section
              UnitsListSection(
                buildingId: building.id,
                canManage: canManage.maybeWhen(
                  data: (value) => value,
                  orElse: () => false,
                ),
              ),

              const SizedBox(height: 16),

              // Notes section
              if (building.notes != null && building.notes!.isNotEmpty) ...[
                _buildSection(
                  context,
                  title: 'Notes',
                  icon: Icons.notes,
                  children: [
                    Text(
                      building.notes!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Timestamps section
              _buildSection(
                context,
                title: 'Informations',
                icon: Icons.info_outline,
                children: [
                  _buildInfoRow(
                    context,
                    'Cree le',
                    _formatDate(building.createdAt),
                  ),
                  _buildInfoRow(
                    context,
                    'Modifie le',
                    _formatDate(building.updatedAt),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    WidgetRef ref,
    Building building,
    AsyncValue<bool> canManage,
  ) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: building.photoUrl != null
            ? CachedNetworkImage(
                imageUrl: building.photoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPhotoPlaceholder(),
                errorWidget: (context, url, error) => _buildPhotoPlaceholder(),
              )
            : _buildPhotoPlaceholder(),
      ),
      actions: [
        // Edit button (for gestionnaire/admin)
        canManage.maybeWhen(
          data: (canManage) => canManage
              ? IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Modifier',
                  onPressed: () => context.push(
                    '${AppRoutes.buildings}/$buildingId/edit',
                  ),
                )
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        ),

        // Delete button (for gestionnaire/admin, disabled if has units)
        canManage.maybeWhen(
          data: (canManage) => canManage
              ? IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: building.hasUnits ? Colors.grey : Colors.red[300],
                  ),
                  tooltip: building.hasUnits
                      ? 'Impossible de supprimer (lots existants)'
                      : 'Supprimer',
                  onPressed: building.hasUnits
                      ? null
                      : () => _showDeleteConfirmation(context, ref, building),
                )
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.apartment,
          size: 80,
          color: Colors.grey[400],
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
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
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
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return Formatters.formatDateTime(date);
  }

  Widget _buildErrorState(BuildContext context, String error) {
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
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Building building,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cet immeuble ?'),
        content: Text(
          'Voulez-vous vraiment supprimer "${building.name}" ?\n\n'
          'Cette action est irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Perform deletion
      final success = await ref.read(deleteBuildingProvider.notifier).deleteBuilding(building.id);

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (success && context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("L'immeuble \"${building.name}\" a ete supprime"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to buildings list
        context.go('/buildings');
      } else if (context.mounted) {
        // Show error message
        final error = ref.read(deleteBuildingProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Erreur lors de la suppression'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Reset the delete state
      ref.read(deleteBuildingProvider.notifier).reset();
    }
  }
}
