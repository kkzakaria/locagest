import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/unit.dart';
import '../../providers/units_provider.dart';
import '../../widgets/units/unit_status_badge.dart';

/// Page displaying detailed information about a unit
class UnitDetailPage extends ConsumerWidget {
  final String buildingId;
  final String unitId;

  const UnitDetailPage({
    super.key,
    required this.buildingId,
    required this.unitId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(unitByIdProvider(unitId));
    final canManage = ref.watch(canManageUnitsProvider);

    return Scaffold(
      body: unitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
        data: (unit) => _buildContent(context, ref, unit, canManage),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Unit unit,
    AsyncValue<bool> canManage,
  ) {
    return CustomScrollView(
      slivers: [
        // App bar with photo
        _buildSliverAppBar(context, ref, unit, canManage),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Reference and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      unit.reference,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  UnitStatusBadge(status: unit.status),
                ],
              ),

              const SizedBox(height: 24),

              // Rent section
              _buildRentSection(context, unit),

              const SizedBox(height: 16),

              // Characteristics section
              _buildSection(
                context,
                title: 'Caractéristiques',
                icon: Icons.info_outline,
                children: [
                  _buildInfoRow(context, 'Type', unit.typeLabel),
                  _buildInfoRow(context, 'Étage', unit.floorDisplay),
                  if (unit.surfaceArea != null)
                    _buildInfoRow(context, 'Surface', unit.surfaceDisplay),
                  if (unit.roomsCount != null)
                    _buildInfoRow(context, 'Pièces', unit.roomsDisplay),
                ],
              ),

              // Equipment section
              if (unit.hasEquipment) ...[
                const SizedBox(height: 16),
                _buildEquipmentSection(context, unit.equipment),
              ],

              // Description section
              if (unit.description != null && unit.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  title: 'Description',
                  icon: Icons.notes,
                  children: [
                    Text(
                      unit.description!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ],

              // Photos section
              if (unit.hasPhotos) ...[
                const SizedBox(height: 16),
                _buildPhotosSection(context, unit.photos),
              ],

              const SizedBox(height: 16),

              // Timestamps section
              _buildSection(
                context,
                title: 'Informations',
                icon: Icons.schedule,
                children: [
                  _buildInfoRow(
                    context,
                    'Créé le',
                    Formatters.formatDateTime(unit.createdAt),
                  ),
                  _buildInfoRow(
                    context,
                    'Modifié le',
                    Formatters.formatDateTime(unit.updatedAt),
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
    Unit unit,
    AsyncValue<bool> canManage,
  ) {
    return SliverAppBar(
      expandedHeight: unit.hasPhotos ? 250 : 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: unit.hasPhotos
            ? CachedNetworkImage(
                imageUrl: unit.photos.first,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPhotoPlaceholder(unit),
                errorWidget: (context, url, error) => _buildPhotoPlaceholder(unit),
              )
            : _buildPhotoPlaceholder(unit),
      ),
      actions: [
        // Edit button (for gestionnaire/admin)
        canManage.maybeWhen(
          data: (canManage) => canManage
              ? IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Modifier',
                  onPressed: () => context.push(
                    '/buildings/$buildingId/units/$unitId/edit',
                  ),
                )
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        ),

        // Delete button (for gestionnaire/admin, only if vacant)
        canManage.maybeWhen(
          data: (canManage) => canManage
              ? IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: unit.isOccupied ? Colors.grey : Colors.red[300],
                  ),
                  tooltip: unit.isOccupied
                      ? 'Impossible de supprimer (lot occupé)'
                      : 'Supprimer',
                  onPressed: unit.isOccupied
                      ? null
                      : () => _showDeleteConfirmation(context, ref, unit),
                )
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder(Unit unit) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          unit.type == UnitType.residential
              ? Icons.meeting_room
              : Icons.storefront,
          size: 80,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildRentSection(BuildContext context, Unit unit) {
    return Card(
      elevation: 2,
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payments,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Loyer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.formatCurrency(unit.totalMonthlyRent),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    Text(
                      'par mois${unit.chargesIncluded ? ' (charges comprises)' : ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (!unit.chargesIncluded && unit.chargesAmount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Charges',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(unit.chargesAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (!unit.chargesIncluded && unit.chargesAmount > 0) ...[
              const SizedBox(height: 12),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Loyer de base',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    Formatters.formatCurrency(unit.baseRent),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
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

  Widget _buildEquipmentSection(BuildContext context, List<String> equipment) {
    return _buildSection(
      context,
      title: 'Équipements',
      icon: Icons.kitchen,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: equipment.map((item) {
            return Chip(
              label: Text(
                item,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPhotosSection(BuildContext context, List<String> photos) {
    return _buildSection(
      context,
      title: 'Photos (${photos.length})',
      icon: Icons.photo_library,
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < photos.length - 1 ? 8 : 0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: photos[index],
                    width: 160,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 160,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 160,
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, color: Colors.grey[400]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    String userMessage = 'Une erreur est survenue';
    if (error.contains('UnitNotFoundException')) {
      userMessage = 'Ce lot n\'existe pas ou a été supprimé';
    } else if (error.contains('UnitUnauthorizedException')) {
      userMessage = 'Vous n\'avez pas accès à ce lot';
    }

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
              'Erreur',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              userMessage,
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
    Unit unit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce lot ?'),
        content: Text(
          'Voulez-vous vraiment supprimer le lot "${unit.reference}" ?\n\n'
          'Cette action est irréversible.',
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
      final success = await ref.read(deleteUnitProvider.notifier).deleteUnit(unit.id);

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (success && context.mounted) {
        // Remove from building's units list
        ref.read(unitsByBuildingProvider(buildingId).notifier).removeUnit(unit.id);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Le lot "${unit.reference}" a été supprimé'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to building detail
        context.pop();
      } else if (context.mounted) {
        // Show error message
        final error = ref.read(deleteUnitProvider).error;
        String errorMessage = 'Erreur lors de la suppression';
        if (error != null && error.contains('UnitHasActiveLeaseException')) {
          errorMessage = 'Impossible de supprimer : ce lot a un bail actif';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Reset the delete state
      ref.read(deleteUnitProvider.notifier).reset();
    }
  }
}
