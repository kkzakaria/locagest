# Data Model: Module Lots/Unités (Unit Management)

**Feature Branch**: `003-unit-management`
**Date**: 2026-01-07

## Entity Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                           BUILDING                               │
│  (existing - from 002-building-management)                       │
├─────────────────────────────────────────────────────────────────┤
│  id: UUID (PK)                                                   │
│  name: string                                                    │
│  total_units: integer  ←── AUTO-UPDATED by trigger               │
│  ...                                                             │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           │ 1:N (one building has many units)
                           │ ON DELETE CASCADE
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                             UNIT                                 │
│  (new - this feature)                                           │
├─────────────────────────────────────────────────────────────────┤
│  id: UUID (PK)                                                   │
│  building_id: UUID (FK → buildings.id) [CASCADE DELETE]         │
│  reference: string (UNIQUE per building)                         │
│  type: enum ['residential', 'commercial']                        │
│  floor: integer (nullable)                                       │
│  surface_area: decimal(10,2) (nullable)                          │
│  rooms_count: integer (nullable)                                 │
│  base_rent: decimal(12,2) [NOT NULL]                            │
│  charges_amount: decimal(12,2) [DEFAULT 0]                       │
│  charges_included: boolean [DEFAULT false]                       │
│  status: enum ['vacant', 'occupied', 'maintenance']              │
│  description: text (nullable)                                    │
│  equipment: jsonb [DEFAULT '[]']                                 │
│  photos: jsonb [DEFAULT '[]']                                    │
│  created_at: timestamptz                                         │
│  updated_at: timestamptz                                         │
└─────────────────────────────────────────────────────────────────┘
```

## Unit Entity

### Domain Entity (Pure Dart)

```dart
/// lib/domain/entities/unit.dart
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
}

enum UnitType { residential, commercial }

enum UnitStatus { vacant, occupied, maintenance }
```

### Field Specifications

| Field | Type | Required | Default | Constraints | Description |
|-------|------|----------|---------|-------------|-------------|
| `id` | UUID | Auto | gen_random_uuid() | PK | Unique identifier |
| `building_id` | UUID | Yes | - | FK → buildings(id), CASCADE | Parent building |
| `reference` | text | Yes | - | max 50 chars, UNIQUE per building | Unit identifier (e.g., "A101") |
| `type` | text | Yes | 'residential' | IN ('residential', 'commercial') | Property type |
| `floor` | integer | No | NULL | - | Floor number (negative for basement) |
| `surface_area` | decimal(10,2) | No | NULL | > 0 if provided | Area in m² |
| `rooms_count` | integer | No | NULL | >= 0 if provided | Number of rooms |
| `base_rent` | decimal(12,2) | Yes | - | > 0 | Monthly rent in FCFA |
| `charges_amount` | decimal(12,2) | No | 0 | >= 0 | Monthly charges in FCFA |
| `charges_included` | boolean | No | false | - | Whether charges are included in rent |
| `status` | text | No | 'vacant' | IN ('vacant', 'occupied', 'maintenance') | Availability status |
| `description` | text | No | NULL | max 2000 chars | Free-form description |
| `equipment` | jsonb | No | '[]' | Array of strings | List of equipment/amenities |
| `photos` | jsonb | No | '[]' | Array of URLs | List of photo signed URLs |
| `created_at` | timestamptz | Auto | now() | - | Creation timestamp |
| `updated_at` | timestamptz | Auto | now() | Auto-updated by trigger | Last update timestamp |

### Computed Properties

```dart
/// Total monthly cost (rent + charges if not included)
double get totalMonthlyRent =>
    chargesIncluded ? baseRent : baseRent + chargesAmount;

/// Human-readable type in French
String get typeLabel => type == UnitType.residential ? 'Résidentiel' : 'Commercial';

/// Human-readable status in French
String get statusLabel {
  switch (status) {
    case UnitStatus.vacant: return 'Disponible';
    case UnitStatus.occupied: return 'Occupé';
    case UnitStatus.maintenance: return 'En maintenance';
  }
}

/// Status color for UI (Constitution II)
Color get statusColor {
  switch (status) {
    case UnitStatus.vacant: return Colors.red;      // 🔴 available
    case UnitStatus.occupied: return Colors.green;  // 🟢 rented
    case UnitStatus.maintenance: return Colors.orange; // 🟠 unavailable
  }
}

/// Floor display (handles negative for basement)
String get floorDisplay {
  if (floor == null) return '-';
  if (floor == 0) return 'RDC'; // Rez-de-chaussée
  if (floor! < 0) return 'Sous-sol ${floor!.abs()}';
  return 'Étage $floor';
}

/// Surface area display with unit
String get surfaceDisplay => surfaceArea != null ? '${surfaceArea} m²' : '-';

/// Has photos
bool get hasPhotos => photos.isNotEmpty;

