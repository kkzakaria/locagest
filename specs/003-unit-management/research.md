# Research: Module Lots/Unités (Unit Management)

**Feature Branch**: `003-unit-management`
**Date**: 2026-01-07

## Overview

This document consolidates research findings for the Unit Management module. Since the project already has established patterns from Building Management (Phase 4), research focuses on unit-specific design decisions and integration patterns.

---

## 1. Unit-Building Relationship Pattern

### Decision
Units belong to exactly one building with cascade delete behavior.

### Rationale
- **Foreign Key with CASCADE**: When a building is deleted, all associated units are automatically removed
- **Consistent with PLAN-DEV-LocaGest.md**: Table design specifies `building_id uuid references public.buildings(id) on delete cascade`
- **User Story 5 Edge Case**: Deletion of units with active leases is prevented at application level (leases table not yet implemented, but designed for `on delete restrict`)

### Alternatives Considered
| Option | Rejected Because |
|--------|------------------|
| Soft delete for units | Over-engineering for MVP; buildings with units show warning before delete |
| Orphan units (no building) | Violates business logic - every unit must belong to a building |

---

## 2. Unit Reference Uniqueness

### Decision
Unit reference is unique within a building, not globally unique.

### Rationale
- **User convention flexibility**: Different buildings may use same reference schemes (e.g., "A1", "A2")
- **Specification FR-008**: "System MUST enforce unique unit references within the same building"
- **Implementation**: Composite unique constraint `UNIQUE(building_id, reference)`

### Alternatives Considered
| Option | Rejected Because |
|--------|------------------|
| Global unique reference | Too restrictive; "Apt 101" is valid in multiple buildings |
| No uniqueness constraint | Allows duplicate references within building, causing confusion |

---

## 3. Equipment Storage Format

### Decision
Store equipment as JSON array of strings in `equipment jsonb` column.

### Rationale
- **Simplicity**: Equipment items are free-form text (e.g., "Climatisation", "Parking sous-sol", "Cuisine équipée")
- **No catalog needed**: Specification assumption states "Equipment items are stored as simple text strings (no predefined equipment catalog needed at this stage)"
- **Flexible**: Supports any language, custom items, no normalization overhead

### Format
```json
["Climatisation", "Cuisine équipée", "Parking", "Balcon"]
```

### Alternatives Considered
| Option | Rejected Because |
|--------|------------------|
| Separate equipment table | Over-engineering; no reporting/filtering on equipment needed for MVP |
| Predefined equipment enum | Too rigid; Ivory Coast properties have diverse equipment types |
| Comma-separated string | Harder to parse, no type safety |

---

## 4. Photos Storage Pattern

### Decision
Reuse existing `photos` bucket with `units/` folder prefix.

### Rationale
- **Building module precedent**: `photos` bucket already exists with RLS policies
- **Consistent URL structure**: `photos/units/{unit_id}/{filename}`
- **Storage policy update**: Add policy for `units` folder (similar to `buildings` folder)
- **Photos array**: Store signed URLs in `photos jsonb` column as array

### Format
```json
[
  "https://xxx.supabase.co/storage/v1/object/sign/photos/units/abc123/photo1.jpg?token=...",
  "https://xxx.supabase.co/storage/v1/object/sign/photos/units/abc123/photo2.jpg?token=..."
]
```

### Alternatives Considered
| Option | Rejected Because |
|--------|------------------|
| Separate `unit_photos` bucket | Unnecessary complexity; same policies apply |
| Store paths instead of URLs | Requires regenerating signed URLs on every read |

---

## 5. Unit Status Management

### Decision
Status is a constrained text field with three values: `vacant`, `occupied`, `maintenance`.

### Rationale
- **Specification FR-005**: Status values defined as "vacant (disponible), occupied (occupé), or maintenance (en maintenance)"
- **Visual indicators (FR-006)**: Maps to Constitution color scheme:
  - 🟢 `occupied` = Green (active lease)
  - 🔴 `vacant` = Red (available)
  - 🟠 `maintenance` = Orange (temporarily unavailable)
- **Default**: New units default to `vacant`

