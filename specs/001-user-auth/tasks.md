# Tasks: User Authentication System

**Input**: Design documents from `/specs/001-user-auth/`
**Prerequisites**: plan.md (required), spec.md (required), data-model.md, contracts/auth-api.md

**Tests**: Tests are NOT explicitly requested in the specification. Test tasks are omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter app**: `lib/` at repository root following Clean Architecture
- **Tests**: `test/` at repository root
- **Database**: `supabase/migrations/` for SQL files

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Project initialization and core infrastructure

- [x] T001 Create Clean Architecture folder structure in lib/ (core/, data/, domain/, presentation/)
- [x] T002 [P] Add dependencies to pubspec.yaml (supabase_flutter, flutter_riverpod, go_router, freezed, flutter_secure_storage)
- [x] T003 [P] Create .env.example with SUPABASE_URL and SUPABASE_ANON_KEY placeholders
- [x] T004 [P] Add .env to .gitignore if not already present
- [x] T005 Run flutter pub get to install dependencies

**Checkpoint**: Project compiles with all dependencies installed

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Create auth constants in lib/core/constants/app_constants.dart (lockout threshold, session duration, password rules)
- [x] T007 [P] Create auth exception hierarchy in lib/core/errors/auth_exceptions.dart (InvalidCredentialsException, EmailAlreadyInUseException, WeakPasswordException, AccountLockedException, NetworkException, TokenExpiredException)
- [x] T008 [P] Create email and password validators in lib/core/utils/validators.dart
- [x] T009 [P] Create secure storage wrapper in lib/core/utils/secure_storage.dart
- [x] T010 Create User entity with UserRole enum in lib/domain/entities/user.dart
- [x] T011 Create UserModel with Freezed in lib/data/models/user_model.dart
- [x] T012 Run flutter pub run build_runner build --delete-conflicting-outputs to generate Freezed code
- [x] T013 Create AuthRepository interface in lib/domain/repositories/auth_repository.dart
- [x] T014 Create AuthRemoteDatasource in lib/data/datasources/auth_remote_datasource.dart
- [x] T015 Create AuthRepositoryImpl in lib/data/repositories/auth_repository_impl.dart
- [x] T016 Create GetCurrentUser use case in lib/domain/usecases/get_current_user.dart
- [x] T017 Create AuthProvider with AsyncNotifier in lib/presentation/providers/auth_provider.dart
- [x] T018 Create AuthGuard widget for route protection in lib/presentation/widgets/auth_guard.dart
- [x] T019 Create Supabase migration file with profiles table, RLS policies, and functions in supabase/migrations/001_auth_setup.sql
- [x] T020 Initialize Supabase client in lib/main.dart with .env configuration
- [x] T021 Configure GoRouter with auth redirect logic in lib/core/router/app_router.dart

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - User Login (Priority: P1)

**Goal**: Allow existing users to securely access their accounts with email and password

**Independent Test**: Create test user in Supabase, attempt login with correct/incorrect credentials, verify dashboard redirect

### Implementation for User Story 1

- [x] T022 [US1] Create SignIn use case in lib/domain/usecases/sign_in.dart
- [x] T023 [US1] Add signIn method to AuthRemoteDatasource with lockout check (check_login_attempt RPC)
- [x] T024 [US1] Add signIn method to AuthRepositoryImpl with error mapping
- [x] T025 [US1] Add signIn method to AuthProvider
- [x] T026 [US1] Create LoginPage UI in lib/presentation/pages/auth/login_page.dart
- [x] T027 [US1] Implement login form with email/password fields, French validation messages
- [x] T028 [US1] Add loading state and error display to LoginPage
- [x] T029 [US1] Implement account lockout display (minutes remaining countdown)
- [x] T030 [US1] Add "Mot de passe oublie?" link to LoginPage (navigation to US3)
- [x] T031 [US1] Add "Creer un compte" link to LoginPage (navigation to US2)
- [x] T032 [US1] Register login route in GoRouter (/auth/login)

**Checkpoint**: User Story 1 complete - users can log in, see lockout messages, navigate to register/forgot password

---

## Phase 4: User Story 2 - User Registration (Priority: P2)

**Goal**: Allow new users to create accounts with email, full name, and secure password

