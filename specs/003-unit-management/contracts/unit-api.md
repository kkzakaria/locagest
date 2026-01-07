# API Contract: Unit Management

**Feature Branch**: `003-unit-management`
**Date**: 2026-01-07
**Backend**: Supabase PostgreSQL

## Table: `units`

### Schema

```sql
CREATE TABLE public.units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  building_id UUID REFERENCES public.buildings(id) ON DELETE CASCADE NOT NULL,
  reference TEXT NOT NULL,
  type TEXT DEFAULT 'residential' CHECK (type IN ('residential', 'commercial')),
  floor INTEGER,
  surface_area DECIMAL(10,2),
  rooms_count INTEGER,
  base_rent DECIMAL(12,2) NOT NULL CHECK (base_rent > 0),
  charges_amount DECIMAL(12,2) DEFAULT 0 CHECK (charges_amount >= 0),
  charges_included BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'vacant' CHECK (status IN ('vacant', 'occupied', 'maintenance')),
  description TEXT,
  equipment JSONB DEFAULT '[]',
  photos JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,

  -- Constraints
  CONSTRAINT units_reference_length CHECK (char_length(reference) BETWEEN 1 AND 50),
  CONSTRAINT units_surface_area_positive CHECK (surface_area IS NULL OR surface_area > 0),
  CONSTRAINT units_rooms_count_positive CHECK (rooms_count IS NULL OR rooms_count >= 0),
  CONSTRAINT units_description_length CHECK (description IS NULL OR char_length(description) <= 2000)
);

-- Unique reference per building
CREATE UNIQUE INDEX idx_units_building_reference ON units(building_id, reference);
```

---

## Repository Interface

### UnitRepository

```dart
/// lib/domain/repositories/unit_repository.dart
abstract class UnitRepository {
  /// Create a new unit within a building
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
  });

  /// Get all units for a specific building (paginated)
  Future<List<Unit>> getUnitsByBuilding({
    required String buildingId,
    int page = 1,
    int limit = 20,
  });

  /// Get unit by ID
  Future<Unit> getUnitById(String id);

  /// Update existing unit
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
  });

  /// Delete unit by ID
  Future<void> deleteUnit(String id);

  /// Upload unit photo and return signed URL
  Future<String> uploadPhoto({
    required String unitId,
    required Uint8List imageBytes,
    required String fileName,
  });

  /// Delete unit photo from storage
  Future<void> deletePhoto(String photoPath);

  /// Get total count of units for a building
  Future<int> getUnitsCount(String buildingId);

  /// Check if current user can manage units (create/edit/delete)
  Future<bool> canManageUnits();

  /// Check if unit reference is unique within building
  Future<bool> isReferenceUnique({
    required String buildingId,
    required String reference,
    String? excludeUnitId,
  });
}
```

---

## Operations

### Create Unit

**Supabase Call**:
```dart
final response = await supabase
    .from('units')
    .insert({
      'building_id': buildingId,
      'reference': reference,
      'type': type,
      'floor': floor,
      'surface_area': surfaceArea,
      'rooms_count': roomsCount,
      'base_rent': baseRent,
      'charges_amount': chargesAmount,
      'charges_included': chargesIncluded,
      'description': description,
      'equipment': equipment,
    })
    .select()
    .single();
```

**Input**:
```json
{
  "building_id": "uuid",
  "reference": "A101",
  "type": "residential",
  "floor": 1,
  "surface_area": 65.5,
  "rooms_count": 3,
  "base_rent": 150000,
  "charges_amount": 25000,
  "charges_included": false,
  "description": "Appartement 3 pièces avec balcon",
  "equipment": ["Climatisation", "Cuisine équipée"]
}
```

**Output**:
```json
{
  "id": "uuid",
  "building_id": "uuid",
  "reference": "A101",
  "type": "residential",
  "floor": 1,
  "surface_area": 65.5,
  "rooms_count": 3,
  "base_rent": 150000,
  "charges_amount": 25000,
  "charges_included": false,
  "status": "vacant",
  "description": "Appartement 3 pièces avec balcon",
  "equipment": ["Climatisation", "Cuisine équipée"],
  "photos": [],
  "created_at": "2026-01-07T10:00:00Z",
  "updated_at": "2026-01-07T10:00:00Z"
}
```

**Errors**:
| Code | Condition | Message (FR) |
|------|-----------|--------------|
| 23505 | Duplicate reference | "Cette référence existe déjà dans cet immeuble" |
| 23503 | Invalid building_id | "L'immeuble spécifié n'existe pas" |
| 23514 | Constraint violation | "Les données saisies sont invalides" |

---

### Get Units by Building

**Supabase Call**:
```dart
final response = await supabase
    .from('units')
    .select()
    .eq('building_id', buildingId)
    .order('created_at', ascending: false)
    .range(offset, offset + limit - 1);
```

**Parameters**:
| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| building_id | UUID | Yes | - | Parent building ID |
| page | int | No | 1 | Page number |
| limit | int | No | 20 | Items per page |

**Output**:
```json
[
  {
    "id": "uuid",
    "building_id": "uuid",
    "reference": "A101",
    "type": "residential",
    "status": "vacant",
    "base_rent": 150000,
    ...
  },
  ...
]
```

---

### Get Unit by ID

**Supabase Call**:
```dart
final response = await supabase
    .from('units')
    .select()
    .eq('id', id)
    .single();
```

**Errors**:
| Code | Condition | Message (FR) |
|------|-----------|--------------|
| PGRST116 | Not found | "Lot non trouvé" |
| 42501 | Unauthorized | "Vous n'avez pas accès à ce lot" |

---

### Update Unit

