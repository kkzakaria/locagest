import 'dart:typed_data';
import '../repositories/unit_repository.dart';

/// Use case for uploading a unit photo
/// Single-responsibility: handles photo upload with compression
class UploadUnitPhoto {
  final UnitRepository _repository;

  /// Maximum file size in bytes (5MB)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  /// Compressed file target size (1MB)
  static const int compressedSizeTarget = 1024 * 1024;

  UploadUnitPhoto(this._repository);

  /// Execute the use case
  /// Returns the signed URL of the uploaded photo
  /// [unitId] The ID of the unit to associate the photo with
  /// [imageBytes] The raw image data (will be compressed if needed)
  /// [fileName] The original file name
  /// Throws [UnitPhotoTooLargeException] if image exceeds 5MB
  /// Throws [UnitPhotoUploadException] on upload failure
  Future<String> call({
    required String unitId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    // Check file size
    if (imageBytes.length > maxFileSizeBytes) {
      throw Exception('UnitPhotoTooLargeException: La photo dépasse 5 Mo');
    }

    // Note: Image compression should be done at the UI layer using image_picker
    // with maxWidth, maxHeight, and imageQuality parameters
    // The compressed bytes are passed here

    return _repository.uploadPhoto(
      unitId: unitId,
      imageBytes: imageBytes,
      fileName: fileName,
    );
  }
}
