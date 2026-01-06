# Feature Specification: User Authentication System

**Feature Branch**: `001-user-auth`
**Created**: 2026-01-06
**Status**: Draft
**Input**: User login, registration, password reset, and role-based access control for LocaGest property management application

## User Scenarios & Testing *(mandatory)*

### User Story 1 - User Login (Priority: P1)

A gestionnaire (property manager) opens the LocaGest application and needs to securely access their property portfolio. They enter their email and password on the login screen and are directed to their personalized dashboard showing their buildings, tenants, and payment status.

**Why this priority**: Login is the gateway to all functionality. Without authentication, no other features can be accessed. This is the most critical user flow.

**Independent Test**: Can be fully tested by creating a test user, attempting login with correct/incorrect credentials, and verifying dashboard access. Delivers secure access to the application.

**Acceptance Scenarios**:

1. **Given** a registered user with valid credentials, **When** they enter their email and password and tap "Connexion", **Then** they are redirected to the dashboard within 3 seconds
2. **Given** a user with invalid credentials, **When** they attempt to login, **Then** they see an error message "Email ou mot de passe incorrect" and remain on the login screen
3. **Given** a user who has entered wrong credentials 5 times, **When** they attempt another login, **Then** they see a message "Compte temporairement bloque. Reessayez dans 15 minutes"
4. **Given** a logged-in user, **When** they close and reopen the app within 30 days, **Then** they remain logged in (persistent session)

---

### User Story 2 - User Registration (Priority: P2)

A new gestionnaire wants to start using LocaGest for their property management. They create an account by providing their full name, email address, and choosing a secure password. After registration, they can immediately start adding their properties.

**Why this priority**: Registration enables new user acquisition. Without it, the application cannot grow its user base. However, it's secondary to login since existing users need login first.

**Independent Test**: Can be tested by completing the registration form, verifying email validation, and confirming the new user can subsequently log in.

**Acceptance Scenarios**:

1. **Given** a visitor on the registration screen, **When** they enter a valid email, full name, and password meeting requirements, **Then** their account is created and they are logged in automatically
2. **Given** a visitor attempting to register, **When** they enter an email already in use, **Then** they see "Cette adresse email est deja utilisee"
3. **Given** a visitor entering a password, **When** the password has fewer than 8 characters, **Then** they see "Le mot de passe doit contenir au moins 8 caracteres"
4. **Given** a visitor entering a password, **When** the password lacks a number or special character, **Then** they see "Le mot de passe doit contenir au moins un chiffre et un caractere special"

---

### User Story 3 - Password Reset (Priority: P3)

A gestionnaire has forgotten their password and cannot access their account. They request a password reset, receive an email with a reset link, and create a new password to regain access to their property data.

**Why this priority**: Password reset is essential for user retention and reduces support burden. However, it's less frequent than daily login/registration flows.

**Independent Test**: Can be tested by requesting a reset for an existing account, clicking the email link, setting a new password, and verifying login works with the new password.

**Acceptance Scenarios**:

1. **Given** a user on the login screen, **When** they tap "Mot de passe oublie?" and enter their registered email, **Then** they see "Un email de reinitialisation a ete envoye" and receive an email within 2 minutes
2. **Given** a user with a reset email, **When** they click the reset link within 1 hour, **Then** they are directed to a "Nouveau mot de passe" form
3. **Given** a user with a reset email, **When** they click the link after 1 hour, **Then** they see "Ce lien a expire. Veuillez demander un nouveau lien"
4. **Given** a user on the reset form, **When** they enter a valid new password and confirm it, **Then** their password is updated and they are logged in automatically

---

### User Story 4 - Role-Based Access Control (Priority: P4)

An admin needs to manage who can access different features within LocaGest. They assign roles (admin, gestionnaire, assistant) to users, which determines what each user can see and do in the application.

**Why this priority**: Role management is important for security and collaboration but is only needed once teams start using the app. Individual gestionnaires can function without it initially.

**Independent Test**: Can be tested by logging in with different role accounts and verifying that UI elements and actions are appropriately shown/hidden per role.

**Acceptance Scenarios**:

1. **Given** an admin user, **When** they access user management, **Then** they can see all users and change their roles
2. **Given** a gestionnaire user, **When** they attempt to access user management, **Then** the option is not visible in their navigation
3. **Given** an assistant user, **When** they view the buildings list, **Then** they can see building details but cannot see edit/delete buttons
4. **Given** an admin changing a user's role, **When** they save the change, **Then** the affected user's permissions update immediately on their next action

