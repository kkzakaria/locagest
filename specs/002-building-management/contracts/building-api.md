# API Contract: Building Management

**Feature**: 002-building-management
**Date**: 2026-01-06
**Backend**: Supabase (PostgreSQL + PostgREST)

## Overview

This document defines the API contract for building CRUD operations using Supabase. All operations go through the Supabase client which translates to PostgREST API calls.

---

## Authentication

All endpoints require authentication via Supabase Auth JWT token.

```dart
// Token is automatically included by supabase_flutter
final supabase = Supabase.instance.client;
```

---

## Operations

### 1. Create Building

**Supabase Operation**: `INSERT`

**Request**:
```dart
final response = await supabase
    .from('buildings')
    .insert({
      'name': 'Résidence Les Palmiers',
      'address': '123 Rue de la Paix',
      'city': 'Abidjan',
      'postal_code': '01 BP 1234', // optional
      'country': "Côte d'Ivoire", // optional, has default
      'photo_url': 'https://...', // optional
      'notes': 'Immeuble récent...', // optional
      'created_by': userId, // current user ID
    })
    .select()
    .single();
```

**Success Response** (201 Created):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Résidence Les Palmiers",
  "address": "123 Rue de la Paix",
  "city": "Abidjan",
  "postal_code": "01 BP 1234",
  "country": "Côte d'Ivoire",
  "total_units": 0,
  "photo_url": "https://...",
  "notes": "Immeuble récent...",
  "created_by": "user-uuid",
  "created_at": "2026-01-06T10:30:00Z",
  "updated_at": "2026-01-06T10:30:00Z"
}
```

**Error Responses**:
| Code | Condition | French Message |
|------|-----------|----------------|
| 400 | Validation failed | "Données invalides. Veuillez vérifier les champs." |
| 401 | Not authenticated | "Veuillez vous connecter." |
| 403 | Not authorized (assistant role) | "Vous n'avez pas les droits pour créer un immeuble." |
| 500 | Server error | "Une erreur s'est produite. Veuillez réessayer." |

---

### 2. Get Buildings (List)

**Supabase Operation**: `SELECT` with pagination

**Request** (Page 1):
```dart
final response = await supabase
    .from('buildings')
    .select()
    .order('created_at', ascending: false)
    .range(0, 19); // First 20 buildings
```

**Request** (Page N):
```dart
final offset = (page - 1) * 20;
final response = await supabase
    .from('buildings')
    .select()
    .order('created_at', ascending: false)
    .range(offset, offset + 19);
```

**Success Response** (200 OK):
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Résidence Les Palmiers",
    "address": "123 Rue de la Paix",
    "city": "Abidjan",
    "postal_code": "01 BP 1234",
    "country": "Côte d'Ivoire",
    "total_units": 5,
    "photo_url": "https://...",
    "notes": null,
    "created_by": "user-uuid",
    "created_at": "2026-01-06T10:30:00Z",
    "updated_at": "2026-01-06T10:30:00Z"
  },
  // ... more buildings
]
```

**Error Responses**:
| Code | Condition | French Message |
|------|-----------|----------------|
| 401 | Not authenticated | "Veuillez vous connecter." |
| 500 | Server error | "Impossible de charger les immeubles. Veuillez réessayer." |

---

### 3. Get Building by ID

**Supabase Operation**: `SELECT` single

**Request**:
```dart
final response = await supabase
    .from('buildings')
    .select()
    .eq('id', buildingId)
    .single();
```

**Success Response** (200 OK):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Résidence Les Palmiers",
  "address": "123 Rue de la Paix",
  "city": "Abidjan",
  "postal_code": "01 BP 1234",
  "country": "Côte d'Ivoire",
  "total_units": 5,
  "photo_url": "https://...",
  "notes": "Immeuble récent...",
  "created_by": "user-uuid",
  "created_at": "2026-01-06T10:30:00Z",
  "updated_at": "2026-01-06T10:30:00Z"
}
```

**Error Responses**:
| Code | Condition | French Message |
|------|-----------|----------------|
| 401 | Not authenticated | "Veuillez vous connecter." |
| 404 | Building not found | "Immeuble non trouvé." |
| 500 | Server error | "Impossible de charger l'immeuble. Veuillez réessayer." |

---

### 4. Update Building

**Supabase Operation**: `UPDATE`

**Request**:
```dart
final response = await supabase
    .from('buildings')
    .update({
      'name': 'Nouveau Nom',
      'address': '456 Nouvelle Rue',
      'city': 'Abidjan',
      'postal_code': null, // can clear optional fields
      'photo_url': 'https://new-photo...',
      'notes': 'Notes mises à jour',
      // updated_at is set automatically by trigger
    })
    .eq('id', buildingId)
    .select()
    .single();
