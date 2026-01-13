-- Migration: 20260115_consolidate_rls_policies
-- Description: Consolidate multiple permissive policies into single policies per action
-- Date: 2026-01-13
-- Issue: Multiple permissive policies for same role/action generate warnings
-- Solution: Combine all role checks into single policy per action

-- ============================================================================
-- HELPER: Create a function to get current user role efficiently
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text AS $$
  SELECT role FROM public.profiles WHERE id = (SELECT auth.uid())
$$ LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public;

-- ============================================================================
-- PROFILES TABLE - Consolidated RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "Users can view profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;
DROP POLICY IF EXISTS "System can insert profiles" ON public.profiles;

-- SELECT: Users see own profile, admins see all
CREATE POLICY "profiles_select" ON public.profiles
FOR SELECT USING (
  (SELECT auth.uid()) = id
  OR (SELECT public.get_user_role()) = 'admin'
);

-- INSERT: Only for own profile (via trigger)
CREATE POLICY "profiles_insert" ON public.profiles
FOR INSERT WITH CHECK (
  (SELECT auth.uid()) = id
);

-- UPDATE: Users update own (except role), admins update any
CREATE POLICY "profiles_update" ON public.profiles
FOR UPDATE USING (
  (SELECT auth.uid()) = id
  OR (SELECT public.get_user_role()) = 'admin'
) WITH CHECK (
  CASE
    WHEN (SELECT public.get_user_role()) = 'admin' THEN true
    WHEN (SELECT auth.uid()) = id AND role = (SELECT public.get_user_role()) THEN true
    ELSE false
  END
);

-- ============================================================================
-- BUILDINGS TABLE - Consolidated RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "admin_full_access" ON public.buildings;
DROP POLICY IF EXISTS "gestionnaire_own_buildings" ON public.buildings;
DROP POLICY IF EXISTS "assistant_read_only" ON public.buildings;

-- SELECT: Admin sees all, gestionnaire sees own, assistant sees all
CREATE POLICY "buildings_select" ON public.buildings
FOR SELECT USING (
  (SELECT public.get_user_role()) IN ('admin', 'assistant')
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND created_by = (SELECT auth.uid())
  )
);

-- INSERT: Admin or gestionnaire only
CREATE POLICY "buildings_insert" ON public.buildings
FOR INSERT WITH CHECK (
  (SELECT public.get_user_role()) IN ('admin', 'gestionnaire')
);

-- UPDATE: Admin updates any, gestionnaire updates own
CREATE POLICY "buildings_update" ON public.buildings
FOR UPDATE USING (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND created_by = (SELECT auth.uid())
  )
) WITH CHECK (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND created_by = (SELECT auth.uid())
  )
);

-- DELETE: Admin deletes any, gestionnaire deletes own
CREATE POLICY "buildings_delete" ON public.buildings
FOR DELETE USING (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND created_by = (SELECT auth.uid())
  )
);

-- ============================================================================
-- UNITS TABLE - Consolidated RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "admin_full_access" ON public.units;
DROP POLICY IF EXISTS "gestionnaire_own_units" ON public.units;
DROP POLICY IF EXISTS "assistant_read_only" ON public.units;

-- SELECT: Admin sees all, assistant sees all, gestionnaire sees own buildings' units
CREATE POLICY "units_select" ON public.units
FOR SELECT USING (
  (SELECT public.get_user_role()) IN ('admin', 'assistant')
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.buildings
      WHERE buildings.id = units.building_id
      AND buildings.created_by = (SELECT auth.uid())
    )
  )
);

-- INSERT: Admin or gestionnaire (own buildings)
CREATE POLICY "units_insert" ON public.units
FOR INSERT WITH CHECK (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.buildings
      WHERE buildings.id = building_id
      AND buildings.created_by = (SELECT auth.uid())
    )
  )
);

-- UPDATE: Admin or gestionnaire (own buildings)
CREATE POLICY "units_update" ON public.units
FOR UPDATE USING (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.buildings
      WHERE buildings.id = units.building_id
      AND buildings.created_by = (SELECT auth.uid())
    )
  )
) WITH CHECK (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.buildings
      WHERE buildings.id = building_id
      AND buildings.created_by = (SELECT auth.uid())
    )
  )
);

