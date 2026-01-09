# Feature Specification: Génération de Quittances PDF

**Feature Branch**: `007-pdf-receipt-generation`
**Created**: 2026-01-09
**Status**: Draft
**Input**: User description: "Génération de quittances PDF pour les paiements de loyer - Phase 9 du plan de développement LocaGest"

## Contexte

Dans le contexte de la gestion locative en Côte d'Ivoire, la quittance de loyer est un document légal obligatoire que le propriétaire ou le gestionnaire doit fournir au locataire après chaque paiement de loyer. Ce document atteste que le locataire a bien payé son loyer pour une période donnée.

LocaGest doit permettre aux gestionnaires de générer automatiquement ces quittances au format PDF, de les prévisualiser, les télécharger, les sauvegarder et les partager avec les locataires.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Générer une quittance après paiement (Priority: P1)

En tant que gestionnaire, après avoir enregistré un paiement de loyer, je veux pouvoir générer immédiatement une quittance PDF pour le locataire afin de lui fournir un justificatif de paiement.

**Why this priority**: C'est la fonctionnalité principale demandée. Sans génération de quittance, le module n'a pas de valeur. C'est également une obligation légale pour les gestionnaires.

**Independent Test**: Après avoir enregistré un paiement sur une échéance, cliquer sur "Générer quittance" et vérifier qu'un PDF est généré avec toutes les informations correctes (locataire, montant, période, adresse du bien).

**Acceptance Scenarios**:

1. **Given** un paiement vient d'être enregistré avec succès, **When** le gestionnaire clique sur "Générer quittance", **Then** un PDF de quittance est généré avec les informations du paiement, du locataire et du bien loué.

2. **Given** un paiement partiel a été enregistré, **When** le gestionnaire génère une quittance, **Then** la quittance indique clairement le montant payé et mentionne qu'il s'agit d'un paiement partiel avec le solde restant.

3. **Given** plusieurs paiements ont été effectués pour une même échéance, **When** le gestionnaire génère une quittance depuis l'historique, **Then** il peut générer une quittance pour le paiement sélectionné.

---

### User Story 2 - Prévisualiser et télécharger la quittance (Priority: P1)

En tant que gestionnaire, je veux pouvoir prévisualiser la quittance avant de la télécharger ou de la partager, afin de vérifier que toutes les informations sont correctes.

**Why this priority**: Essentielle pour l'expérience utilisateur. Le gestionnaire doit voir le document avant de le partager avec le locataire.

**Independent Test**: Après génération, vérifier que l'aperçu s'affiche correctement et que le téléchargement produit un fichier PDF valide.

**Acceptance Scenarios**:

1. **Given** une quittance a été générée, **When** le gestionnaire clique sur "Aperçu", **Then** le PDF s'affiche dans une vue de prévisualisation plein écran.

2. **Given** la prévisualisation est affichée, **When** le gestionnaire clique sur "Télécharger", **Then** le fichier PDF est téléchargé sur l'appareil avec un nom explicite (ex: "Quittance_Janvier2026_NomLocataire.pdf").

3. **Given** la prévisualisation est affichée, **When** le gestionnaire clique sur "Imprimer", **Then** la boîte de dialogue d'impression du système s'ouvre.

---

### User Story 3 - Sauvegarder la quittance dans le système (Priority: P2)

En tant que gestionnaire, je veux que les quittances générées soient automatiquement sauvegardées dans le système, afin de pouvoir les retrouver et les renvoyer ultérieurement si nécessaire.

**Why this priority**: Important pour l'archivage et la traçabilité, mais le système peut fonctionner initialement sans cette fonctionnalité.

**Independent Test**: Générer une quittance, puis retrouver cette quittance dans l'historique des documents du bail ou du paiement.

**Acceptance Scenarios**:

1. **Given** une quittance est générée, **When** le gestionnaire confirme la sauvegarde, **Then** le document est automatiquement sauvegardé et associé au paiement correspondant.

2. **Given** des quittances ont été générées pour un bail, **When** le gestionnaire consulte le détail du bail, **Then** il voit la liste des quittances générées avec leur date et peut les télécharger à nouveau.

3. **Given** un locataire demande une copie d'une ancienne quittance, **When** le gestionnaire recherche dans l'historique, **Then** il peut retrouver et renvoyer la quittance originale.

---

### User Story 4 - Partager la quittance avec le locataire (Priority: P2)

En tant que gestionnaire, je veux pouvoir partager facilement la quittance avec le locataire par email ou messagerie (WhatsApp), afin de lui transmettre son justificatif rapidement.

**Why this priority**: Améliore significativement l'expérience utilisateur en évitant les manipulations manuelles, mais pas bloquante pour une première version.

**Independent Test**: Depuis l'aperçu de la quittance, utiliser l'option de partage et vérifier que le document est envoyé via le canal choisi.

**Acceptance Scenarios**:

1. **Given** une quittance est en prévisualisation, **When** le gestionnaire clique sur "Partager", **Then** les options de partage disponibles sur l'appareil s'affichent (email, WhatsApp, autres applications).

2. **Given** le gestionnaire choisit "Envoyer par email", **When** l'application de messagerie s'ouvre, **Then** le PDF est attaché automatiquement et l'adresse email du locataire est pré-remplie (si disponible).

3. **Given** le gestionnaire choisit "Partager via WhatsApp", **When** WhatsApp s'ouvre, **Then** le PDF est prêt à être envoyé avec un message pré-formaté.

---

### User Story 5 - Consulter l'historique des quittances d'un locataire (Priority: P3)

En tant que gestionnaire, je veux pouvoir consulter toutes les quittances générées pour un locataire donné, afin d'avoir une vue complète de son historique de paiements documentés.

