# API Contract: Tenant Management

**Feature Branch**: `004-tenant-management`
**Date**: 2026-01-07
**Backend**: Supabase PostgreSQL

## Table: `tenants`

### Schema

```sql
CREATE TABLE public.tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT,
  phone TEXT NOT NULL,
  phone_secondary TEXT,
  id_type TEXT CHECK (id_type IN ('cni', 'passport', 'residence_permit')),
  id_number TEXT,
  id_document_url TEXT,
  profession TEXT,
  employer TEXT,
  guarantor_name TEXT,
  guarantor_phone TEXT,
  guarantor_id_url TEXT,
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,

  -- Constraints
  CONSTRAINT tenants_first_name_length CHECK (char_length(first_name) BETWEEN 1 AND 100),
  CONSTRAINT tenants_last_name_length CHECK (char_length(last_name) BETWEEN 1 AND 100),
  CONSTRAINT tenants_phone_not_empty CHECK (char_length(phone) >= 1),
  CONSTRAINT tenants_id_number_length CHECK (id_number IS NULL OR char_length(id_number) <= 50),
  CONSTRAINT tenants_notes_length CHECK (notes IS NULL OR char_length(notes) <= 2000),
  CONSTRAINT tenants_guarantor_name_length CHECK (guarantor_name IS NULL OR char_length(guarantor_name) <= 200),
  CONSTRAINT tenants_profession_length CHECK (profession IS NULL OR char_length(profession) <= 200),
  CONSTRAINT tenants_employer_length CHECK (employer IS NULL OR char_length(employer) <= 200)
);

-- Indexes
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

---

## Repository Interface

### TenantRepository

```dart
/// lib/domain/repositories/tenant_repository.dart
abstract class TenantRepository {
  /// Create a new tenant
  Future<Tenant> createTenant({
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    String? phoneSecondary,
    String? idType,
    String? idNumber,
    String? idDocumentUrl,
    String? profession,
    String? employer,
    String? guarantorName,
    String? guarantorPhone,
    String? guarantorIdUrl,
    String? notes,
  });

  /// Get all tenants (paginated)
  Future<List<Tenant>> getTenants({
    int page = 1,
    int limit = 20,
  });

  /// Get tenant by ID
  Future<Tenant> getTenantById(String id);

  /// Get tenant by ID with lease history
  Future<TenantWithLeases> getTenantWithLeases(String id);

  /// Update existing tenant
  Future<Tenant> updateTenant({
    required String id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? phoneSecondary,
    String? idType,
    String? idNumber,
    String? idDocumentUrl,
    String? profession,
    String? employer,
    String? guarantorName,
    String? guarantorPhone,
    String? guarantorIdUrl,
    String? notes,
  });

  /// Delete tenant by ID
  Future<void> deleteTenant(String id);

  /// Search tenants by name or phone
  Future<List<Tenant>> searchTenants(String query);

  /// Upload tenant document (ID or guarantor ID)
  Future<String> uploadDocument({
    required String tenantId,
    required Uint8List fileBytes,
    required String fileName,
    required DocumentType documentType,
  });

  /// Delete document from storage
  Future<void> deleteDocument(String storagePath);

  /// Get signed URL for document
  Future<String> getDocumentUrl(String storagePath);

  /// Check if phone number already exists
  Future<List<Tenant>> checkPhoneDuplicate(String phone, {String? excludeTenantId});

  /// Check if tenant can be deleted (no active leases)
  Future<bool> canDeleteTenant(String tenantId);
}

enum DocumentType { idDocument, guarantorId }
```

---

## Operations

### Create Tenant

**Supabase Call**:
```dart
final response = await supabase
    .from('tenants')
    .insert({
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'phone_secondary': phoneSecondary,
      'id_type': idType,
      'id_number': idNumber,
      'id_document_url': idDocumentUrl,
      'profession': profession,
      'employer': employer,
      'guarantor_name': guarantorName,
      'guarantor_phone': guarantorPhone,
      'guarantor_id_url': guarantorIdUrl,
      'notes': notes,
    })
    .select()
    .single();