**Independent Test**: Complete registration form, verify profile created, confirm auto-login after registration

### Implementation for User Story 2

- [x] T033 [US2] Create SignUp use case in lib/domain/usecases/sign_up.dart
- [x] T034 [US2] Add signUp method to AuthRemoteDatasource (with full_name in metadata)
- [x] T035 [US2] Add signUp method to AuthRepositoryImpl with error mapping
- [x] T036 [US2] Add signUp method to AuthProvider
- [x] T037 [US2] Create RegisterPage UI in lib/presentation/pages/auth/register_page.dart
- [x] T038 [US2] Implement registration form with full_name, email, password, confirm_password fields
- [x] T039 [US2] Add real-time password strength validation (8 chars, number, special char)
- [x] T040 [US2] Add loading state and error display to RegisterPage
- [x] T041 [US2] Add "Deja un compte? Connexion" link to RegisterPage
- [x] T042 [US2] Register registration route in GoRouter (/auth/register)

**Checkpoint**: User Story 2 complete - new users can register and are auto-logged in

---

## Phase 5: User Story 3 - Password Reset (Priority: P3)

**Goal**: Allow users who forgot their password to reset it via email

**Independent Test**: Request reset for existing account, click email link, set new password, verify login works

### Implementation for User Story 3

- [x] T043 [US3] Create ResetPassword use case in lib/domain/usecases/reset_password.dart (request + update)
- [x] T044 [US3] Add resetPasswordForEmail method to AuthRemoteDatasource
- [x] T045 [US3] Add updatePassword method to AuthRemoteDatasource
- [x] T046 [US3] Add password reset methods to AuthRepositoryImpl with error mapping
- [x] T047 [US3] Add password reset methods to AuthProvider
- [x] T048 [US3] Create ForgotPasswordPage UI in lib/presentation/pages/auth/forgot_password_page.dart
- [x] T049 [US3] Implement email input form with success message display
- [x] T050 [US3] Create ResetPasswordPage UI in lib/presentation/pages/auth/reset_password_page.dart
- [x] T051 [US3] Implement new password form with confirmation field
- [x] T052 [US3] Handle deep link token extraction for password reset
- [x] T053 [US3] Add loading state and error display to both pages
- [x] T054 [US3] Register password reset routes in GoRouter (/auth/forgot-password, /auth/reset-password)

**Checkpoint**: User Story 3 complete - users can request and complete password reset

---

## Phase 6: User Story 4 - Role-Based Access Control (Priority: P4)

**Goal**: Allow admins to manage user roles and restrict feature access based on roles

**Independent Test**: Log in as admin, change user role, verify gestionnaire/assistant see restricted UI

### Implementation for User Story 4

- [x] T055 [US4] Create UpdateUserRole use case in lib/domain/usecases/update_user_role.dart
- [x] T056 [US4] Add getAllUsers method to AuthRemoteDatasource (admin only)
- [x] T057 [US4] Add updateUserRole method to AuthRemoteDatasource
- [x] T058 [US4] Add user management methods to AuthRepositoryImpl
- [x] T059 [US4] Create UsersProvider for user list management in lib/presentation/providers/users_provider.dart
- [x] T060 [US4] Create RoleGuard widget in lib/presentation/widgets/role_guard.dart
- [x] T061 [US4] Create UserManagementPage UI in lib/presentation/pages/settings/user_management_page.dart
- [x] T062 [US4] Implement user list with role dropdown per user
- [x] T063 [US4] Add last admin protection UI (disable role change for last admin)
- [x] T064 [US4] Add loading state and error display to UserManagementPage
- [x] T065 [US4] Register user management route in GoRouter (/settings/users) with admin guard
- [x] T066 [US4] Apply RoleGuard to navigation items (hide user management for non-admins)

**Checkpoint**: User Story 4 complete - admins can manage roles, non-admins see restricted UI

---

## Phase 7: User Story 5 - User Logout (Priority: P5)

**Goal**: Allow users to securely log out and invalidate their session

**Independent Test**: Log in, tap logout, verify redirect to login, verify cannot navigate back

### Implementation for User Story 5

