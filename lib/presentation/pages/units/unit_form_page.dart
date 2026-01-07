import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/unit.dart';
import '../../providers/units_provider.dart';
import '../../widgets/units/unit_form.dart';

/// Page for creating or editing a unit
/// Supports both create mode (unit = null) and edit mode (unit provided)
class UnitFormPage extends ConsumerWidget {
  /// Building ID the unit belongs to
  final String buildingId;

  /// Existing unit for edit mode, null for create mode
  final Unit? unit;

  const UnitFormPage({
    super.key,
    required this.buildingId,
    this.unit,
  });

  bool get isEditMode => unit != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Modifier le lot' : 'Nouveau lot'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(context, ref),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: UnitForm(
                buildingId: buildingId,
                unit: unit,
                onSuccess: (createdUnit) => _handleSuccess(context, createdUnit),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleClose(BuildContext context, WidgetRef ref) {
    // Reset provider state when closing
    if (isEditMode) {
      ref.read(editUnitProvider.notifier).reset();
    } else {
      ref.read(createUnitProvider.notifier).reset();
    }
    context.pop();
  }

  void _handleSuccess(BuildContext context, Unit unit) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditMode
              ? 'Le lot a été modifié avec succès'
              : 'Lot créé avec succès',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back to building detail
    context.pop();
  }
}
