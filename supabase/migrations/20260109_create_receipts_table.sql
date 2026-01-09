-- Migration: Create receipts table for rent receipt (quittance) tracking
-- Feature: 007-pdf-receipt-generation
-- Date: 2026-01-09

-- Create receipts table
CREATE TABLE receipts (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign keys
  payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE SET NULL,
  created_by UUID REFERENCES profiles(id),

  -- Receipt data
  receipt_number TEXT NOT NULL,
  file_url TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'valid' CHECK (status IN ('valid', 'cancelled')),

  -- Timestamps
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_receipts_payment_id ON receipts(payment_id);
CREATE INDEX idx_receipts_created_by ON receipts(created_by);
CREATE INDEX idx_receipts_status ON receipts(status);

-- Enable Row Level Security
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

-- Select policy: users see their own receipts, admins see all
CREATE POLICY "receipts_select_policy"
  ON receipts FOR SELECT
  USING (
    created_by = auth.uid() OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Insert policy: authenticated users can create receipts
CREATE POLICY "receipts_insert_policy"
  ON receipts FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND created_by = auth.uid());

-- Update policy: owner can update status
CREATE POLICY "receipts_update_policy"
  ON receipts FOR UPDATE
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

-- Comment on table
COMMENT ON TABLE receipts IS 'Stores metadata for generated rent receipts (quittances)';
COMMENT ON COLUMN receipts.file_url IS 'Storage path in documents bucket, not signed URL';
COMMENT ON COLUMN receipts.status IS 'valid = active receipt, cancelled = associated payment was deleted';
