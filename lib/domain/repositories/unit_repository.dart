import 'dart:typed_data';
import '../entities/unit.dart';

/// Unit repository interface (Domain layer)
/// Defines the contract for unit operations
abstract class UnitRepository {
  /// Create a new unit within a building
  /// Throws [UnitDuplicateReferenceException] if reference already exists in building
  /// Throws [UnitBuildingNotFoundException] if building doesn't exist
  /// Throws [UnitUnauthorizedException] if user doesn't have permission
  Future<Unit> createUnit({
    required String buildingId,
    required String reference,
    required double baseRent,
    String type = 'residential',
    int? floor,
    double? surfaceArea,
    int? roomsCount,
    double chargesAmount = 0,
    bool chargesIncluded = false,
    String? description,
    List<String> equipment = const [],
  });

  /// Get all units for a specific building (paginated)
  /// [page] starts at 1
  /// [limit] defaults to 20 items per page
  /// Returns empty list if no units found
  Future<List<Unit>> getUnitsByBuilding({
    required String buildingId,
    int page = 1,
    int limit = 20,
  });

  /// Get unit by ID
  /// Throws [UnitNotFoundException] if not found
  /// Throws [UnitUnauthorizedException] if user doesn't have access
  Future<Unit> getUnitById(String id);

  /// Update existing unit
  /// Only provided fields will be updated
  /// Throws [UnitNotFoundException] if not found
  /// Throws [UnitDuplicateReferenceException] if new reference already exists in building
  /// Throws [UnitUnauthorizedException] if user doesn't have permission
  Future<Unit> updateUnit({
    required String id,
    String? reference,
    String? type,
    int? floor,
    double? surfaceArea,
    int? roomsCount,
    double? baseRent,
    double? chargesAmount,
    bool? chargesIncluded,
    String? status,
    String? description,
    List<String>? equipment,
    List<String>? photos,
  });

  /// Delete unit by ID
  /// Throws [UnitNotFoundException] if not found
  /// Throws [UnitHasActiveLeaseException] if unit has active leases
  /// Throws [UnitUnauthorizedException] if user doesn't have permission
  Future<void> deleteUnit(String id);

  /// Upload unit photo and return the signed URL
  /// [imageBytes] is the raw image data
  /// Images are compressed before upload (max 1MB)
  /// Returns the signed URL valid for 1 year
  /// Throws [UnitPhotoUploadException] on failure
  /// Throws [UnitPhotoTooLargeException] if image exceeds 5MB
  Future<String> uploadPhoto({
    required String unitId,
    required Uint8List imageBytes,
    required String fileName,
  });

  /// Delete unit photo from storage
  /// [photoPath] is the storage path (not the signed URL)
  Future<void> deletePhoto(String photoPath);

  /// Get total count of units for a building
  Future<int> getUnitsCount(String buildingId);

  /// Check if current user can manage units (create/edit/delete)
  /// Returns false for assistant role
  Future<bool> canManageUnits();

  /// Check if unit reference is unique within building
  /// [excludeUnitId] can be provided when editing to exclude the current unit
  Future<bool> isReferenceUnique({
    required String buildingId,
    required String reference,
    String? excludeUnitId,
  });
}
