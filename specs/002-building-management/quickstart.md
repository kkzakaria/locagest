# Quickstart: Building Management

**Feature**: 002-building-management
**Date**: 2026-01-06

## Prerequisites

Before implementing this feature, ensure:

- [ ] Flutter SDK installed and configured
- [ ] Supabase project created and accessible
- [ ] Auth feature (001-user-auth) implemented and working
- [ ] Access to Supabase dashboard for SQL migrations

## Setup Steps

### 1. Add Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  # ... existing dependencies
  flutter_image_compress: ^2.1.0
  cached_network_image: ^3.3.1
```

Run:
```bash
flutter pub get
```

### 2. Run Database Migration

Execute in Supabase SQL Editor:

```sql
-- Create buildings table
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

  CONSTRAINT buildings_name_length CHECK (char_length(name) BETWEEN 1 AND 100),
  CONSTRAINT buildings_address_length CHECK (char_length(address) BETWEEN 1 AND 200),
  CONSTRAINT buildings_city_length CHECK (char_length(city) BETWEEN 1 AND 100),
  CONSTRAINT buildings_postal_code_length CHECK (postal_code IS NULL OR char_length(postal_code) <= 20),
  CONSTRAINT buildings_notes_length CHECK (notes IS NULL OR char_length(notes) <= 1000),
  CONSTRAINT buildings_total_units_positive CHECK (total_units >= 0)
);

-- Create indexes
CREATE INDEX idx_buildings_created_by ON buildings(created_by);
CREATE INDEX idx_buildings_city ON buildings(city);
CREATE INDEX idx_buildings_created_at ON buildings(created_at DESC);

-- Enable RLS
ALTER TABLE buildings ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
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

-- RLS Policies
CREATE POLICY "admin_full_access" ON buildings
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );

CREATE POLICY "gestionnaire_own_buildings" ON buildings
  FOR ALL USING (
    created_by = auth.uid() AND
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'gestionnaire')
  );

CREATE POLICY "assistant_read_only" ON buildings
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'assistant')
  );

-- Create photos bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('photos', 'photos', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "users_upload_photos" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'photos' AND auth.role() = 'authenticated'
  );

CREATE POLICY "users_view_photos" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'photos' AND auth.role() = 'authenticated'
  );

CREATE POLICY "users_delete_photos" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'photos' AND auth.role() = 'authenticated'
  );
```

### 3. Create File Structure

```bash
# Domain layer
mkdir -p lib/domain/usecases/buildings

# Data layer
touch lib/data/models/building_model.dart
touch lib/data/datasources/building_remote_datasource.dart
touch lib/data/repositories/building_repository_impl.dart

# Presentation layer
mkdir -p lib/presentation/widgets/buildings
touch lib/presentation/providers/buildings_provider.dart

# Errors
touch lib/core/errors/building_exceptions.dart
```

### 4. Implement in Order

Follow this implementation order:

1. **Exceptions** (`lib/core/errors/building_exceptions.dart`)
2. **Domain Entity** (`lib/domain/entities/building.dart`)
3. **Repository Interface** (`lib/domain/repositories/building_repository.dart`)
4. **Freezed Model** (`lib/data/models/building_model.dart`) → run `build_runner`
5. **Datasource** (`lib/data/datasources/building_remote_datasource.dart`)
6. **Repository Impl** (`lib/data/repositories/building_repository_impl.dart`)
7. **Use Cases** (`lib/domain/usecases/buildings/*.dart`)
8. **Provider** (`lib/presentation/providers/buildings_provider.dart`)
9. **Widgets** (`lib/presentation/widgets/buildings/*.dart`)
10. **Pages** (`lib/presentation/pages/buildings/*.dart`)
11. **Router** (update `lib/core/router/app_router.dart`)
12. **Navigation** (add to bottom nav)

### 5. Generate Freezed Code

After creating `building_model.dart`:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 6. Update Router

Add routes to `app_router.dart`:

```dart
GoRoute(
  path: '/buildings',
  builder: (context, state) => const BuildingsListPage(),
  routes: [
    GoRoute(
      path: 'new',
      builder: (context, state) => const BuildingFormPage(),
    ),
    GoRoute(
      path: ':id',
      builder: (context, state) => BuildingDetailPage(
        buildingId: state.pathParameters['id']!,
      ),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => BuildingFormPage(
            buildingId: state.pathParameters['id'],
          ),
        ),
      ],
    ),
  ],
),
```

## Verification Checklist

After implementation, verify:

- [ ] Can create a building with all required fields
- [ ] Can create a building with optional photo
- [ ] Buildings list displays correctly with pagination
- [ ] Can view building details
- [ ] Can edit building information
- [ ] Can delete building without units
- [ ] Cannot delete building with units (error shown)
- [ ] Assistant role can only view (no create/edit/delete buttons)
- [ ] All error messages display in French
- [ ] Photo upload compresses to <1MB
- [ ] Loading states show during operations

## Common Issues

### Build Runner Fails
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### RLS Blocks All Queries
- Check that user has a profile in `profiles` table
- Check that profile has valid `role` field
- Verify auth.uid() matches created_by for gestionnaire

### Photo Upload Fails
- Check storage bucket exists and has correct policies
- Verify image compression is working
- Check file size before upload

## Next Steps

After completing this feature:
1. Run `/speckit.tasks` to generate detailed implementation tasks
2. Implement following task order (Setup → Foundational → User Stories)
3. Test against acceptance scenarios in spec.md
4. Proceed to 003-unit-management feature
