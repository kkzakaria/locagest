# Data Model: Building Management

**Feature**: 002-building-management
**Date**: 2026-01-06

## Entity: Building (Immeuble)

### Overview

A Building represents a physical property containing rental units. It is the top-level entity in the property hierarchy and serves as the container for all units, which in turn link to tenants and leases.

### Database Schema

```sql
CREATE TABLE public.buildings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  postal_code TEXT,
  country TEXT DEFAULT 'Côte d''Ivoire',
  total_units INTEGER DEFAULT 0,
  photo_url TEXT,
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,

  -- Constraints
  CONSTRAINT buildings_name_length CHECK (char_length(name) BETWEEN 1 AND 100),
  CONSTRAINT buildings_address_length CHECK (char_length(address) BETWEEN 1 AND 200),
  CONSTRAINT buildings_city_length CHECK (char_length(city) BETWEEN 1 AND 100),
  CONSTRAINT buildings_postal_code_length CHECK (postal_code IS NULL OR char_length(postal_code) <= 20),
  CONSTRAINT buildings_notes_length CHECK (notes IS NULL OR char_length(notes) <= 1000),
  CONSTRAINT buildings_total_units_positive CHECK (total_units >= 0)
);

-- Indexes for common queries
CREATE INDEX idx_buildings_created_by ON buildings(created_by);
CREATE INDEX idx_buildings_city ON buildings(city);
CREATE INDEX idx_buildings_created_at ON buildings(created_at DESC);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER buildings_updated_at
  BEFORE UPDATE ON buildings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### Field Specifications

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| id | UUID | Yes | Auto-generated | Unique identifier |
| name | TEXT | Yes | - | Building name (1-100 chars) |
| address | TEXT | Yes | - | Street address (1-200 chars) |
| city | TEXT | Yes | - | City name (1-100 chars) |
| postal_code | TEXT | No | NULL | Postal/ZIP code (max 20 chars) |
| country | TEXT | No | "Côte d'Ivoire" | Country name |
| total_units | INTEGER | No | 0 | Count of units (auto-updated) |
| photo_url | TEXT | No | NULL | Signed URL to building photo |
| notes | TEXT | No | NULL | Free-form notes (max 1000 chars) |
| created_by | UUID | Yes | Current user | Reference to profiles.id |
| created_at | TIMESTAMPTZ | Yes | now() | Creation timestamp |
| updated_at | TIMESTAMPTZ | Yes | now() | Last modification timestamp |

### Relationships

```
profiles (users)
    │
    └──< buildings (1:N - user creates many buildings)
            │
            └──< units (1:N - building contains many units) [Future feature]
```

### Row Level Security (RLS)

```sql
-- Enable RLS
ALTER TABLE buildings ENABLE ROW LEVEL SECURITY;

-- Policy 1: Admin has full access to all buildings
CREATE POLICY "admin_full_access" ON buildings
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policy 2: Gestionnaire has full access to own buildings
CREATE POLICY "gestionnaire_own_buildings" ON buildings
  FOR ALL
  USING (
    created_by = auth.uid() AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'gestionnaire'
    )
  )
  WITH CHECK (
    created_by = auth.uid() AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'gestionnaire'
    )
  );

-- Policy 3: Assistant has read-only access
CREATE POLICY "assistant_read_only" ON buildings
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'assistant'
    )
  );
```

### Storage Configuration

```sql
-- Create photos bucket if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('photos', 'photos', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policy: Authenticated users can upload to their folder
CREATE POLICY "users_upload_own_photos" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'photos' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = 'buildings'
  );

-- Storage policy: Users can view photos they have access to
CREATE POLICY "users_view_photos" ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'photos' AND
    auth.role() = 'authenticated'
  );

-- Storage policy: Users can delete their own uploads
CREATE POLICY "users_delete_own_photos" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'photos' AND
    auth.uid()::text = (storage.foldername(name))[2]
  );
```

---

## Domain Entity: Building

### Dart Entity (lib/domain/entities/building.dart)

```dart
/// Building entity (Domain layer - pure Dart, no dependencies)
class Building {
  final String id;
  final String name;
  final String address;
  final String city;
  final String? postalCode;
  final String country;
  final int totalUnits;
  final String? photoUrl;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Building({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.postalCode,
    this.country = "Côte d'Ivoire",
    this.totalUnits = 0,
    this.photoUrl,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Full formatted address
  String get fullAddress {
    final parts = [address, city];
    if (postalCode != null && postalCode!.isNotEmpty) {
      parts.add(postalCode!);
    }
    parts.add(country);
    return parts.join(', ');
  }

  /// Check if building has units (prevents deletion)
  bool get hasUnits => totalUnits > 0;

  /// Check if building has a photo
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;
}
```

### Freezed Model (lib/data/models/building_model.dart)

```dart
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
```

---

## Validation Rules

| Field | Rule | Error Message (French) |
|-------|------|----------------------|
| name | Required, 1-100 chars | "Le nom de l'immeuble est requis" / "Le nom ne peut pas dépasser 100 caractères" |
| address | Required, 1-200 chars | "L'adresse est requise" / "L'adresse ne peut pas dépasser 200 caractères" |
| city | Required, 1-100 chars | "La ville est requise" / "Le nom de la ville ne peut pas dépasser 100 caractères" |
| postal_code | Optional, max 20 chars | "Le code postal ne peut pas dépasser 20 caractères" |
| notes | Optional, max 1000 chars | "Les notes ne peuvent pas dépasser 1000 caractères" |
| photo | Optional, max 1MB after compression | "L'image est trop volumineuse. Veuillez choisir une image plus petite." |

---

## State Transitions

Buildings have no explicit status field. The implicit states are:

| State | Condition | Allowed Actions |
|-------|-----------|-----------------|
| Empty | totalUnits = 0 | Create, Read, Update, Delete |
| Occupied | totalUnits > 0 | Create, Read, Update (Delete blocked) |

Transition trigger: `total_units` is updated automatically when units are added/removed (future feature will add trigger).