- [x] T067 [US5] Create SignOut use case in lib/domain/usecases/sign_out.dart
- [x] T068 [US5] Add signOut method to AuthRemoteDatasource
- [x] T069 [US5] Add signOut method to AuthRepositoryImpl
- [x] T070 [US5] Add signOut method to AuthProvider with session cleanup
- [x] T071 [US5] Add logout button to settings/profile area with confirmation dialog
- [x] T072 [US5] Clear local storage on logout (secure_storage)
- [x] T073 [US5] Ensure GoRouter redirects to login after logout

**Checkpoint**: User Story 5 complete - users can log out securely

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T074 [P] Add consistent loading indicator widget for all auth pages
- [x] T075 [P] Ensure all error messages display in French per spec
- [x] T076 [P] Add keyboard type configuration (email keyboard for email fields)
- [x] T077 [P] Ensure minimum 48dp touch targets on all interactive elements
- [x] T078 [P] Add session expiry handling (redirect to login with French message)
- [x] T079 [P] Add network error handling for offline scenarios
- [x] T080 Run flutter analyze and fix any issues
- [ ] T081 Test complete auth flow: register -> logout -> login -> forgot password -> reset -> login -> role change (admin) -> logout
- [ ] T082 Verify quickstart.md verification checklist passes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - User stories can then proceed in priority order (P1 -> P2 -> P3 -> P4 -> P5)
  - US1 (Login) should be first as other stories reference it
  - US2-US5 can be developed after US1 in any order, though priority order recommended
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (Login)**: Can start after Foundational - No dependencies on other stories
- **US2 (Registration)**: Can start after Foundational - Links to US1 (login page)
- **US3 (Password Reset)**: Can start after Foundational - Links to US1 (login page)
- **US4 (RBAC)**: Can start after Foundational - Requires US1 for login testing
- **US5 (Logout)**: Can start after Foundational - Requires US1 for login

### Within Each User Story

- Use cases before datasource/repository methods
- Repository methods before provider methods
- Provider methods before UI pages
- Core implementation before polish/integration

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Polish tasks marked [P] can run in parallel

---

## Parallel Execution Examples

### Phase 2: Foundational (Parallelizable)

```text
# Group 1: Can run in parallel (different files)
Task: T007 [P] Create auth exception hierarchy in lib/core/errors/auth_exceptions.dart
Task: T008 [P] Create email and password validators in lib/core/utils/validators.dart
Task: T009 [P] Create secure storage wrapper in lib/core/utils/secure_storage.dart

# Group 2: Depends on Group 1
Task: T010 Create User entity in lib/domain/entities/user.dart
Task: T011 Create UserModel in lib/data/models/user_model.dart
```

### Phase 8: Polish (Parallelizable)

```text
# All can run in parallel (independent improvements)
Task: T074 [P] Add consistent loading indicator widget
Task: T075 [P] Ensure all error messages display in French
Task: T076 [P] Add keyboard type configuration
Task: T077 [P] Ensure minimum 48dp touch targets
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Login)
4. **STOP and VALIDATE**: Test login flow independently
5. Deploy/demo if ready - users can log in with pre-seeded accounts

### Incremental Delivery

1. Complete Setup + Foundational -> Foundation ready
2. Add User Story 1 (Login) -> Test independently -> Users can log in
3. Add User Story 2 (Registration) -> Test independently -> New users can join
4. Add User Story 3 (Password Reset) -> Test independently -> Users can recover access
5. Add User Story 4 (RBAC) -> Test independently -> Admins can manage team
6. Add User Story 5 (Logout) -> Test independently -> Complete auth cycle
7. Polish phase -> Production ready

### Task Count Summary

| Phase | Tasks | Parallel Opportunities |
|-------|-------|------------------------|
| Phase 1: Setup | 5 | 3 |
| Phase 2: Foundational | 16 | 4 |
| Phase 3: US1 Login | 11 | 0 |
| Phase 4: US2 Registration | 10 | 0 |
| Phase 5: US3 Password Reset | 12 | 0 |
| Phase 6: US4 RBAC | 12 | 0 |
| Phase 7: US5 Logout | 7 | 0 |
| Phase 8: Polish | 9 | 5 |
| **Total** | **82** | **12** |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All French messages per specification (no accents in code strings to avoid encoding issues)
- Supabase migration must be run manually via SQL Editor before Flutter testing
