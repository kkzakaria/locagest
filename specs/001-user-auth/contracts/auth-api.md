# API Contracts: User Authentication

**Feature**: 001-user-auth
**Date**: 2026-01-06

This document defines the API contracts between the Flutter frontend and Supabase backend for authentication operations.

---

## Overview

The authentication system uses:
- **Supabase Auth API** for sign up, sign in, sign out, and password reset
- **Custom RPC functions** for lockout logic and admin operations
- **Direct table access** for profile management (via RLS)

---

## 1. User Registration

### Sign Up
**Supabase Method**: `supabase.auth.signUp()`

**Request:**
```dart
final response = await supabase.auth.signUp(
  email: 'user@example.com',
  password: 'SecurePass1!',
  data: {
    'full_name': 'Jean Dupont',
  },
);
```

**Success Response:**
```dart
AuthResponse(
  session: Session(...),  // JWT tokens
  user: User(
    id: 'uuid',
    email: 'user@example.com',
    userMetadata: {'full_name': 'Jean Dupont'},
  ),
)
```

**Error Responses:**

| Code | Message | French UI Message |
|------|---------|-------------------|
| 400 | User already registered | "Cette adresse email est deja utilisee" |
| 422 | Password should be at least 6 characters | "Le mot de passe doit contenir au moins 8 caracteres" |
| 500 | Database error | "Une erreur est survenue. Veuillez reessayer" |

**Side Effects:**
- Trigger creates profile record automatically
- Default role: 'gestionnaire'

---

## 2. User Login

### Sign In
**Supabase Method**: `supabase.auth.signInWithPassword()`

**Pre-check (Lockout):**
```dart
// Call RPC before attempting login
final lockoutCheck = await supabase.rpc(
  'check_login_attempt',
  params: {'user_email': email},
);

// Returns: {allowed: bool, reason: string?, locked_until: timestamp?}
if (!lockoutCheck['allowed']) {
  throw AccountLockedException(lockoutCheck['locked_until']);
}
```

**Request:**
```dart
final response = await supabase.auth.signInWithPassword(
  email: 'user@example.com',
  password: 'SecurePass1!',
);
```

**Success Response:**
```dart
AuthResponse(
  session: Session(
    accessToken: 'jwt...',
    refreshToken: 'refresh...',
    expiresIn: 3600,
  ),
  user: User(
    id: 'uuid',
    email: 'user@example.com',
  ),
)
```

**Post-Success:**
```dart
// Reset failed attempts counter
await supabase.rpc('reset_login_attempts', params: {'user_email': email});
```

**Error Responses:**

| Code | Message | French UI Message |
|------|---------|-------------------|
| 400 | Invalid login credentials | "Email ou mot de passe incorrect" |
| 429 | Too many requests | "Trop de tentatives. Veuillez patienter" |

**Post-Failure:**
```dart
// Increment failed attempts (may trigger lockout)
await supabase.rpc('record_failed_login', params: {'user_email': email});
```

---

## 3. Password Reset

### Request Reset Email
**Supabase Method**: `supabase.auth.resetPasswordForEmail()`

**Request:**
```dart
await supabase.auth.resetPasswordForEmail(
  'user@example.com',
  redirectTo: 'locagest://reset-password',
);
```

**Response:** No data returned (fire-and-forget)

**UI Message:** "Un email de reinitialisation a ete envoye" (always shown, even if email not found - security)

### Update Password (from reset link)
**Supabase Method**: `supabase.auth.updateUser()`

**Request:**
```dart
// User arrives with access_token in URL/deep link
// Supabase SDK handles session restoration automatically

final response = await supabase.auth.updateUser(
  UserAttributes(password: 'NewSecurePass1!'),
);
```

**Success Response:**
```dart
UserResponse(
  user: User(...),
)
```

**Error Responses:**

| Code | Message | French UI Message |
|------|---------|-------------------|
| 400 | Password should be at least 6 characters | "Le mot de passe doit contenir au moins 8 caracteres" |
| 401 | Invalid token | "Ce lien a expire. Veuillez demander un nouveau lien" |

---

## 4. User Logout

### Sign Out
**Supabase Method**: `supabase.auth.signOut()`

**Request:**
```dart
await supabase.auth.signOut();
```

**Response:** No data returned

**Side Effects:**
- Session tokens invalidated server-side
- Local storage cleared automatically by SDK

---

## 5. Session Management

### Get Current User
**Supabase Method**: `supabase.auth.currentUser`