```

**Input**:
```json
{
  "first_name": "Konan",
  "last_name": "Kouadio",
  "phone": "+225 07 XX XX XX XX",
  "email": "konan.kouadio@email.com",
  "phone_secondary": "+225 05 XX XX XX XX",
  "id_type": "cni",
  "id_number": "CI123456789",
  "id_document_url": "tenants/abc123/id_document.pdf",
  "profession": "Ingénieur",
  "employer": "Orange CI",
  "guarantor_name": "Yao Aimé",
  "guarantor_phone": "+225 07 XX XX XX XX",
  "guarantor_id_url": "tenants/abc123/guarantor_id.pdf",
  "notes": "Locataire fiable, toujours ponctuel"
}
```

**Output**:
```json
{
  "id": "uuid",
  "first_name": "Konan",
  "last_name": "Kouadio",
  "phone": "+225 07 XX XX XX XX",
  "email": "konan.kouadio@email.com",
  "phone_secondary": "+225 05 XX XX XX XX",
  "id_type": "cni",
  "id_number": "CI123456789",
  "id_document_url": "tenants/abc123/id_document.pdf",
  "profession": "Ingénieur",
  "employer": "Orange CI",
  "guarantor_name": "Yao Aimé",
  "guarantor_phone": "+225 07 XX XX XX XX",
  "guarantor_id_url": "tenants/abc123/guarantor_id.pdf",
  "notes": "Locataire fiable, toujours ponctuel",
  "created_by": "user-uuid",
  "created_at": "2026-01-07T10:00:00Z",
  "updated_at": "2026-01-07T10:00:00Z"
}
```

**Errors**:
| Code | Condition | Message (FR) |
|------|-----------|--------------|
| 23514 | Constraint violation | "Les données saisies sont invalides" |
| 42501 | Unauthorized | "Vous n'avez pas la permission de créer un locataire" |

---

### Get All Tenants

**Supabase Call**:
```dart
final response = await supabase
    .from('tenants')
    .select()
    .order('last_name', ascending: true)
    .order('first_name', ascending: true)
    .range(offset, offset + limit - 1);
```

**Parameters**:
| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| page | int | No | 1 | Page number |
| limit | int | No | 20 | Items per page |

**Output**:
```json
[
  {
    "id": "uuid",
    "first_name": "Konan",
    "last_name": "Kouadio",
    "phone": "+225 07 XX XX XX XX",
    "email": "konan.kouadio@email.com",
    ...
  },
  ...
]
```

---

### Get Tenant by ID

**Supabase Call**:
```dart
final response = await supabase
    .from('tenants')
    .select()
    .eq('id', id)
    .single();
```

**Errors**:
| Code | Condition | Message (FR) |
|------|-----------|--------------|
| PGRST116 | Not found | "Locataire non trouvé" |
| 42501 | Unauthorized | "Vous n'avez pas accès à ce locataire" |

---

### Get Tenant with Leases

**Supabase Call**:
```dart
final response = await supabase
    .from('tenants')
    .select('''
      *,
      leases (
        id,
        unit_id,
        start_date,
        end_date,
        status,
        rent_amount,
        units (
          reference,
          buildings (name)
        )
      )
    ''')
    .eq('id', id)
    .single();
```

**Output**:
```json
{
  "id": "uuid",
  "first_name": "Konan",
  "last_name": "Kouadio",
  ...
  "leases": [
    {
      "id": "lease-uuid",
      "unit_id": "unit-uuid",
      "start_date": "2025-01-01",
      "end_date": "2026-01-01",
      "status": "active",
      "rent_amount": 150000,
      "units": {
        "reference": "A101",
        "buildings": {
          "name": "Résidence Palmier"
        }
      }
    }
  ]
}
```

---

### Search Tenants

**Supabase Call (Simple ILIKE)**:
```dart
final response = await supabase
    .from('tenants')
    .select()
    .or('first_name.ilike.%$query%,last_name.ilike.%$query%,phone.ilike.%$query%')
    .order('last_name')
    .limit(50);
