import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/unit.dart';
import '../../providers/units_provider.dart';
import '../../widgets/units/unit_form.dart';

/// Page for editing an existing unit
/// Loads the unit data and passes it to UnitForm in edit mode
class UnitEditPage extends ConsumerWidget {
  final String buildingId;
  final String unitId;

  const UnitEditPage({
    super.key,
    required this.buildingId,
    required this.unitId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(unitByIdProvider(unitId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le lot'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(context, ref),
        ),
      ),
      body: unitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
        data: (unit) => _buildForm(context, ref, unit),
      ),
    );
  }

  Widget _buildForm(BuildContext context, WidgetRef ref, Unit unit) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: UnitForm(
              buildingId: buildingId,
              unit: unit,
              onSuccess: (updatedUnit) => _handleSuccess(context, ref, updatedUnit),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    String userMessage = 'Impossible de charger le lot';
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

  void _handleClose(BuildContext context, WidgetRef ref) {
    ref.read(editUnitProvider.notifier).reset();
    context.pop();
  }

  void _handleSuccess(BuildContext context, WidgetRef ref, Unit unit) {
    // Invalidate the unit cache to refetch fresh data
    ref.invalidate(unitByIdProvider(unitId));

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Le lot a été modifié avec succès'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back to unit detail
    context.pop();
  }
}
