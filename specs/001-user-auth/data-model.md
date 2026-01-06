# Data Model: User Authentication System

**Feature**: 001-user-auth
**Date**: 2026-01-06

## Entity Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         auth.users                               │
│                    (Supabase Auth - managed)                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ id (uuid) PK                                             │    │
│  │ email (text) UNIQUE                                      │    │
│  │ encrypted_password (text)                                │    │
│  │ created_at (timestamptz)                                 │    │
│  │ updated_at (timestamptz)                                 │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ 1:1 (FK: id)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         profiles                                 │
│                    (Custom table - public)                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ id (uuid) PK FK → auth.users.id                          │    │
│  │ email (text) NOT NULL                                    │    │
│  │ full_name (text) NOT NULL                                │    │
│  │ role (text) DEFAULT 'gestionnaire'                       │    │
│  │ avatar_url (text) NULL                                   │    │
│  │ failed_login_attempts (int) DEFAULT 0                    │    │
│  │ locked_until (timestamptz) NULL                          │    │
│  │ created_at (timestamptz) DEFAULT now()                   │    │
│  │ updated_at (timestamptz) DEFAULT now()                   │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Entities

### 1. profiles

**Purpose**: Extended user information beyond Supabase Auth, including role and lockout tracking.

**Table Definition:**
```sql
CREATE TABLE public.profiles (
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
CREATE INDEX idx_profiles_role ON profiles(role);

-- Trigger for updated_at
CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

**Fields:**

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | uuid | PK, FK to auth.users | Links to Supabase Auth user |
| email | text | NOT NULL | Denormalized from auth.users for convenience |
| full_name | text | NOT NULL | User's display name |
| role | text | NOT NULL, CHECK | One of: admin, gestionnaire, assistant |
| avatar_url | text | NULL | Optional profile picture URL |
| failed_login_attempts | int | NOT NULL, DEFAULT 0 | Counter for lockout (FR-006) |
| locked_until | timestamptz | NULL | When lockout expires (FR-006) |
| created_at | timestamptz | NOT NULL, DEFAULT now() | Audit timestamp |
| updated_at | timestamptz | NOT NULL, DEFAULT now() | Audit timestamp |

**Validation Rules:**
- role MUST be one of: 'admin', 'gestionnaire', 'assistant'
- full_name MUST NOT be empty
- email MUST match auth.users.email (sync via trigger)

**State Transitions (Lockout):**
```
Normal → Locked: failed_login_attempts >= 5
Locked → Normal: current_timestamp > locked_until OR admin reset
```

---

## Row Level Security (RLS) Policies

### profiles Table

```sql
-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- Admins can read all profiles
CREATE POLICY "Admins can view all profiles"
ON profiles FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Users can update their own profile (except role)
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id
  AND role = (SELECT role FROM profiles WHERE id = auth.uid())
);

-- Admins can update any profile (including role)
CREATE POLICY "Admins can update any profile"
ON profiles FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Profiles are auto-created via trigger, not direct insert
CREATE POLICY "System can insert profiles"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);
```

---

## Database Functions

### 1. Auto-create profile on signup

```sql
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

-- Trigger on auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

### 2. Check login attempt (lockout logic)

```sql
CREATE OR REPLACE FUNCTION public.check_login_attempt(user_email text)
RETURNS json AS $$
DECLARE
  profile_record profiles%ROWTYPE;
  result json;
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
```

### 3. Record failed login attempt

```sql
CREATE OR REPLACE FUNCTION public.record_failed_login(user_email text)
RETURNS void AS $$
DECLARE
  current_attempts integer;
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
```

### 4. Reset login attempts on success

```sql
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
```

### 5. Prevent last admin demotion

```sql
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

CREATE TRIGGER prevent_last_admin_demotion
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  WHEN (OLD.role = 'admin')
  EXECUTE FUNCTION public.check_admin_count();
```

---

## Flutter Entities

### User Entity (Domain Layer)

```dart
// lib/domain/entities/user.dart
class User {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isGestionnaire => role == UserRole.gestionnaire;
  bool get isAssistant => role == UserRole.assistant;
}

enum UserRole {
  admin,
  gestionnaire,
  assistant;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.gestionnaire,
    );
  }
}
```

### UserModel (Data Layer)

```dart
// lib/data/models/user_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    @JsonKey(name: 'full_name') required String fullName,
    required String role,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

extension UserModelX on UserModel {
  User toEntity() => User(
        id: id,
        email: email,
        fullName: fullName,
        role: UserRole.fromString(role),
        avatarUrl: avatarUrl,
        createdAt: createdAt,
      );
}
```

---

## Migration File

```sql
-- supabase/migrations/001_auth_setup.sql

-- Helper function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Profiles table
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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Updated_at trigger
CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies (as defined above)
-- ... [include all policies from RLS section]

-- Functions (as defined above)
-- ... [include all functions]

-- Trigger for auto-creating profile
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```
