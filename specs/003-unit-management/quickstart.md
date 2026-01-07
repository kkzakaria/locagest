# Quickstart: Module Lots/Unités (Unit Management)

**Feature Branch**: `003-unit-management`
**Date**: 2026-01-07

## Prerequisites

Before starting implementation:

1. **Building module complete**: Phase 4 (Building Management) must be merged to main
2. **Supabase running**: Local or remote Supabase instance accessible
3. **Development environment**: Flutter SDK stable, dependencies installed

```bash
# Verify prerequisites
flutter doctor
supabase status  # If using local Supabase

# Ensure you're on the feature branch
git checkout 003-unit-management
```

## Implementation Order

Follow this order to ensure dependencies are satisfied:

### Phase 1: Database Setup
1. Create migration `supabase/migrations/003_units.sql`
2. Apply migration to Supabase
3. Verify RLS policies work correctly

### Phase 2: Data Layer
1. Create `lib/core/errors/unit_exceptions.dart`
2. Create `lib/domain/entities/unit.dart`
3. Create `lib/data/models/unit_model.dart`
4. Run `flutter pub run build_runner build --delete-conflicting-outputs`
5. Create `lib/domain/repositories/unit_repository.dart`
6. Create `lib/data/datasources/unit_remote_datasource.dart`
7. Create `lib/data/repositories/unit_repository_impl.dart`

### Phase 3: Domain Layer
1. Create use cases in `lib/domain/usecases/`:
   - `create_unit.dart`
   - `get_units_by_building.dart`
   - `get_unit_by_id.dart`
   - `update_unit.dart`
   - `delete_unit.dart`
   - `upload_unit_photo.dart`

### Phase 4: Presentation Layer
1. Create `lib/presentation/providers/units_provider.dart`
2. Create widgets in `lib/presentation/widgets/units/`:
   - `unit_status_badge.dart`
   - `unit_card.dart`
   - `unit_form.dart`
   - `equipment_list_editor.dart`
   - `unit_photos_gallery.dart`
3. Create pages in `lib/presentation/pages/units/`:
   - `unit_form_page.dart`
   - `unit_detail_page.dart`
   - `unit_edit_page.dart`

### Phase 5: Integration
1. Add routes to `lib/core/router/app_router.dart`
2. Integrate unit list into `building_detail_page.dart`
3. Add validators to `lib/core/utils/validators.dart`

---

## Quick Reference

### Database Migration

```sql
-- supabase/migrations/003_units.sql
CREATE TABLE public.units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  building_id UUID REFERENCES public.buildings(id) ON DELETE CASCADE NOT NULL,
  reference TEXT NOT NULL,
  type TEXT DEFAULT 'residential' CHECK (type IN ('residential', 'commercial')),
  floor INTEGER,
  surface_area DECIMAL(10,2),
  rooms_count INTEGER,
  base_rent DECIMAL(12,2) NOT NULL CHECK (base_rent > 0),
  charges_amount DECIMAL(12,2) DEFAULT 0,
  charges_included BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'vacant' CHECK (status IN ('vacant', 'occupied', 'maintenance')),
  description TEXT,
  equipment JSONB DEFAULT '[]',
  photos JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Apply with: supabase db push (or run SQL in Supabase dashboard)
```

### Entity Template

```dart
// lib/domain/entities/unit.dart
enum UnitType { residential, commercial }
enum UnitStatus { vacant, occupied, maintenance }

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

  // Constructor and copyWith...
}
```

### Provider Template

```dart
// lib/presentation/providers/units_provider.dart
final unitsByBuildingProvider = FutureProvider.family<List<Unit>, String>(
  (ref, buildingId) async {
    final repository = ref.watch(unitRepositoryProvider);
    return repository.getUnitsByBuilding(buildingId: buildingId);
  },
);

final unitByIdProvider = FutureProvider.family<Unit, String>(
  (ref, unitId) async {
    final repository = ref.watch(unitRepositoryProvider);
    return repository.getUnitById(unitId);
  },
);
```

### Status Badge Widget

```dart
// lib/presentation/widgets/units/unit_status_badge.dart
Widget build(BuildContext context) {
  final (label, color) = switch (status) {
    UnitStatus.vacant => ('Disponible', Colors.red),
    UnitStatus.occupied => ('Occupé', Colors.green),
    UnitStatus.maintenance => ('En maintenance', Colors.orange),
  };

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

---

## Key Files Reference

| Layer | File | Purpose |
|-------|------|---------|
| Migration | `supabase/migrations/003_units.sql` | Database schema |
| Entity | `lib/domain/entities/unit.dart` | Domain model |
| Model | `lib/data/models/unit_model.dart` | Freezed + JSON |
| Repository (i) | `lib/domain/repositories/unit_repository.dart` | Interface |
| Repository | `lib/data/repositories/unit_repository_impl.dart` | Implementation |
| Datasource | `lib/data/datasources/unit_remote_datasource.dart` | Supabase calls |
| Provider | `lib/presentation/providers/units_provider.dart` | Riverpod state |
| Exceptions | `lib/core/errors/unit_exceptions.dart` | Error types |

---

## Testing Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/domain/usecases/create_unit_test.dart

# Regenerate Freezed models
flutter pub run build_runner build --delete-conflicting-outputs

# Analyze code
flutter analyze
```

---

## Validation Checklist

Before marking tasks complete:

- [ ] Database migration applied successfully
- [ ] RLS policies tested (admin, gestionnaire, assistant)
- [ ] Unit CRUD operations work end-to-end
- [ ] Building total_units updates correctly
- [ ] Photo upload/delete works
- [ ] Equipment list editing works
- [ ] Status badge colors match Constitution (🔴🟢🟠)
- [ ] All text is in French
- [ ] Currency formatted as FCFA with spaces
- [ ] Form validation shows French error messages
- [ ] Empty states display correctly
- [ ] Loading states show during async operations
- [ ] Unit list pagination works for 50+ units
