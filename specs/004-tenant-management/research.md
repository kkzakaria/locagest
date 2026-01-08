# Research: Module Locataires (Tenant Management)

**Feature Branch**: `004-tenant-management`
**Date**: 2026-01-07

## Overview

This document consolidates research findings for the Tenant Management module. Since the project already has established patterns from Building and Unit Management (Phases 4-5), research focuses on tenant-specific design decisions and integration patterns.

---

## 1. Tenant Status (Active/Inactive) Determination

### Decision
Tenant status is **computed** based on lease existence, not stored as a column.

### Rationale
- **FR-007**: "System MUST display tenant status (active if current lease, inactive otherwise)"
- **Dynamic status**: A tenant becomes active when a lease starts and inactive when all leases end
- **No manual override needed**: Status is purely derived from business logic
- **Lease module dependency**: Until leases are implemented, all tenants show as "inactive"

### Implementation
```dart
/// Computed in entity
bool get isActive => hasActiveLease;

/// Query with lease join (when leases table exists)
final tenantWithStatus = await supabase
    .from('tenants')
    .select('''
      *,
      leases!inner(status)
    ''')
    .eq('leases.status', 'active');
```

### Alternatives Considered
| Option | Rejected Because |
|--------|------------------|
| Stored `is_active` column | Requires trigger/sync logic when leases change; data can become stale |
| Separate status field | Over-engineering; status is fully determined by lease relationship |

---

## 2. Identity Document Storage Pattern

### Decision
Store identity documents in a private `documents` bucket with folder structure `tenants/{tenant_id}/`.

### Rationale
- **FR-003**: "System MUST allow recording identity document: type (CNI, passport, carte de séjour), number, and digital copy"
- **Constitution V (Security)**: "Sensitive data (ID documents, contracts) MUST be stored in private buckets with time-limited signed URLs"
- **Separate from photos bucket**: Documents are more sensitive than building/unit photos

### Storage Structure
```
documents/
└── tenants/
    └── {tenant_id}/
        ├── id_document.{pdf|jpg|png}
        └── guarantor_id.{pdf|jpg|png}
```

### URL Storage
Store the storage path (not signed URL) in the database:
```json
{
  "id_document_url": "tenants/abc123/id_document.pdf"
}
```
Generate signed URLs on-demand with 1-hour expiry for security.

### Alternatives Considered
| Option | Rejected Because |
|--------|------------------|
| Store signed URLs directly | URLs expire; requires regeneration tracking |
| Use photos bucket | Documents need stricter access control than property photos |
| Store documents inline (base64) | Database bloat; poor performance |

---

## 3. Phone Number Validation (Ivory Coast)

### Decision
Accept multiple Ivory Coast phone formats with normalization.

### Rationale
- **FR-012**: "System MUST validate phone format (Ivorian format +225 or local format)"
- **Local conventions**: Users may enter phones in various formats

### Accepted Formats
| Input Format | Normalized | Description |
|--------------|------------|-------------|
| `+225 07 XX XX XX XX` | `+2250700000000` | International with operator prefix 07 |
| `+225 05 XX XX XX XX` | `+2250500000000` | International with operator prefix 05 |
| `+225 01 XX XX XX XX` | `+2250100000000` | International with operator prefix 01 |
| `07 XX XX XX XX` | `+2250700000000` | Local 10-digit (auto-add +225) |
| `05 XX XX XX XX` | `+2250500000000` | Local 10-digit (auto-add +225) |
| `07XXXXXXXX` | `+2250700000000` | Compact local |

### Validation Regex
```dart
/// Validates Ivorian phone numbers
static final _phoneRegex = RegExp(
  r'^(\+225)?[0-9\s]{10,14}$'
);

static String? validatePhone(String? value) {
  if (value == null || value.isEmpty) {
    return 'Le numéro de téléphone est requis';
  }
  final cleaned = value.replaceAll(RegExp(r'[\s\-\.]'), '');
  if (!_phoneRegex.hasMatch(cleaned)) {
    return 'Format de téléphone invalide (ex: 07 XX XX XX XX)';
  }
  // Check valid operator prefixes for Ivory Coast
  final digits = cleaned.replaceAll('+225', '');
  if (!['01', '05', '07'].any((p) => digits.startsWith(p))) {
    return 'Préfixe opérateur invalide (07, 05 ou 01 attendu)';
  }
  return null;
}
```