/// Has equipment
bool get hasEquipment => equipment.isNotEmpty;
```

## Data Model (Freezed)

### UnitModel

```dart
/// lib/data/models/unit_model.dart
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

  Unit toEntity() => Unit(
    id: id,
    buildingId: buildingId,
    reference: reference,
    type: UnitType.values.firstWhere((e) => e.name == type),
    floor: floor,
    surfaceArea: surfaceArea,
    roomsCount: roomsCount,
    baseRent: baseRent,
    chargesAmount: chargesAmount,
    chargesIncluded: chargesIncluded,
    status: UnitStatus.values.firstWhere((e) => e.name == status),
    description: description,
    equipment: equipment,
    photos: photos,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
```

### CreateUnitInput

```dart
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
```

### UpdateUnitInput

```dart
@freezed
class UpdateUnitInput with _$UpdateUnitInput {
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
}
```

## Validation Rules

### Client-Side (Dart)

```dart
/// lib/core/utils/validators.dart (additions)

class UnitValidators {
  static String? validateReference(String? value) {
    if (value == null || value.isEmpty) {
      return 'La référence est requise';
    }
    if (value.length > 50) {
      return 'La référence ne doit pas dépasser 50 caractères';
    }
    return null;
  }

  static String? validateBaseRent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le loyer de base est requis';
    }
    final rent = double.tryParse(value.replaceAll(' ', ''));
    if (rent == null || rent <= 0) {
      return 'Le loyer doit être un nombre positif';
    }
    return null;
  }

  static String? validateSurfaceArea(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    final area = double.tryParse(value);
    if (area == null || area <= 0) {
      return 'La surface doit être un nombre positif';
    }
    return null;
  }

  static String? validateRoomsCount(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    final rooms = int.tryParse(value);
    if (rooms == null || rooms < 0) {
      return 'Le nombre de pièces doit être un nombre positif';
    }
    return null;
  }

  static String? validateChargesAmount(String? value) {
    if (value == null || value.isEmpty) return null; // Optional, defaults to 0
    final charges = double.tryParse(value.replaceAll(' ', ''));
    if (charges == null || charges < 0) {
      return 'Les charges doivent être un nombre positif ou zéro';
    }
    return null;
  }
}
```

### Server-Side (SQL Constraints)

```sql
-- Defined in migration 003_units.sql
CONSTRAINT units_reference_length CHECK (char_length(reference) BETWEEN 1 AND 50),
CONSTRAINT units_base_rent_positive CHECK (base_rent > 0),
CONSTRAINT units_charges_amount_positive CHECK (charges_amount >= 0),
CONSTRAINT units_surface_area_positive CHECK (surface_area IS NULL OR surface_area > 0),
CONSTRAINT units_rooms_count_positive CHECK (rooms_count IS NULL OR rooms_count >= 0),
CONSTRAINT units_description_length CHECK (description IS NULL OR char_length(description) <= 2000),
CONSTRAINT units_type_valid CHECK (type IN ('residential', 'commercial')),
CONSTRAINT units_status_valid CHECK (status IN ('vacant', 'occupied', 'maintenance'))
```

## State Transitions

### Unit Status

```
                    ┌──────────────────────┐
                    │    NEW UNIT          │
                    │  (status: vacant)    │
                    └──────────┬───────────┘
                               │
                               ▼
        ┌──────────────────────────────────────────────┐
        │                                              │
        ▼                                              ▼
┌───────────────┐                            ┌─────────────────┐
│    VACANT     │◄──────────────────────────►│  MAINTENANCE    │
│   🔴 Red      │      manual change         │    🟠 Orange    │
└───────┬───────┘                            └─────────────────┘
        │                                              ▲
        │ lease created                                │
        │ (future module)                              │
        ▼                                              │
┌───────────────┐                                      │
│   OCCUPIED    │──────────────────────────────────────┘
│   🟢 Green    │        lease terminated
│               │        (future module)
└───────────────┘

Note: OCCUPIED → MAINTENANCE not allowed directly
      (must terminate lease first)
```

### Status Change Rules

| From | To | Allowed | Condition |
|------|-----|---------|-----------|
| vacant | occupied | Yes (future) | Lease module creates lease |
| vacant | maintenance | Yes | Manual status change |
| occupied | vacant | Yes (future) | Lease module terminates lease |
| occupied | maintenance | No | Cannot put occupied unit in maintenance |
| maintenance | vacant | Yes | Manual status change |
| maintenance | occupied | Yes (future) | Create lease while in maintenance |

## Indexes

```sql
-- Performance indexes for common queries
CREATE INDEX idx_units_building_id ON units(building_id);
CREATE INDEX idx_units_status ON units(status);
CREATE INDEX idx_units_type ON units(type);
CREATE INDEX idx_units_created_at ON units(created_at DESC);

-- Unique constraint for reference per building
CREATE UNIQUE INDEX idx_units_building_reference ON units(building_id, reference);
```

## Relationships Summary

| Entity | Relationship | Cardinality | On Delete |
|--------|--------------|-------------|-----------|
| Building → Unit | Has many | 1:N | CASCADE |
| Unit → Building | Belongs to | N:1 | - |
| Unit → Lease | Has many (future) | 1:N | RESTRICT |
| Unit → Photos | Embedded | 1:N (array) | Inline delete |
| Unit → Equipment | Embedded | 1:N (array) | Inline update |
