import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/building.dart';
import '../../providers/buildings_provider.dart';
import '../../widgets/buildings/building_form.dart';

/// Wrapper that loads building data before showing the edit form
class BuildingEditPageWrapper extends ConsumerWidget {
  final String buildingId;

  const BuildingEditPageWrapper({
    super.key,
    required this.buildingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildingAsync = ref.watch(buildingByIdProvider(buildingId));

    return buildingAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
        ),
        body: Center(
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
                  'Impossible de charger l\'immeuble',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.red[700],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
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
        ),
      ),
      data: (building) => BuildingEditPage(building: building),
    );
  }
}

/// Page for editing an existing building
class BuildingEditPage extends ConsumerWidget {
  final Building building;

  const BuildingEditPage({
    super.key,
    required this.building,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier l'immeuble"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(context, ref),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: BuildingForm(
                building: building,
                onSuccess: (updatedBuilding) => _handleSuccess(context, updatedBuilding),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleClose(BuildContext context, WidgetRef ref) {
    // Reset provider state when closing
    ref.read(editBuildingProvider.notifier).reset();
    context.pop();
  }

  void _handleSuccess(BuildContext context, Building updatedBuilding) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("L'immeuble a ete modifie avec succes"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back to detail page
    context.pop();
  }
}