**Request:**
```dart
final user = supabase.auth.currentUser;
// Returns User? - null if not authenticated
```

### Get Current Session
**Supabase Method**: `supabase.auth.currentSession`

**Request:**
```dart
final session = supabase.auth.currentSession;
// Returns Session? - includes access_token, refresh_token, expires_at
```

### Listen to Auth State Changes
**Supabase Method**: `supabase.auth.onAuthStateChange`

**Request:**
```dart
supabase.auth.onAuthStateChange.listen((data) {
  final event = data.event; // signedIn, signedOut, tokenRefreshed, etc.
  final session = data.session;
});
```

---

## 6. Profile Operations

### Get User Profile
**Table**: `profiles`
**RLS**: User can read own profile, admins can read all

**Request:**
```dart
final profile = await supabase
    .from('profiles')
    .select()
    .eq('id', supabase.auth.currentUser!.id)
    .single();
```

**Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "full_name": "Jean Dupont",
  "role": "gestionnaire",
  "avatar_url": null,
  "created_at": "2026-01-06T10:00:00Z",
  "updated_at": "2026-01-06T10:00:00Z"
}
```

### Update Own Profile
**Table**: `profiles`
**RLS**: User can update own profile (except role)

**Request:**
```dart
await supabase
    .from('profiles')
    .update({
      'full_name': 'Jean-Pierre Dupont',
      'avatar_url': 'https://...',
    })
    .eq('id', supabase.auth.currentUser!.id);
```

---

## 7. User Management (Admin Only)

### List All Users
**Table**: `profiles`
**RLS**: Admin only

**Request:**
```dart
final users = await supabase
    .from('profiles')
    .select()
    .order('created_at', ascending: false);
```

**Response:**
```json
[
  {
    "id": "uuid1",
    "email": "admin@locagest.ci",
    "full_name": "Administrateur",
    "role": "admin",
    "created_at": "2026-01-01T00:00:00Z"
  },
  {
    "id": "uuid2",
    "email": "user@example.com",
    "full_name": "Jean Dupont",
    "role": "gestionnaire",
    "created_at": "2026-01-06T10:00:00Z"
  }
]
```

### Update User Role
**Table**: `profiles`
**RLS**: Admin only

**Request:**
```dart
await supabase
    .from('profiles')
    .update({'role': 'assistant'})
    .eq('id', targetUserId);
```

**Error Responses:**

| Code | Message | French UI Message |
|------|---------|-------------------|
| 403 | RLS policy violation | "Vous n'avez pas les droits pour cette action" |
| 400 | Cannot demote the last admin | "Il doit y avoir au moins un administrateur" |

---

## 8. Custom RPC Functions

### check_login_attempt

**Purpose**: Check if user account is locked before login attempt

**Request:**
```dart
final result = await supabase.rpc(
  'check_login_attempt',
  params: {'user_email': 'user@example.com'},
);
```

**Response:**
```json
{
  "allowed": true,
  "reason": null
}
// or
{
  "allowed": false,
  "reason": "locked",
  "locked_until": "2026-01-06T10:15:00Z"
}
```

### record_failed_login

**Purpose**: Increment failed attempt counter, potentially lock account

**Request:**
```dart
await supabase.rpc(
  'record_failed_login',
  params: {'user_email': 'user@example.com'},
);
```

**Response:** void

### reset_login_attempts

**Purpose**: Clear failed attempts on successful login

**Request:**
```dart
await supabase.rpc(
  'reset_login_attempts',
  params: {'user_email': 'user@example.com'},
);
```

**Response:** void

---

## Error Handling Summary

| Supabase Error | AuthException Type | French Message |
|----------------|-------------------|----------------|
| Invalid login credentials | InvalidCredentialsException | Email ou mot de passe incorrect |
| User already registered | EmailAlreadyInUseException | Cette adresse email est deja utilisee |
| Password too weak | WeakPasswordException | Le mot de passe doit contenir au moins 8 caracteres |
| Invalid token (reset) | TokenExpiredException | Ce lien a expire. Veuillez demander un nouveau lien |
| Network error | NetworkException | Connexion impossible. Verifiez votre connexion internet |
| RLS violation | UnauthorizedException | Vous n'avez pas les droits pour cette action |
| Account locked | AccountLockedException | Compte temporairement bloque. Reessayez dans X minutes |

---

## Rate Limits

Supabase applies default rate limits:
- Sign up: 5 per hour per IP
- Sign in: 30 per hour per IP
- Password reset: 5 per hour per email

These are in addition to the custom account lockout (5 failures = 15 min lock).