```

**Supabase Call (Full-text Search)**:
```dart
final response = await supabase
    .from('tenants')
    .select()
    .textSearch('first_name || last_name || phone', query, type: TextSearchType.websearch)
    .order('last_name')
    .limit(50);
```

**Parameters**:
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| query | string | Yes | Search term (name or phone) |

---

### Update Tenant

**Supabase Call**:
```dart
final response = await supabase
    .from('tenants')
    .update({
      // Only include non-null fields
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (phoneSecondary != null) 'phone_secondary': phoneSecondary,
      if (idType != null) 'id_type': idType,
      if (idNumber != null) 'id_number': idNumber,
      if (idDocumentUrl != null) 'id_document_url': idDocumentUrl,
      if (profession != null) 'profession': profession,
      if (employer != null) 'employer': employer,
      if (guarantorName != null) 'guarantor_name': guarantorName,
      if (guarantorPhone != null) 'guarantor_phone': guarantorPhone,
      if (guarantorIdUrl != null) 'guarantor_id_url': guarantorIdUrl,
      if (notes != null) 'notes': notes,
    })
    .eq('id', id)
    .select()
    .single();
```

**Errors**:
| Code | Condition | Message (FR) |
|------|-----------|--------------|
| PGRST116 | Not found | "Locataire non trouvé" |
| 42501 | Unauthorized | "Vous n'avez pas la permission de modifier ce locataire" |

---

### Delete Tenant

**Pre-check Active Leases**:
```dart
// Check for active leases first
final activeLeases = await supabase
    .from('leases')
    .select('id')
    .eq('tenant_id', tenantId)
    .eq('status', 'active');

if (activeLeases.isNotEmpty) {
  throw TenantHasActiveLeaseException();
}
```

**Supabase Call**:
```dart
await supabase
    .from('tenants')
    .delete()
    .eq('id', id);
```

**Pre-conditions**:
- User must have gestionnaire or admin role
- Tenant must not have active leases

**Errors**:
| Code | Condition | Message (FR) |
|------|-----------|--------------|
| PGRST116 | Not found | "Locataire non trouvé" |
| 42501 | Unauthorized | "Vous n'avez pas la permission de supprimer ce locataire" |
| 23503 | Has active lease | "Ce locataire ne peut pas être supprimé car il a un bail actif" |

---

### Upload Document

**Supabase Call**:
```dart
// 1. Determine path based on document type
final path = documentType == DocumentType.idDocument
    ? 'tenants/$tenantId/id_document_${DateTime.now().millisecondsSinceEpoch}.$extension'
    : 'tenants/$tenantId/guarantor_id_${DateTime.now().millisecondsSinceEpoch}.$extension';

// 2. Upload to storage
await supabase.storage
    .from('documents')
    .uploadBinary(path, fileBytes, fileOptions: FileOptions(
      contentType: mimeType,
    ));

// 3. Return storage path (not signed URL)
return path;
```

**Update Tenant with Document Path**:
```dart
final fieldName = documentType == DocumentType.idDocument
    ? 'id_document_url'
    : 'guarantor_id_url';

await supabase
    .from('tenants')
    .update({fieldName: path})
    .eq('id', tenantId);
```

**Constraints**:
- Max file size: 5MB
- Supported formats: JPEG, PNG, PDF
- Files stored in private `documents` bucket

---

### Get Document Signed URL

**Supabase Call**:
```dart
final signedUrl = await supabase.storage
    .from('documents')
    .createSignedUrl(storagePath, 3600); // 1 hour validity

return signedUrl;
```

---

### Check Phone Duplicate

**Supabase Call**:
```dart
var query = supabase
    .from('tenants')
    .select('id, first_name, last_name')
    .eq('phone', phone);

