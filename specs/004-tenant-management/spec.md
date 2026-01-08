# Feature Specification: Module Locataires (Tenant Management)

**Feature Branch**: `004-tenant-management`
**Created**: 2026-01-07
**Status**: Draft
**Input**: User description: "Module Locataires (Tenant Management) - Gestion des locataires pour l'application LocaGest. Fonctionnalités: CRUD locataires, informations personnelles (nom, prénom, email, téléphone principal/secondaire), documents d'identité (type CNI/passeport/carte de séjour, numéro, upload document), informations professionnelles (profession, employeur), garant (nom, téléphone, upload pièce d'identité), notes, historique des baux. Interface en français, contexte Côte d'Ivoire."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Tenants List (Priority: P1) MVP

Le gestionnaire immobilier souhaite consulter la liste de tous ses locataires pour avoir une vue d'ensemble de son portefeuille. La liste affiche les informations essentielles (nom complet, téléphone, statut du bail) et permet de rechercher rapidement un locataire.

**Why this priority**: C'est la fonctionnalité de base qui permet de naviguer et trouver les locataires. Sans cette vue, impossible d'accéder aux autres fonctionnalités. Indispensable pour le MVP.

**Independent Test**: Peut être testé en naviguant vers la page des locataires et en vérifiant que la liste s'affiche avec les informations de base de chaque locataire.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est connecté en tant que gestionnaire, **When** il accède à la page "Locataires", **Then** il voit une liste de tous les locataires avec nom complet, téléphone principal et statut (actif/inactif).
2. **Given** la liste des locataires est affichée, **When** l'utilisateur saisit un terme de recherche, **Then** la liste est filtrée pour afficher uniquement les locataires correspondants (par nom, prénom ou téléphone).
3. **Given** il n'y a aucun locataire enregistré, **When** l'utilisateur accède à la page "Locataires", **Then** un message "Aucun locataire" s'affiche avec un bouton "Ajouter un locataire".

---

### User Story 2 - Create a New Tenant (Priority: P1) MVP

Le gestionnaire souhaite enregistrer un nouveau locataire avec toutes ses informations personnelles, professionnelles et les informations de son garant pour pouvoir ensuite lui attribuer un logement via un bail.

**Why this priority**: L'ajout de locataires est fondamental pour créer des baux. C'est la deuxième étape du flux principal après avoir créé des biens (immeubles/lots).

**Independent Test**: Peut être testé en créant un nouveau locataire avec toutes les informations requises et en vérifiant qu'il apparaît dans la liste.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur la page des locataires, **When** il clique sur "Ajouter un locataire" et remplit le formulaire avec les champs obligatoires (nom, prénom, téléphone), **Then** le locataire est créé et apparaît dans la liste.
2. **Given** l'utilisateur remplit le formulaire de création, **When** il laisse un champ obligatoire vide et tente de sauvegarder, **Then** un message d'erreur en français indique le champ manquant.
3. **Given** l'utilisateur crée un locataire, **When** il ajoute une pièce d'identité avec upload de document, **Then** le document est enregistré et visible dans la fiche du locataire.
4. **Given** l'utilisateur crée un locataire, **When** il ajoute les informations du garant avec upload de pièce d'identité, **Then** les informations du garant sont enregistrées et visibles.

---

### User Story 3 - View Tenant Details (Priority: P2)

Le gestionnaire souhaite consulter toutes les informations d'un locataire spécifique, y compris ses documents d'identité, informations professionnelles, garant et historique des baux.

**Why this priority**: Permet d'accéder aux informations détaillées pour la gestion quotidienne. Nécessaire pour vérifier les informations avant de créer un bail ou contacter un locataire.

**Independent Test**: Peut être testé en cliquant sur un locataire dans la liste et en vérifiant que toutes ses informations s'affichent correctement.

**Acceptance Scenarios**:

