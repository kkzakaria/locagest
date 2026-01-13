-- Migration: 20260113_optimize_rls_performance
-- Description: Optimize RLS policies to prevent per-row function re-evaluation
-- Date: 2026-01-13
-- Issue: auth.uid() and auth.<function>() are re-evaluated for each row
-- Solution: Wrap in (SELECT ...) to evaluate once per query

-- ============================================================================
-- PROFILES TABLE - Optimized RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "Users can view profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;
DROP POLICY IF EXISTS "System can insert profiles" ON public.profiles;

-- Users can read their own profile OR admins can read all
CREATE POLICY "Users can view profiles"
ON public.profiles FOR SELECT
USING (
  (SELECT auth.uid()) = id
  OR public.is_admin()
);

-- Users can update their own profile (but not their role)
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
USING ((SELECT auth.uid()) = id)
WITH CHECK (
  (SELECT auth.uid()) = id
  AND role = (SELECT public.get_my_role())
);

-- Admins can update any profile (including role)
CREATE POLICY "Admins can update any profile"
ON public.profiles FOR UPDATE
USING (public.is_admin());

-- Profiles are auto-created via trigger, but allow system inserts
CREATE POLICY "System can insert profiles"
ON public.profiles FOR INSERT
WITH CHECK ((SELECT auth.uid()) = id);

-- ============================================================================
-- BUILDINGS TABLE - Optimized RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "admin_full_access" ON public.buildings;
DROP POLICY IF EXISTS "gestionnaire_own_buildings" ON public.buildings;
DROP POLICY IF EXISTS "assistant_read_only" ON public.buildings;

-- Admin: Full access to all buildings
CREATE POLICY "admin_full_access" ON public.buildings
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'admin'
    )
  );

-- Gestionnaire: Full access to own buildings
CREATE POLICY "gestionnaire_own_buildings" ON public.buildings
  FOR ALL
  USING (
    created_by = (SELECT auth.uid()) AND
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'gestionnaire'
    )
  )
  WITH CHECK (
    created_by = (SELECT auth.uid()) AND
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'gestionnaire'
    )
  );

-- Assistant: Read-only access
CREATE POLICY "assistant_read_only" ON public.buildings
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'assistant'
    )
  );

-- ============================================================================
-- UNITS TABLE - Optimized RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "admin_full_access" ON public.units;
DROP POLICY IF EXISTS "gestionnaire_own_units" ON public.units;
DROP POLICY IF EXISTS "assistant_read_only" ON public.units;

-- Admin: Full access to all units
CREATE POLICY "admin_full_access" ON public.units
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'admin'
    )
  );

-- Gestionnaire: Full access to units in their buildings
CREATE POLICY "gestionnaire_own_units" ON public.units
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.buildings
      WHERE buildings.id = units.building_id
      AND buildings.created_by = (SELECT auth.uid())
    )
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'gestionnaire'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.buildings
      WHERE buildings.id = units.building_id
      AND buildings.created_by = (SELECT auth.uid())
    )
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'gestionnaire'
    )
  );

-- Assistant: Read-only access
CREATE POLICY "assistant_read_only" ON public.units
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'assistant'
    )
  );

-- ============================================================================
-- TENANTS TABLE - Optimized RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "admin_full_access" ON public.tenants;
DROP POLICY IF EXISTS "gestionnaire_own_tenants" ON public.tenants;
DROP POLICY IF EXISTS "assistant_read" ON public.tenants;
DROP POLICY IF EXISTS "assistant_create" ON public.tenants;

-- Admin: Full access to all tenants
CREATE POLICY "admin_full_access" ON public.tenants
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'admin'
    )
  );

-- Gestionnaire: Full access to tenants they created
CREATE POLICY "gestionnaire_own_tenants" ON public.tenants
  FOR ALL
  USING (
    created_by = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'gestionnaire'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'gestionnaire'
    )
  );

-- Assistant: Read all tenants
CREATE POLICY "assistant_read" ON public.tenants
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'assistant'
    )
  );

-- Assistant: Create tenants
CREATE POLICY "assistant_create" ON public.tenants
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'assistant'
    )
  );

-- ============================================================================
-- LEASES TABLE - Optimized RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "admin_full_access_leases" ON public.leases;
DROP POLICY IF EXISTS "gestionnaire_own_leases" ON public.leases;
DROP POLICY IF EXISTS "assistant_read_leases" ON public.leases;

-- Admin: Full access to all leases
CREATE POLICY "admin_full_access_leases" ON public.leases
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'admin'
        )
    );