**Why this priority**: Fonctionnalité de confort qui améliore la gestion mais n'est pas critique pour le MVP.

**Independent Test**: Accéder à la fiche d'un locataire et vérifier que la liste des quittances générées est visible et accessible.

**Acceptance Scenarios**:

1. **Given** un locataire a plusieurs quittances générées, **When** le gestionnaire consulte sa fiche, **Then** une section "Quittances" affiche la liste des documents avec date et période concernée.

2. **Given** la liste des quittances est affichée, **When** le gestionnaire clique sur une quittance, **Then** l'aperçu du PDF s'ouvre.

---

### Edge Cases

- **Paiement partiel**: La quittance doit mentionner clairement qu'il s'agit d'un acompte et indiquer le solde restant dû.
- **Paiement en retard**: La quittance ne doit pas mentionner le retard (c'est un justificatif de paiement, pas une mise en demeure).
- **Locataire sans email**: Le partage par email n'est pas pré-rempli, le gestionnaire peut saisir une adresse manuellement ou utiliser un autre canal.
- **Erreur de génération**: Si la génération échoue, un message d'erreur clair s'affiche avec la possibilité de réessayer.
- **Quittance pour paiement supprimé**: Si le paiement associé est supprimé, la quittance reste accessible dans l'historique mais est marquée comme "Paiement annulé".
- **Génération hors connexion**: Informer l'utilisateur que la génération nécessite une connexion pour récupérer les données à jour.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre de générer une quittance PDF après l'enregistrement d'un paiement.
- **FR-002**: La quittance DOIT contenir les informations suivantes:
  - Nom et coordonnées du bailleur/gestionnaire
  - Nom et prénom du locataire
  - Adresse complète du bien loué (immeuble, lot, ville)
  - Période concernée (mois et année)
  - Montant du loyer (hors charges)
  - Montant des charges
  - Montant total payé
  - Date du paiement
  - Mode de paiement
  - Numéro de reçu
- **FR-003**: La quittance DOIT afficher la mention légale "Pour valoir ce que de droit" et la date de génération.
- **FR-004**: Le système DOIT permettre de prévisualiser le PDF avant téléchargement ou partage.
- **FR-005**: Le système DOIT permettre de télécharger le PDF sur l'appareil de l'utilisateur.
- **FR-006**: Le système DOIT permettre d'imprimer directement la quittance.
- **FR-007**: Le système DOIT sauvegarder automatiquement les quittances générées dans le stockage cloud.
- **FR-008**: Le système DOIT permettre de retrouver les quittances générées depuis le détail d'un bail ou d'un paiement.
- **FR-009**: Le système DOIT permettre de partager la quittance via les applications de l'appareil (email, WhatsApp, etc.).
- **FR-010**: Pour un paiement partiel, la quittance DOIT mentionner "Acompte" et indiquer le montant restant dû.
- **FR-011**: Le nom du fichier PDF DOIT suivre le format: "Quittance_[Periode]_[NomLocataire].pdf" (ex: "Quittance_Janvier2026_KONAN.pdf").
- **FR-012**: Le système DOIT afficher le bouton "Générer quittance" dans le message de succès après enregistrement d'un paiement.
- **FR-013**: Le système DOIT permettre de régénérer une quittance pour un paiement existant depuis l'historique des paiements.

### Key Entities

- **Receipt (Quittance)**: Document PDF généré attestant d'un paiement. Attributs: identifiant unique, référence au paiement, URL du fichier stocké, date de génération, statut (valide/annulée).
- **Payment (Paiement)**: Paiement de loyer existant. La quittance est générée à partir des données du paiement et de l'échéance associée.
- **Lease (Bail)**: Contrat de location contenant les informations du locataire et du bien loué nécessaires pour la quittance.
- **Tenant (Locataire)**: Personne ayant effectué le paiement, dont le nom apparaît sur la quittance.
- **Unit (Lot)**: Bien loué dont l'adresse apparaît sur la quittance.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Les gestionnaires peuvent générer une quittance PDF en moins de 5 secondes après un paiement.
- **SC-002**: 100% des quittances générées contiennent toutes les informations légales requises (bailleur, locataire, bien, période, montant, date).
- **SC-003**: Les quittances sont accessibles et téléchargeables dans les 30 jours suivant leur génération sans perte de données.
- **SC-004**: Le partage par email ou messagerie fonctionne sur 95% des appareils mobiles (Android et iOS).
- **SC-005**: Les gestionnaires peuvent retrouver une quittance archivée en moins de 3 clics depuis la fiche du bail.
- **SC-006**: Le format de la quittance est professionnel et conforme aux pratiques locales en Côte d'Ivoire.

## Assumptions

- Le gestionnaire connecté a les droits nécessaires pour générer des quittances (rôle admin ou gestionnaire).
- Les informations du bailleur/gestionnaire sont disponibles dans le profil de l'utilisateur connecté ou dans une configuration du système.
- La connexion internet est disponible pour la sauvegarde cloud des quittances.
- Le stockage cloud utilise le bucket `documents` existant dans Supabase Storage.
- La langue des quittances est le français.
- La devise affichée est le FCFA avec le formatage standard (XXX XXX FCFA).

## Out of Scope

- Génération automatique de quittances sans action de l'utilisateur.
- Envoi automatique par email/SMS au locataire sans action du gestionnaire.
- Personnalisation du template de quittance par l'utilisateur.
- Signature électronique sur la quittance.
- Génération de quittances en lot (batch).
- Quittances pour d'autres types de paiements (dépôt de garantie, charges exceptionnelles).
