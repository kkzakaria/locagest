import '../entities/building.dart';
import '../repositories/building_repository.dart';

/// Use case for updating an existing building
/// Single-responsibility: handles building update logic
class UpdateBuilding {
  final BuildingRepository _repository;

  UpdateBuilding(this._repository);

  /// Execute the use case
  /// Returns the updated building
  /// Only provided fields will be updated
  /// Throws [BuildingNotFoundException] if not found
  /// Throws [BuildingUnauthorizedException] if user doesn't have permission
  /// Throws [BuildingValidationException] if validation fails
  Future<Building> call({
    required String id,
    String? name,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? photoUrl,
    String? notes,
  }) async {
    return _repository.updateBuilding(
      id: id,
      name: name,
      address: address,
      city: city,
      postalCode: postalCode,
      country: country,
      photoUrl: photoUrl,
      notes: notes,
    );
  }
}
