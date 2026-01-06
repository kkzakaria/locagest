-- Migration: 002_buildings
-- Feature: Building Management (002-building-management)
-- Date: 2026-01-06

-- ============================================================================
-- CREATE BUILDINGS TABLE
-- ============================================================================

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

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_buildings_created_by ON buildings(created_by);
CREATE INDEX idx_buildings_city ON buildings(city);
CREATE INDEX idx_buildings_created_at ON buildings(created_at DESC);

-- ============================================================================
-- TRIGGER FOR UPDATED_AT
-- ============================================================================

-- Create or replace function (may already exist from other tables)
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

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

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

-- ============================================================================
-- STORAGE BUCKET FOR PHOTOS
-- ============================================================================

-- Create photos bucket if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('photos', 'photos', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policy: Authenticated users can upload to buildings folder
CREATE POLICY "users_upload_building_photos" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'photos' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = 'buildings'
  );

-- Storage policy: Authenticated users can view photos
CREATE POLICY "users_view_building_photos" ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'photos' AND
    auth.role() = 'authenticated'
  );

-- Storage policy: Users can update their own uploads
CREATE POLICY "users_update_building_photos" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'photos' AND
    auth.role() = 'authenticated'
  );

-- Storage policy: Users can delete photos from buildings folder
CREATE POLICY "users_delete_building_photos" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'photos' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = 'buildings'
  );

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE buildings IS 'Buildings (immeubles) managed by property managers';
COMMENT ON COLUMN buildings.name IS 'Building name (1-100 characters)';
COMMENT ON COLUMN buildings.address IS 'Street address (1-200 characters)';
COMMENT ON COLUMN buildings.city IS 'City name (1-100 characters)';
COMMENT ON COLUMN buildings.postal_code IS 'Postal/ZIP code (optional, max 20 characters)';
COMMENT ON COLUMN buildings.country IS 'Country name (defaults to Côte d''Ivoire)';
COMMENT ON COLUMN buildings.total_units IS 'Count of units in building (auto-updated)';
COMMENT ON COLUMN buildings.photo_url IS 'Signed URL to building photo in storage';
COMMENT ON COLUMN buildings.notes IS 'Free-form notes (optional, max 1000 characters)';
COMMENT ON COLUMN buildings.created_by IS 'UUID of user who created the building';
