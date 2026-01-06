# Quickstart: User Authentication System

**Feature**: 001-user-auth
**Date**: 2026-01-06

This guide walks through setting up and verifying the authentication system for LocaGest.

---

## Prerequisites

1. **Flutter SDK** installed (stable channel)
2. **Supabase project** created at [supabase.com](https://supabase.com)
3. **Repository** cloned and on branch `001-user-auth`

---

## Step 1: Supabase Setup

### 1.1 Get Credentials

1. Go to your Supabase project dashboard
2. Navigate to **Settings > API**
3. Copy:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)

### 1.2 Create Environment File

```bash
# From project root
cp .env.example .env
```

Edit `.env`:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

> **IMPORTANT**: Never commit `.env` to git. It's already in `.gitignore`.

### 1.3 Run Database Migration

1. Go to **Supabase Dashboard > SQL Editor**
2. Open `supabase/migrations/001_auth_setup.sql`
3. Copy contents and execute in SQL Editor
4. Verify:
   - `profiles` table exists
   - RLS is enabled
   - Functions are created

---

## Step 2: Flutter Setup

### 2.1 Install Dependencies

```bash
flutter pub get
```

### 2.2 Generate Freezed Models

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2.3 Verify Setup

```bash
flutter analyze
# Should complete with no errors
```

---

## Step 3: Create Initial Admin

Since the first user can't grant themselves admin role, we need to seed it.

### 3.1 Create Auth User via Dashboard

1. Go to **Supabase Dashboard > Authentication > Users**
2. Click **Add User**
3. Enter:
   - Email: `admin@locagest.ci` (or your admin email)
   - Password: A secure password
4. Click **Create User**
5. Copy the user's **UUID** from the list

### 3.2 Update Profile to Admin

1. Go to **SQL Editor**
2. Run:
```sql
UPDATE profiles
SET role = 'admin'
WHERE email = 'admin@locagest.ci';
```

---

## Step 4: Verify Authentication Flow

### 4.1 Run the App

```bash
flutter run -d chrome  # or android/ios
```

### 4.2 Test Login

1. App should show login screen
2. Enter admin credentials
3. Verify redirect to dashboard
4. Check that user management is visible (admin only)

### 4.3 Test Registration

1. Logout
2. Navigate to registration
3. Create a new account
4. Verify:
   - Auto-login after registration
   - Default role is "gestionnaire"
   - User management NOT visible

### 4.4 Test Password Reset

1. Logout
2. Click "Mot de passe oublie?"
3. Enter email
4. Check email inbox (may be in spam)
5. Click reset link
6. Set new password
7. Verify login with new password

### 4.5 Test Account Lockout

1. Attempt login with wrong password 5 times
2. Verify lockout message appears
3. Wait 15 minutes (or reset via SQL)
4. Verify login works again

```sql
-- To manually reset lockout:
UPDATE profiles
SET failed_login_attempts = 0, locked_until = NULL
WHERE email = 'test@example.com';
```

---

## Step 5: Test Role-Based Access

### 5.1 Admin User

Login as admin and verify:
- [x] Can see user management in settings
- [x] Can view all users
- [x] Can change user roles
- [x] Cannot demote self if last admin

### 5.2 Gestionnaire User

Login as gestionnaire and verify:
- [x] Cannot see user management
- [x] Can see buildings (CRUD)
- [x] Can see tenants (CRUD)
- [x] Can see payments

### 5.3 Assistant User

Create assistant via admin, login and verify:
- [x] Can see buildings (read only)
- [x] Cannot see edit/delete buttons on buildings
- [x] Can see tenants (CRUD)
- [x] Cannot see reports

---

## Troubleshooting

### "Invalid login credentials" even with correct password

- Verify email is registered
- Check Supabase Auth Users list
- Ensure profile exists in profiles table

### Profile not created on signup

- Check that `on_auth_user_created` trigger exists
- Verify `handle_new_user` function is created
- Check Supabase logs for errors

### RLS blocking access

- Verify user is authenticated (`supabase.auth.currentUser` not null)
- Check user's role in profiles table
- Review RLS policies in Supabase dashboard

### Account locked unexpectedly

```sql
-- Check lockout status
SELECT email, failed_login_attempts, locked_until
FROM profiles
WHERE email = 'user@example.com';

-- Reset if needed
UPDATE profiles
SET failed_login_attempts = 0, locked_until = NULL
WHERE email = 'user@example.com';
```

### Password reset email not arriving

- Check spam/junk folder
- Verify email templates in Supabase Auth settings
- Check SMTP configuration in Supabase

---

## Verification Checklist

Before marking feature complete, verify all acceptance criteria:

### User Story 1 - Login
- [ ] Valid credentials → Dashboard in <3 seconds
- [ ] Invalid credentials → French error message
- [ ] 5 failed attempts → Account locked for 15 minutes
- [ ] Session persists across app restart (30 days)

### User Story 2 - Registration
- [ ] Valid data → Account created, auto-login
- [ ] Duplicate email → French error message
- [ ] Weak password → French error message

### User Story 3 - Password Reset
- [ ] Request sent → Confirmation message
- [ ] Reset link works within 1 hour
- [ ] Expired link → French error message

### User Story 4 - Role-Based Access
- [ ] Admin can manage users
- [ ] Gestionnaire cannot see user management
- [ ] Assistant has read-only access to buildings

### User Story 5 - Logout
- [ ] Logout clears session
- [ ] Cannot navigate back to protected screens

---

## Next Steps

After authentication is verified:
1. Run `/speckit.tasks` to generate implementation tasks
2. Continue with building management feature
3. Implement remaining property management modules

---

## Support

If issues persist:
1. Check Supabase status: [status.supabase.com](https://status.supabase.com)
2. Review Supabase logs in dashboard
3. Check Flutter console for detailed error messages
