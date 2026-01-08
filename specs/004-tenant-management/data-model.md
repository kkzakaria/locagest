# Data Model: Module Locataires (Tenant Management)

**Feature Branch**: `004-tenant-management`
**Date**: 2026-01-07

## Entity Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                           TENANT                                 │
│  (new - this feature)                                           │
├─────────────────────────────────────────────────────────────────┤
│  id: UUID (PK)                                                   │
│  first_name: text [NOT NULL]                                     │
│  last_name: text [NOT NULL]                                      │
│  email: text (nullable)                                          │
│  phone: text [NOT NULL]                                          │
│  phone_secondary: text (nullable)                                │
│  id_type: enum ['cni', 'passport', 'residence_permit'] (nullable)│
│  id_number: text (nullable)                                      │
│  id_document_url: text (nullable) - storage path                 │
│  profession: text (nullable)                                     │
│  employer: text (nullable)                                       │
│  guarantor_name: text (nullable)                                 │
│  guarantor_phone: text (nullable)                                │
│  guarantor_id_url: text (nullable) - storage path                │
│  notes: text (nullable)                                          │
│  created_by: UUID (FK → profiles.id)                            │
│  created_at: timestamptz                                         │
│  updated_at: timestamptz                                         │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           │ 1:N (one tenant has many leases)
                           │ ON DELETE RESTRICT
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                           LEASE                                  │
│  (future - Phase 7)                                             │
├─────────────────────────────────────────────────────────────────┤
│  id: UUID (PK)                                                   │
│  tenant_id: UUID (FK → tenants.id) [RESTRICT DELETE]            │
│  unit_id: UUID (FK → units.id)                                  │
│  status: enum ['pending', 'active', 'terminated', 'expired']    │
│  ...                                                             │
└─────────────────────────────────────────────────────────────────┘
```

## Tenant Entity

### Domain Entity (Pure Dart)

```dart
/// lib/domain/entities/tenant.dart

enum IdDocumentType { cni, passport, residencePermit }

class Tenant {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String phone;
  final String? phoneSecondary;
  final IdDocumentType? idType;
  final String? idNumber;
  final String? idDocumentUrl;
  final String? profession;
  final String? employer;
  final String? guarantorName;
  final String? guarantorPhone;
  final String? guarantorIdUrl;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed property - requires lease data
  final bool hasActiveLease;

  const Tenant({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.phone,
    this.phoneSecondary,
    this.idType,
    this.idNumber,
    this.idDocumentUrl,
    this.profession,
    this.employer,
    this.guarantorName,
    this.guarantorPhone,
    this.guarantorIdUrl,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.hasActiveLease = false,
  });
}
```

### Field Specifications

| Field | Type | Required | Default | Constraints | Description |
|-------|------|----------|---------|-------------|-------------|
| `id` | UUID | Auto | gen_random_uuid() | PK | Unique identifier |
| `first_name` | text | Yes | - | max 100 chars | Prénom |
| `last_name` | text | Yes | - | max 100 chars | Nom de famille |
| `email` | text | No | NULL | valid email format | Adresse email |
| `phone` | text | Yes | - | Ivorian format | Téléphone principal |
| `phone_secondary` | text | No | NULL | Ivorian format | Téléphone secondaire |
| `id_type` | text | No | NULL | IN ('cni', 'passport', 'residence_permit') | Type de pièce d'identité |
| `id_number` | text | No | NULL | max 50 chars | Numéro de pièce d'identité |
| `id_document_url` | text | No | NULL | storage path | Chemin vers le document uploadé |
| `profession` | text | No | NULL | max 200 chars | Profession |
| `employer` | text | No | NULL | max 200 chars | Employeur |
| `guarantor_name` | text | No | NULL | max 200 chars | Nom complet du garant |
| `guarantor_phone` | text | No | NULL | Ivorian format | Téléphone du garant |
| `guarantor_id_url` | text | No | NULL | storage path | Pièce d'identité du garant |
| `notes` | text | No | NULL | max 2000 chars | Notes libres |
| `created_by` | UUID | Yes | auth.uid() | FK → profiles(id) | Créateur du locataire |
| `created_at` | timestamptz | Auto | now() | - | Date de création |
| `updated_at` | timestamptz | Auto | now() | Auto-updated by trigger | Dernière modification |

### Computed Properties

```dart
/// Full name display
String get fullName => '$firstName $lastName';

/// Human-readable ID type in French
String get idTypeLabel {
  if (idType == null) return '-';
  switch (idType!) {
    case IdDocumentType.cni: return 'CNI';
    case IdDocumentType.passport: return 'Passeport';
    case IdDocumentType.residencePermit: return 'Carte de séjour';
  }
}

