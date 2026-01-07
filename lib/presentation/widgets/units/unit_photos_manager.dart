import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/validators.dart';
import '../../providers/units_provider.dart';

/// Widget for managing unit photos (upload, view, delete)
/// Supports image compression and progress indicators
class UnitPhotosManager extends ConsumerStatefulWidget {
  final String unitId;
  final List<String> initialPhotos;
  final ValueChanged<List<String>>? onPhotosChanged;

  const UnitPhotosManager({
    super.key,
    required this.unitId,
    this.initialPhotos = const [],
    this.onPhotosChanged,
  });

  @override
  ConsumerState<UnitPhotosManager> createState() => _UnitPhotosManagerState();
}

class _UnitPhotosManagerState extends ConsumerState<UnitPhotosManager> {
  late List<String> _photos;
  bool _isUploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85, // Compress to ~85% quality
    );

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();

    // Validate file size (after compression)
    final sizeError = UnitValidators.validatePhotoSize(bytes.length);
    if (sizeError != null) {
      setState(() => _error = sizeError);
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final url = await ref.read(unitRepositoryProvider).uploadPhoto(
        unitId: widget.unitId,
        imageBytes: bytes,
        fileName: pickedFile.name,
      );

      setState(() {
        _photos.add(url);
        _isUploading = false;
      });

      widget.onPhotosChanged?.call(_photos);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _error = _getErrorMessage(e.toString());
      });
    }
  }

  Future<void> _deletePhoto(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette photo ?'),
        content: const Text('Cette action est irréversible.'),
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

    if (confirmed == true) {
      setState(() {
        _photos.removeAt(index);
      });

      widget.onPhotosChanged?.call(_photos);

      // Note: Storage cleanup is handled server-side or via background task
      // The photo URL is removed from the unit's photos array
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('UnitPhotoTooLargeException')) {
      return 'La photo dépasse la taille maximale de 5 Mo';
    }
    if (error.contains('UnitPhotoUploadException')) {
      return 'Erreur lors de l\'envoi de la photo';
    }
    return 'Une erreur est survenue';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_library,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Photos (${_photos.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            // Add photo button
            TextButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadImage,
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate, size: 18),
              label: Text(_isUploading ? 'Envoi...' : 'Ajouter'),
            ),
          ],
        ),

        // Error message
        if (_error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _error = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Photos grid
        if (_photos.isEmpty)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 32, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune photo',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                return _buildPhotoTile(index);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoTile(int index) {
    return Padding(
      padding: EdgeInsets.only(right: index < _photos.length - 1 ? 8 : 0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: _photos[index],
              width: 160,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 160,
                height: 120,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                width: 160,
                height: 120,
                color: Colors.grey[200],
                child: Icon(Icons.broken_image, color: Colors.grey[400]),
              ),
            ),
          ),
          // Delete button
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _deletePhoto(index),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
