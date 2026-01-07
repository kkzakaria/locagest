-- Migration: 003_units
-- Feature: Unit Management (003-unit-management)
-- Date: 2026-01-07

-- ============================================================================
-- CREATE UNITS TABLE
-- ============================================================================

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

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_units_building_id ON units(building_id);
CREATE INDEX idx_units_status ON units(status);
CREATE INDEX idx_units_type ON units(type);
CREATE INDEX idx_units_created_at ON units(created_at DESC);

-- Unique reference per building
CREATE UNIQUE INDEX idx_units_building_reference ON units(building_id, reference);

-- ============================================================================
-- TRIGGER FOR UPDATED_AT
-- ============================================================================

-- Reuses existing function from buildings migration
CREATE TRIGGER units_updated_at
  BEFORE UPDATE ON units
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER FOR BUILDING TOTAL_UNITS COUNT
-- ============================================================================

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

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

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

-- ============================================================================
-- STORAGE POLICIES FOR UNITS PHOTOS
-- ============================================================================

-- Upload policy for units folder
CREATE POLICY "users_upload_unit_photos" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'photos' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = 'units'
  );

-- Delete policy for units folder
CREATE POLICY "users_delete_unit_photos" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'photos' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = 'units'
  );

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE units IS 'Rental units (lots) within buildings';
COMMENT ON COLUMN units.building_id IS 'Parent building UUID (CASCADE delete)';
COMMENT ON COLUMN units.reference IS 'Unit identifier unique within building (1-50 chars)';
COMMENT ON COLUMN units.type IS 'Property type: residential or commercial';
COMMENT ON COLUMN units.floor IS 'Floor number (negative for basement, 0 for ground floor)';
COMMENT ON COLUMN units.surface_area IS 'Area in square meters (max 2 decimals)';
COMMENT ON COLUMN units.rooms_count IS 'Number of rooms';
COMMENT ON COLUMN units.base_rent IS 'Monthly rent in FCFA (must be positive)';
COMMENT ON COLUMN units.charges_amount IS 'Monthly charges in FCFA (default 0)';
COMMENT ON COLUMN units.charges_included IS 'Whether charges are included in base rent';
COMMENT ON COLUMN units.status IS 'Availability: vacant, occupied, or maintenance';
COMMENT ON COLUMN units.description IS 'Free-form description (max 2000 chars)';
COMMENT ON COLUMN units.equipment IS 'JSON array of equipment/amenities strings';
COMMENT ON COLUMN units.photos IS 'JSON array of photo signed URLs';
