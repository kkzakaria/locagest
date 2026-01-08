# Quickstart: Module Locataires (Tenant Management)

**Feature Branch**: `004-tenant-management`
**Date**: 2026-01-07

## Prerequisites

Before starting implementation:

1. **Unit module complete**: Phase 5 (Unit Management) must be merged to main
2. **Supabase running**: Local or remote Supabase instance accessible
3. **Development environment**: Flutter SDK stable, dependencies installed

```bash
# Verify prerequisites
flutter doctor
supabase status  # If using local Supabase

# Ensure you're on the feature branch
git checkout 004-tenant-management
```

## Implementation Order

Follow this order to ensure dependencies are satisfied:

### Phase 1: Database Setup
1. Create migration `supabase/migrations/004_tenants.sql`
2. Create private `documents` bucket in Supabase Storage (if not exists)
3. Apply migration to Supabase
4. Verify RLS policies work correctly

### Phase 2: Data Layer
1. Create `lib/core/errors/tenant_exceptions.dart`
2. Create `lib/domain/entities/tenant.dart`
3. Create `lib/data/models/tenant_model.dart`
4. Run `flutter pub run build_runner build --delete-conflicting-outputs`
5. Create `lib/domain/repositories/tenant_repository.dart`
6. Create `lib/data/datasources/tenant_remote_datasource.dart`
7. Create `lib/data/repositories/tenant_repository_impl.dart`

### Phase 3: Domain Layer
1. Create use cases in `lib/domain/usecases/`:
   - `create_tenant.dart`
   - `get_tenants.dart`
   - `get_tenant_by_id.dart`
   - `update_tenant.dart`
   - `delete_tenant.dart`
   - `search_tenants.dart`
   - `upload_tenant_document.dart`

### Phase 4: Presentation Layer
1. Create `lib/presentation/providers/tenants_provider.dart`
2. Create widgets in `lib/presentation/widgets/tenants/`:
   - `tenant_status_badge.dart`
   - `tenant_card.dart`
   - `tenant_form.dart`
   - `identity_document_section.dart`
   - `guarantor_section.dart`
   - `lease_history_section.dart`
3. Create pages in `lib/presentation/pages/tenants/`:
   - `tenants_list_page.dart`
   - `tenant_detail_page.dart`
   - `tenant_form_page.dart`
   - `tenant_edit_page.dart`

### Phase 5: Integration
1. Add routes to `lib/core/router/app_router.dart`
2. Add tenants to bottom navigation
3. Add phone validators to `lib/core/utils/validators.dart`

---

## Quick Reference

### Database Migration

```sql
-- supabase/migrations/004_tenants.sql
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
  CONSTRAINT tenants_phone_not_empty CHECK (char_length(phone) >= 1)
);

-- Apply with: supabase db push (or run SQL in Supabase dashboard)
```

### Entity Template

```dart
// lib/domain/entities/tenant.dart
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
  final bool hasActiveLease;

  // Constructor and copyWith...

  String get fullName => '$firstName $lastName';
  bool get isActive => hasActiveLease;
  String get statusLabel => isActive ? 'Actif' : 'Inactif';
}
```

### Provider Template

```dart
// lib/presentation/providers/tenants_provider.dart
final tenantsProvider = FutureProvider<List<Tenant>>((ref) async {
  final repository = ref.watch(tenantRepositoryProvider);
  return repository.getTenants();
});

final tenantByIdProvider = FutureProvider.family<Tenant, String>(
  (ref, tenantId) async {
    final repository = ref.watch(tenantRepositoryProvider);
    return repository.getTenantById(tenantId);
  },
);

final tenantSearchProvider = FutureProvider.family<List<Tenant>, String>(
  (ref, query) async {
    if (query.isEmpty) return [];
    final repository = ref.watch(tenantRepositoryProvider);
    return repository.searchTenants(query);
  },
);
```

### Status Badge Widget

```dart
// lib/presentation/widgets/tenants/tenant_status_badge.dart
Widget build(BuildContext context) {
  final (label, color) = isActive
      ? ('Actif', Colors.green)
      : ('Inactif', Colors.grey);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 12)),
  );
}
```

### Phone Validator

```dart
// lib/core/utils/validators.dart (additions)
static String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Le numéro de téléphone est requis';
  }
  final cleaned = value.replaceAll(RegExp(r'[\s\-\.]'), '');
  if (cleaned.length < 10) {
    return 'Format de téléphone invalide (ex: 07 XX XX XX XX)';
  }
  final digits = cleaned.replaceAll('+225', '');
  if (!['01', '05', '07'].any((p) => digits.startsWith(p))) {
    return 'Préfixe opérateur invalide (07, 05 ou 01 attendu)';
  }
  return null;
}
```

---

## Key Files Reference

| Layer | File | Purpose |
|-------|------|---------|
| Migration | `supabase/migrations/004_tenants.sql` | Database schema |
| Entity | `lib/domain/entities/tenant.dart` | Domain model |
| Model | `lib/data/models/tenant_model.dart` | Freezed + JSON |
| Repository (i) | `lib/domain/repositories/tenant_repository.dart` | Interface |
| Repository | `lib/data/repositories/tenant_repository_impl.dart` | Implementation |
| Datasource | `lib/data/datasources/tenant_remote_datasource.dart` | Supabase calls |
| Provider | `lib/presentation/providers/tenants_provider.dart` | Riverpod state |
| Exceptions | `lib/core/errors/tenant_exceptions.dart` | Error types |

---

## Testing Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/domain/usecases/create_tenant_test.dart

# Regenerate Freezed models
flutter pub run build_runner build --delete-conflicting-outputs

# Analyze code
flutter analyze
```

---

## Validation Checklist

Before marking tasks complete:

- [ ] Database migration applied successfully
- [ ] Documents storage bucket created with correct policies
- [ ] RLS policies tested (admin, gestionnaire, assistant)
- [ ] Tenant CRUD operations work end-to-end
- [ ] Search functionality returns results in <1 second
- [ ] Document upload/delete works (max 5MB, JPEG/PNG/PDF)
- [ ] Phone validation accepts Ivorian formats (+225, 07, 05, 01)
- [ ] Status badge shows Active/Inactive correctly
- [ ] All text is in French
- [ ] Form validation shows French error messages
- [ ] Empty states display correctly ("Aucun locataire")
- [ ] Loading states show during async operations
- [ ] Tenant list pagination works for 100+ tenants
- [ ] Delete protection works (cannot delete tenant with active lease)
- [ ] Duplicate phone warning displays correctly

---

## ID Document Types Reference

| Type Code | French Label | Description |
|-----------|--------------|-------------|
| `cni` | CNI | Carte Nationale d'Identité |
| `passport` | Passeport | Passeport |
| `residence_permit` | Carte de séjour | Carte de séjour (residence permit) |