### Alternatives Considered
| Option | Rejected Because |
|--------|------------------|
| Strict E.164 only | Users unfamiliar with international format |
| No validation | Poor data quality; duplicate entries harder to detect |
| International library (libphonenumber) | Overkill for single-country use case |

---

## 4. Guarantor Information Structure

### Decision
Store guarantor info as embedded fields in the tenant record, not a separate table.

### Rationale
- **Specification assumption**: "A tenant can only have one guarantor at a time (guarantor info integrated in profile)"
- **Simplicity**: No need for separate table when 1:1 relationship is guaranteed
- **FR-005**: "System MUST allow recording guarantor information: name, phone, and copy of ID"

### Schema Design
```sql
guarantor_name text,
guarantor_phone text,
guarantor_id_url text  -- Storage path to document
```

### Alternatives Considered
| Option | Rejected Because |
|--------|------------------|
| Separate guarantors table | Spec explicitly limits to one guarantor; adds unnecessary joins |
| JSONB guarantor object | Less query-able; harder to validate |
| Multiple guarantor support | Out of scope per specification |

---

## 5. Tenant Search Implementation

### Decision
Use PostgreSQL full-text search with GIN index on name and phone.

### Rationale
- **FR-006**: "System MUST display list of all tenants with search by name, first name, or phone"
- **SC-002**: "Search returns results in less than 1 second"
- **Performance**: GIN index provides efficient text matching

### Implementation
```sql
-- Create search index
CREATE INDEX idx_tenants_search ON tenants
USING GIN (
  to_tsvector('french', coalesce(first_name, '') || ' ' || coalesce(last_name, '') || ' ' || coalesce(phone, ''))
);

-- Search query
SELECT * FROM tenants
WHERE to_tsvector('french', first_name || ' ' || last_name || ' ' || phone)
      @@ plainto_tsquery('french', :search_term)
ORDER BY last_name, first_name;
```

### Alternative (Simple ILIKE)
For MVP, simpler ILIKE pattern matching may suffice:
```dart
final results = await supabase
    .from('tenants')
    .select()
    .or('first_name.ilike.%$query%,last_name.ilike.%$query%,phone.ilike.%$query%')
    .order('last_name')
    .limit(50);
```

### Alternatives Considered
| Option | Rejected Because |
|--------|------------------|
| Client-side filtering | Poor performance for 200+ tenants |
| External search service | Over-engineering for MVP scale |

---

## 6. Document Upload Constraints

### Decision
Limit uploads to 5MB, support JPEG, PNG, and PDF formats.

### Rationale
- **FR-014**: "System MUST limit uploaded file size to 5 MB maximum"
- **FR-015**: "System MUST accept common image formats (JPEG, PNG) and PDF for documents"
- **Constitution Performance**: "Images MUST be compressed before upload (max 1MB for photos)"

### Implementation
```dart
static const maxDocumentSize = 5 * 1024 * 1024; // 5 MB
static const allowedMimeTypes = ['image/jpeg', 'image/png', 'application/pdf'];

Future<void> validateDocument(Uint8List bytes, String mimeType) async {
  if (bytes.length > maxDocumentSize) {
    throw TenantDocumentTooLargeException();
  }
  if (!allowedMimeTypes.contains(mimeType)) {
    throw TenantDocumentInvalidFormatException();
  }
}
```

### Client-side Compression
For images (JPEG/PNG), compress before upload:
```dart
// Use flutter_image_compress or similar
final compressed = await FlutterImageCompress.compressWithList(
  imageBytes,
  quality: 80,
  minWidth: 1200,
  minHeight: 1200,
);
```

---

## 7. Duplicate Phone Warning

### Decision
Allow duplicate phone numbers but display a warning during entry.

