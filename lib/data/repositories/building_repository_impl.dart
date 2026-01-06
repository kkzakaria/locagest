import 'dart:typed_data';
import '../../domain/entities/building.dart';
import '../../domain/repositories/building_repository.dart';
import '../datasources/building_remote_datasource.dart';

/// Implementation of BuildingRepository using Supabase
class BuildingRepositoryImpl implements BuildingRepository {
  final BuildingRemoteDatasource _datasource;

  BuildingRepositoryImpl(this._datasource);

  @override
  Future<Building> createBuilding({
    required String name,
    required String address,
    required String city,
    String? postalCode,
    String? country,
    String? photoUrl,
    String? notes,
  }) async {
    final model = await _datasource.createBuilding(
      name: name,
      address: address,
      city: city,
      postalCode: postalCode,
      country: country,
      photoUrl: photoUrl,
      notes: notes,
    );
    return model.toEntity();
  }

  @override
  Future<List<Building>> getBuildings({int page = 1, int limit = 20}) async {
    final models = await _datasource.getBuildings(page: page, limit: limit);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Building> getBuildingById(String id) async {
    final model = await _datasource.getBuildingById(id);
    return model.toEntity();
  }

  @override
  Future<Building> updateBuilding({
    required String id,
    String? name,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? photoUrl,
    String? notes,
  }) async {
    final model = await _datasource.updateBuilding(
      id: id,
      name: name,
      address: address,
      city: city,
      postalCode: postalCode,
      country: country,
      photoUrl: photoUrl,
      notes: notes,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteBuilding(String id) async {
    await _datasource.deleteBuilding(id);
  }

  @override
  Future<String> uploadPhoto({
    required String buildingId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    return _datasource.uploadPhoto(
      buildingId: buildingId,
      imageBytes: imageBytes,
      fileName: fileName,
    );
  }

  @override
  Future<void> deletePhoto(String photoPath) async {
    await _datasource.deletePhoto(photoPath);
  }

  @override
  Future<int> getBuildingsCount() async {
    return _datasource.getBuildingsCount();
  }

  @override
  Future<bool> canManageBuildings() async {
    return _datasource.canManageBuildings();
  }
}
