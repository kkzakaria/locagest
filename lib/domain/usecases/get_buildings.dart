import '../entities/building.dart';
import '../repositories/building_repository.dart';

/// Use case for getting buildings list with pagination
/// Single-responsibility: handles fetching paginated buildings
class GetBuildings {
  final BuildingRepository _repository;

  GetBuildings(this._repository);

  /// Execute the use case
  /// Returns paginated list of buildings
  /// [page] starts at 1
  /// [limit] defaults to 20 items per page
  Future<List<Building>> call({int page = 1, int limit = 20}) async {
    return _repository.getBuildings(page: page, limit: limit);
  }
}
