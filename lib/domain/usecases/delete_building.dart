import '../repositories/building_repository.dart';

/// Use case for deleting a building
/// Single-responsibility: handles building deletion with unit count check
class DeleteBuilding {
  final BuildingRepository _repository;

  DeleteBuilding(this._repository);

  /// Execute the use case
  /// Throws [BuildingNotFoundException] if not found
  /// Throws [BuildingHasUnitsException] if building has units
  /// Throws [BuildingUnauthorizedException] if user doesn't have permission
  Future<void> call(String id) async {
    return _repository.deleteBuilding(id);
  }
}
