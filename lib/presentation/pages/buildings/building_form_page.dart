import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/building.dart';
import '../../providers/buildings_provider.dart';
import '../../widgets/buildings/building_form.dart';

/// Page for creating or editing a building
/// Supports both create mode (building = null) and edit mode (building provided)
class BuildingFormPage extends ConsumerWidget {
  /// Existing building for edit mode, null for create mode
  final Building? building;

  const BuildingFormPage({
    super.key,
    this.building,
  });

  bool get isEditMode => building != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? "Modifier l'immeuble" : 'Nouvel immeuble'),
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
                onSuccess: (createdBuilding) => _handleSuccess(context, createdBuilding),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleClose(BuildContext context, WidgetRef ref) {
    // Reset provider state when closing
    ref.read(createBuildingProvider.notifier).reset();
    context.pop();
  }

  void _handleSuccess(BuildContext context, Building building) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditMode
              ? "L'immeuble a ete modifie avec succes"
              : "L'immeuble a ete cree avec succes",
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back (or to the building detail in future)
    context.pop();
  }
}