### State Transitions
```
vacant → occupied     (when lease created - future module)
occupied → vacant     (when lease terminated - future module)
vacant → maintenance  (manual status change)
maintenance → vacant  (manual status change)
occupied → maintenance (NOT ALLOWED - must terminate lease first)
```

### Alternatives Considered
| Option | Rejected Because |
|--------|------------------|
| Boolean `is_occupied` | Doesn't capture maintenance state |
| Separate maintenance flag | More complex queries, two fields to maintain |

---

## 6. Building total_units Auto-Update

### Decision
Use database trigger to maintain `buildings.total_units` count.

### Rationale
- **Specification FR-011**: "System MUST update the building's total units count when units are added or removed"
- **Data integrity**: Trigger ensures count is always accurate, even for direct DB operations
- **Performance**: Avoids counting on every building read

### Implementation
```sql
-- Trigger function
CREATE OR REPLACE FUNCTION update_building_total_units()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE buildings SET total_units = total_units + 1 WHERE id = NEW.building_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE buildings SET total_units = total_units - 1 WHERE id = OLD.building_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

### Alternatives Considered
| Option | Rejected Because |
|--------|------------------|
| Calculate count on read | Performance penalty for large buildings; N+1 queries |
| Update count in application | Risk of inconsistency; doesn't handle direct DB changes |

---

## 7. RLS Policy Pattern

### Decision
Follow building RLS pattern with role-based access.

### Rationale
- **Constitution Principle III**: RLS must be enabled and role-based
- **Consistency**: Same pattern as buildings table
- **Unit access through building**: User can access units if they can access the parent building

### Policies
1. **Admin**: Full access to all units
2. **Gestionnaire**: Full access to units in their buildings (`buildings.created_by = auth.uid()`)
3. **Assistant**: Read-only access to all units

### Implementation Note
Units RLS checks building ownership via join:
```sql
-- Gestionnaire policy uses subquery to check building ownership
EXISTS (
  SELECT 1 FROM buildings
  WHERE buildings.id = units.building_id
  AND buildings.created_by = auth.uid()
)
```

---

## 8. Pagination Strategy

### Decision
Use cursor-based pagination for unit lists.

### Rationale
- **Specification FR-018**: "System MUST support pagination/lazy loading for buildings with many units (50+ units)"
- **Consistency**: Match building list pagination pattern
- **Performance**: Efficient for large lists using indexed `created_at` cursor

### Implementation
- Default page size: 20 units
- Order by: `created_at DESC` (newest first)
- Cursor: UUID of last item

---

## 9. Form Validation Rules

### Decision
Client-side validation with server-side constraints as backup.

### Rationale
- **Constitution Principle V**: "Input validation MUST occur on both client (UX) and server (RLS/constraints) sides"
- **Immediate feedback**: French error messages for UX
- **Database constraints**: Final safeguard

### Validation Rules
| Field | Client | Server Constraint |
|-------|--------|-------------------|
| reference | Required, max 50 chars | `NOT NULL`, `CHECK char_length <= 50` |
| base_rent | Required, positive number | `NOT NULL`, `CHECK base_rent > 0` |
| type | Required, enum selection | `CHECK type IN ('residential', 'commercial')` |
| surface_area | Optional, positive if provided | `CHECK surface_area > 0 OR surface_area IS NULL` |
| rooms_count | Optional, positive integer | `CHECK rooms_count >= 0 OR rooms_count IS NULL` |
| floor | Optional, integer (negative allowed) | No constraint |

---

## 10. Currency Formatting

### Decision
Use existing CFA Franc formatter from `formatters.dart`.

### Rationale
- **Constitution Principle IV**: Currency displays as "FCFA" with space thousands separator
- **Existing infrastructure**: `formatters.dart` already has currency utilities

### Format Examples
- `150000` → `150 000 FCFA`
- `25000.50` → `25 000 FCFA` (round to nearest integer for display)

---

## Summary

All research topics are resolved. No NEEDS CLARIFICATION items remain. The module follows established patterns from Building Management with unit-specific adaptations for:
- Unique reference constraint per building
- Equipment as JSON array
- Status-based visual indicators
- Trigger-maintained total_units count
- Nested RLS via building ownership

Ready to proceed with Phase 1: Data Model and Contracts.
