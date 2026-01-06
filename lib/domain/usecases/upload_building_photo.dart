import 'dart:typed_data';
import '../repositories/building_repository.dart';

/// Use case for uploading a building photo
/// Single-responsibility: handles photo upload with compression
class UploadBuildingPhoto {
  final BuildingRepository _repository;

  UploadBuildingPhoto(this._repository);

  /// Execute the use case
  /// Returns the signed URL of the uploaded photo
  /// [buildingId] can be 'new' for new buildings (will be updated after creation)
  /// Throws [BuildingPhotoUploadException] on failure
  /// Throws [BuildingPhotoTooLargeException] if image exceeds 5MB
  Future<String> call({
    required String buildingId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    return _repository.uploadPhoto(
      buildingId: buildingId,
      imageBytes: imageBytes,
      fileName: fileName,
    );
  }
}
