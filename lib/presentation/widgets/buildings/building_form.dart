import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/validators.dart';
import '../../../domain/entities/building.dart';
import '../../providers/buildings_provider.dart';

/// Form widget for creating or editing a building
/// Supports photo selection, form validation with French messages
class BuildingForm extends ConsumerStatefulWidget {
  /// Existing building for edit mode, null for create mode
  final Building? building;

  /// Callback when form is successfully submitted
  final void Function(Building building)? onSuccess;

  const BuildingForm({
    super.key,
    this.building,
    this.onSuccess,
  });

  @override
  ConsumerState<BuildingForm> createState() => _BuildingFormState();
}

class _BuildingFormState extends ConsumerState<BuildingForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _notesController = TextEditingController();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.building != null;

    if (_isEditMode) {
      _nameController.text = widget.building!.name;
      _addressController.text = widget.building!.address;
      _cityController.text = widget.building!.city;
      _postalCodeController.text = widget.building!.postalCode ?? '';
      _notesController.text = widget.building!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();

      // Validate file size
      final sizeError = BuildingValidators.validatePhotoSize(bytes.length);
      if (sizeError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sizeError),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = pickedFile.name;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
    // Also remove from provider state if uploaded
    if (_isEditMode) {
      ref.read(editBuildingProvider.notifier).removeNewPhoto();
    } else {
      ref.read(createBuildingProvider.notifier).removePhoto();
    }
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
    final notifier = ref.read(createBuildingProvider.notifier);

    // Upload photo first if selected
    if (_selectedImageBytes != null && _selectedImageName != null) {
      await notifier.uploadPhoto(_selectedImageBytes!, _selectedImageName!);

      // Check for upload error
      final state = ref.read(createBuildingProvider);
      if (state.error != null) {
        return; // Error will be displayed by the UI
      }
    }

    // Create the building
    final building = await notifier.createBuilding(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim().isEmpty
          ? null
          : _postalCodeController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (building != null && mounted) {
      // Reset form state
      notifier.reset();

      // Call success callback
      widget.onSuccess?.call(building);
    }
  }

  Future<void> _handleUpdate() async {
    final notifier = ref.read(editBuildingProvider.notifier);
    final buildingId = widget.building!.id;
    bool hasNewPhoto = false;

    // Upload new photo if selected
    if (_selectedImageBytes != null && _selectedImageName != null) {
      await notifier.uploadPhoto(buildingId, _selectedImageBytes!, _selectedImageName!);

      // Check for upload error
      final state = ref.read(editBuildingProvider);
      if (state.error != null) {
        return; // Error will be displayed by the UI
      }
      hasNewPhoto = true;
    }

    // Update the building
    final building = await notifier.updateBuilding(
      id: buildingId,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim().isEmpty
          ? null
          : _postalCodeController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      useNewPhoto: hasNewPhoto,
    );

    if (building != null && mounted) {
      // Reset form state
      notifier.reset();

      // Call success callback
      widget.onSuccess?.call(building);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the appropriate provider based on mode
    final bool isLoading;
    final bool isUploadingPhoto;
    final String? error;

    if (_isEditMode) {
      final editState = ref.watch(editBuildingProvider);
      isLoading = editState.isLoading;
      isUploadingPhoto = editState.isUploadingPhoto;
      error = editState.error;
    } else {
      final createState = ref.watch(createBuildingProvider);
      isLoading = createState.isLoading;
      isUploadingPhoto = createState.isUploadingPhoto;
      error = createState.error;
    }

    final isProcessing = isLoading || isUploadingPhoto;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error display
          if (error != null) ...[
            _ErrorBanner(message: error),
            const SizedBox(height: 16),
          ],

          // Photo picker
          _PhotoPicker(
            imageBytes: _selectedImageBytes,
            existingPhotoUrl: widget.building?.photoUrl,
            isUploading: isUploadingPhoto,
            onPickImage: isProcessing ? null : _pickImage,
            onRemoveImage: isProcessing ? null : _removeImage,
          ),

          const SizedBox(height: 24),

          // Name field (required)
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            enabled: !isProcessing,
            decoration: const InputDecoration(
              labelText: "Nom de l'immeuble *",
              hintText: 'Residence Les Palmiers',
              prefixIcon: Icon(Icons.apartment),
            ),
            validator: BuildingValidators.validateName,
          ),

          const SizedBox(height: 16),

          // Address field (required)
          TextFormField(
            controller: _addressController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            enabled: !isProcessing,
            decoration: const InputDecoration(
              labelText: 'Adresse *',
              hintText: '123 Boulevard de la Paix',
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: BuildingValidators.validateAddress,
          ),

          const SizedBox(height: 16),

          // City field (required)
          TextFormField(
            controller: _cityController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            enabled: !isProcessing,
            decoration: const InputDecoration(
              labelText: 'Ville *',
              hintText: 'Abidjan',
              prefixIcon: Icon(Icons.location_city),
            ),
            validator: BuildingValidators.validateCity,
          ),

          const SizedBox(height: 16),

          // Postal code field (optional)
          TextFormField(
            controller: _postalCodeController,
            textInputAction: TextInputAction.next,
            enabled: !isProcessing,
            decoration: const InputDecoration(
              labelText: 'Code postal',
              hintText: '01 BP 1234',
              prefixIcon: Icon(Icons.markunread_mailbox),
            ),
            validator: BuildingValidators.validatePostalCode,
          ),

          const SizedBox(height: 16),

          // Notes field (optional)
          TextFormField(
            controller: _notesController,
            textInputAction: TextInputAction.done,
            maxLines: 3,
            enabled: !isProcessing,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Informations supplementaires...',
              prefixIcon: Icon(Icons.notes),
              alignLabelWithHint: true,
            ),
            validator: BuildingValidators.validateNotes,
            onFieldSubmitted: (_) => _handleSubmit(),
          ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isProcessing ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.6),
              ),
              child: isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isUploadingPhoto
                              ? 'Envoi de la photo...'
                              : 'Enregistrement...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _isEditMode ? 'Modifier' : 'Creer l\'immeuble',
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
        ],
      ),
    );
  }
}

/// Photo picker widget with preview
class _PhotoPicker extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? existingPhotoUrl;
  final bool isUploading;
  final VoidCallback? onPickImage;
  final VoidCallback? onRemoveImage;

  const _PhotoPicker({
    this.imageBytes,
    this.existingPhotoUrl,
    this.isUploading = false,
    this.onPickImage,
    this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null || existingPhotoUrl != null;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: hasImage ? _buildImagePreview(context) : _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return InkWell(
      onTap: onPickImage,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Ajouter une photo',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Maximum 5 Mo',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageBytes != null
              ? Image.memory(
                  imageBytes!,
                  fit: BoxFit.cover,
                )
              : Image.network(
                  existingPhotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
        ),

        // Overlay when uploading
        if (isUploading)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),

        // Remove button
        if (!isUploading)
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                // Change photo button
                _buildActionButton(
                  icon: Icons.edit,
                  onTap: onPickImage,
                  tooltip: 'Changer la photo',
                ),
                const SizedBox(width: 8),
                // Remove photo button
                _buildActionButton(
                  icon: Icons.close,
                  onTap: onRemoveImage,
                  tooltip: 'Supprimer la photo',
                  isDestructive: true,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    VoidCallback? onTap,
    String? tooltip,
    bool isDestructive = false,
  }) {
    return Material(
      color: isDestructive ? Colors.red : Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Tooltip(
          message: tooltip ?? '',
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
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
