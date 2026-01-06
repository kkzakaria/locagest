# Research: User Authentication System

**Feature**: 001-user-auth
**Date**: 2026-01-06

## Research Summary

This document captures technology decisions, best practices research, and architectural choices for the LocaGest authentication system.

---

## 1. Authentication Provider

### Decision: Supabase Auth

**Rationale:**
- Already specified in constitution as the project backend
- Provides email/password authentication out-of-the-box
- Built-in password reset flow with customizable email templates
- JWT-based sessions with automatic refresh
- Integrates seamlessly with Supabase RLS for authorization

**Alternatives Considered:**

| Option | Pros | Cons | Why Rejected |
|--------|------|------|--------------|
| Firebase Auth | Mature, well-documented | Requires separate backend for RLS-like policies | Constitution mandates Supabase-first |
| Custom JWT | Full control | Significant development effort, security risks | Over-engineering for MVP scope |
| Auth0 | Enterprise features | Cost, external dependency | Complexity not needed for 100 users |

---

## 2. Session Persistence Strategy

### Decision: Supabase Session + flutter_secure_storage

**Rationale:**
- Supabase Flutter SDK handles JWT refresh automatically
- flutter_secure_storage provides secure, encrypted storage on mobile (Keychain/Keystore)
- Web uses secure httpOnly cookies via Supabase
- 30-day session persistence matches spec requirement (FR-005)

**Implementation Pattern:**
```dart
// Supabase handles session automatically, but we can persist across app restarts:
// 1. On app start: Check Supabase.instance.client.auth.currentSession
// 2. If null, redirect to login
// 3. If valid, proceed to dashboard
// 4. On logout: Supabase.instance.client.auth.signOut() clears session
```

**Alternatives Considered:**

| Option | Pros | Cons | Why Rejected |
|--------|------|------|--------------|
| shared_preferences | Simple API | Not encrypted, insecure for tokens | Security requirement violation |
| Hive encrypted box | Fast, encrypted | Additional dependency | flutter_secure_storage is standard |
| Session-only (no persist) | Simpler | Poor UX, re-login daily | Spec requires 30-day persistence |

---

## 3. Account Lockout Implementation

### Decision: Custom lockout logic with Supabase function

**Rationale:**
- Supabase Auth doesn't have built-in account lockout
- Implement via database trigger + metadata field
- Track failed_attempts and locked_until in profiles table
- Check before allowing login attempt

**Implementation Pattern:**
```sql
-- Add to profiles table:
ALTER TABLE profiles ADD COLUMN failed_login_attempts integer DEFAULT 0;
ALTER TABLE profiles ADD COLUMN locked_until timestamptz;

-- RPC function to check lockout:
CREATE OR REPLACE FUNCTION check_login_attempt(user_email text)
RETURNS json AS $$
  -- Returns {allowed: boolean, reason: string}
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Alternatives Considered:**

| Option | Pros | Cons | Why Rejected |
|--------|------|------|--------------|
| Client-side only | Simple | Easily bypassed, no real security | Security vulnerability |
| Rate limiting at edge | Scalable | Doesn't track per-account | Spec requires per-account lockout |
| External service (fail2ban) | Battle-tested | Infrastructure complexity | Over-engineering for scale |

---

## 4. Role-Based Access Control (RBAC)

### Decision: Database role field + RLS policies + Flutter guards

**Rationale:**
- Store role in profiles table (admin/gestionnaire/assistant)
- RLS policies enforce data access at database level
- Flutter UI guards hide/show elements based on role
- Double protection: even if UI bypassed, RLS blocks unauthorized actions

**Implementation Pattern:**
```sql
-- RLS policy example for buildings:
CREATE POLICY "Admins and gestionnaires can manage buildings"
ON buildings FOR ALL
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role IN ('admin', 'gestionnaire')
  )
);

CREATE POLICY "Assistants can view buildings"
ON buildings FOR SELECT
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'assistant'
  )
);
```

**Flutter UI Guard:**
```dart
class RoleGuard extends ConsumerWidget {
  final List<String> allowedRoles;
  final Widget child;
  final Widget? fallback;