/// Status based on active lease
bool get isActive => hasActiveLease;

/// Status label in French
String get statusLabel => isActive ? 'Actif' : 'Inactif';

/// Status color for UI (Constitution II)
Color get statusColor => isActive ? Colors.green : Colors.grey;

/// Has identity document
bool get hasIdDocument => idDocumentUrl != null && idDocumentUrl!.isNotEmpty;

/// Has guarantor info
bool get hasGuarantor => guarantorName != null && guarantorName!.isNotEmpty;

/// Has professional info
bool get hasProfessionalInfo =>
    (profession != null && profession!.isNotEmpty) ||
    (employer != null && employer!.isNotEmpty);

/// Formatted phone for display
String get phoneDisplay {
  // Format: XX XX XX XX XX
  final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.length == 10) {
    return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)} ${digits.substring(8, 10)}';
  }
  return phone;
}
```

## Data Model (Freezed)

### TenantModel

```dart
/// lib/data/models/tenant_model.dart
@freezed
class TenantModel with _$TenantModel {
  const TenantModel._();

  const factory TenantModel({
    required String id,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    String? email,
    required String phone,
    @JsonKey(name: 'phone_secondary') String? phoneSecondary,
    @JsonKey(name: 'id_type') String? idType,
    @JsonKey(name: 'id_number') String? idNumber,
    @JsonKey(name: 'id_document_url') String? idDocumentUrl,
    String? profession,
    String? employer,
    @JsonKey(name: 'guarantor_name') String? guarantorName,
    @JsonKey(name: 'guarantor_phone') String? guarantorPhone,
    @JsonKey(name: 'guarantor_id_url') String? guarantorIdUrl,
    String? notes,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    // Computed from join (when available)
    @JsonKey(name: 'has_active_lease') @Default(false) bool hasActiveLease,
  }) = _TenantModel;

  factory TenantModel.fromJson(Map<String, dynamic> json) =>
      _$TenantModelFromJson(json);

  Tenant toEntity() => Tenant(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    phone: phone,
    phoneSecondary: phoneSecondary,
    idType: idType != null
        ? IdDocumentType.values.firstWhere(
            (e) => e.name == idType || _idTypeFromDb(idType!) == e)
        : null,
    idNumber: idNumber,
    idDocumentUrl: idDocumentUrl,
    profession: profession,
    employer: employer,
    guarantorName: guarantorName,
    guarantorPhone: guarantorPhone,
    guarantorIdUrl: guarantorIdUrl,
    notes: notes,
    createdBy: createdBy,
    createdAt: createdAt,
    updatedAt: updatedAt,
    hasActiveLease: hasActiveLease,
  );

  static IdDocumentType? _idTypeFromDb(String value) {
    switch (value) {
      case 'cni': return IdDocumentType.cni;
      case 'passport': return IdDocumentType.passport;
      case 'residence_permit': return IdDocumentType.residencePermit;
      default: return null;
    }
  }
}
```

### CreateTenantInput

```dart
@freezed
class CreateTenantInput with _$CreateTenantInput {
  const factory CreateTenantInput({
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    String? email,
    required String phone,
    @JsonKey(name: 'phone_secondary') String? phoneSecondary,
    @JsonKey(name: 'id_type') String? idType,
    @JsonKey(name: 'id_number') String? idNumber,
    @JsonKey(name: 'id_document_url') String? idDocumentUrl,
    String? profession,
    String? employer,
    @JsonKey(name: 'guarantor_name') String? guarantorName,
    @JsonKey(name: 'guarantor_phone') String? guarantorPhone,
    @JsonKey(name: 'guarantor_id_url') String? guarantorIdUrl,
    String? notes,
  }) = _CreateTenantInput;

  factory CreateTenantInput.fromJson(Map<String, dynamic> json) =>
      _$CreateTenantInputFromJson(json);
}
```

### UpdateTenantInput

```dart
@freezed
class UpdateTenantInput with _$UpdateTenantInput {
  const factory UpdateTenantInput({
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    String? email,
    String? phone,
    @JsonKey(name: 'phone_secondary') String? phoneSecondary,
    @JsonKey(name: 'id_type') String? idType,
    @JsonKey(name: 'id_number') String? idNumber,
    @JsonKey(name: 'id_document_url') String? idDocumentUrl,
    String? profession,
    String? employer,
    @JsonKey(name: 'guarantor_name') String? guarantorName,
    @JsonKey(name: 'guarantor_phone') String? guarantorPhone,
    @JsonKey(name: 'guarantor_id_url') String? guarantorIdUrl,
    String? notes,
  }) = _UpdateTenantInput;

