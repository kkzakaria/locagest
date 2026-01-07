import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/unit.dart';

part 'unit_model.freezed.dart';
part 'unit_model.g.dart';

/// UnitModel for Supabase units table (Data layer)
@freezed
class UnitModel with _$UnitModel {
  const UnitModel._();

  const factory UnitModel({
    required String id,
    @JsonKey(name: 'building_id') required String buildingId,
    required String reference,
    @Default('residential') String type,
    int? floor,
    @JsonKey(name: 'surface_area') double? surfaceArea,
    @JsonKey(name: 'rooms_count') int? roomsCount,
    @JsonKey(name: 'base_rent') required double baseRent,
    @JsonKey(name: 'charges_amount') @Default(0) double chargesAmount,
    @JsonKey(name: 'charges_included') @Default(false) bool chargesIncluded,
    @Default('vacant') String status,
    String? description,
    @Default([]) List<String> equipment,
    @Default([]) List<String> photos,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _UnitModel;

  factory UnitModel.fromJson(Map<String, dynamic> json) =>
      _$UnitModelFromJson(json);

  /// Convert to domain entity
  Unit toEntity() => Unit(
        id: id,
        buildingId: buildingId,
        reference: reference,
        type: _parseUnitType(type),
        floor: floor,
        surfaceArea: surfaceArea,
        roomsCount: roomsCount,
        baseRent: baseRent,
        chargesAmount: chargesAmount,
        chargesIncluded: chargesIncluded,
        status: _parseUnitStatus(status),
        description: description,
        equipment: equipment,
        photos: photos,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Parse type string to enum
  static UnitType _parseUnitType(String type) {
    return UnitType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => UnitType.residential,
    );
  }

  /// Parse status string to enum
  static UnitStatus _parseUnitStatus(String status) {
    return UnitStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => UnitStatus.vacant,
    );
  }
}

/// Extension to create UnitModel from Unit entity
extension UnitModelFromEntity on Unit {
  UnitModel toModel() {
    return UnitModel(
      id: id,
      buildingId: buildingId,
      reference: reference,
      type: type.name,
      floor: floor,
      surfaceArea: surfaceArea,
      roomsCount: roomsCount,
      baseRent: baseRent,
      chargesAmount: chargesAmount,
      chargesIncluded: chargesIncluded,
      status: status.name,
      description: description,
      equipment: equipment,
      photos: photos,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Input model for creating a new unit (no id, timestamps)
@freezed
class CreateUnitInput with _$CreateUnitInput {
  const factory CreateUnitInput({
    @JsonKey(name: 'building_id') required String buildingId,
    required String reference,
    @Default('residential') String type,
    int? floor,
    @JsonKey(name: 'surface_area') double? surfaceArea,
    @JsonKey(name: 'rooms_count') int? roomsCount,
    @JsonKey(name: 'base_rent') required double baseRent,
    @JsonKey(name: 'charges_amount') @Default(0) double chargesAmount,
    @JsonKey(name: 'charges_included') @Default(false) bool chargesIncluded,
    String? description,
    @Default([]) List<String> equipment,
  }) = _CreateUnitInput;

  factory CreateUnitInput.fromJson(Map<String, dynamic> json) =>
      _$CreateUnitInputFromJson(json);
}

/// Input model for updating an existing unit
@freezed
class UpdateUnitInput with _$UpdateUnitInput {
  const UpdateUnitInput._();

  const factory UpdateUnitInput({
    String? reference,
    String? type,
    int? floor,
    @JsonKey(name: 'surface_area') double? surfaceArea,
    @JsonKey(name: 'rooms_count') int? roomsCount,
    @JsonKey(name: 'base_rent') double? baseRent,
    @JsonKey(name: 'charges_amount') double? chargesAmount,
    @JsonKey(name: 'charges_included') bool? chargesIncluded,
    String? status,
    String? description,
    List<String>? equipment,
    List<String>? photos,
  }) = _UpdateUnitInput;

  factory UpdateUnitInput.fromJson(Map<String, dynamic> json) =>
      _$UpdateUnitInputFromJson(json);

  /// Convert to Map with only non-null fields for Supabase update
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (reference != null) map['reference'] = reference;
    if (type != null) map['type'] = type;
    if (floor != null) map['floor'] = floor;
    if (surfaceArea != null) map['surface_area'] = surfaceArea;
    if (roomsCount != null) map['rooms_count'] = roomsCount;
    if (baseRent != null) map['base_rent'] = baseRent;
    if (chargesAmount != null) map['charges_amount'] = chargesAmount;
    if (chargesIncluded != null) map['charges_included'] = chargesIncluded;
    if (status != null) map['status'] = status;
    if (description != null) map['description'] = description;
    if (equipment != null) map['equipment'] = equipment;
    if (photos != null) map['photos'] = photos;
    return map;
  }
}
