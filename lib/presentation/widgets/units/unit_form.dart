import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../domain/entities/unit.dart';
import '../../providers/units_provider.dart';
import 'equipment_list_editor.dart';

/// Form widget for creating or editing a unit
/// Supports all unit fields with French validation messages
class UnitForm extends ConsumerStatefulWidget {
  /// Building ID for the unit (required for create mode)
  final String buildingId;

  /// Existing unit for edit mode, null for create mode
  final Unit? unit;

  /// Callback when form is successfully submitted
  final void Function(Unit unit)? onSuccess;

  const UnitForm({
    super.key,
    required this.buildingId,
    this.unit,
    this.onSuccess,
  });

  @override
  ConsumerState<UnitForm> createState() => _UnitFormState();
}

class _UnitFormState extends ConsumerState<UnitForm> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _floorController = TextEditingController();
  final _surfaceAreaController = TextEditingController();
  final _roomsCountController = TextEditingController();
  final _baseRentController = TextEditingController();
  final _chargesAmountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'residential';
  bool _chargesIncluded = false;
  bool _isEditMode = false;
  List<String> _equipment = [];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.unit != null;

    if (_isEditMode) {
      _referenceController.text = widget.unit!.reference;
      _selectedType = widget.unit!.type.name;
      if (widget.unit!.floor != null) {
        _floorController.text = widget.unit!.floor.toString();
      }
      if (widget.unit!.surfaceArea != null) {
        _surfaceAreaController.text = widget.unit!.surfaceArea!.toStringAsFixed(2);
      }
      if (widget.unit!.roomsCount != null) {
        _roomsCountController.text = widget.unit!.roomsCount.toString();
      }
      _baseRentController.text = widget.unit!.baseRent.toStringAsFixed(0);
      _chargesAmountController.text = widget.unit!.chargesAmount.toStringAsFixed(0);
      _chargesIncluded = widget.unit!.chargesIncluded;
      _descriptionController.text = widget.unit!.description ?? '';
      _equipment = List.from(widget.unit!.equipment);
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _floorController.dispose();
    _surfaceAreaController.dispose();
    _roomsCountController.dispose();
    _baseRentController.dispose();
    _chargesAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isEditMode) {
      await _handleUpdate();
    } else {
      await _handleCreate();
    }
  }

  Future<void> _handleCreate() async {
    final notifier = ref.read(createUnitProvider.notifier);

    final unit = await notifier.createUnit(
      buildingId: widget.buildingId,
      reference: _referenceController.text.trim(),
      baseRent: UnitValidators.parseAmount(_baseRentController.text) ?? 0,
      type: _selectedType,
      floor: UnitValidators.parseInt(_floorController.text),
      surfaceArea: _surfaceAreaController.text.trim().isEmpty
          ? null
          : double.tryParse(_surfaceAreaController.text.trim().replaceAll(',', '.')),
      roomsCount: UnitValidators.parseInt(_roomsCountController.text),
      chargesAmount: UnitValidators.parseAmount(_chargesAmountController.text) ?? 0,
      chargesIncluded: _chargesIncluded,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      equipment: _equipment,
    );

    if (unit != null && mounted) {
      // Add to building's units list
      ref.read(unitsByBuildingProvider(widget.buildingId).notifier).addUnit(unit);

      // Reset form state
      notifier.reset();

      // Call success callback
      widget.onSuccess?.call(unit);
    }
  }

  Future<void> _handleUpdate() async {
    final notifier = ref.read(editUnitProvider.notifier);

    final unit = await notifier.updateUnit(
      id: widget.unit!.id,
      reference: _referenceController.text.trim(),
      baseRent: UnitValidators.parseAmount(_baseRentController.text),
      type: _selectedType,
      floor: UnitValidators.parseInt(_floorController.text),
      surfaceArea: _surfaceAreaController.text.trim().isEmpty
          ? null
          : double.tryParse(_surfaceAreaController.text.trim().replaceAll(',', '.')),
      roomsCount: UnitValidators.parseInt(_roomsCountController.text),
      chargesAmount: UnitValidators.parseAmount(_chargesAmountController.text),
      chargesIncluded: _chargesIncluded,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      equipment: _equipment,
    );

    if (unit != null && mounted) {
      // Update in building's units list
      ref.read(unitsByBuildingProvider(widget.buildingId).notifier).updateUnit(unit);

      // Reset form state
      notifier.reset();

      // Call success callback
      widget.onSuccess?.call(unit);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the appropriate provider based on mode
    final bool isLoading;
    final String? error;

    if (_isEditMode) {
      final editState = ref.watch(editUnitProvider);
      isLoading = editState.isLoading;
      error = editState.error;
    } else {
      final createState = ref.watch(createUnitProvider);
      isLoading = createState.isLoading;
      error = createState.error;
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error display
            if (error != null) ...[
              _ErrorBanner(message: _getErrorMessage(error)),
              const SizedBox(height: 16),
            ],

            // Reference field (required)
            TextFormField(
              controller: _referenceController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Référence *',
                hintText: 'A101, LOT-01, etc.',
                prefixIcon: Icon(Icons.tag),
                helperText: 'Identifiant unique du lot dans l\'immeuble',
              ),
              validator: UnitValidators.validateReference,
            ),

            const SizedBox(height: 16),

            // Type dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type de lot *',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'residential',
                  child: Text('Résidentiel'),
                ),
                DropdownMenuItem(
                  value: 'commercial',
                  child: Text('Commercial'),
                ),
              ],
              onChanged: isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                        });
                      }
                    },
            ),

            const SizedBox(height: 16),

            // Floor and Surface area row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Floor field
                Expanded(
                  child: TextFormField(
                    controller: _floorController,
                    textInputAction: TextInputAction.next,
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                    ],
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Étage',
                      hintText: '0 = RDC',
                      prefixIcon: Icon(Icons.layers),
                      helperText: 'Négatif = sous-sol',
                    ),
                    validator: UnitValidators.validateFloor,
                  ),
                ),
                const SizedBox(width: 16),
                // Surface area field
                Expanded(
                  child: TextFormField(
                    controller: _surfaceAreaController,
                    textInputAction: TextInputAction.next,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
                    ],
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Surface (m²)',
                      hintText: '75.5',
                      prefixIcon: Icon(Icons.square_foot),
                    ),
                    validator: UnitValidators.validateSurfaceArea,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Rooms count field
            TextFormField(
              controller: _roomsCountController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Nombre de pièces',
                hintText: '3',
                prefixIcon: Icon(Icons.meeting_room),
              ),
              validator: UnitValidators.validateRoomsCount,
            ),

            const SizedBox(height: 24),

            // Rent section header
            Row(
              children: [
                Icon(Icons.payments, size: 20, color: Theme.of(context).primaryColor),
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

            // Base rent field (required)
            TextFormField(
              controller: _baseRentController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Loyer de base (FCFA) *',
                hintText: '150000',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'FCFA/mois',
              ),
              validator: UnitValidators.validateBaseRent,
            ),

            const SizedBox(height: 16),

            // Charges amount and toggle row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Charges amount field
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _chargesAmountController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Charges (FCFA)',
                      hintText: '25000',
                      prefixIcon: Icon(Icons.receipt_long),
                      suffixText: 'FCFA/mois',
                    ),
                    validator: UnitValidators.validateChargesAmount,
                  ),
                ),
                const SizedBox(width: 16),
                // Charges included toggle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Charges comprises',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Switch(
                        value: _chargesIncluded,
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _chargesIncluded = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Description field (optional)
            TextFormField(
              controller: _descriptionController,
              textInputAction: TextInputAction.done,
              maxLines: 3,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Informations supplémentaires sur le lot...',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              validator: UnitValidators.validateDescription,
              onFieldSubmitted: (_) => _handleSubmit(),
            ),

            const SizedBox(height: 24),

            // Equipment list editor
            EquipmentListEditor(
              initialEquipment: _equipment,
              onEquipmentChanged: (equipment) {
                setState(() {
                  _equipment = equipment;
                });
              },
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.6),
                ),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Enregistrement...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _isEditMode ? 'Modifier le lot' : 'Créer le lot',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 8),

            // Required fields note
            Text(
              '* Champs obligatoires',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(String error) {
    // Map technical errors to French user-friendly messages
    if (error.contains('UnitDuplicateReferenceException')) {
      return 'Cette référence existe déjà dans cet immeuble';
    }
    if (error.contains('UnitBuildingNotFoundException')) {
      return 'L\'immeuble n\'existe pas ou a été supprimé';
    }
    if (error.contains('UnitUnauthorizedException')) {
      return 'Vous n\'avez pas les droits pour effectuer cette action';
    }
    if (error.contains('UnitValidationException')) {
      return 'Données invalides. Vérifiez les champs du formulaire.';
    }
    if (error.contains('network') || error.contains('Connection')) {
      return 'Erreur de connexion. Vérifiez votre connexion internet.';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}

/// Error banner widget
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[900]),
            ),
          ),
        ],
      ),
    );
  }
}
