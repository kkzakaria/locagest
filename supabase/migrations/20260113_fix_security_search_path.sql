-- Migration: 20260113_fix_security_search_path
-- Description: Fix mutable search_path security vulnerability in all functions
-- Date: 2026-01-13
-- Issue: Functions without SET search_path can be exploited via schema injection attacks

-- ============================================================================
-- FIX 1: update_updated_at_column
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SET search_path = public;

-- ============================================================================
-- FIX 2: is_admin
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
DECLARE
  user_role text;
BEGIN
  SELECT role INTO user_role
  FROM public.profiles
  WHERE id = auth.uid();

  RETURN user_role = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public;

-- ============================================================================
-- FIX 3: get_my_role
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text AS $$
DECLARE
  user_role text;
BEGIN
  SELECT role INTO user_role
  FROM public.profiles
  WHERE id = auth.uid();

  RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public;

-- ============================================================================
-- FIX 4: handle_new_user
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
    'gestionnaire'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- ============================================================================
-- FIX 5: check_login_attempt
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_login_attempt(user_email text)
RETURNS json AS $$
DECLARE
  profile_record public.profiles%ROWTYPE;
BEGIN
  SELECT * INTO profile_record
  FROM public.profiles
  WHERE email = user_email;

  IF NOT FOUND THEN
    RETURN json_build_object('allowed', true, 'reason', null);
  END IF;

  IF profile_record.locked_until IS NOT NULL
     AND profile_record.locked_until > now() THEN
    RETURN json_build_object(
      'allowed', false,
      'reason', 'locked',
      'locked_until', profile_record.locked_until
    );
  END IF;

  RETURN json_build_object('allowed', true, 'reason', null);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- ============================================================================
-- FIX 6: record_failed_login
-- ============================================================================

CREATE OR REPLACE FUNCTION public.record_failed_login(user_email text)
RETURNS void AS $$
BEGIN
  UPDATE public.profiles
  SET
    failed_login_attempts = failed_login_attempts + 1,
    locked_until = CASE
      WHEN failed_login_attempts + 1 >= 5
      THEN now() + interval '15 minutes'
      ELSE locked_until
    END,
    updated_at = now()
  WHERE email = user_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- ============================================================================
-- FIX 7: reset_login_attempts
-- ============================================================================

CREATE OR REPLACE FUNCTION public.reset_login_attempts(user_email text)
RETURNS void AS $$
BEGIN
  UPDATE public.profiles
  SET
    failed_login_attempts = 0,
    locked_until = NULL,
    updated_at = now()
  WHERE email = user_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- ============================================================================
-- FIX 8: check_admin_count
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_admin_count()
RETURNS trigger AS $$
DECLARE
  admin_count integer;
BEGIN
  IF OLD.role = 'admin' AND NEW.role != 'admin' THEN
    SELECT COUNT(*) INTO admin_count
    FROM public.profiles
    WHERE role = 'admin' AND id != OLD.id;

    IF admin_count = 0 THEN
      RAISE EXCEPTION 'Cannot demote the last admin';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SET search_path = public;

-- ============================================================================
-- FIX 9: update_building_total_units
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_building_total_units()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.buildings
    SET total_units = total_units + 1
    WHERE id = NEW.building_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.buildings
    SET total_units = total_units - 1
    WHERE id = OLD.building_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql
SET search_path = public;

-- ============================================================================
-- FIX 10: set_tenant_created_by
-- ============================================================================

CREATE OR REPLACE FUNCTION public.set_tenant_created_by()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.created_by IS NULL THEN
    NEW.created_by := auth.uid();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SET search_path = public;

-- ============================================================================
-- FIX 11: set_lease_created_by
-- ============================================================================

CREATE OR REPLACE FUNCTION public.set_lease_created_by()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.created_by IS NULL THEN
        NEW.created_by := auth.uid();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- ============================================================================
-- FIX 12: generate_receipt_number
-- ============================================================================

CREATE OR REPLACE FUNCTION public.generate_receipt_number()
RETURNS TEXT AS $$
DECLARE
    current_prefix TEXT;
    next_seq INTEGER;
