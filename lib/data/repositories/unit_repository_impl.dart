import 'dart:typed_data';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/unit_repository.dart';
import '../datasources/unit_remote_datasource.dart';
import '../models/unit_model.dart';

/// Implementation of UnitRepository using remote datasource
class UnitRepositoryImpl implements UnitRepository {
  final UnitRemoteDatasource _datasource;

  UnitRepositoryImpl(this._datasource);

  @override
  Future<Unit> createUnit({
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
    final input = CreateUnitInput(
      buildingId: buildingId,
      reference: reference,
      type: type,
      floor: floor,
      surfaceArea: surfaceArea,
      roomsCount: roomsCount,
      baseRent: baseRent,
      chargesAmount: chargesAmount,
      chargesIncluded: chargesIncluded,
      description: description,
      equipment: equipment,
    );

    final model = await _datasource.createUnit(input);
    return model.toEntity();
  }

  @override
  Future<List<Unit>> getUnitsByBuilding({
    required String buildingId,
    int page = 1,
    int limit = 20,
  }) async {
    final models = await _datasource.getUnitsByBuilding(
      buildingId: buildingId,
      page: page,
      limit: limit,
    );

    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Unit> getUnitById(String id) async {
    final model = await _datasource.getUnitById(id);
    return model.toEntity();
  }

  @override
  Future<Unit> updateUnit({
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
    final input = UpdateUnitInput(
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

    final model = await _datasource.updateUnit(id: id, input: input);
    return model.toEntity();
  }

  @override
  Future<void> deleteUnit(String id) async {
    await _datasource.deleteUnit(id);
  }

  @override
  Future<String> uploadPhoto({
    required String unitId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    return _datasource.uploadPhoto(
      unitId: unitId,
      imageBytes: imageBytes,
      fileName: fileName,
    );
  }

  @override
  Future<void> deletePhoto(String photoPath) async {
    await _datasource.deletePhoto(photoPath);
  }

  @override
  Future<int> getUnitsCount(String buildingId) async {
    return _datasource.getUnitsCount(buildingId);
  }

  @override
  Future<bool> canManageUnits() async {
    return _datasource.canManageUnits();
  }

  @override
  Future<bool> isReferenceUnique({
    required String buildingId,
    required String reference,
    String? excludeUnitId,
  }) async {
    return _datasource.isReferenceUnique(
      buildingId: buildingId,
      reference: reference,
      excludeUnitId: excludeUnitId,
    );
  }
}
