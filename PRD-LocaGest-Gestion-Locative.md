# LOCAGEST

## Product Requirements Document (PRD)

### Application de Gestion Immobilière Locative

---

| Information | Valeur |
|-------------|--------|
| Version | 1.0 |
| Date | Janvier 2026 |
| Statut | Draft |
| Plateforme | Mobile (Flutter) + Web |

---

## Sommaire

1. [Vue d'ensemble](#1-vue-densemble)
2. [Contexte et objectifs](#2-contexte-et-objectifs)
3. [Personas et utilisateurs](#3-personas-et-utilisateurs)
4. [Périmètre fonctionnel](#4-périmètre-fonctionnel)
5. [User Stories](#5-user-stories)
6. [Modèle de données](#6-modèle-de-données)
7. [Architecture technique](#7-architecture-technique)
8. [Interfaces utilisateur](#8-interfaces-utilisateur)
9. [Roadmap et phases](#9-roadmap-et-phases)
10. [Métriques de succès](#10-métriques-de-succès)
11. [Risques et contraintes](#11-risques-et-contraintes)

---

## 1. Vue d'ensemble

### 1.1 Résumé exécutif

LocaGest est une application mobile et web de gestion immobilière locative conçue pour les gestionnaires professionnels indépendants. Elle permet de centraliser la gestion des biens (immeubles et lots), le suivi des locataires, la collecte des loyers, le suivi des dépenses et la génération de documents comptables.

### 1.2 Proposition de valeur

- Centralisation de toutes les informations immobilières en un seul endroit
- Suivi en temps réel des paiements et des impayés
- Génération automatique des quittances de loyer
- États des lieux numériques avec photos et signature électronique
- Rapports comptables pour faciliter les déclarations
- Accessibilité mobile pour la gestion en déplacement

---

## 2. Contexte et objectifs

### 2.1 Contexte

Le client est un gestionnaire immobilier indépendant qui gère actuellement environ 100 biens locatifs (appartements et locaux commerciaux). La gestion actuelle repose sur des outils disparates (Excel, documents papier) ce qui entraîne des pertes de temps, des erreurs et une difficulté à avoir une vue d'ensemble.

### 2.2 Objectifs métier

| Objectif | KPI cible |
|----------|-----------|
| Réduire le temps de gestion administrative | -50% en 6 mois |
| Améliorer le taux de recouvrement | >95% |
| Digitaliser les états des lieux | 100% numérique |
| Faciliter la génération de rapports | <5 min par rapport |

---

## 3. Personas et utilisateurs

### 3.1 Persona principal : Le Gestionnaire

- **Profil** : Professionnel indépendant gérant un portefeuille de 50-150 biens
- **Besoins** : Vue d'ensemble du portefeuille, alertes sur les impayés, génération rapide de documents
- **Frustrations** : Perte de temps sur les tâches administratives, difficulté à suivre les paiements
- **Objectifs** : Optimiser son temps, professionnaliser sa gestion, avoir des données fiables

### 3.2 Persona secondaire : L'Assistant/Collaborateur

- **Profil** : Employé ou collaborateur du gestionnaire avec des droits limités
- **Besoins** : Accès aux informations nécessaires pour ses tâches, saisie des données terrain
- **Frustrations** : Manque d'autonomie, dépendance au gestionnaire pour les informations
- **Objectifs** : Effectuer ses tâches efficacement, remonter les informations terrain

### 3.3 Matrice des rôles

| Fonctionnalité | Admin | Gestionnaire | Assistant |
|----------------|-------|--------------|-----------|
| Gestion utilisateurs | ✓ | — | — |
| CRUD Biens | ✓ | ✓ | Lecture |
| CRUD Locataires | ✓ | ✓ | ✓ |
| Enregistrer paiements | ✓ | ✓ | ✓ |
| États des lieux | ✓ | ✓ | ✓ |
| Rapports comptables | ✓ | ✓ | — |
| Paramètres | ✓ | Partiel | — |

---

## 4. Périmètre fonctionnel

### 4.1 Gestion des biens immobiliers

Le système doit permettre de gérer une structure hiérarchique : **Immeuble → Lots** (appartements, locaux commerciaux).

**Attributs d'un immeuble :**

- Nom, adresse complète, nombre de lots
- Photo de façade, documents associés (titre foncier, etc.)
- Charges communes (gardiennage, électricité parties communes...)

**Attributs d'un lot :**

- Référence, type (résidentiel/commercial), surface, étage
- Loyer de base, charges incluses (optionnel)
- Statut (vacant, occupé, en travaux)
- Photos, équipements, compteurs

### 4.2 Gestion des locataires et baux

**Informations locataire :**

- Identité complète (nom, prénom, contact, pièce d'identité)
- Garant (optionnel) : identité et coordonnées
- Documents : CNI, bulletins de salaire, contrat de travail

**Informations bail :**

- Date de début, durée, date de fin prévue
- Montant du loyer, dépôt de garantie
- Périodicité de paiement (mensuel), date d'échéance
- Clause de révision annuelle (optionnel)
- Document du bail signé (PDF)

### 4.3 Suivi des paiements

- Enregistrement des paiements : date, montant, mode (espèces, chèque), référence
- Gestion des paiements partiels et des reliquats
- Calcul automatique des arriérés
- Génération automatique des échéances mensuelles
- Alertes sur les impayés (paramétrable : 5, 10, 15 jours)
- Historique complet des paiements par locataire

### 4.4 Gestion des dépenses

- Catégories : réparations, entretien, taxes, assurances, charges communes
- Association à un bien (immeuble ou lot spécifique)
- Pièces justificatives (photos de factures)
- Répartition des charges entre locataires (optionnel, phase 2)

### 4.5 États des lieux

Fonctionnalité complète pour les états des lieux d'entrée et de sortie :

- Création par pièce (cuisine, salon, chambre 1, etc.)
- Pour chaque pièce : état général, équipements, observations
- Capture de photos avec annotations
- Relevé des compteurs (eau, électricité, gaz)
- Signature électronique (gestionnaire + locataire)
- Génération PDF automatique
- Comparaison entrée/sortie avec mise en évidence des différences

### 4.6 Documents et quittances

- Génération automatique de quittances de loyer (PDF)
- Personnalisation du modèle de quittance (logo, mentions légales)
- Historique des documents générés
- Export et partage (email, WhatsApp)

### 4.7 Rapports comptables

- Rapport de revenus par période (mensuel, trimestriel, annuel)
- Rapport de dépenses par catégorie et par bien
- Bilan net (revenus - dépenses)
- État des impayés
- Taux d'occupation
- Export PDF et Excel

---

## 5. User Stories

### 5.1 Gestion des biens

| ID | User Story | Priorité |
|----|------------|----------|
| US-01 | En tant que gestionnaire, je veux ajouter un immeuble avec ses informations pour organiser mon portefeuille | Must Have |
| US-02 | En tant que gestionnaire, je veux ajouter des lots à un immeuble pour détailler chaque unité locative | Must Have |
| US-03 | En tant que gestionnaire, je veux voir le statut de tous mes lots (occupé/vacant) sur un tableau de bord | Must Have |
| US-04 | En tant que gestionnaire, je veux filtrer mes biens par statut, type ou localisation | Should Have |

### 5.2 Gestion des locataires

| ID | User Story | Priorité |
|----|------------|----------|
| US-05 | En tant que gestionnaire, je veux créer une fiche locataire avec ses informations personnelles | Must Have |
| US-06 | En tant que gestionnaire, je veux associer un locataire à un lot via un bail | Must Have |
| US-07 | En tant que gestionnaire, je veux stocker les documents du locataire (CNI, contrat) | Should Have |
| US-08 | En tant que gestionnaire, je veux être alerté avant la fin d'un bail | Should Have |

### 5.3 Paiements

| ID | User Story | Priorité |
|----|------------|----------|
| US-09 | En tant que gestionnaire, je veux enregistrer un paiement de loyer rapidement | Must Have |
| US-10 | En tant que gestionnaire, je veux voir la liste des loyers impayés avec le nombre de jours de retard | Must Have |
| US-11 | En tant que gestionnaire, je veux générer une quittance après un paiement | Must Have |
| US-12 | En tant que gestionnaire, je veux recevoir une notification pour les loyers en retard | Should Have |

### 5.4 États des lieux

| ID | User Story | Priorité |
|----|------------|----------|
| US-13 | En tant que gestionnaire, je veux créer un état des lieux d'entrée pièce par pièce | Must Have |
| US-14 | En tant que gestionnaire, je veux prendre des photos et les annoter | Must Have |
| US-15 | En tant que gestionnaire, je veux faire signer électroniquement l'état des lieux | Must Have |
| US-16 | En tant que gestionnaire, je veux comparer l'état d'entrée et de sortie | Should Have |

---

## 6. Modèle de données

### 6.1 Schéma des entités principales

#### users

```
id, email, full_name, role (admin/gestionnaire/assistant), created_at
```

#### buildings (Immeubles)

```
id, name, address, city, postal_code, country, total_units, photo_url, created_by, created_at
```

#### units (Lots)

```
id, building_id (FK), reference, type (residential/commercial), floor, surface_area, base_rent, charges_included, status (vacant/occupied/maintenance), created_at
```

#### tenants (Locataires)

```
id, first_name, last_name, email, phone, id_number, id_document_url, guarantor_name, guarantor_phone, created_at
```

#### leases (Baux)

```
id, unit_id (FK), tenant_id (FK), start_date, end_date, rent_amount, deposit_amount, payment_day, status (active/terminated/pending), document_url, created_at
```

#### rent_schedules (Échéances)

```
id, lease_id (FK), due_date, amount_due, amount_paid, status (pending/partial/paid/overdue), created_at
```

#### payments (Paiements)

```
id, rent_schedule_id (FK), amount, payment_date, payment_method (cash/check), reference, receipt_url, created_by, created_at
```

#### expenses (Dépenses)

```
id, building_id (FK nullable), unit_id (FK nullable), category, description, amount, expense_date, receipt_url, created_by, created_at
```

#### inventory_reports (États des lieux)

```
id, lease_id (FK), type (entry/exit), report_date, meter_readings (JSON), tenant_signature_url, manager_signature_url, pdf_url, created_by, created_at
```

#### inventory_rooms (Pièces état des lieux)

```
id, inventory_report_id (FK), room_name, condition (good/fair/poor), equipment (JSON), observations, photos (JSON array)
```

### 6.2 Diagramme des relations

```
users
  │
  ├──< buildings
  │       │
  │       └──< units
  │              │
  │              └──< leases
  │                     │
  │                     ├──> tenants
  │                     │
  │                     ├──< rent_schedules
  │                     │        │
  │                     │        └──< payments
  │                     │
  │                     └──< inventory_reports
  │                              │
  │                              └──< inventory_rooms
  │
  └──< expenses (→ buildings ou units)
```

---

## 7. Architecture technique

### 7.1 Stack technologique

| Composant | Technologie |
|-----------|-------------|
| Frontend Mobile | Flutter (Dart) |
| Frontend Web | Flutter Web |
| Backend | Supabase (PostgreSQL + Auth + Storage + Edge Functions) |
| Base de données | PostgreSQL (via Supabase) |
| Stockage fichiers | Supabase Storage |
| Authentification | Supabase Auth |
| Génération PDF | pdf (Flutter) + Edge Functions |
| Notifications | Firebase Cloud Messaging (optionnel) |

### 7.2 Architecture applicative

L'application suit une architecture **Clean Architecture** avec les couches suivantes :

1. **Presentation Layer** : Widgets Flutter, state management (Riverpod ou Bloc)
2. **Domain Layer** : Use cases, entities, repository interfaces
3. **Data Layer** : Repository implementations, Supabase data sources

### 7.3 Sécurité

- Row Level Security (RLS) sur toutes les tables Supabase
- JWT pour l'authentification
- Policies basées sur les rôles utilisateurs
- Chiffrement des données sensibles
- Stockage sécurisé des documents (buckets privés)

### 7.4 Structure du projet Flutter

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── theme/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── pages/
│   ├── widgets/
│   └── providers/
└── main.dart
```

---

## 8. Interfaces utilisateur

### 8.1 Écrans principaux

| Écran | Description |
|-------|-------------|
| Dashboard | Vue d'ensemble : KPIs, alertes impayés, baux expirant, graphiques revenus |
| Liste Immeubles | Cards des immeubles avec photo, adresse, taux d'occupation |
| Détail Immeuble | Infos immeuble + liste des lots avec statut |
| Détail Lot | Infos lot, locataire actuel, historique paiements, états des lieux |
| Liste Locataires | Recherche et liste des locataires avec statut paiement |
| Fiche Locataire | Infos personnelles, bail actif, historique, documents |
| Paiements | Liste des échéances, filtres (impayés, mois), enregistrement rapide |
| État des lieux | Wizard multi-étapes : pièces, photos, compteurs, signature |
| Rapports | Sélection période, type de rapport, visualisation et export |
| Paramètres | Profil, utilisateurs, modèles documents, notifications |

### 8.2 Principes UX

- **Mobile-first** : interface optimisée pour l'utilisation terrain
- **Actions rapides** : enregistrer un paiement en moins de 3 taps
- **Feedback visuel clair** : codes couleur pour les statuts
- **Mode hors-ligne** : consultation des données essentielles sans connexion
- **Recherche globale** : trouver rapidement un bien ou locataire

### 8.3 Codes couleur des statuts

| Statut | Couleur |
|--------|---------|
| Payé / Occupé | 🟢 Vert |
| En attente | 🟡 Jaune |
| Impayé / Vacant | 🔴 Rouge |
| En travaux | 🟠 Orange |

---

## 9. Roadmap et phases

### 9.1 Phase 1 : MVP (2 semaines)

**Objectif** : Application fonctionnelle avec les features core

**Semaine 1 :**

1. Setup projet Flutter + Supabase
2. Authentification et gestion des rôles
3. CRUD Immeubles et Lots
4. CRUD Locataires et Baux

**Semaine 2 :**

1. Gestion des paiements et échéances
2. Génération de quittances PDF
3. Dashboard basique avec KPIs
4. Tests et corrections

### 9.2 Phase 2 : États des lieux (1 semaine)

- Module états des lieux complet
- Capture et annotation photos
- Signature électronique
- Génération PDF état des lieux

### 9.3 Phase 3 : Rapports et améliorations (1 semaine)

- Rapports comptables complets
- Export Excel
- Notifications push
- Gestion des dépenses avancée

### 9.4 Phase 4 : Évolutions futures

- Répartition des charges entre locataires
- Portail locataire (consultation quittances, signalement problèmes)
- Intégration comptable (export format comptable standard)
- Mode multi-propriétaires

---

## 10. Métriques de succès

| Métrique | Cible MVP | Cible 6 mois |
|----------|-----------|--------------|
| Temps enregistrement paiement | < 30 secondes | < 15 secondes |
| Taux adoption utilisateur | Usage quotidien | 100% des tâches |
| Temps génération quittance | < 5 secondes | < 3 secondes |
| Taux de recouvrement visible | Affiché en temps réel | > 95% |
| Satisfaction utilisateur | > 4/5 | > 4.5/5 |

---

## 11. Risques et contraintes

### 11.1 Risques identifiés

| Risque | Impact | Probabilité | Mitigation |
|--------|--------|-------------|------------|
| Connectivité terrain limitée | Élevé | Moyenne | Mode offline |
| Adoption utilisateur | Élevé | Faible | Formation, UX simple |
| Migration données existantes | Moyen | Élevée | Import Excel prévu |
| Performance avec volume | Moyen | Faible | Pagination, indexation |

### 11.2 Contraintes

- **Budget** : Solution 100% cloud avec Supabase (plan gratuit suffisant pour démarrer)
- **Délai** : MVP fonctionnel en 2 semaines
- **Technique** : Compatibilité Android/iOS/Web avec une seule codebase Flutter
- **Légal** : Conformité RGPD pour les données personnelles des locataires

---

## Annexes

### A. Glossaire

| Terme | Définition |
|-------|------------|
| Lot | Unité locative individuelle (appartement, local commercial) |
| Bail | Contrat de location liant un locataire à un lot |
| Échéance | Date à laquelle un loyer est dû |
| Quittance | Document attestant le paiement d'un loyer |
| État des lieux | Constat de l'état d'un logement à l'entrée ou sortie |
| RLS | Row Level Security - sécurité au niveau des lignes dans PostgreSQL |

### B. Références

- Documentation Flutter : [flutter.dev](https://flutter.dev)
- Documentation Supabase : [supabase.com/docs](https://supabase.com/docs)
- Législation baux d'habitation Côte d'Ivoire

### C. Historique des versions

| Version | Date | Auteur | Modifications |
|---------|------|--------|---------------|
| 1.0 | Janvier 2026 | — | Création initiale |

---

*Document généré pour le projet LocaGest - Application de Gestion Immobilière Locative*
