import '../entities/building.dart';
import '../repositories/building_repository.dart';

/// Use case for getting a single building by ID
/// Single-responsibility: handles fetching a building by its unique identifier
class GetBuildingById {
  final BuildingRepository _repository;

  GetBuildingById(this._repository);

  /// Execute the use case
  /// Returns the building with the given ID
  /// Throws [BuildingNotFoundException] if not found
  /// Throws [BuildingUnauthorizedException] if user doesn't have access
  Future<Building> call(String id) async {
    return _repository.getBuildingById(id);
  }
}
