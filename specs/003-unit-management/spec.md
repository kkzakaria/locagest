# Feature Specification: Module Lots/Unités (Unit Management)

**Feature Branch**: `003-unit-management`
**Created**: 2026-01-07
**Status**: Draft
**Input**: User description: "Module Lots/Unités - CRUD des lots liés aux immeubles @PLAN-DEV-LocaGest.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Units List within a Building (Priority: P1)

As a property manager (gestionnaire), I need to see all rental units within a specific building so I can understand the building's rental inventory and availability at a glance.

**Why this priority**: This is the foundational capability - without viewing units, no other operations are possible. Property managers need to quickly assess their portfolio.

**Independent Test**: Can be fully tested by navigating to a building detail page and verifying the units list displays correctly with all relevant information.

**Acceptance Scenarios**:

1. **Given** I am logged in and viewing a building's detail page, **When** I access the units section, **Then** I see a list of all units with their reference, type, floor, rent amount, and status displayed.
2. **Given** I am viewing a building with no units, **When** I access the units section, **Then** I see an empty state message inviting me to create the first unit.
3. **Given** I am viewing units in a building, **When** I look at a unit card, **Then** I can identify its status (vacant/occupied/maintenance) through a clear visual indicator (badge/color).

---

### User Story 2 - Create a New Unit (Priority: P1)

As a property manager, I need to register a new rental unit within a building so I can track and manage it in my portfolio.

**Why this priority**: Creating units is essential to populate the system. Without units, tenants cannot be assigned and rent cannot be collected.

**Independent Test**: Can be fully tested by filling out the unit creation form and verifying the unit appears in the building's unit list.

**Acceptance Scenarios**:

1. **Given** I am on a building's detail page, **When** I click "Add Unit", **Then** I see a form with fields for unit reference, type, floor, surface area, number of rooms, base rent, charges, and description.
2. **Given** I am filling the unit creation form, **When** I submit with valid required fields (reference, base rent, building association), **Then** the unit is created with status "vacant" and I see a success confirmation.
3. **Given** I am filling the unit creation form, **When** I submit without required fields, **Then** I see clear error messages in French indicating which fields are missing.
4. **Given** I have created a unit, **When** I return to the building detail, **Then** the building's total units count is automatically updated.

---

### User Story 3 - View Unit Details (Priority: P2)

As a property manager, I need to see complete information about a specific unit so I can make informed decisions about pricing, availability, and tenant assignment.

**Why this priority**: Detailed unit information is essential for operational decisions but depends on units existing first.

**Independent Test**: Can be fully tested by clicking on a unit and verifying all stored information is displayed accurately.

**Acceptance Scenarios**:

1. **Given** I am viewing a unit list, **When** I tap on a unit, **Then** I see a detail page showing all unit information: reference, type, floor, surface area, rooms, rent, charges, status, description, and equipment.
2. **Given** I am viewing a unit's detail page, **When** the unit has photos attached, **Then** I can view them in a gallery format.
3. **Given** I am viewing a unit's detail page, **When** I look at the financial information, **Then** I see the base rent and charges displayed in proper currency format (CFA Franc).

---

### User Story 4 - Edit Unit Information (Priority: P2)

As a property manager, I need to update unit information when conditions change (rent adjustment, renovation, new equipment) so my records stay accurate.

**Why this priority**: Property details change over time - rent adjustments, renovations, equipment additions. Keeping data current is essential for accurate reporting.

**Independent Test**: Can be fully tested by modifying unit fields and verifying changes persist after saving.

**Acceptance Scenarios**:

1. **Given** I am viewing a unit's detail page, **When** I click "Edit", **Then** I see a pre-filled form with all current unit data.
2. **Given** I am editing a unit, **When** I modify fields and save, **Then** the changes are persisted and I see a success confirmation.
3. **Given** I am editing a unit, **When** I change the status from "vacant" to "maintenance", **Then** the status badge updates accordingly on all views.

---

### User Story 5 - Delete a Unit (Priority: P3)

As a property manager, I need to remove a unit that no longer exists (demolished, merged, or incorrectly created) so my portfolio accurately reflects reality.

**Why this priority**: Deletion is less frequent than other operations. Most units are permanent. This is a maintenance operation.

**Independent Test**: Can be fully tested by deleting a vacant unit and verifying it no longer appears in the building's unit list.

**Acceptance Scenarios**:

1. **Given** I am viewing a vacant unit's detail page, **When** I click "Delete", **Then** I see a confirmation dialog in French warning this action is irreversible.
2. **Given** I confirm unit deletion, **When** the unit has no active lease, **Then** the unit is removed and the building's unit count decreases.
3. **Given** I attempt to delete a unit, **When** the unit has an active lease, **Then** I see an error message explaining the unit cannot be deleted while occupied.

---

### User Story 6 - Manage Unit Photos (Priority: P3)

As a property manager, I need to upload and manage photos of a unit so I can document its condition and have visual references for marketing or inventory purposes.

**Why this priority**: Photos enhance the system but are not blocking for core rental management workflows.

**Independent Test**: Can be fully tested by uploading photos to a unit and verifying they appear in the unit's gallery.

**Acceptance Scenarios**:

1. **Given** I am editing or creating a unit, **When** I add photos from my device, **Then** the photos are compressed and uploaded, showing upload progress.
2. **Given** I am viewing a unit's photos, **When** I want to remove a photo, **Then** I can delete it with confirmation.
3. **Given** I am uploading a photo, **When** the file exceeds acceptable size limits, **Then** it is automatically compressed before upload.