  factory UpdateTenantInput.fromJson(Map<String, dynamic> json) =>
      _$UpdateTenantInputFromJson(json);
}
```

## Validation Rules

### Client-Side (Dart)

```dart
/// lib/core/utils/validators.dart (additions)

class TenantValidators {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );

  static final _phoneRegex = RegExp(
    r'^(\+225)?[0-9\s\-\.]{10,14}$'
  );

  static String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prénom est requis';
    }
    if (value.length > 100) {
      return 'Le prénom ne doit pas dépasser 100 caractères';
    }
    return null;
  }

  static String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom est requis';
    }
    if (value.length > 100) {
      return 'Le nom ne doit pas dépasser 100 caractères';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    if (!_emailRegex.hasMatch(value)) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\.]'), '');
    if (!_phoneRegex.hasMatch(cleaned)) {
      return 'Format de téléphone invalide (ex: 07 XX XX XX XX)';
    }
    // Check valid operator prefixes for Ivory Coast
    final digits = cleaned.replaceAll('+225', '');
    if (digits.length >= 2 && !['01', '05', '07'].any((p) => digits.startsWith(p))) {
      return 'Préfixe opérateur invalide (07, 05 ou 01 attendu)';
    }
    return null;
  }

  static String? validatePhoneOptional(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    return validatePhone(value);
  }

  static String? validateIdNumber(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    if (value.length > 50) {
      return 'Le numéro ne doit pas dépasser 50 caractères';
    }
    return null;
  }

  static String? validateNotes(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    if (value.length > 2000) {
      return 'Les notes ne doivent pas dépasser 2000 caractères';
    }
    return null;
  }

  static String? validateGuarantorName(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    if (value.length > 200) {
      return 'Le nom du garant ne doit pas dépasser 200 caractères';
    }
    return null;
  }

  static String? validateProfession(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    if (value.length > 200) {
      return 'La profession ne doit pas dépasser 200 caractères';
    }
    return null;
  }
}
```

### Server-Side (SQL Constraints)

```sql
-- Defined in migration 004_tenants.sql
CONSTRAINT tenants_first_name_length CHECK (char_length(first_name) BETWEEN 1 AND 100),
CONSTRAINT tenants_last_name_length CHECK (char_length(last_name) BETWEEN 1 AND 100),
CONSTRAINT tenants_phone_not_empty CHECK (char_length(phone) >= 1),
CONSTRAINT tenants_id_number_length CHECK (id_number IS NULL OR char_length(id_number) <= 50),
CONSTRAINT tenants_notes_length CHECK (notes IS NULL OR char_length(notes) <= 2000),
CONSTRAINT tenants_id_type_valid CHECK (id_type IS NULL OR id_type IN ('cni', 'passport', 'residence_permit')),
CONSTRAINT tenants_guarantor_name_length CHECK (guarantor_name IS NULL OR char_length(guarantor_name) <= 200),
CONSTRAINT tenants_profession_length CHECK (profession IS NULL OR char_length(profession) <= 200),
CONSTRAINT tenants_employer_length CHECK (employer IS NULL OR char_length(employer) <= 200)
```

## Indexes

```sql
-- Performance indexes for common queries
CREATE INDEX idx_tenants_created_by ON tenants(created_by);
CREATE INDEX idx_tenants_created_at ON tenants(created_at DESC);
CREATE INDEX idx_tenants_phone ON tenants(phone);
CREATE INDEX idx_tenants_last_name ON tenants(last_name);

-- Full-text search index
CREATE INDEX idx_tenants_search ON tenants
USING GIN (
  to_tsvector('french',
    coalesce(first_name, '') || ' ' ||
    coalesce(last_name, '') || ' ' ||
    coalesce(phone, '')
  )
);
```

## Relationships Summary

| Entity | Relationship | Cardinality | On Delete |
|--------|--------------|-------------|-----------|
| Profile → Tenant | Creates | 1:N | SET NULL (optional) |
| Tenant → Lease (future) | Has many | 1:N | RESTRICT |
| Tenant → ID Document | Embedded | 1:1 (path) | Inline delete |
| Tenant → Guarantor ID | Embedded | 1:1 (path) | Inline delete |

## Storage Paths

### Document Storage Structure

```
documents/                          # Private bucket
└── tenants/
    └── {tenant_id}/
        ├── id_document.{ext}       # Tenant's identity document
        └── guarantor_id.{ext}      # Guarantor's identity document
```

### URL Generation

```dart
/// Generate signed URL for document access (1 hour validity)
Future<String> getSignedDocumentUrl(String storagePath) async {
  final signedUrl = await supabase.storage
      .from('documents')
      .createSignedUrl(storagePath, 3600); // 1 hour
  return signedUrl;
}
```
