-- Migration: 005_leases
-- Feature: Lease Management (005-lease-management)
-- Date: 2026-01-08
-- Description: Creates leases and rent_schedules tables for rental contract management

-- ============================================================================
-- HELPER FUNCTIONS (if not exists)
-- ============================================================================

-- Ensure update_updated_at_column function exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- LEASES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.leases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- References
    unit_id UUID NOT NULL REFERENCES public.units(id) ON DELETE RESTRICT,
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE RESTRICT,

    -- Contract terms
    start_date DATE NOT NULL,
    end_date DATE,
    duration_months INTEGER,
    rent_amount DECIMAL(12,2) NOT NULL,
    charges_amount DECIMAL(12,2) DEFAULT 0,
    deposit_amount DECIMAL(12,2),
    deposit_paid BOOLEAN DEFAULT false,
    payment_day INTEGER DEFAULT 1,
    annual_revision BOOLEAN DEFAULT false,
    revision_rate DECIMAL(5,2),

    -- Status: pending, active, terminated, expired
    status TEXT DEFAULT 'active' NOT NULL CHECK (status IN ('pending', 'active', 'terminated', 'expired')),
    termination_date DATE,
    termination_reason TEXT,

    -- Documents
    document_url TEXT,
    notes TEXT,

    -- Audit
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,

    -- Constraints
    CONSTRAINT leases_rent_amount_positive CHECK (rent_amount > 0),
    CONSTRAINT leases_charges_amount_non_negative CHECK (charges_amount >= 0),
    CONSTRAINT leases_deposit_amount_non_negative CHECK (deposit_amount IS NULL OR deposit_amount >= 0),
    CONSTRAINT leases_payment_day_valid CHECK (payment_day BETWEEN 1 AND 28),
    CONSTRAINT leases_dates_valid CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT leases_revision_rate_valid CHECK (revision_rate IS NULL OR revision_rate BETWEEN 0 AND 100),
    CONSTRAINT leases_termination_date_required CHECK (
        (status != 'terminated') OR (termination_date IS NOT NULL)
    )
);

-- ============================================================================
-- RENT_SCHEDULES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.rent_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Reference
    lease_id UUID NOT NULL REFERENCES public.leases(id) ON DELETE CASCADE,

    -- Period
    due_date DATE NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,

    -- Amounts
    amount_due DECIMAL(12,2) NOT NULL,
    amount_paid DECIMAL(12,2) DEFAULT 0,
    balance DECIMAL(12,2) GENERATED ALWAYS AS (amount_due - amount_paid) STORED,

    -- Status: pending, partial, paid, overdue, cancelled
    status TEXT DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'partial', 'paid', 'overdue', 'cancelled')),

    -- Audit
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,

    -- Constraints
    CONSTRAINT rent_schedules_amount_due_positive CHECK (amount_due > 0),
    CONSTRAINT rent_schedules_amount_paid_non_negative CHECK (amount_paid >= 0),
    CONSTRAINT rent_schedules_period_valid CHECK (period_end >= period_start)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Leases indexes
CREATE INDEX IF NOT EXISTS idx_leases_unit ON leases(unit_id);
CREATE INDEX IF NOT EXISTS idx_leases_tenant ON leases(tenant_id);
CREATE INDEX IF NOT EXISTS idx_leases_status ON leases(status);
CREATE INDEX IF NOT EXISTS idx_leases_start_date ON leases(start_date DESC);
CREATE INDEX IF NOT EXISTS idx_leases_created_by ON leases(created_by);
CREATE INDEX IF NOT EXISTS idx_leases_created_at ON leases(created_at DESC);

-- Unique constraint: only one active/pending lease per unit
CREATE UNIQUE INDEX IF NOT EXISTS idx_leases_active_unit ON leases(unit_id)
    WHERE status IN ('pending', 'active');

-- Rent schedules indexes
CREATE INDEX IF NOT EXISTS idx_rent_schedules_lease ON rent_schedules(lease_id);
CREATE INDEX IF NOT EXISTS idx_rent_schedules_status ON rent_schedules(status);
CREATE INDEX IF NOT EXISTS idx_rent_schedules_due_date ON rent_schedules(due_date);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Auto-update updated_at for leases
DROP TRIGGER IF EXISTS leases_updated_at ON leases;
CREATE TRIGGER leases_updated_at
    BEFORE UPDATE ON leases
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Auto-update updated_at for rent_schedules
DROP TRIGGER IF EXISTS rent_schedules_updated_at ON rent_schedules;
CREATE TRIGGER rent_schedules_updated_at
    BEFORE UPDATE ON rent_schedules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Auto-set created_by to current user for leases
