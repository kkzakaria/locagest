import '../entities/unit.dart';
import '../repositories/unit_repository.dart';

/// Use case for getting a single unit by ID
/// Single-responsibility: handles fetching a specific unit
class GetUnitById {
  final UnitRepository _repository;

  GetUnitById(this._repository);

  /// Execute the use case
  /// Returns the unit with the specified ID
  /// Throws [UnitNotFoundException] if not found
  /// Throws [UnitUnauthorizedException] if user doesn't have access
  Future<Unit> call(String id) async {
    return _repository.getUnitById(id);
  }
}