**Supabase Call**:
```dart
final response = await supabase
    .from('units')
    .update({
      // Only include non-null fields
      if (reference != null) 'reference': reference,
      if (type != null) 'type': type,
      if (floor != null) 'floor': floor,
      if (surfaceArea != null) 'surface_area': surfaceArea,
      if (roomsCount != null) 'rooms_count': roomsCount,
      if (baseRent != null) 'base_rent': baseRent,
      if (chargesAmount != null) 'charges_amount': chargesAmount,
      if (chargesIncluded != null) 'charges_included': chargesIncluded,
      if (status != null) 'status': status,
      if (description != null) 'description': description,
      if (equipment != null) 'equipment': equipment,
      if (photos != null) 'photos': photos,
    })
    .eq('id', id)
    .select()
    .single();
```

**Errors**:
| Code | Condition | Message (FR) |
|------|-----------|--------------|
| PGRST116 | Not found | "Lot non trouvé" |
| 23505 | Duplicate reference | "Cette référence existe déjà dans cet immeuble" |
| 42501 | Unauthorized | "Vous n'avez pas la permission de modifier ce lot" |

---

### Delete Unit

**Supabase Call**:
```dart
await supabase
    .from('units')
    .delete()
    .eq('id', id);
```

**Pre-conditions**:
- User must have gestionnaire or admin role
- Unit must not have active leases (checked via application logic until leases table exists)

**Errors**:
| Code | Condition | Message (FR) |
|------|-----------|--------------|
| PGRST116 | Not found | "Lot non trouvé" |
| 42501 | Unauthorized | "Vous n'avez pas la permission de supprimer ce lot" |
| 23503 | Has active lease (future) | "Ce lot ne peut pas être supprimé car il a un bail actif" |

---

### Upload Photo

**Supabase Call**:
```dart
// 1. Upload to storage
final path = 'units/$unitId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
await supabase.storage
    .from('photos')
    .uploadBinary(path, imageBytes);

// 2. Get signed URL (1 year validity)
final signedUrl = await supabase.storage
    .from('photos')
    .createSignedUrl(path, 31536000); // 365 days

// 3. Update unit photos array
final unit = await getUnitById(unitId);
final updatedPhotos = [...unit.photos, signedUrl];
await updateUnit(id: unitId, photos: updatedPhotos);
```

**Constraints**:
- Max file size: 5MB (compressed to 1MB before upload)
- Supported formats: JPEG, PNG
- Max photos per unit: No hard limit (storage quota applies)

---

### Check Reference Uniqueness

**Supabase Call**:
```dart
final query = supabase
    .from('units')
    .select('id')
    .eq('building_id', buildingId)
    .eq('reference', reference);

if (excludeUnitId != null) {
  query.neq('id', excludeUnitId);
}

final response = await query;
return response.isEmpty; // true if unique
```

---

## Row Level Security (RLS)

### Policies

```sql
-- Enable RLS
ALTER TABLE units ENABLE ROW LEVEL SECURITY;

-- Policy 1: Admin has full access to all units
CREATE POLICY "admin_full_access" ON units
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

-- Policy 2: Gestionnaire has full access to units in their buildings
CREATE POLICY "gestionnaire_own_units" ON units
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM buildings
      WHERE buildings.id = units.building_id
      AND buildings.created_by = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'gestionnaire'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM buildings
      WHERE buildings.id = units.building_id
      AND buildings.created_by = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'gestionnaire'
    )
  );

-- Policy 3: Assistant has read-only access
CREATE POLICY "assistant_read_only" ON units
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'assistant'
    )
  );
```

---

## Storage Policies

### Photos Bucket (units folder)

```sql
-- Upload policy for units folder
CREATE POLICY "users_upload_unit_photos" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'photos' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = 'units'
  );

-- View policy (already exists for photos bucket)

-- Delete policy for units folder
CREATE POLICY "users_delete_unit_photos" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'photos' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = 'units'
  );
```

---

## Triggers

### Update updated_at

```sql
-- Reuses existing function from buildings migration
CREATE TRIGGER units_updated_at
  BEFORE UPDATE ON units
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### Update building total_units

```sql
CREATE OR REPLACE FUNCTION update_building_total_units()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE buildings
    SET total_units = total_units + 1
    WHERE id = NEW.building_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE buildings
    SET total_units = total_units - 1
    WHERE id = OLD.building_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER units_update_building_count
  AFTER INSERT OR DELETE ON units
  FOR EACH ROW
  EXECUTE FUNCTION update_building_total_units();
```

---

## Exception Types

```dart
/// lib/core/errors/unit_exceptions.dart

abstract class UnitException implements Exception {
  final String message;
  const UnitException(this.message);
}

class UnitNotFoundException extends UnitException {
  const UnitNotFoundException() : super('Lot non trouvé');
}

class UnitUnauthorizedException extends UnitException {
  const UnitUnauthorizedException()
      : super('Vous n\'avez pas accès à ce lot');
}

class UnitDuplicateReferenceException extends UnitException {
  const UnitDuplicateReferenceException()
      : super('Cette référence existe déjà dans cet immeuble');
}

class UnitValidationException extends UnitException {
  const UnitValidationException(String message) : super(message);
}

class UnitHasActiveLeaseException extends UnitException {
  const UnitHasActiveLeaseException()
      : super('Ce lot ne peut pas être supprimé car il a un bail actif');
}

class UnitPhotoUploadException extends UnitException {
  const UnitPhotoUploadException()
      : super('Échec du téléchargement de la photo');
}

class UnitPhotoTooLargeException extends UnitException {
  const UnitPhotoTooLargeException()
      : super('La photo est trop volumineuse (max 5 Mo)');
}
```