BEGIN
    current_prefix := 'QUI-' || TO_CHAR(NOW(), 'YYYYMM') || '-';

    SELECT COALESCE(MAX(CAST(SUBSTRING(receipt_number FROM 13) AS INTEGER)), 0) + 1
    INTO next_seq
    FROM public.payments
    WHERE receipt_number LIKE current_prefix || '%';

    RETURN current_prefix || LPAD(next_seq::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql
SET search_path = public;

-- ============================================================================
-- FIX 13: set_payment_receipt_number
-- ============================================================================

CREATE OR REPLACE FUNCTION public.set_payment_receipt_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.receipt_number IS NULL OR NEW.receipt_number = '' THEN
        NEW.receipt_number := public.generate_receipt_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SET search_path = public;

-- ============================================================================
-- FIX 14: set_payment_created_by
-- ============================================================================

CREATE OR REPLACE FUNCTION public.set_payment_created_by()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.created_by IS NULL THEN
        NEW.created_by := auth.uid();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- ============================================================================
-- FIX 15: update_rent_schedule_on_payment
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_rent_schedule_on_payment()
RETURNS TRIGGER AS $$
DECLARE
    total_paid DECIMAL(12,2);
    schedule_amount_due DECIMAL(12,2);
    schedule_due_date DATE;
    new_status TEXT;
BEGIN
    -- Get the schedule ID based on operation type
    IF TG_OP = 'DELETE' THEN
        -- Calculate new total for the schedule
        SELECT COALESCE(SUM(amount), 0) INTO total_paid
        FROM public.payments
        WHERE rent_schedule_id = OLD.rent_schedule_id AND id != OLD.id;

        -- Get schedule details
        SELECT amount_due, due_date INTO schedule_amount_due, schedule_due_date
        FROM public.rent_schedules
        WHERE id = OLD.rent_schedule_id;

        -- Determine new status
        IF total_paid >= schedule_amount_due THEN
            new_status := 'paid';
        ELSIF total_paid > 0 THEN
            new_status := 'partial';
        ELSIF schedule_due_date < CURRENT_DATE THEN
            new_status := 'overdue';
        ELSE
            new_status := 'pending';
        END IF;

        -- Update the schedule
        UPDATE public.rent_schedules
        SET amount_paid = total_paid,
            status = new_status,
            updated_at = now()
        WHERE id = OLD.rent_schedule_id
          AND status != 'cancelled';

        RETURN OLD;
    ELSE
        -- INSERT or UPDATE
        -- Calculate new total for the schedule
        SELECT COALESCE(SUM(amount), 0) INTO total_paid
        FROM public.payments
        WHERE rent_schedule_id = NEW.rent_schedule_id;

        -- Get schedule details
        SELECT amount_due, due_date INTO schedule_amount_due, schedule_due_date
        FROM public.rent_schedules
        WHERE id = NEW.rent_schedule_id;

        -- Determine new status
        IF total_paid >= schedule_amount_due THEN
            new_status := 'paid';
        ELSIF total_paid > 0 THEN
            new_status := 'partial';
        ELSIF schedule_due_date < CURRENT_DATE THEN
            new_status := 'overdue';
        ELSE
            new_status := 'pending';
        END IF;

        -- Update the schedule
        UPDATE public.rent_schedules
        SET amount_paid = total_paid,
            status = new_status,
            updated_at = now()
        WHERE id = NEW.rent_schedule_id
          AND status != 'cancelled';

        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql
SET search_path = public;

-- ============================================================================
-- VERIFICATION COMMENT
-- ============================================================================

COMMENT ON FUNCTION public.update_updated_at_column() IS 'Updates updated_at timestamp - search_path secured';
COMMENT ON FUNCTION public.is_admin() IS 'Check if current user is admin - search_path secured';
COMMENT ON FUNCTION public.get_my_role() IS 'Get current user role - search_path secured';
COMMENT ON FUNCTION public.handle_new_user() IS 'Create profile on user signup - search_path secured';
COMMENT ON FUNCTION public.check_login_attempt(text) IS 'Check login lockout status - search_path secured';
COMMENT ON FUNCTION public.record_failed_login(text) IS 'Record failed login attempt - search_path secured';
COMMENT ON FUNCTION public.reset_login_attempts(text) IS 'Reset login attempts - search_path secured';
COMMENT ON FUNCTION public.check_admin_count() IS 'Prevent last admin demotion - search_path secured';
COMMENT ON FUNCTION public.update_building_total_units() IS 'Update building unit count - search_path secured';
COMMENT ON FUNCTION public.set_tenant_created_by() IS 'Auto-set tenant creator - search_path secured';
COMMENT ON FUNCTION public.set_lease_created_by() IS 'Auto-set lease creator - search_path secured';
COMMENT ON FUNCTION public.generate_receipt_number() IS 'Generate receipt number - search_path secured';
COMMENT ON FUNCTION public.set_payment_receipt_number() IS 'Auto-set receipt number - search_path secured';
COMMENT ON FUNCTION public.set_payment_created_by() IS 'Auto-set payment creator - search_path secured';
COMMENT ON FUNCTION public.update_rent_schedule_on_payment() IS 'Update schedule on payment - search_path secured';
