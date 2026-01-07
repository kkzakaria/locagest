import '../repositories/unit_repository.dart';

/// Use case for deleting a unit
/// Single-responsibility: handles unit deletion logic
class DeleteUnit {
  final UnitRepository _repository;

  DeleteUnit(this._repository);

  /// Execute the use case
  /// Deletes the unit with the specified ID
  /// Throws [UnitNotFoundException] if not found
  /// Throws [UnitHasActiveLeaseException] if unit has active leases
  /// Throws [UnitUnauthorizedException] if user doesn't have permission
  Future<void> call(String id) async {
    return _repository.deleteUnit(id);
  }
}
