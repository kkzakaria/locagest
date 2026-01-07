import '../entities/unit.dart';
import '../repositories/unit_repository.dart';

/// Use case for getting units list for a building with pagination
/// Single-responsibility: handles fetching paginated units for a specific building
class GetUnitsByBuilding {
  final UnitRepository _repository;

  GetUnitsByBuilding(this._repository);

  /// Execute the use case
  /// Returns paginated list of units for the specified building
  /// [buildingId] is required - the ID of the building to fetch units for
  /// [page] starts at 1
  /// [limit] defaults to 20 items per page
  Future<List<Unit>> call({
    required String buildingId,
    int page = 1,
    int limit = 20,
  }) async {
    return _repository.getUnitsByBuilding(
      buildingId: buildingId,
      page: page,
      limit: limit,
    );
  }
}
