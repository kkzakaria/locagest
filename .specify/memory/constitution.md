<!--
=============================================================================
SYNC IMPACT REPORT
=============================================================================
Version change: N/A (initial) → 1.0.0
Bump rationale: Initial constitution creation (MAJOR version for new document)

Modified principles: N/A (initial creation)

Added sections:
- Core Principles (5 principles)
- Technical Standards
- Development Workflow
- Governance

Removed sections: N/A (initial creation)

Templates requiring updates:
- .specify/templates/plan-template.md: ✅ Compatible (Constitution Check section exists)
- .specify/templates/spec-template.md: ✅ Compatible (Requirements section aligned)
- .specify/templates/tasks-template.md: ✅ Compatible (Phase structure supports principles)

Follow-up TODOs: None
=============================================================================
-->

# LocaGest Constitution

## Core Principles

### I. Clean Architecture

All code MUST follow Clean Architecture with strict layer separation:

- **Presentation Layer** (`lib/presentation/`): UI widgets, pages, and Riverpod providers. This layer MUST NOT contain business logic or direct database calls.
- **Domain Layer** (`lib/domain/`): Entities, repository interfaces, and use cases. This layer MUST be pure Dart with no Flutter or Supabase dependencies.
- **Data Layer** (`lib/data/`): Models (Freezed), datasources (Supabase), and repository implementations. This layer handles all external data concerns.

**Non-negotiable rules:**
- Dependencies MUST flow inward: Presentation → Domain ← Data
- Use cases MUST be single-responsibility with one public method
- Repository interfaces MUST be defined in Domain, implementations in Data
- No direct Supabase calls from Presentation layer

**Rationale:** Property management involves complex business rules (rent calculations, lease validations, payment reconciliation). Clean separation ensures business logic remains testable and maintainable as the application scales to 100+ managed properties.

### II. Mobile-First UX

The application MUST prioritize mobile usability for field operations:

- **Touch targets** MUST be minimum 48x48 dp for all interactive elements
- **Critical actions** (register payment, create tenant) MUST be completable in ≤3 taps
- **Offline capability** MUST be supported for read operations on essential data (buildings, units, tenants)
- **Visual feedback** MUST use consistent status colors: 🟢 paid/occupied, 🟡 pending, 🔴 overdue/vacant, 🟠 maintenance

**Non-negotiable rules:**
- All forms MUST have proper keyboard types (numeric for amounts, email for contacts)
- Loading states MUST be displayed for all async operations
- Error messages MUST be in French and actionable
- Bottom navigation MUST be used for primary navigation

**Rationale:** Target users are property managers in the field visiting properties, meeting tenants, and collecting payments. The interface must be fast and finger-friendly.

### III. Supabase-First Data

All data operations MUST leverage Supabase capabilities:

- **Row Level Security (RLS)** MUST be enabled and enforced on every table
- **Policies** MUST be role-based: admin (full), gestionnaire (owned data), assistant (read + limited write)
- **Storage buckets** MUST be private with signed URLs for document access
- **Real-time subscriptions** SHOULD be used for payment status updates on dashboard

**Non-negotiable rules:**
- Never disable RLS for convenience—create proper policies
- All file uploads MUST go through Supabase Storage, not external services
- Database migrations MUST be tracked (SQL files or Supabase CLI)
- Credentials (URL, keys) MUST be in `.env` and NEVER committed

**Rationale:** Supabase provides authentication, authorization, storage, and real-time in one platform. Leveraging built-in RLS ensures data isolation by user without custom backend code.

### IV. French Localization

All user-facing content MUST be in French (Ivory Coast context):

- **UI text** MUST be in French: labels, buttons, messages, placeholders
- **Generated documents** (quittances, états des lieux) MUST use French legal terminology
- **Date format** MUST be DD/MM/YYYY (European)
- **Currency** MUST display as "FCFA" or "F CFA" with space thousands separator (e.g., "150 000 FCFA")

**Non-negotiable rules:**
- Error messages MUST be translated and user-friendly in French
- PDF templates MUST include required French legal mentions
- Field labels MUST use property management terminology (bail, locataire, quittance, échéance)

**Rationale:** The target market is Ivory Coast property managers. Professional credibility requires correct legal French and local currency formatting.

### V. Security by Design

All features MUST implement security from the start:

- **Authentication** MUST be required for all routes except login/register
- **Authorization** MUST be checked at both UI (hide unauthorized actions) and API (RLS policies) levels
- **Sensitive data** (ID documents, contracts) MUST be stored in private buckets with time-limited signed URLs
- **Input validation** MUST occur on both client (UX) and server (RLS/constraints) sides

**Non-negotiable rules:**
- Never trust client-side validation alone—database constraints MUST enforce business rules
- File uploads MUST validate type and size before storage
- Session tokens MUST be stored securely (flutter_secure_storage for mobile)
- Audit trail: `created_by` and timestamps MUST be present on all user-generated records

**Rationale:** Property management involves sensitive personal data (tenant IDs, financial information). GDPR-aligned practices and defense-in-depth protect both users and tenants.

## Technical Standards

**Technology Stack:**
- Frontend: Flutter (Dart) targeting Android, iOS, and Web
- State Management: Riverpod (flutter_riverpod)
- Navigation: GoRouter with authentication guards
- Data Models: Freezed with JSON serialization
- Backend: Supabase (PostgreSQL, Auth, Storage)
- PDF Generation: pdf + printing packages

**Code Quality:**
- All models MUST use Freezed for immutability
- Generated code (`*.g.dart`, `*.freezed.dart`) MUST NOT be committed—regenerate via `build_runner`
- Providers MUST handle loading, error, and data states explicitly
- Functions MUST have explicit return types (no dynamic)

**Performance:**
- List views MUST use pagination or lazy loading for >20 items
- Images MUST be compressed before upload (max 1MB for photos)
- Dashboard queries MUST complete in <2 seconds

## Development Workflow

**Feature Development:**
1. Create feature specification using `/speckit.specify`
2. Generate implementation plan using `/speckit.plan`
3. Generate tasks using `/speckit.tasks`
4. Implement following task order (Setup → Foundational → User Stories)
5. Verify against acceptance criteria before marking complete

**Code Changes:**
- All changes MUST pass `flutter analyze` with no errors
- Models changes require regeneration: `flutter pub run build_runner build --delete-conflicting-outputs`
- Database schema changes MUST include migration SQL

**Commit Standards:**
- Commits MUST reference the task ID or user story when applicable
- Commit messages MUST be in English for tooling compatibility
- Feature branches MUST follow pattern: `feature/[short-description]`

## Governance

**Constitution Authority:**
- This constitution supersedes all other development practices
- All code reviews MUST verify compliance with these principles
- Violations MUST be documented with explicit justification

**Amendment Process:**
1. Propose change with rationale
2. Update constitution version following semantic versioning:
   - MAJOR: Principle removed or fundamentally redefined
   - MINOR: New principle or section added
   - PATCH: Clarification or typo fix
3. Update dependent templates if principles change
4. Document change in sync impact report

**Compliance Review:**
- New features MUST pass Constitution Check before implementation begins
- PRs MUST not introduce principle violations without documented justification
- Quarterly review recommended to assess principle relevance

**Version**: 1.0.0 | **Ratified**: 2026-01-06 | **Last Amended**: 2026-01-06
