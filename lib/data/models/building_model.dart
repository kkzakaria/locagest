import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/building.dart';

part 'building_model.freezed.dart';
part 'building_model.g.dart';

/// BuildingModel for Supabase buildings table (Data layer)
@freezed
class BuildingModel with _$BuildingModel {
  const BuildingModel._();

  const factory BuildingModel({
    required String id,
    required String name,
    required String address,
    required String city,
    @JsonKey(name: 'postal_code') String? postalCode,
    @Default("Côte d'Ivoire") String country,
    @JsonKey(name: 'total_units') @Default(0) int totalUnits,
    @JsonKey(name: 'photo_url') String? photoUrl,
    String? notes,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _BuildingModel;

  factory BuildingModel.fromJson(Map<String, dynamic> json) =>
      _$BuildingModelFromJson(json);

  /// Convert to domain entity
  Building toEntity() => Building(
        id: id,
        name: name,
        address: address,
        city: city,
        postalCode: postalCode,
        country: country,
        totalUnits: totalUnits,
        photoUrl: photoUrl,
        notes: notes,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

/// Extension to create BuildingModel from Building entity
extension BuildingModelFromEntity on Building {
  BuildingModel toModel() {
    return BuildingModel(
      id: id,
      name: name,
      address: address,
      city: city,
      postalCode: postalCode,
      country: country,
      totalUnits: totalUnits,
      photoUrl: photoUrl,
      notes: notes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Input model for creating a new building (no id, timestamps)
@freezed
class CreateBuildingInput with _$CreateBuildingInput {
  const factory CreateBuildingInput({
    required String name,
    required String address,
    required String city,
    String? postalCode,
    @Default("Côte d'Ivoire") String country,
    String? photoUrl,
    String? notes,
  }) = _CreateBuildingInput;

  factory CreateBuildingInput.fromJson(Map<String, dynamic> json) =>
      _$CreateBuildingInputFromJson(json);
}

/// Input model for updating an existing building
@freezed
class UpdateBuildingInput with _$UpdateBuildingInput {
  const factory UpdateBuildingInput({
    String? name,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? photoUrl,
    String? notes,
  }) = _UpdateBuildingInput;

  factory UpdateBuildingInput.fromJson(Map<String, dynamic> json) =>
      _$UpdateBuildingInputFromJson(json);
}