-- DELETE: Admin or gestionnaire (own buildings)
CREATE POLICY "units_delete" ON public.units
FOR DELETE USING (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.buildings
      WHERE buildings.id = units.building_id
      AND buildings.created_by = (SELECT auth.uid())
    )
  )
);

-- ============================================================================
-- TENANTS TABLE - Consolidated RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "admin_full_access" ON public.tenants;
DROP POLICY IF EXISTS "gestionnaire_own_tenants" ON public.tenants;
DROP POLICY IF EXISTS "assistant_read" ON public.tenants;
DROP POLICY IF EXISTS "assistant_create" ON public.tenants;

-- SELECT: Admin sees all, assistant sees all, gestionnaire sees own
CREATE POLICY "tenants_select" ON public.tenants
FOR SELECT USING (
  (SELECT public.get_user_role()) IN ('admin', 'assistant')
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND created_by = (SELECT auth.uid())
  )
);

-- INSERT: Admin, gestionnaire, or assistant
CREATE POLICY "tenants_insert" ON public.tenants
FOR INSERT WITH CHECK (
  (SELECT public.get_user_role()) IN ('admin', 'gestionnaire', 'assistant')
);

-- UPDATE: Admin updates any, gestionnaire updates own
CREATE POLICY "tenants_update" ON public.tenants
FOR UPDATE USING (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND created_by = (SELECT auth.uid())
  )
) WITH CHECK (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND created_by = (SELECT auth.uid())
  )
);

-- DELETE: Admin deletes any, gestionnaire deletes own
CREATE POLICY "tenants_delete" ON public.tenants
FOR DELETE USING (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND created_by = (SELECT auth.uid())
  )
);

-- ============================================================================
-- LEASES TABLE - Consolidated RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "admin_full_access_leases" ON public.leases;
DROP POLICY IF EXISTS "gestionnaire_own_leases" ON public.leases;
DROP POLICY IF EXISTS "assistant_read_leases" ON public.leases;

-- SELECT: Admin sees all, assistant sees all, gestionnaire sees own
CREATE POLICY "leases_select" ON public.leases
FOR SELECT USING (
  (SELECT public.get_user_role()) IN ('admin', 'assistant')
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND created_by = (SELECT auth.uid())
  )
);

-- INSERT: Admin or gestionnaire
CREATE POLICY "leases_insert" ON public.leases
FOR INSERT WITH CHECK (
  (SELECT public.get_user_role()) IN ('admin', 'gestionnaire')
);

-- UPDATE: Admin updates any, gestionnaire updates own
CREATE POLICY "leases_update" ON public.leases
FOR UPDATE USING (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND created_by = (SELECT auth.uid())
  )
) WITH CHECK (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND created_by = (SELECT auth.uid())
  )
);

-- DELETE: Admin deletes any, gestionnaire deletes own
CREATE POLICY "leases_delete" ON public.leases
FOR DELETE USING (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND created_by = (SELECT auth.uid())
  )
);

-- ============================================================================
-- RENT_SCHEDULES TABLE - Consolidated RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "admin_full_access_rent_schedules" ON public.rent_schedules;
DROP POLICY IF EXISTS "gestionnaire_own_rent_schedules" ON public.rent_schedules;
DROP POLICY IF EXISTS "assistant_read_rent_schedules" ON public.rent_schedules;

-- SELECT: Admin sees all, assistant sees all, gestionnaire sees own leases' schedules
CREATE POLICY "rent_schedules_select" ON public.rent_schedules
FOR SELECT USING (
  (SELECT public.get_user_role()) IN ('admin', 'assistant')
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.leases
      WHERE leases.id = rent_schedules.lease_id
      AND leases.created_by = (SELECT auth.uid())
    )
  )
);

-- INSERT: Admin or gestionnaire (own leases)
CREATE POLICY "rent_schedules_insert" ON public.rent_schedules
FOR INSERT WITH CHECK (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.leases
      WHERE leases.id = lease_id
      AND leases.created_by = (SELECT auth.uid())
    )
  )
);

-- UPDATE: Admin or gestionnaire (own leases)
CREATE POLICY "rent_schedules_update" ON public.rent_schedules
FOR UPDATE USING (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.leases
      WHERE leases.id = rent_schedules.lease_id
      AND leases.created_by = (SELECT auth.uid())
    )
  )
) WITH CHECK (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.leases
      WHERE leases.id = lease_id
      AND leases.created_by = (SELECT auth.uid())
    )
  )
);