---

### User Story 5 - User Logout (Priority: P5)

A gestionnaire using a shared device needs to securely log out of LocaGest to prevent unauthorized access to sensitive tenant and financial data.

**Why this priority**: Logout is essential for security but is a simple, low-risk feature that complements login.

**Independent Test**: Can be tested by logging in, performing logout, and verifying the user cannot access protected screens without re-authenticating.

**Acceptance Scenarios**:

1. **Given** a logged-in user, **When** they tap "Deconnexion" in settings, **Then** they are returned to the login screen and their session is invalidated
2. **Given** a logged-out user, **When** they try to navigate directly to a protected screen, **Then** they are redirected to the login screen
3. **Given** a user who logged out, **When** they press the back button, **Then** they cannot return to authenticated screens

---

### Edge Cases

- What happens when a user tries to register with a malformed email (e.g., "test@" or "test.com")? System shows "Veuillez entrer une adresse email valide"
- What happens when the network is unavailable during login? System shows "Connexion impossible. Verifiez votre connexion internet"
- What happens when a user's session expires while using the app? System redirects to login with message "Votre session a expire. Veuillez vous reconnecter"
- What happens when an admin tries to delete their own account? System prevents this with "Vous ne pouvez pas supprimer votre propre compte"
- What happens when the last admin tries to change their role to gestionnaire? System prevents this with "Il doit y avoir au moins un administrateur"

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to create accounts with email, full name, and password
- **FR-002**: System MUST validate email format and uniqueness during registration
- **FR-003**: System MUST enforce password requirements: minimum 8 characters, at least one number, at least one special character
- **FR-004**: System MUST authenticate users via email and password
- **FR-005**: System MUST maintain persistent sessions for up to 30 days of inactivity
- **FR-006**: System MUST lock accounts after 5 consecutive failed login attempts for 15 minutes
- **FR-007**: System MUST allow users to request password reset via email
- **FR-008**: System MUST expire password reset links after 1 hour
- **FR-009**: System MUST support three user roles: admin, gestionnaire, assistant
- **FR-010**: System MUST restrict feature access based on user role as defined in the role matrix
- **FR-011**: System MUST allow admins to view all users and modify their roles
- **FR-012**: System MUST allow users to log out, invalidating their current session
- **FR-013**: System MUST redirect unauthenticated users to the login screen
- **FR-014**: System MUST display all authentication messages in French
- **FR-015**: System MUST prevent deletion of the last admin account
- **FR-016**: System MUST prevent the last admin from changing their own role

### Role Permission Matrix

| Feature                                  | Admin | Gestionnaire | Assistant |
|------------------------------------------|-------|--------------|-----------|
| User management (view/edit/delete users) | Full  | None         | None      |
| Own profile management                   | Full  | Full         | Full      |
| Building CRUD                            | Full  | Full         | Read only |
| Unit CRUD                                | Full  | Full         | Read only |
| Tenant CRUD                              | Full  | Full         | Full      |
| Lease CRUD                               | Full  | Full         | Read only |
| Payment recording                        | Full  | Full         | Full      |
| Report generation                        | Full  | Full         | None      |
| Expense management                       | Full  | Full         | None      |
| System settings                          | Full  | Limited      | None      |

### Key Entities

- **User (Utilisateur)**: Represents a person who can access the system. Has email (unique identifier), full name, hashed password, role, and account status (active/locked). Related to all data they create via ownership.
- **Session**: Represents an active login. Tracks user identity, creation time, last activity time, and device information. Expires after 30 days of inactivity.
- **Password Reset Request**: Temporary record for password recovery. Contains user reference, unique token, creation time, and expiration time (1 hour). Invalidated after use.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete registration in under 2 minutes
- **SC-002**: Users can log in within 5 seconds of submitting credentials
- **SC-003**: 95% of password reset emails arrive within 2 minutes
- **SC-004**: System supports 100 concurrent authenticated users without performance degradation
- **SC-005**: 90% of users successfully complete login on their first attempt
- **SC-006**: Account lockout reduces brute-force attack success rate to near zero
- **SC-007**: Role-based restrictions prevent 100% of unauthorized feature access attempts
- **SC-008**: Session persistence reduces daily re-authentication rate by 80%

## Assumptions

- Email is the primary identifier; phone-based authentication is out of scope for MVP
- Users have access to email for registration and password reset
- The application will initially have a single admin created during system setup
- French is the only supported language for this feature
- Password reset emails are sent via the backend service
- Device/browser fingerprinting for session management is not required for MVP
