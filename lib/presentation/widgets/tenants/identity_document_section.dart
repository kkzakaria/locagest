import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/utils/validators.dart';
import '../../../domain/entities/tenant.dart';

/// Section for managing identity document in tenant form
/// Supports ID type selection and document upload (JPEG, PNG, PDF - max 5MB)
class IdentityDocumentSection extends StatefulWidget {
  /// Current ID document type
  final IdDocumentType? idType;

  /// Current ID number
  final String? idNumber;

  /// Existing document URL (for edit mode)
  final String? existingDocumentUrl;

  /// Whether document is currently uploading
  final bool isUploading;

  /// Upload progress (0.0 to 1.0)
  final double? uploadProgress;

  /// Callback when ID type changes
  final ValueChanged<IdDocumentType?>? onIdTypeChanged;

  /// Callback when ID number changes
  final ValueChanged<String>? onIdNumberChanged;

  /// Callback when document is selected for upload
  final void Function(Uint8List bytes, String fileName)? onDocumentSelected;

  /// Callback when document should be removed
  final VoidCallback? onDocumentRemoved;

  /// Whether the form is disabled
  final bool enabled;

  const IdentityDocumentSection({
    super.key,
    this.idType,
    this.idNumber,
    this.existingDocumentUrl,
    this.isUploading = false,
    this.uploadProgress,
    this.onIdTypeChanged,
    this.onIdNumberChanged,
    this.onDocumentSelected,
    this.onDocumentRemoved,
    this.enabled = true,
  });

  @override
  State<IdentityDocumentSection> createState() => _IdentityDocumentSectionState();
}

class _IdentityDocumentSectionState extends State<IdentityDocumentSection> {
  final _idNumberController = TextEditingController();
  Uint8List? _selectedDocumentBytes;
  String? _selectedDocumentName;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _idNumberController.text = widget.idNumber ?? '';
    _isExpanded = widget.idType != null || widget.existingDocumentUrl != null;
  }

  @override
  void didUpdateWidget(IdentityDocumentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.idNumber != oldWidget.idNumber) {
      _idNumberController.text = widget.idNumber ?? '';
    }
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie photo'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Document PDF'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    Uint8List? bytes;
    String? fileName;

    if (result == 'pdf') {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (picked != null && picked.files.single.bytes != null) {
        bytes = picked.files.single.bytes!;
        fileName = picked.files.single.name;
      }
    } else {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: result == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        bytes = await pickedFile.readAsBytes();
        fileName = pickedFile.name;
      }
    }

    if (bytes != null && fileName != null) {
      // Validate file size
      final sizeError = TenantValidators.validateDocumentSize(bytes.length);
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

      // Validate file format
      final formatError = TenantValidators.validateDocumentFormat(fileName);
      if (formatError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(formatError),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedDocumentBytes = bytes;
        _selectedDocumentName = fileName;
      });

      widget.onDocumentSelected?.call(bytes, fileName);
    }
  }

  void _removeDocument() {
    setState(() {
      _selectedDocumentBytes = null;
      _selectedDocumentName = null;
    });
    widget.onDocumentRemoved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with expand toggle
        InkWell(
          onTap: widget.enabled ? () => setState(() => _isExpanded = !_isExpanded) : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Piece d\'identite',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '(Optionnel)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),

        // Expanded content
        if (_isExpanded) ...[
          const SizedBox(height: 16),

          // ID Type dropdown
          DropdownButtonFormField<IdDocumentType>(
            value: widget.idType,
            decoration: const InputDecoration(
              labelText: 'Type de piece',
              prefixIcon: Icon(Icons.credit_card),
            ),
            items: IdDocumentType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.label),
              );
            }).toList(),
            onChanged: widget.enabled ? widget.onIdTypeChanged : null,
          ),

          const SizedBox(height: 16),

          // ID Number field
          TextFormField(
            controller: _idNumberController,
            enabled: widget.enabled,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Numero de piece',
              hintText: 'CI123456789',
              prefixIcon: Icon(Icons.numbers),
            ),
            onChanged: widget.onIdNumberChanged,
            validator: TenantValidators.validateIdNumber,
          ),

          const SizedBox(height: 16),

          // Document upload area
          _buildDocumentPicker(),
        ],
      ],
    );
  }

  Widget _buildDocumentPicker() {
    final hasDocument = _selectedDocumentBytes != null || widget.existingDocumentUrl != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: hasDocument
          ? _buildDocumentPreview()
          : _buildDocumentPlaceholder(),
    );
  }

  Widget _buildDocumentPlaceholder() {
    return InkWell(
      onTap: widget.enabled ? _pickDocument : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Ajouter un document',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'JPEG, PNG ou PDF - Max 5 Mo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPreview() {
    final isImage = _selectedDocumentName?.toLowerCase().endsWith('.jpg') == true ||
        _selectedDocumentName?.toLowerCase().endsWith('.jpeg') == true ||
        _selectedDocumentName?.toLowerCase().endsWith('.png') == true;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Document icon or thumbnail
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _selectedDocumentBytes != null && isImage
                      ? Image.memory(
                          _selectedDocumentBytes!,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          _selectedDocumentName?.toLowerCase().endsWith('.pdf') == true
                              ? Icons.picture_as_pdf
                              : Icons.image,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Document info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDocumentName ?? 'Document existant',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedDocumentBytes != null)
                      Text(
                        _formatFileSize(_selectedDocumentBytes!.length),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Upload progress overlay
        if (widget.isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.uploadProgress != null)
                      CircularProgressIndicator(
                        value: widget.uploadProgress,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    else
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Envoi en cours...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Action buttons
        if (!widget.isUploading && widget.enabled)
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  onTap: _pickDocument,
                  tooltip: 'Changer',
                ),
                const SizedBox(width: 4),
                _buildActionButton(
                  icon: Icons.close,
                  onTap: _removeDocument,
                  tooltip: 'Supprimer',
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: tooltip ?? '',
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}
