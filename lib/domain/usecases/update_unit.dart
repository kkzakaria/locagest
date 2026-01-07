import '../entities/unit.dart';
import '../repositories/unit_repository.dart';

/// Use case for updating an existing unit
/// Single-responsibility: handles unit update logic
class UpdateUnit {
  final UnitRepository _repository;

  UpdateUnit(this._repository);

  /// Execute the use case
  /// Returns the updated unit
  /// Only provided fields will be updated
  /// Throws [UnitNotFoundException] if not found
  /// Throws [UnitDuplicateReferenceException] if new reference already exists in building
  /// Throws [UnitValidationException] if validation fails
  /// Throws [UnitUnauthorizedException] if user doesn't have permission
  Future<Unit> call({
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
  }) async {
    return _repository.updateUnit(
      id: id,
      reference: reference,
      type: type,
      floor: floor,
      surfaceArea: surfaceArea,
      roomsCount: roomsCount,
      baseRent: baseRent,
      chargesAmount: chargesAmount,
      chargesIncluded: chargesIncluded,
      status: status,
      description: description,
      equipment: equipment,
      photos: photos,
    );
  }
}
