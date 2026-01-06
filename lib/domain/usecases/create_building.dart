import '../entities/building.dart';
import '../repositories/building_repository.dart';

/// Use case for creating a new building
/// Single-responsibility: handles building creation logic
class CreateBuilding {
  final BuildingRepository _repository;

  CreateBuilding(this._repository);

  /// Execute the use case
  /// Returns the created building
  /// Throws [BuildingValidationException] if validation fails
  /// Throws [BuildingUnauthorizedException] if user doesn't have permission
  Future<Building> call({
    required String name,
    required String address,
    required String city,
    String? postalCode,
    String? country,
    String? photoUrl,
    String? notes,
  }) async {
    return _repository.createBuilding(
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
