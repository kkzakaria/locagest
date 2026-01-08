-- Migration: 004_tenants
-- Feature: Tenant Management (004-tenant-management)
-- Date: 2026-01-08

-- ============================================================================
-- CREATE TENANTS TABLE
-- ============================================================================

CREATE TABLE public.tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT,
  phone TEXT NOT NULL,
  phone_secondary TEXT,
  id_type TEXT CHECK (id_type IS NULL OR id_type IN ('cni', 'passport', 'residence_permit')),
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

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_tenants_created_by ON tenants(created_by);
CREATE INDEX idx_tenants_created_at ON tenants(created_at DESC);
CREATE INDEX idx_tenants_phone ON tenants(phone);
CREATE INDEX idx_tenants_last_name ON tenants(last_name);

-- Full-text search index for French
CREATE INDEX idx_tenants_search ON tenants
USING GIN (
  to_tsvector('french',
    coalesce(first_name, '') || ' ' ||
    coalesce(last_name, '') || ' ' ||
    coalesce(phone, '')
  )
);

-- ============================================================================
-- TRIGGER FOR UPDATED_AT
-- ============================================================================

-- Reuses existing function from profiles/buildings migration
CREATE TRIGGER tenants_updated_at
  BEFORE UPDATE ON tenants
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER FOR AUTO-SETTING CREATED_BY
-- ============================================================================

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

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

-- Policy 1: Admin has full access to all tenants
CREATE POLICY "admin_full_access" ON tenants
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

-- Policy 2: Gestionnaire has full access to tenants they created
CREATE POLICY "gestionnaire_own_tenants" ON tenants
  FOR ALL
  USING (
    created_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'gestionnaire'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'gestionnaire'
    )
  );

-- Policy 3: Assistant can read all tenants
CREATE POLICY "assistant_read" ON tenants
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'assistant'
    )
  );

-- Policy 4: Assistant can create tenants
CREATE POLICY "assistant_create" ON tenants
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'assistant'
    )
  );

-- ============================================================================
-- CREATE DOCUMENTS STORAGE BUCKET
-- ============================================================================

-- Create private documents bucket (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- STORAGE POLICIES FOR TENANT DOCUMENTS
-- ============================================================================

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

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE tenants IS 'Tenants (locataires) who can rent units through leases';
COMMENT ON COLUMN tenants.first_name IS 'Tenant first name (prénom), 1-100 chars';
COMMENT ON COLUMN tenants.last_name IS 'Tenant last name (nom de famille), 1-100 chars';
COMMENT ON COLUMN tenants.email IS 'Optional email address';
COMMENT ON COLUMN tenants.phone IS 'Primary phone number (Ivorian format)';
COMMENT ON COLUMN tenants.phone_secondary IS 'Optional secondary phone number';
COMMENT ON COLUMN tenants.id_type IS 'ID document type: cni, passport, or residence_permit';
COMMENT ON COLUMN tenants.id_number IS 'ID document number, max 50 chars';
COMMENT ON COLUMN tenants.id_document_url IS 'Storage path to ID document (private bucket)';
COMMENT ON COLUMN tenants.profession IS 'Tenant profession, max 200 chars';
COMMENT ON COLUMN tenants.employer IS 'Tenant employer, max 200 chars';
COMMENT ON COLUMN tenants.guarantor_name IS 'Guarantor full name, max 200 chars';
COMMENT ON COLUMN tenants.guarantor_phone IS 'Guarantor phone number';
COMMENT ON COLUMN tenants.guarantor_id_url IS 'Storage path to guarantor ID document';
COMMENT ON COLUMN tenants.notes IS 'Free-form notes, max 2000 chars';
COMMENT ON COLUMN tenants.created_by IS 'User who created this tenant record';