```

**Success Response** (200 OK):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Nouveau Nom",
  "address": "456 Nouvelle Rue",
  "city": "Abidjan",
  "postal_code": null,
  "country": "Côte d'Ivoire",
  "total_units": 5,
  "photo_url": "https://new-photo...",
  "notes": "Notes mises à jour",
  "created_by": "user-uuid",
  "created_at": "2026-01-06T10:30:00Z",
  "updated_at": "2026-01-06T11:45:00Z"
}
```

**Error Responses**:
| Code | Condition | French Message |
|------|-----------|----------------|
| 400 | Validation failed | "Données invalides. Veuillez vérifier les champs." |
| 401 | Not authenticated | "Veuillez vous connecter." |
| 403 | Not authorized | "Vous n'avez pas les droits pour modifier cet immeuble." |
| 404 | Building not found | "Immeuble non trouvé." |
| 500 | Server error | "Impossible de mettre à jour l'immeuble. Veuillez réessayer." |

---

### 5. Delete Building

**Supabase Operation**: `DELETE`

**Pre-check** (client-side):
```dart
// Check if building has units before attempting delete
final building = await supabase
    .from('buildings')
    .select('total_units')
    .eq('id', buildingId)
    .single();

if (building['total_units'] > 0) {
  throw BuildingHasUnitsException();
}
```

**Request**:
```dart
await supabase
    .from('buildings')
    .delete()
    .eq('id', buildingId);
```

**Success Response** (204 No Content):
```
// Empty response body
```

**Error Responses**:
| Code | Condition | French Message |
|------|-----------|----------------|
| 401 | Not authenticated | "Veuillez vous connecter." |
| 403 | Not authorized | "Vous n'avez pas les droits pour supprimer cet immeuble." |
| 404 | Building not found | "Immeuble non trouvé." |
| 409 | Has units (FK constraint) | "Impossible de supprimer cet immeuble car il contient des lots." |
| 500 | Server error | "Impossible de supprimer l'immeuble. Veuillez réessayer." |

---

## Photo Upload

### Upload Building Photo

**Supabase Operation**: Storage upload

**Request**:
```dart
// 1. Compress image first (max 1MB)
final compressedBytes = await FlutterImageCompress.compressWithList(
  imageBytes,
  minWidth: 1024,
  minHeight: 1024,
  quality: 85,
);

// 2. Upload to storage
final path = 'buildings/${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
await supabase.storage
    .from('photos')
    .uploadBinary(path, compressedBytes);

// 3. Get signed URL (valid for 1 year)
final signedUrl = await supabase.storage
    .from('photos')
    .createSignedUrl(path, 60 * 60 * 24 * 365);
```

**Success Response**:
- Upload returns the path
- Signed URL is stored in building.photo_url

**Error Responses**:
| Condition | French Message |
|-----------|----------------|
| File too large | "L'image est trop volumineuse. Maximum 5 Mo." |
| Invalid file type | "Format d'image non supporté. Utilisez JPG ou PNG." |
| Upload failed | "Échec du téléchargement. Veuillez réessayer." |

---

## Repository Interface

```dart
/// Building repository interface (Domain layer)
abstract class BuildingRepository {
  /// Create a new building
  Future<Building> createBuilding({
    required String name,
    required String address,
    required String city,
    String? postalCode,
    String? country,
    String? photoUrl,
    String? notes,
  });

  /// Get all buildings for current user (paginated)
  Future<List<Building>> getBuildings({int page = 1, int limit = 20});

  /// Get building by ID
  Future<Building> getBuildingById(String id);

  /// Update existing building
  Future<Building> updateBuilding({
    required String id,
    String? name,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? photoUrl,
    String? notes,
  });

  /// Delete building (fails if has units)
  Future<void> deleteBuilding(String id);

  /// Upload building photo and return URL
  Future<String> uploadPhoto(String buildingId, List<int> imageBytes);
}
```

---

## Error Handling

All Supabase errors should be caught and converted to domain exceptions:

```dart
class BuildingException implements Exception {
  final String message;
  final String? code;
  BuildingException(this.message, {this.code});
}

class BuildingNotFoundException extends BuildingException {
  BuildingNotFoundException() : super("Immeuble non trouvé.");
}

class BuildingHasUnitsException extends BuildingException {
  BuildingHasUnitsException()
      : super("Impossible de supprimer cet immeuble car il contient des lots.");
}

class BuildingUnauthorizedException extends BuildingException {
  BuildingUnauthorizedException()
      : super("Vous n'avez pas les droits pour cette opération.");
}

class BuildingValidationException extends BuildingException {
  final Map<String, String> fieldErrors;
  BuildingValidationException(this.fieldErrors)
      : super("Données invalides. Veuillez vérifier les champs.");
}
```