if (excludeTenantId != null) {
  query = query.neq('id', excludeTenantId);
}

final response = await query;
return response.map((e) => TenantModel.fromJson(e).toEntity()).toList();
```

**Returns**: List of existing tenants with same phone (for warning display)

---

## Row Level Security (RLS)

### Policies

```sql
-- Enable RLS
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

-- Policy 1: Admin has full access to all tenants
CREATE POLICY "admin_full_access" ON tenants
  FOR ALL
  USING (public.get_user_role() = 'admin')
  WITH CHECK (public.get_user_role() = 'admin');

-- Policy 2: Gestionnaire has full access to tenants they created
CREATE POLICY "gestionnaire_own_tenants" ON tenants
  FOR ALL
  USING (
    created_by = auth.uid()
    AND public.get_user_role() = 'gestionnaire'
  )
  WITH CHECK (
    public.get_user_role() = 'gestionnaire'
  );

-- Policy 3: Assistant can read all tenants
CREATE POLICY "assistant_read" ON tenants
  FOR SELECT
  USING (public.get_user_role() = 'assistant');

-- Policy 4: Assistant can create tenants
CREATE POLICY "assistant_create" ON tenants
  FOR INSERT
  WITH CHECK (public.get_user_role() = 'assistant');
```

### Helper Function

```sql
-- Get current user's role (reuse from existing setup)
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;
```

---

## Storage Policies

### Documents Bucket

```sql
-- Create private documents bucket (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false)
ON CONFLICT DO NOTHING;

-- Upload policy for tenants folder
CREATE POLICY "users_upload_tenant_documents" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'documents' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = 'tenants'
  );

-- View policy - only authenticated users with signed URLs
CREATE POLICY "users_view_tenant_documents" ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'documents' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = 'tenants'
  );

-- Delete policy for tenants folder
CREATE POLICY "users_delete_tenant_documents" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'documents' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = 'tenants'
  );
```

---

## Triggers

### Update updated_at

```sql
-- Reuses existing function from buildings migration
CREATE TRIGGER tenants_updated_at
  BEFORE UPDATE ON tenants
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### Set created_by on Insert

```sql
-- Automatically set created_by to current user
CREATE OR REPLACE FUNCTION set_tenant_created_by()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.created_by IS NULL THEN
    NEW.created_by := auth.uid();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tenants_set_created_by
  BEFORE INSERT ON tenants
  FOR EACH ROW
  EXECUTE FUNCTION set_tenant_created_by();
```

---

## Exception Types

```dart
/// lib/core/errors/tenant_exceptions.dart

abstract class TenantException implements Exception {
  final String message;
  const TenantException(this.message);
}

class TenantNotFoundException extends TenantException {
  const TenantNotFoundException() : super('Locataire non trouvé');
}

class TenantUnauthorizedException extends TenantException {
  const TenantUnauthorizedException()
      : super('Vous n\'avez pas accès à ce locataire');
}

class TenantValidationException extends TenantException {
  const TenantValidationException(String message) : super(message);
}

class TenantHasActiveLeaseException extends TenantException {
  const TenantHasActiveLeaseException()
      : super('Ce locataire ne peut pas être supprimé car il a un bail actif');
}

class TenantDocumentTooLargeException extends TenantException {
  const TenantDocumentTooLargeException()
      : super('Le document est trop volumineux (max 5 Mo)');
}

class TenantDocumentInvalidFormatException extends TenantException {
  const TenantDocumentInvalidFormatException()
      : super('Format de document non supporté (JPEG, PNG ou PDF attendu)');
}

class TenantDocumentUploadException extends TenantException {
  const TenantDocumentUploadException()
      : super('Échec du téléchargement du document');
}

class TenantPhoneInvalidException extends TenantException {
  const TenantPhoneInvalidException()
      : super('Format de téléphone invalide');
}

class TenantEmailInvalidException extends TenantException {
  const TenantEmailInvalidException()
      : super('Format d\'email invalide');
}
```
