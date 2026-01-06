-- ============================================================================
-- Migration: 001_auth_setup.sql
-- Feature: User Authentication System (001-user-auth)
-- Description: Creates profiles table, RLS policies, and auth helper functions
-- ============================================================================

-- Helper function for updating updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PROFILES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email text NOT NULL,
  full_name text NOT NULL,
  role text NOT NULL DEFAULT 'gestionnaire'
    CHECK (role IN ('admin', 'gestionnaire', 'assistant')),
  avatar_url text,
  failed_login_attempts integer NOT NULL DEFAULT 0,
  locked_until timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Index for role-based queries
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Trigger for updated_at
DROP TRIGGER IF EXISTS set_profiles_updated_at ON profiles;
CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- HELPER FUNCTION TO CHECK ADMIN STATUS (bypasses RLS)
-- ============================================================================

-- This function is used by RLS policies to avoid infinite recursion
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
DECLARE
  user_role text;
BEGIN
  SELECT role INTO user_role
  FROM profiles
  WHERE id = auth.uid();

  RETURN user_role = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Get current user's role (bypasses RLS)
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text AS $$
DECLARE
  user_role text;
BEGIN
  SELECT role INTO user_role
  FROM profiles
  WHERE id = auth.uid();

  RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile OR admins can read all
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
CREATE POLICY "Users can view profiles"
ON profiles FOR SELECT
USING (
  auth.uid() = id
  OR public.is_admin()
);

-- Users can update their own profile (but not their role)
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id
  AND role = public.get_my_role()
);

-- Admins can update any profile (including role)
DROP POLICY IF EXISTS "Admins can update any profile" ON profiles;
CREATE POLICY "Admins can update any profile"
ON profiles FOR UPDATE
USING (public.is_admin());

-- Profiles are auto-created via trigger, but allow system inserts
DROP POLICY IF EXISTS "System can insert profiles" ON profiles;
CREATE POLICY "System can insert profiles"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- ============================================================================
-- AUTH HELPER FUNCTIONS
-- ============================================================================

-- Auto-create profile on user signup
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create profile on auth.users insert
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- LOGIN LOCKOUT FUNCTIONS
-- ============================================================================

-- Check if login attempt is allowed (account not locked)
CREATE OR REPLACE FUNCTION public.check_login_attempt(user_email text)
RETURNS json AS $$
DECLARE
  profile_record profiles%ROWTYPE;
BEGIN
  SELECT * INTO profile_record
  FROM profiles
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Record a failed login attempt (may trigger lockout)
CREATE OR REPLACE FUNCTION public.record_failed_login(user_email text)
RETURNS void AS $$
BEGIN
  UPDATE profiles
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Reset login attempts on successful login
CREATE OR REPLACE FUNCTION public.reset_login_attempts(user_email text)
RETURNS void AS $$
BEGIN
  UPDATE profiles
  SET
    failed_login_attempts = 0,
    locked_until = NULL,
    updated_at = now()
  WHERE email = user_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ADMIN PROTECTION
-- ============================================================================

-- Prevent demoting the last admin
CREATE OR REPLACE FUNCTION public.check_admin_count()
RETURNS trigger AS $$
DECLARE
  admin_count integer;
BEGIN
  IF OLD.role = 'admin' AND NEW.role != 'admin' THEN
    SELECT COUNT(*) INTO admin_count
    FROM profiles
    WHERE role = 'admin' AND id != OLD.id;

    IF admin_count = 0 THEN
      RAISE EXCEPTION 'Cannot demote the last admin';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS prevent_last_admin_demotion ON profiles;
CREATE TRIGGER prevent_last_admin_demotion
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  WHEN (OLD.role = 'admin')
  EXECUTE FUNCTION public.check_admin_count();

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant usage on functions to authenticated users
GRANT EXECUTE ON FUNCTION public.check_login_attempt(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_failed_login(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reset_login_attempts(text) TO authenticated;

-- Also allow anonymous access for check_login_attempt (needed before login)
GRANT EXECUTE ON FUNCTION public.check_login_attempt(text) TO anon;
GRANT EXECUTE ON FUNCTION public.record_failed_login(text) TO anon;
