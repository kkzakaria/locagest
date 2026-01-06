# Feature Specification: Building Management (Gestion des Immeubles)

**Feature Branch**: `002-building-management`
**Created**: 2026-01-06
**Status**: Draft
**Input**: User description: "Implement building management with CRUD operations for property managers"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Add New Building (Priority: P1)

As a property manager (gestionnaire), I want to register a new building in the system so that I can start managing its units and tenants.

The manager opens the buildings section, taps the "Add Building" button, fills in the building details (name, address, city, optional photo), and saves. The building appears in their list immediately and they can start adding units to it.

**Why this priority**: This is the foundational action for all property management. Without buildings, no units, tenants, or leases can be created. This enables the entire downstream workflow.

**Independent Test**: Can be fully tested by creating a building and verifying it appears in the buildings list. Delivers immediate value by establishing the property portfolio.

**Acceptance Scenarios**:

1. **Given** an authenticated gestionnaire with no buildings, **When** they tap "Ajouter un immeuble" and complete the form with valid data, **Then** the building is saved and displayed in the buildings list with status confirmed.
2. **Given** a gestionnaire filling the building form, **When** they submit with a missing required field (name, address, or city), **Then** an error message in French indicates which field is missing and the form is not submitted.
3. **Given** a gestionnaire adding a building, **When** they optionally upload a photo, **Then** the photo is stored securely and displayed as a thumbnail in the building card.

---

### User Story 2 - View Buildings List (Priority: P1)

As a property manager, I want to see all my buildings at a glance so that I can quickly access any property I manage.

The manager opens the app and navigates to the buildings section. They see a list of all buildings they have access to, each showing the building name, address, and number of units. They can tap any building to see its details.

**Why this priority**: Viewing buildings is required to navigate to any downstream feature (units, tenants, leases). Tied with P1 because create and view must work together.

**Independent Test**: Can be fully tested by displaying a list of existing buildings with key information. Delivers value by providing portfolio overview.

**Acceptance Scenarios**:

1. **Given** a gestionnaire with 5 buildings registered, **When** they open the buildings list, **Then** all 5 buildings are displayed with name, address, city, and unit count.
2. **Given** a gestionnaire with no buildings, **When** they open the buildings list, **Then** an empty state message in French encourages them to add their first building.
3. **Given** a gestionnaire with 50+ buildings, **When** they scroll the list, **Then** buildings load progressively without freezing the interface.

---

### User Story 3 - View Building Details (Priority: P2)

As a property manager, I want to view complete details of a building so that I can review its information and access its units.

The manager taps on a building from the list. They see the full building information: name, complete address, photo (if uploaded), notes, creation date, and a summary showing total units and occupancy status.

**Why this priority**: Essential for navigating to units and understanding building status. Required before unit management can be used effectively.

**Independent Test**: Can be tested by tapping a building and verifying all stored data is displayed correctly.

**Acceptance Scenarios**:

1. **Given** a building with all fields populated, **When** the manager views its details, **Then** all information is displayed including photo, address, notes, and unit summary.
2. **Given** a building with units, **When** viewing details, **Then** a summary shows total units, occupied count, vacant count, and units under maintenance.
3. **Given** a building detail page, **When** the manager taps "Voir les lots", **Then** they are navigated to the units list filtered for that building.

---

### User Story 4 - Edit Building Information (Priority: P2)

As a property manager, I want to update a building's information so that I can correct errors or reflect changes (e.g., address change, new photo).

The manager opens a building's details, taps the edit button, modifies the desired fields, and saves. The changes are reflected immediately.

**Why this priority**: Important for data accuracy but not blocking for initial setup flow. Buildings rarely change after initial creation.

**Independent Test**: Can be tested by modifying a building's name and verifying the change persists.

**Acceptance Scenarios**:

1. **Given** a building with name "Résidence Palm", **When** the manager changes the name to "Résidence Les Palmiers" and saves, **Then** the new name is displayed everywhere the building appears.
2. **Given** a building with a photo, **When** the manager uploads a new photo, **Then** the old photo is replaced and the new one is displayed.
3. **Given** a manager editing a building, **When** they clear a required field and try to save, **Then** validation prevents saving and shows an error in French.

---

### User Story 5 - Delete Building (Priority: P3)

As a property manager, I want to delete a building I no longer manage so that my portfolio stays clean and accurate.

The manager opens a building's details, taps delete, confirms the action in a dialog, and the building is removed from their list.