-- DELETE: Admin or gestionnaire (own leases)
CREATE POLICY "rent_schedules_delete" ON public.rent_schedules
FOR DELETE USING (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.leases
      WHERE leases.id = rent_schedules.lease_id
      AND leases.created_by = (SELECT auth.uid())
    )
  )
);

-- ============================================================================
-- PAYMENTS TABLE - Consolidated RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "admin_full_access_payments" ON public.payments;
DROP POLICY IF EXISTS "gestionnaire_own_payments" ON public.payments;
DROP POLICY IF EXISTS "assistant_read_payments" ON public.payments;
DROP POLICY IF EXISTS "assistant_insert_payments" ON public.payments;

-- SELECT: Admin sees all, assistant sees all, gestionnaire sees own leases' payments
CREATE POLICY "payments_select" ON public.payments
FOR SELECT USING (
  (SELECT public.get_user_role()) IN ('admin', 'assistant')
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.rent_schedules rs
      JOIN public.leases l ON l.id = rs.lease_id
      WHERE rs.id = payments.rent_schedule_id
      AND l.created_by = (SELECT auth.uid())
    )
  )
);

-- INSERT: Admin, gestionnaire (own leases), or assistant
CREATE POLICY "payments_insert" ON public.payments
FOR INSERT WITH CHECK (
  (SELECT public.get_user_role()) IN ('admin', 'assistant')
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.rent_schedules rs
      JOIN public.leases l ON l.id = rs.lease_id
      WHERE rs.id = rent_schedule_id
      AND l.created_by = (SELECT auth.uid())
    )
  )
);

-- UPDATE: Admin or gestionnaire (own leases)
CREATE POLICY "payments_update" ON public.payments
FOR UPDATE USING (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.rent_schedules rs
      JOIN public.leases l ON l.id = rs.lease_id
      WHERE rs.id = payments.rent_schedule_id
      AND l.created_by = (SELECT auth.uid())
    )
  )
) WITH CHECK (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.rent_schedules rs
      JOIN public.leases l ON l.id = rs.lease_id
      WHERE rs.id = rent_schedule_id
      AND l.created_by = (SELECT auth.uid())
    )
  )
);

-- DELETE: Admin or gestionnaire (own leases)
CREATE POLICY "payments_delete" ON public.payments
FOR DELETE USING (
  (SELECT public.get_user_role()) = 'admin'
  OR (
    (SELECT public.get_user_role()) = 'gestionnaire'
    AND EXISTS (
      SELECT 1 FROM public.rent_schedules rs
      JOIN public.leases l ON l.id = rs.lease_id
      WHERE rs.id = payments.rent_schedule_id
      AND l.created_by = (SELECT auth.uid())
    )
  )
);

-- ============================================================================
-- RECEIPTS TABLE - Consolidated RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS "receipts_select_policy" ON public.receipts;
DROP POLICY IF EXISTS "receipts_insert_policy" ON public.receipts;
DROP POLICY IF EXISTS "receipts_update_policy" ON public.receipts;

-- SELECT: Admin sees all, others see own
CREATE POLICY "receipts_select" ON public.receipts
FOR SELECT USING (
  (SELECT public.get_user_role()) = 'admin'
  OR created_by = (SELECT auth.uid())
);

-- INSERT: Any authenticated user
CREATE POLICY "receipts_insert" ON public.receipts
FOR INSERT WITH CHECK (
  (SELECT auth.uid()) IS NOT NULL
  AND created_by = (SELECT auth.uid())
);

-- UPDATE: Owner only
CREATE POLICY "receipts_update" ON public.receipts
FOR UPDATE USING (
  created_by = (SELECT auth.uid())
) WITH CHECK (
  created_by = (SELECT auth.uid())
);

-- DELETE: Admin or owner
CREATE POLICY "receipts_delete" ON public.receipts
FOR DELETE USING (
  (SELECT public.get_user_role()) = 'admin'
  OR created_by = (SELECT auth.uid())
);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON FUNCTION public.get_user_role() IS 'Get current user role efficiently for RLS policies';