CREATE OR REPLACE FUNCTION set_lease_created_by()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.created_by IS NULL THEN
        NEW.created_by := auth.uid();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS leases_set_created_by ON leases;
CREATE TRIGGER leases_set_created_by
    BEFORE INSERT ON leases
    FOR EACH ROW
    EXECUTE FUNCTION set_lease_created_by();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE leases ENABLE ROW LEVEL SECURITY;
ALTER TABLE rent_schedules ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "admin_full_access_leases" ON leases;
DROP POLICY IF EXISTS "gestionnaire_own_leases" ON leases;
DROP POLICY IF EXISTS "assistant_read_leases" ON leases;

DROP POLICY IF EXISTS "admin_full_access_rent_schedules" ON rent_schedules;
DROP POLICY IF EXISTS "gestionnaire_own_rent_schedules" ON rent_schedules;
DROP POLICY IF EXISTS "assistant_read_rent_schedules" ON rent_schedules;

-- ============================================================================
-- LEASES POLICIES
-- ============================================================================

-- Admin: Full access to all leases
CREATE POLICY "admin_full_access_leases" ON leases
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

-- Gestionnaire: Full access to their own leases
CREATE POLICY "gestionnaire_own_leases" ON leases
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

-- Assistant: Read-only access to all leases
CREATE POLICY "assistant_read_leases" ON leases
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'assistant'
        )
    );

-- ============================================================================
-- RENT_SCHEDULES POLICIES
-- ============================================================================

-- Admin: Full access to all rent_schedules
CREATE POLICY "admin_full_access_rent_schedules" ON rent_schedules
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

-- Gestionnaire: Full access to rent_schedules for their own leases
CREATE POLICY "gestionnaire_own_rent_schedules" ON rent_schedules
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM leases
            WHERE leases.id = rent_schedules.lease_id
            AND leases.created_by = auth.uid()
        )
        AND EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'gestionnaire'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM leases
            WHERE leases.id = rent_schedules.lease_id
            AND leases.created_by = auth.uid()
        )
        AND EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'gestionnaire'
        )
    );

-- Assistant: Read-only access to all rent_schedules
CREATE POLICY "assistant_read_rent_schedules" ON rent_schedules
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'assistant'
        )
    );

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE leases IS 'Rental contracts (baux) linking tenants to units';
COMMENT ON COLUMN leases.id IS 'Unique lease identifier';
COMMENT ON COLUMN leases.unit_id IS 'Reference to the rented unit (lot)';
COMMENT ON COLUMN leases.tenant_id IS 'Reference to the tenant (locataire)';
COMMENT ON COLUMN leases.start_date IS 'Lease start date';
COMMENT ON COLUMN leases.end_date IS 'Lease end date (null = open-ended)';
COMMENT ON COLUMN leases.duration_months IS 'Contract duration in months';
COMMENT ON COLUMN leases.rent_amount IS 'Monthly rent amount in FCFA';
COMMENT ON COLUMN leases.charges_amount IS 'Monthly charges amount in FCFA';
COMMENT ON COLUMN leases.deposit_amount IS 'Security deposit in FCFA';
COMMENT ON COLUMN leases.deposit_paid IS 'Whether deposit has been paid';
COMMENT ON COLUMN leases.payment_day IS 'Day of month rent is due (1-28)';
COMMENT ON COLUMN leases.annual_revision IS 'Whether annual rent revision applies';
COMMENT ON COLUMN leases.revision_rate IS 'Annual revision percentage';
COMMENT ON COLUMN leases.status IS 'Lease status: pending, active, terminated, expired';
COMMENT ON COLUMN leases.termination_date IS 'Date lease was terminated';
COMMENT ON COLUMN leases.termination_reason IS 'Reason for termination';

COMMENT ON TABLE rent_schedules IS 'Monthly rent obligations (échéances) generated from leases';
COMMENT ON COLUMN rent_schedules.id IS 'Unique schedule identifier';
COMMENT ON COLUMN rent_schedules.lease_id IS 'Reference to parent lease';
COMMENT ON COLUMN rent_schedules.due_date IS 'Date rent is due';
COMMENT ON COLUMN rent_schedules.period_start IS 'Start of rental period';
COMMENT ON COLUMN rent_schedules.period_end IS 'End of rental period';
COMMENT ON COLUMN rent_schedules.amount_due IS 'Total amount due for this period';
COMMENT ON COLUMN rent_schedules.amount_paid IS 'Total amount paid';
COMMENT ON COLUMN rent_schedules.balance IS 'Remaining balance (computed)';
COMMENT ON COLUMN rent_schedules.status IS 'Payment status: pending, partial, paid, overdue, cancelled';
