import '../entities/unit.dart';
import '../repositories/unit_repository.dart';

/// Use case for creating a new unit within a building
/// Single-responsibility: handles unit creation logic
class CreateUnit {
  final UnitRepository _repository;

  CreateUnit(this._repository);

  /// Execute the use case
  /// Returns the created unit
  /// Throws [UnitDuplicateReferenceException] if reference already exists in building
  /// Throws [UnitBuildingNotFoundException] if building doesn't exist
  /// Throws [UnitValidationException] if validation fails
  /// Throws [UnitUnauthorizedException] if user doesn't have permission
  Future<Unit> call({
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
  }) async {
    return _repository.createUnit(
      buildingId: buildingId,
      reference: reference,
      baseRent: baseRent,
      type: type,
      floor: floor,
      surfaceArea: surfaceArea,
      roomsCount: roomsCount,
      chargesAmount: chargesAmount,
      chargesIncluded: chargesIncluded,
      description: description,
      equipment: equipment,
    );
  }
}