---

### User Story 7 - Manage Unit Equipment List (Priority: P3)

As a property manager, I need to record what equipment/amenities are included in a unit (kitchen appliances, air conditioning, parking, etc.) so this information is available for lease documents and tenant communication.

**Why this priority**: Equipment tracking is useful for documentation but does not block core rental operations.

**Independent Test**: Can be fully tested by adding equipment items to a unit and verifying they appear in the unit details.

**Acceptance Scenarios**:

1. **Given** I am editing a unit, **When** I access the equipment section, **Then** I can add, edit, or remove equipment items from a list.
2. **Given** I am adding equipment, **When** I type an item name, **Then** it is added to the unit's equipment list.
3. **Given** I am viewing unit details, **When** equipment exists, **Then** I see the list of equipment items clearly displayed.

---

### Edge Cases

- What happens when a user tries to create a unit with a duplicate reference within the same building? → System prevents creation and shows an error.
- What happens when a user tries to delete a building that contains units? → The deletion cascades and removes all associated units (with appropriate warning).
- How does the system handle very large surface area values? → Values are capped at reasonable limits with validation.
- What happens when the unit photos storage quota is exceeded? → User is notified and cannot upload additional photos until space is freed.
- What happens when creating a unit and the building has reached maximum units? → System allows unlimited units per building (no artificial limit).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow authenticated users with appropriate roles (admin, gestionnaire) to create units within a building.
- **FR-002**: System MUST require a unit reference and base rent as mandatory fields when creating a unit.
- **FR-003**: System MUST automatically associate each unit with exactly one building (many-to-one relationship).
- **FR-004**: System MUST support unit types: "residential" (résidentiel) or "commercial".
- **FR-005**: System MUST track unit status with values: "vacant" (disponible), "occupied" (occupé), or "maintenance" (en maintenance).
- **FR-006**: System MUST display unit status with distinct visual indicators (colored badges).
- **FR-007**: System MUST prevent deletion of units that have active leases.
- **FR-008**: System MUST enforce unique unit references within the same building.
- **FR-009**: System MUST allow storing multiple photos per unit with automatic compression.
- **FR-010**: System MUST store equipment as a list of items per unit.
- **FR-011**: System MUST update the building's total units count when units are added or removed.
- **FR-012**: System MUST support floor number tracking (positive integers for above ground, negative or zero for underground).
- **FR-013**: System MUST store surface area in square meters with up to 2 decimal places.
- **FR-014**: System MUST store rent and charges amounts with appropriate precision for CFA Franc currency.
- **FR-015**: System MUST display all user-facing text in French.
- **FR-016**: System MUST format dates as DD/MM/YYYY in all displays.
- **FR-017**: System MUST respect role-based access: assistants have read-only access, gestionnaires and admins have full CRUD access.
- **FR-018**: System MUST support pagination/lazy loading for buildings with many units (50+ units).
- **FR-019**: System MUST provide form validation with clear French error messages.
- **FR-020**: System MUST show loading states during data operations.
- **FR-021**: System MUST show empty states when no units exist in a building.
- **FR-022**: System MUST allow tracking whether charges are included in rent or separate.

### Key Entities

- **Unit (Lot)**: A rentable space within a building. Attributes include: reference (unique within building), type (residential/commercial), floor, surface area, room count, base rent, charges amount, charges included flag, status, description, equipment list, and photos.
- **Building (Immeuble)**: Parent entity that contains units. A building has many units. Building's total_units count reflects the number of associated units.
- **Unit Status**: Represents the current state of a unit - vacant (available for new tenants), occupied (has an active lease), or maintenance (temporarily unavailable).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a new unit with all required fields in under 2 minutes.
- **SC-002**: Users can view a building's unit list and identify vacant units in under 5 seconds.
- **SC-003**: Unit list displays correctly for buildings with up to 100 units without performance issues.
- **SC-004**: 100% of form submissions provide clear feedback (success or error) within 3 seconds.
- **SC-005**: Photo upload completes within 10 seconds for typical smartphone images.
- **SC-006**: Unit status changes reflect immediately across all views without requiring page refresh.
- **SC-007**: Users with assistant role cannot access create/edit/delete functions (0% unauthorized access).
- **SC-008**: All unit data persists correctly across app sessions (0% data loss).
- **SC-009**: Unit deletion is prevented 100% of the time when an active lease exists.
- **SC-010**: Building total_units count is accurate 100% of the time after unit creation or deletion.

## Assumptions

- Currency is CFA Franc (FCFA) - standard for Ivory Coast target market.
- Building management module is already implemented and functional (Phase 4 complete).
- User authentication and role-based access control are already implemented (Phase 3 complete).
- Photo storage uses existing Supabase storage infrastructure established in building management.
- The system targets property managers handling 50-150 units, so performance is optimized for this scale.
- Equipment items are stored as simple text strings (no predefined equipment catalog needed at this stage).
- Unit references follow user-defined conventions (no system-enforced format).
- Charges can be either included in rent or tracked separately based on lease arrangement.

## Dependencies

- Building Management Module (Phase 4) - must be complete to associate units with buildings.
- User Authentication Module (Phase 3) - required for role-based access control.
- Supabase Storage - required for photo upload functionality.

## Out of Scope

- Tenant assignment to units (handled in Lease Management module).
- Rent collection and payment tracking (handled in Payments module).
- Unit availability calendar or booking system.
- Automated rent pricing suggestions.
- Unit comparison features.
- Export of unit data to external formats.
- Unit search across all buildings (global search planned for later phase).
