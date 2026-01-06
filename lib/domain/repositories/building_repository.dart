import 'dart:typed_data';
import '../entities/building.dart';

/// Building repository interface (Domain layer)
/// Defines the contract for building operations
abstract class BuildingRepository {
  /// Create a new building
  /// Throws [BuildingException] on failure
  Future<Building> createBuilding({
    required String name,
    required String address,
    required String city,
    String? postalCode,
    String? country,
    String? photoUrl,
    String? notes,
  });

  /// Get all buildings for current user (paginated)
  /// [page] starts at 1
  /// [limit] defaults to 20 items per page
  /// Returns empty list if no buildings found
  Future<List<Building>> getBuildings({int page = 1, int limit = 20});

  /// Get building by ID
  /// Throws [BuildingNotFoundException] if not found
  /// Throws [BuildingUnauthorizedException] if user doesn't have access
  Future<Building> getBuildingById(String id);

  /// Update existing building
  /// Only provided fields will be updated
  /// Throws [BuildingNotFoundException] if not found
  /// Throws [BuildingUnauthorizedException] if user doesn't have permission
  /// Throws [BuildingValidationException] if validation fails
  Future<Building> updateBuilding({
    required String id,
    String? name,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? photoUrl,
    String? notes,
  });

  /// Delete building by ID
  /// Throws [BuildingNotFoundException] if not found
  /// Throws [BuildingHasUnitsException] if building has units
  /// Throws [BuildingUnauthorizedException] if user doesn't have permission
  Future<void> deleteBuilding(String id);

  /// Upload building photo and return the signed URL
  /// [imageBytes] is the raw image data
  /// Images are compressed before upload (max 1MB)
  /// Returns the signed URL valid for 1 year
  /// Throws [BuildingPhotoUploadException] on failure
  /// Throws [BuildingPhotoTooLargeException] if image exceeds 5MB
  Future<String> uploadPhoto({
    required String buildingId,
    required Uint8List imageBytes,
    required String fileName,
  });

  /// Delete building photo from storage
  /// [photoPath] is the storage path (not the signed URL)
  Future<void> deletePhoto(String photoPath);

  /// Get total count of buildings for current user
  Future<int> getBuildingsCount();

  /// Check if current user can manage buildings (create/edit/delete)
  /// Returns false for assistant role
  Future<bool> canManageBuildings();
}