**Why this priority**: Lower priority because deletion is rare and has significant implications. Most users archive rather than delete.

**Independent Test**: Can be tested by deleting a building with no units and verifying it disappears from the list.

**Acceptance Scenarios**:

1. **Given** a building with no units, **When** the manager taps delete and confirms, **Then** the building is permanently removed from the system.
2. **Given** a building with active units, **When** the manager attempts to delete, **Then** the system prevents deletion and displays a message explaining units must be removed first.
3. **Given** the delete confirmation dialog, **When** the manager taps "Annuler", **Then** the dialog closes and the building remains unchanged.

---

### Edge Cases

- What happens when the user loses internet connection while saving a building? The system should display a French error message and allow retry without losing entered data.
- What happens when the photo upload exceeds size limits? The system should compress the image automatically or display a message asking for a smaller image.
- What happens when two users edit the same building simultaneously? The last save wins, and the user sees the most recent data on next view.
- What happens when a building name already exists? The system allows duplicate names (different addresses distinguish buildings).
- What happens when the user navigates away during form entry? Unsaved data is lost (standard behavior, no draft saving required).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow authenticated users with role "admin" or "gestionnaire" to create new buildings.
- **FR-002**: System MUST require building name, street address, and city as mandatory fields.
- **FR-003**: System MUST accept optional fields: postal code, country (default: "Côte d'Ivoire"), photo, and notes.
- **FR-004**: System MUST display all buildings the current user has permission to view.
- **FR-005**: System MUST show building card with name, address, city, and unit count on the list view.
- **FR-006**: System MUST allow users to view full building details including all fields and unit summary.
- **FR-007**: System MUST allow users with appropriate permissions to edit any building field.
- **FR-008**: System MUST track and display when a building was created and last updated.
- **FR-009**: System MUST prevent deletion of buildings that contain units.
- **FR-010**: System MUST require confirmation before deleting a building.
- **FR-011**: System MUST validate form inputs and display errors in French.
- **FR-012**: System MUST automatically update the total_units count when units are added or removed.
- **FR-013**: System MUST store building photos in secure private storage with appropriate access controls.
- **FR-014**: System MUST support users managing up to 200 buildings without performance degradation.
- **FR-015**: Users with role "assistant" MUST have read-only access to buildings (view only, no create/edit/delete).

### Key Entities

- **Building (Immeuble)**: Represents a physical property containing rental units. Key attributes: name, address (street, city, postal code, country), photo, notes, unit count, ownership/creation tracking.
- **User (Profile)**: The property manager who created/manages the building. Relationship: A user can manage many buildings; a building is created by one user.
- **Unit (Lot)**: Individual rental spaces within a building. Relationship: A building contains zero to many units. (Not implemented in this feature, but referenced.)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Property managers can add a new building in under 60 seconds (form completion to confirmation).
- **SC-002**: Building list loads and displays within 2 seconds for portfolios up to 100 buildings.
- **SC-003**: 95% of users successfully create their first building on their first attempt without errors.
- **SC-004**: All building CRUD operations provide visual feedback within 500ms of user action.
- **SC-005**: Building photo uploads complete within 10 seconds for images up to 5MB.
- **SC-006**: Zero data loss when network interruption occurs mid-save (graceful error handling).
- **SC-007**: Users can locate a specific building from a list of 50+ in under 5 seconds using visual scanning.

## Assumptions

- Buildings are single structures; multi-building complexes are registered as separate buildings.
- The address format follows standard Ivory Coast conventions (street, city, optional postal code).
- Photo storage uses the same infrastructure as other document storage in the application.
- Role-based permissions are already implemented from the authentication feature (001-user-auth).
- The navigation structure places buildings as a primary section accessible from the main menu.
- Country defaults to "Côte d'Ivoire" as this is the primary market.
- Building deletion is a rare operation; no soft-delete or archiving is needed for MVP.

## Dependencies

- **001-user-auth**: Authentication and role-based authorization must be implemented before this feature.
- **Database setup**: The buildings table with RLS policies must be created as part of this feature.
- **Storage setup**: Private bucket for building photos must be configured.

## Out of Scope

- Unit management within buildings (separate feature: 003-unit-management)
- Building-level financial summaries or reports
- Bulk import of buildings from external sources
- Map integration or geocoding of addresses
- Building document storage (beyond the single photo)
- Multi-language support (French only per constitution)