### Rationale
- **Edge case**: "Duplicate phone: System allows duplicate phones (family case) but displays a warning"
- **Real-world scenario**: Family members living in same property may share phone

### Implementation
```dart
/// Check if phone exists when user finishes typing
Future<bool> checkPhoneDuplicate(String phone, {String? excludeTenantId}) async {
  final query = supabase
      .from('tenants')
      .select('id, first_name, last_name')
      .eq('phone', normalizePhone(phone));

  if (excludeTenantId != null) {
    query.neq('id', excludeTenantId);
  }

  final existing = await query;
  return existing.isNotEmpty;
}
```

UI displays warning (not error):
```dart
if (isDuplicate) {
  showSnackBar('Ce numéro est déjà utilisé par un autre locataire');
  // Allow submission anyway
}
```

---

## 8. Lease History Display

### Decision
Lease history is read-only in tenant detail, managed by Lease module.

### Rationale
- **Assumption**: "Lease history is read-only in tenant profile (managed by Lease module)"
- **FR-011**: "System MUST display lease history in tenant profile"
- **Module separation**: Tenant module displays but doesn't modify leases

### Implementation
```dart
/// Fetch tenant with lease history
Future<TenantWithLeases> getTenantWithLeases(String tenantId) async {
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
          units (
            reference,
            buildings (name)
          )
        )
      ''')
      .eq('id', tenantId)
      .single();

  return TenantWithLeases.fromJson(response);
}
```

### Display
- Show list of leases with: Unit reference, Building name, Dates, Status
- Sort by start_date descending (most recent first)
- Visual indicators: 🟢 active, 🟡 pending, ⚫ terminated/expired

---

## 9. Delete Tenant Protection

### Decision
Prevent deletion of tenants with active leases, allow deletion with only historical leases.

### Rationale
- **FR-009**: "System MUST prevent deletion of tenant with active lease"
- **FR-010**: "System MUST allow deletion of tenant without active lease with confirmation"
- **Edge case**: "Tenant with history only: A tenant with only terminated leases (past) can be deleted after confirmation"

### Implementation
```dart
Future<void> deleteTenant(String tenantId) async {
  // Check for active leases
  final activeLeases = await supabase
      .from('leases')
      .select('id')
      .eq('tenant_id', tenantId)
      .eq('status', 'active');

  if (activeLeases.isNotEmpty) {
    throw TenantHasActiveLeaseException();
  }

  // Proceed with deletion (historical leases remain orphaned or cascade based on FK)
  await supabase.from('tenants').delete().eq('id', tenantId);
}
```

### Database Constraint
```sql
-- leases table already has: tenant_id REFERENCES tenants(id) ON DELETE RESTRICT
-- This prevents deletion at DB level if any lease exists

-- For soft delete of historical data, use application logic
```

---

## 10. RLS Policy Pattern

### Decision
Follow building/unit RLS pattern with role-based access and created_by ownership.

### Rationale
- **Constitution Principle III**: RLS must be enabled and role-based
- **FR-017**: "System MUST restrict access by role (gestionnaire/admin: full CRUD, assistant: read-only + add)"

### Policies
1. **Admin**: Full access to all tenants
2. **Gestionnaire**: Full access to tenants they created (`created_by = auth.uid()`)
3. **Assistant**: Read all tenants, Create new tenants only (no edit/delete)

### Implementation Note
```sql
-- Policy: Assistant can read and create, but not update or delete
CREATE POLICY "assistant_read_create" ON tenants
  FOR SELECT
  USING (public.get_user_role() = 'assistant');

CREATE POLICY "assistant_insert" ON tenants
  FOR INSERT
  WITH CHECK (public.get_user_role() = 'assistant');
```

---

## Summary

All research topics are resolved. No NEEDS CLARIFICATION items remain. The module follows established patterns from Building and Unit Management with tenant-specific adaptations for:
- Computed active/inactive status based on leases
- Private document storage with signed URLs
- Ivory Coast phone validation
- Embedded guarantor information
- Full-text search capability
- Duplicate phone warning (not error)
- Lease history read-only display
- Delete protection for active leases

Ready to proceed with Phase 1: Data Model and Contracts.
