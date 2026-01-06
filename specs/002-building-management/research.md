# Research: Building Management

**Feature**: 002-building-management
**Date**: 2026-01-06
**Status**: Complete

## Research Summary

This document captures technical decisions and best practices research for implementing the building management feature. Since this is a straightforward CRUD feature following established patterns from the auth feature, no major unknowns required deep research.

---

## Decision 1: Image Handling for Building Photos

**Context**: Buildings can have an optional photo. Need to decide on upload, storage, and display strategy.

**Decision**: Use Supabase Storage with client-side compression before upload.

**Rationale**:
- Constitution requires images compressed to max 1MB
- Constitution requires private storage with signed URLs
- Supabase Storage is already configured for the project
- Flutter `image_picker` package already in dependencies

**Implementation Details**:
- Use `image_picker` to select from gallery or camera
- Compress to max 1MB using `flutter_image_compress` (add to dependencies)
- Upload to `photos` bucket with path: `buildings/{building_id}/{timestamp}.jpg`
- Store signed URL in building record (refresh on access if expired)
- Display using `CachedNetworkImage` for performance

**Alternatives Considered**:
| Alternative | Why Rejected |
|-------------|--------------|
| Base64 in database | Poor performance, bloats database size |
| External CDN | Violates constitution (Supabase-only storage) |
| No compression | Would exceed 1MB limit, slow uploads |

---

## Decision 2: RLS Policy Design for Buildings

**Context**: Need role-based access control matching spec requirements (FR-001, FR-015).

**Decision**: Three RLS policies based on user role.

**Rationale**:
- Admin: Full access to all buildings
- Gestionnaire: Full CRUD on own buildings (created_by = auth.uid())
- Assistant: Read-only access to buildings in their scope

**Implementation Details**:
```sql
-- Policy: Admin full access
CREATE POLICY "admin_all_access" ON buildings
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Policy: Gestionnaire CRUD on own buildings
CREATE POLICY "gestionnaire_own_buildings" ON buildings
  FOR ALL USING (
    created_by = auth.uid() AND
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'gestionnaire')
  );

-- Policy: Assistant read-only
CREATE POLICY "assistant_read_only" ON buildings
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'assistant')
  );
```

**Alternatives Considered**:
| Alternative | Why Rejected |
|-------------|--------------|
| Single policy with CASE | Less readable, harder to maintain |
| Application-level only | Violates constitution (RLS required) |
| Shared buildings table | Over-engineered for MVP scope |

---

## Decision 3: Delete Protection Strategy

**Context**: FR-009 requires preventing deletion of buildings with units.

**Decision**: Database constraint + application-level check.

**Rationale**:
- Defense in depth: both UI and database enforce the rule
- Constitution requires constraints at database level
- Better UX with clear error message in French

**Implementation Details**:
- Database: `ON DELETE RESTRICT` on units.building_id foreign key
- Application: Check unit count before showing delete button
- Error handling: Catch constraint violation, show French message

**Alternatives Considered**:
| Alternative | Why Rejected |
|-------------|--------------|
| Soft delete | Over-engineered for MVP (spec says deletion is rare) |
| Cascade delete | Dangerous, could lose tenant/lease data |
| Application-only check | Violates constitution (database constraints required) |

---

## Decision 4: List Performance Strategy

**Context**: SC-002 requires list to load in <2 seconds for 100 buildings.

**Decision**: Pagination with 20 items per page, lazy loading on scroll.

**Rationale**:
- Constitution requires pagination for >20 items
- Riverpod AsyncNotifier handles loading states
- Supabase supports efficient pagination with range queries

**Implementation Details**:
- Initial load: 20 buildings, ordered by created_at DESC
- On scroll near bottom: Load next 20
- Use Supabase `.range(from, to)` for pagination
- Cache current page in provider state
- Refresh on pull-down

**Alternatives Considered**:
| Alternative | Why Rejected |
|-------------|--------------|
| Load all at once | Violates constitution, poor performance at scale |
| Cursor pagination | More complex, not needed for this scale |
| Virtual scrolling | Overkill for <200 items max |

---

## Decision 5: Form Validation Strategy

**Context**: FR-011 requires French validation messages.

**Decision**: Client-side validation with Form widget + server constraints.

**Rationale**:
- Better UX with immediate feedback
- Constitution requires both client and server validation
- Existing validators.dart can be extended

**Implementation Details**:
- Use Flutter Form widget with TextFormField validators
- Required fields: name (non-empty), address (non-empty), city (non-empty)
- Optional fields: postal_code, country, notes, photo
- Error messages in French from validators.dart
- Database constraints as backup validation

**Validation Rules**:
| Field | Validation | French Error Message |
|-------|------------|---------------------|
| name | Required, 1-100 chars | "Le nom de l'immeuble est requis" |
| address | Required, 1-200 chars | "L'adresse est requise" |
| city | Required, 1-100 chars | "La ville est requise" |
| postal_code | Optional, max 20 chars | - |
| notes | Optional, max 1000 chars | - |

---

## Decision 6: Navigation Integration

**Context**: Need to integrate buildings into existing app navigation.

**Decision**: Add to bottom navigation + GoRouter routes.

**Rationale**:
- Constitution requires bottom navigation for primary sections
- Buildings is a primary section per spec assumptions
- GoRouter already configured with auth guards

**Implementation Details**:
- Add "Immeubles" tab to bottom navigation (index 1)
- Routes: `/buildings`, `/buildings/:id`, `/buildings/new`, `/buildings/:id/edit`
- All routes protected by AuthGuard
- Edit/delete buttons hidden for assistant role (UI authorization)

---

## Dependencies to Add

Based on research, the following packages need to be added to `pubspec.yaml`:

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_image_compress | ^2.1.0 | Compress photos before upload |
| cached_network_image | ^3.3.1 | Efficient image display with caching |

---

## Database Migration Required

SQL migration file needed for:
1. Create `buildings` table with all fields
2. Enable RLS on `buildings`
3. Create RLS policies (admin, gestionnaire, assistant)
4. Create `photos` storage bucket if not exists
5. Create storage policy for authenticated users
6. Create trigger to update `updated_at` on changes

---

## No Outstanding Research Items

All technical decisions have been made. Ready to proceed to Phase 1 (Design & Contracts).