  // Shows child only if user has required role
}
```

**Alternatives Considered:**

| Option | Pros | Cons | Why Rejected |
|--------|------|------|--------------|
| JWT claims only | Fast checks | Stale if role changes | Requires re-login on role change |
| Separate permissions table | Granular | Over-complex for 3 roles | YAGNI - 3 roles sufficient |
| Client-side only | Simple | Security vulnerability | Constitution requires server-side enforcement |

---

## 5. Password Validation

### Decision: Client-side regex + server-side Supabase Auth policy

**Rationale:**
- Immediate feedback for users (UX)
- Supabase Auth enforces minimum requirements server-side
- Spec requires: 8+ chars, 1 number, 1 special character

**Validation Regex:**
```dart
// At least 8 chars, 1 digit, 1 special char
final passwordRegex = RegExp(r'^(?=.*[0-9])(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$');
```

**French Error Messages:**
- Too short: "Le mot de passe doit contenir au moins 8 caracteres"
- Missing number/special: "Le mot de passe doit contenir au moins un chiffre et un caractere special"

---

## 6. Navigation & Auth Guards

### Decision: GoRouter with redirect guards

**Rationale:**
- Constitution specifies GoRouter for navigation
- Built-in redirect support for auth state changes
- Can listen to Supabase auth state stream

**Implementation Pattern:**
```dart
final router = GoRouter(
  refreshListenable: authStateNotifier,
  redirect: (context, state) {
    final isLoggedIn = authStateNotifier.isLoggedIn;
    final isAuthRoute = state.matchedLocation.startsWith('/auth');

    if (!isLoggedIn && !isAuthRoute) return '/auth/login';
    if (isLoggedIn && isAuthRoute) return '/dashboard';
    return null;
  },
  routes: [...],
);
```

---

## 7. State Management for Auth

### Decision: Riverpod with AsyncNotifier

**Rationale:**
- Constitution specifies Riverpod
- AsyncNotifier handles loading/error/data states naturally
- Can persist across hot reload during development

**Provider Structure:**
```dart
// Auth state provider
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

// Current user role (derived)
final userRoleProvider = Provider<UserRole?>((ref) {
  final user = ref.watch(authProvider).valueOrNull;
  return user?.role;
});
```

---

## 8. Error Handling Strategy

### Decision: Custom AuthException hierarchy

**Rationale:**
- Type-safe error handling in Dart
- Easy to map to French user-facing messages
- Consistent across all auth operations

**Exception Types:**
```dart
sealed class AuthException implements Exception {
  String get messageFr;
}

class InvalidCredentialsException extends AuthException {
  String get messageFr => 'Email ou mot de passe incorrect';
}

class AccountLockedException extends AuthException {
  final DateTime lockedUntil;
  String get messageFr => 'Compte temporairement bloque. Reessayez dans ${_minutesRemaining} minutes';
}

class EmailAlreadyInUseException extends AuthException {
  String get messageFr => 'Cette adresse email est deja utilisee';
}

class WeakPasswordException extends AuthException {
  String get messageFr => 'Le mot de passe doit contenir au moins 8 caracteres';
}

class NetworkException extends AuthException {
  String get messageFr => 'Connexion impossible. Verifiez votre connexion internet';
}
```

---

## 9. Testing Strategy

### Decision: Unit tests for use cases + Widget tests for pages

**Rationale:**
- Use cases contain business logic - must be unit tested
- Widget tests verify UI behavior and user flows
- Mock Supabase client for isolation

**Test Coverage Targets:**
- Use cases: 100% coverage (sign_in, sign_up, sign_out, reset_password)
- Validators: 100% coverage (email, password validation)
- Auth pages: Key user flows (successful login, error states, loading states)

---

## 10. Initial Admin Setup

### Decision: Seed script + environment variable

**Rationale:**
- First admin cannot be created through normal registration (chicken-egg)
- Seed script runs during initial deployment
- Admin email/password from secure environment variables

**Implementation:**
```sql
-- supabase/seed.sql (run manually or via CI)
-- First, create user via Supabase Auth API, then:
INSERT INTO profiles (id, email, full_name, role)
VALUES (
  'uuid-from-auth-user',
  'admin@locagest.ci',
  'Administrateur',
  'admin'
);
```

---

## Dependencies Confirmed

| Package | Version | Purpose |
|---------|---------|---------|
| supabase_flutter | ^2.0.0 | Supabase client (Auth, Database) |
| flutter_riverpod | ^2.4.0 | State management |
| go_router | ^13.0.0 | Navigation with auth guards |
| freezed_annotation | ^2.4.0 | Immutable models |
| json_annotation | ^4.8.0 | JSON serialization |
| flutter_secure_storage | ^9.0.0 | Secure token storage |

---

## Open Questions Resolved

| Question | Resolution |
|----------|------------|
| How to handle account lockout? | Custom DB field + RPC function |
| Where to store JWT? | flutter_secure_storage (mobile), Supabase default (web) |
| How to enforce roles at DB level? | RLS policies per table |
| How to create first admin? | Seed script with env vars |
| Email verification required? | No - spec doesn't require, simplifies MVP |