1. **Given** la liste des locataires est affichée, **When** l'utilisateur clique sur un locataire, **Then** la page de détail s'affiche avec toutes les informations personnelles (nom, prénom, email, téléphones).
2. **Given** l'utilisateur consulte la fiche d'un locataire, **When** le locataire a un document d'identité enregistré, **Then** les informations (type, numéro) et un aperçu/lien vers le document sont affichés.
3. **Given** l'utilisateur consulte la fiche d'un locataire, **When** le locataire a un garant enregistré, **Then** les informations du garant (nom, téléphone, document) sont affichées.
4. **Given** l'utilisateur consulte la fiche d'un locataire, **When** le locataire a des baux (actifs ou passés), **Then** l'historique des baux est affiché avec le lot concerné et les dates.

---

### User Story 4 - Edit Tenant Information (Priority: P2)

Le gestionnaire souhaite modifier les informations d'un locataire existant pour mettre à jour ses coordonnées, documents ou informations professionnelles.

**Why this priority**: Les informations des locataires changent (nouveau téléphone, nouvel employeur, renouvellement de pièce d'identité). Essentiel pour maintenir des données à jour.

**Independent Test**: Peut être testé en modifiant les informations d'un locataire et en vérifiant que les changements sont persistés.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur la page de détail d'un locataire, **When** il clique sur "Modifier", **Then** un formulaire pré-rempli avec les informations actuelles s'affiche.
2. **Given** l'utilisateur modifie les informations, **When** il sauvegarde les modifications, **Then** les nouvelles informations sont enregistrées et affichées.
3. **Given** l'utilisateur modifie un document d'identité, **When** il uploade un nouveau document, **Then** l'ancien document est remplacé par le nouveau.

---

### User Story 5 - Delete a Tenant (Priority: P3)

Le gestionnaire souhaite supprimer un locataire qui n'a plus de bail actif pour maintenir une base de données propre.

**Why this priority**: Fonctionnalité de maintenance de la base de données. Moins critique car un locataire sans bail actif ne pose pas de problème opérationnel.

**Independent Test**: Peut être testé en supprimant un locataire sans bail actif et en vérifiant qu'il n'apparaît plus dans la liste.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur la page de détail d'un locataire sans bail actif, **When** il clique sur "Supprimer" et confirme, **Then** le locataire est supprimé de la base de données.
2. **Given** l'utilisateur tente de supprimer un locataire avec un bail actif, **When** il clique sur "Supprimer", **Then** un message d'erreur indique que le locataire ne peut pas être supprimé car il a un bail actif.
3. **Given** l'utilisateur clique sur "Supprimer", **When** une boîte de dialogue de confirmation s'affiche, **Then** l'utilisateur doit confirmer avant la suppression définitive.

---

### User Story 6 - Manage Identity Documents (Priority: P3)

Le gestionnaire souhaite gérer les documents d'identité des locataires (CNI, passeport, carte de séjour) avec upload sécurisé et visualisation.

**Why this priority**: Important pour la conformité et la vérification d'identité, mais peut être ajouté après les fonctionnalités de base du CRUD.

**Independent Test**: Peut être testé en uploadant, visualisant et remplaçant un document d'identité pour un locataire.

**Acceptance Scenarios**:

1. **Given** l'utilisateur édite un locataire, **When** il sélectionne un type de document (CNI, passeport, carte de séjour), **Then** il peut saisir le numéro et uploader une copie numérique.
2. **Given** un document est uploadé, **When** l'utilisateur consulte la fiche du locataire, **Then** il peut visualiser ou télécharger le document.
3. **Given** un document existe, **When** l'utilisateur uploade un nouveau document, **Then** l'ancien est remplacé.

---

### Edge Cases

- **Téléphone invalide**: Le système affiche un message d'erreur en français si le format de téléphone ne correspond pas aux formats acceptés (ivoirien +225 ou formats locaux 07/05/01).
- **Email invalide**: Le système valide le format email et affiche un message d'erreur si mal formaté.
- **Document trop volumineux**: Le système rejette les fichiers de plus de 5 Mo avec un message explicatif.
- **Format de document non supporté**: Le système n'accepte que JPEG, PNG et PDF pour les documents d'identité.
- **Suppression avec historique**: Un locataire avec uniquement des baux terminés (passés) peut être supprimé après confirmation.
- **Doublon de locataire**: Le système permet les doublons de téléphone (cas de famille) mais affiche un avertissement.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre de créer un locataire avec nom (obligatoire), prénom (obligatoire) et téléphone principal (obligatoire).
- **FR-002**: Le système DOIT permettre d'ajouter des informations optionnelles : email, téléphone secondaire, notes.
- **FR-003**: Le système DOIT permettre d'enregistrer les informations de pièce d'identité : type (CNI, passeport, carte de séjour), numéro, et copie numérique.
- **FR-004**: Le système DOIT permettre d'enregistrer les informations professionnelles : profession et employeur.
- **FR-005**: Le système DOIT permettre d'enregistrer les informations du garant : nom, téléphone et copie de pièce d'identité.
- **FR-006**: Le système DOIT afficher une liste de tous les locataires avec recherche par nom, prénom ou téléphone.
- **FR-007**: Le système DOIT afficher le statut du locataire (actif si bail en cours, inactif sinon).
- **FR-008**: Le système DOIT permettre de modifier toutes les informations d'un locataire existant.
- **FR-009**: Le système DOIT empêcher la suppression d'un locataire ayant un bail actif.
- **FR-010**: Le système DOIT permettre la suppression d'un locataire sans bail actif avec confirmation.
- **FR-011**: Le système DOIT afficher l'historique des baux dans la fiche du locataire.
- **FR-012**: Le système DOIT valider le format du téléphone (format ivoirien +225 ou format local).
- **FR-013**: Le système DOIT valider le format de l'email si fourni.
- **FR-014**: Le système DOIT limiter la taille des fichiers uploadés à 5 Mo maximum.
- **FR-015**: Le système DOIT accepter les formats d'image courants (JPEG, PNG) et PDF pour les documents.
- **FR-016**: L'interface DOIT être entièrement en français.
- **FR-017**: Le système DOIT restreindre l'accès selon les rôles (gestionnaire/admin: CRUD complet, assistant: lecture seule + ajout).

### Key Entities

- **Tenant (Locataire)**: Représente une personne physique pouvant louer un bien. Attributs clés : identité (nom, prénom), coordonnées (email, téléphones), document d'identité (type, numéro, copie), profession, employeur, informations garant, notes. Relation : peut avoir plusieurs baux (historique).

- **Identity Document (Pièce d'identité)**: Type de document (CNI, passeport, carte de séjour), numéro unique, copie numérique. Stocké comme partie intégrante du profil locataire.

- **Guarantor (Garant)**: Personne se portant caution pour le locataire. Attributs : nom complet, téléphone, copie de pièce d'identité. Stocké comme partie intégrante du profil locataire.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Les utilisateurs peuvent créer un nouveau locataire avec toutes les informations en moins de 3 minutes.
- **SC-002**: La recherche d'un locataire par nom ou téléphone retourne les résultats en moins de 1 seconde.
- **SC-003**: 100% des champs obligatoires sont validés avant la création/modification d'un locataire.
- **SC-004**: Les documents uploadés sont accessibles et téléchargeables à tout moment.
- **SC-005**: Le système empêche 100% des tentatives de suppression de locataires avec baux actifs.
- **SC-006**: L'historique des baux d'un locataire est complet et à jour.
- **SC-007**: Tous les messages d'erreur et labels sont affichés en français.

## Assumptions

- Le format de téléphone ivoirien standard est utilisé (+225 XX XX XX XX XX ou format local 07/05/01 XX XX XX XX).
- Les documents d'identité sont stockés de manière sécurisée avec accès restreint aux utilisateurs autorisés.
- Un locataire ne peut avoir qu'un seul garant à la fois (informations garant intégrées au profil).
- L'historique des baux est en lecture seule dans la fiche locataire (géré par le module Baux).
- La compression d'image sera appliquée aux uploads pour optimiser le stockage.
- Les locataires avec des baux terminés (historique) peuvent être conservés pour référence ou supprimés.

## Out of Scope

- Portail locataire (connexion des locataires à l'application).
- Envoi automatique de SMS ou emails aux locataires.
- Vérification automatique de l'authenticité des documents d'identité.
- Gestion multi-garants (un seul garant par locataire).
- Import en masse de locataires depuis un fichier Excel.