-- Gestionnaire: Full access to their own leases
CREATE POLICY "gestionnaire_own_leases" ON public.leases
    FOR ALL
    USING (
        created_by = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'gestionnaire'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'gestionnaire'
        )
    );

-- Assistant: Read-only access to all leases
CREATE POLICY "assistant_read_leases" ON public.leases
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'assistant'
        )
    );

-- ============================================================================
-- RENT_SCHEDULES TABLE - Optimized RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "admin_full_access_rent_schedules" ON public.rent_schedules;
DROP POLICY IF EXISTS "gestionnaire_own_rent_schedules" ON public.rent_schedules;
DROP POLICY IF EXISTS "assistant_read_rent_schedules" ON public.rent_schedules;

-- Admin: Full access to all rent_schedules
CREATE POLICY "admin_full_access_rent_schedules" ON public.rent_schedules
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'admin'
        )
    );

-- Gestionnaire: Full access to rent_schedules for their own leases
CREATE POLICY "gestionnaire_own_rent_schedules" ON public.rent_schedules
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.leases
            WHERE leases.id = rent_schedules.lease_id
            AND leases.created_by = (SELECT auth.uid())
        )
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'gestionnaire'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.leases
            WHERE leases.id = rent_schedules.lease_id
            AND leases.created_by = (SELECT auth.uid())
        )
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'gestionnaire'
        )
    );

-- Assistant: Read-only access to all rent_schedules
CREATE POLICY "assistant_read_rent_schedules" ON public.rent_schedules
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'assistant'
        )
    );

-- ============================================================================
-- PAYMENTS TABLE - Optimized RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "admin_full_access_payments" ON public.payments;
DROP POLICY IF EXISTS "gestionnaire_own_payments" ON public.payments;
DROP POLICY IF EXISTS "assistant_read_payments" ON public.payments;
DROP POLICY IF EXISTS "assistant_insert_payments" ON public.payments;

-- Admin: Full access to all payments
CREATE POLICY "admin_full_access_payments" ON public.payments
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'admin'
        )
    );

-- Gestionnaire: Full access to payments for their own leases
CREATE POLICY "gestionnaire_own_payments" ON public.payments
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.rent_schedules rs
            JOIN public.leases l ON l.id = rs.lease_id
            WHERE rs.id = payments.rent_schedule_id
            AND l.created_by = (SELECT auth.uid())
        )
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'gestionnaire'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.rent_schedules rs
            JOIN public.leases l ON l.id = rs.lease_id
            WHERE rs.id = payments.rent_schedule_id
            AND l.created_by = (SELECT auth.uid())
        )
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'gestionnaire'
        )
    );

-- Assistant: Read all payments
CREATE POLICY "assistant_read_payments" ON public.payments
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'assistant'
        )
    );

-- Assistant: Insert new payments
CREATE POLICY "assistant_insert_payments" ON public.payments
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'assistant'
        )
    );

-- ============================================================================
-- RECEIPTS TABLE - Optimized RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "receipts_select_policy" ON public.receipts;
DROP POLICY IF EXISTS "receipts_insert_policy" ON public.receipts;
DROP POLICY IF EXISTS "receipts_update_policy" ON public.receipts;

-- Select policy: users see their own receipts, admins see all
CREATE POLICY "receipts_select_policy"
  ON public.receipts FOR SELECT
  USING (
    created_by = (SELECT auth.uid()) OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = (SELECT auth.uid()) AND role = 'admin')
  );

-- Insert policy: authenticated users can create receipts
CREATE POLICY "receipts_insert_policy"
  ON public.receipts FOR INSERT
  WITH CHECK ((SELECT auth.uid()) IS NOT NULL AND created_by = (SELECT auth.uid()));

-- Update policy: owner can update status
CREATE POLICY "receipts_update_policy"
  ON public.receipts FOR UPDATE
  USING (created_by = (SELECT auth.uid()))
  WITH CHECK (created_by = (SELECT auth.uid()));

-- ============================================================================
-- COMMENT: Performance optimization applied
-- ============================================================================

COMMENT ON TABLE public.profiles IS 'User profiles with optimized RLS policies';
COMMENT ON TABLE public.buildings IS 'Buildings with optimized RLS policies';
COMMENT ON TABLE public.units IS 'Units with optimized RLS policies';
COMMENT ON TABLE public.tenants IS 'Tenants with optimized RLS policies';
COMMENT ON TABLE public.leases IS 'Leases with optimized RLS policies';
COMMENT ON TABLE public.rent_schedules IS 'Rent schedules with optimized RLS policies';
COMMENT ON TABLE public.payments IS 'Payments with optimized RLS policies';
COMMENT ON TABLE public.receipts IS 'Receipts with optimized RLS policies';
