import 'package:flutter/material.dart';

/// Unit type enumeration
enum UnitType {
  residential,
  commercial;

  /// Get French label for the type
  String get label {
    switch (this) {
      case UnitType.residential:
        return 'Résidentiel';
      case UnitType.commercial:
        return 'Commercial';
    }
  }
}

/// Unit status enumeration
enum UnitStatus {
  vacant,
  occupied,
  maintenance;

  /// Get French label for the status
  String get label {
    switch (this) {
      case UnitStatus.vacant:
        return 'Disponible';
      case UnitStatus.occupied:
        return 'Occupé';
      case UnitStatus.maintenance:
        return 'En maintenance';
    }
  }

  /// Get Constitution-compliant color for the status
  Color get color {
    switch (this) {
      case UnitStatus.vacant:
        return Colors.red; // 🔴 available
      case UnitStatus.occupied:
        return Colors.green; // 🟢 rented
      case UnitStatus.maintenance:
        return Colors.orange; // 🟠 unavailable
    }
  }
}

/// Unit entity (Domain layer - pure Dart, no Supabase dependencies)
/// Represents a rentable space within a building
class Unit {
  final String id;
  final String buildingId;
  final String reference;
  final UnitType type;
  final int? floor;
  final double? surfaceArea;
  final int? roomsCount;
  final double baseRent;
  final double chargesAmount;
  final bool chargesIncluded;
  final UnitStatus status;
  final String? description;
  final List<String> equipment;
  final List<String> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Unit({
    required this.id,
    required this.buildingId,
    required this.reference,
    required this.type,
    this.floor,
    this.surfaceArea,
    this.roomsCount,
    required this.baseRent,
    this.chargesAmount = 0,
    this.chargesIncluded = false,
    this.status = UnitStatus.vacant,
    this.description,
    this.equipment = const [],
    this.photos = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================================
  // COMPUTED PROPERTIES
  // ============================================================================

  /// Total monthly cost (rent + charges if not included)
  double get totalMonthlyRent =>
      chargesIncluded ? baseRent : baseRent + chargesAmount;

  /// Human-readable type in French
  String get typeLabel => type.label;

  /// Human-readable status in French
  String get statusLabel => status.label;

  /// Status color for UI (Constitution II)
  Color get statusColor => status.color;

  /// Floor display (handles negative for basement)
  String get floorDisplay {
    if (floor == null) return '-';
    if (floor == 0) return 'RDC'; // Rez-de-chaussée
    if (floor! < 0) return 'Sous-sol ${floor!.abs()}';
    return 'Étage $floor';
  }

  /// Surface area display with unit
  String get surfaceDisplay =>
      surfaceArea != null ? '${surfaceArea!.toStringAsFixed(2)} m²' : '-';

  /// Rooms count display
  String get roomsDisplay {
    if (roomsCount == null) return '-';
    if (roomsCount == 1) return '1 pièce';
    return '$roomsCount pièces';
  }

  /// Has photos
  bool get hasPhotos => photos.isNotEmpty;

  /// Has equipment
  bool get hasEquipment => equipment.isNotEmpty;

  /// Is unit available for new tenants
  bool get isAvailable => status == UnitStatus.vacant;

  /// Is unit currently rented
  bool get isOccupied => status == UnitStatus.occupied;

  /// Is unit under maintenance
  bool get isUnderMaintenance => status == UnitStatus.maintenance;

  // ============================================================================
  // COPY WITH
  // ============================================================================

  /// Copy with modified fields
  Unit copyWith({
    String? id,
    String? buildingId,
    String? reference,
    UnitType? type,
    int? floor,
    double? surfaceArea,
    int? roomsCount,
    double? baseRent,
    double? chargesAmount,
    bool? chargesIncluded,
    UnitStatus? status,
    String? description,
    List<String>? equipment,
    List<String>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Unit(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      reference: reference ?? this.reference,
      type: type ?? this.type,
      floor: floor ?? this.floor,
      surfaceArea: surfaceArea ?? this.surfaceArea,
      roomsCount: roomsCount ?? this.roomsCount,
      baseRent: baseRent ?? this.baseRent,
      chargesAmount: chargesAmount ?? this.chargesAmount,
      chargesIncluded: chargesIncluded ?? this.chargesIncluded,
      status: status ?? this.status,
      description: description ?? this.description,
      equipment: equipment ?? this.equipment,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================================
  // EQUALITY
  // ============================================================================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Unit &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          buildingId == other.buildingId &&
          reference == other.reference &&
          type == other.type &&
          floor == other.floor &&
          surfaceArea == other.surfaceArea &&
          roomsCount == other.roomsCount &&
          baseRent == other.baseRent &&
          chargesAmount == other.chargesAmount &&
          chargesIncluded == other.chargesIncluded &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      buildingId.hashCode ^
      reference.hashCode ^
      type.hashCode ^
      status.hashCode ^
      baseRent.hashCode;

  @override
  String toString() {
    return 'Unit{id: $id, reference: $reference, type: $type, status: $status, baseRent: $baseRent}';
  }
}
