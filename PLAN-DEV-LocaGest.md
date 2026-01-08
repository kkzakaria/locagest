# LOCAGEST - Plan de Développement
## Checklist de suivi des étapes

---

> **Légende :**
> - [ ] À faire
> - [x] Terminé
> - 🔴 Bloquant / Critique
> - 🟡 Important
> - 🟢 Nice to have

---

# SPRINT 1 : MVP (Semaines 1-2)

## Phase 1 : Setup Initial

### 1.1 Environnement de développement
- [X] Installer/Mettre à jour Flutter SDK (version stable)
- [X] Créer le projet Flutter : `flutter create --org com.locagest locagest`
- [X] Configurer les plateformes cibles (Android, iOS, Web)
- [X] Initialiser le repository Git
- [X] Créer la structure de dossiers (Clean Architecture)

### 1.2 Projet Supabase
- [ ] Créer le projet sur supabase.com
- [ ] Noter les credentials (URL, anon key, service key)
- [X] Configurer les variables d'environnement (.env)
- [ ] Installer le CLI Supabase (optionnel, pour migrations)

### 1.3 Dépendances Flutter
- [X] Ajouter les packages au `pubspec.yaml` :
  ```yaml
  dependencies:
    supabase_flutter: ^2.0.0
    flutter_riverpod: ^2.4.0
    go_router: ^13.0.0
    freezed_annotation: ^2.4.0
    json_annotation: ^4.8.0
    intl: ^0.18.0
    pdf: ^3.10.0
    printing: ^5.11.0
    image_picker: ^1.0.0
    signature: ^5.4.0
    shared_preferences: ^2.2.0
    flutter_dotenv: ^5.1.0

  dev_dependencies:
    freezed: ^2.4.0
    json_serializable: ^6.7.0
    build_runner: ^2.4.0
  ```
- [X] Exécuter `flutter pub get`

### 1.4 Structure du projet
- [X] Créer l'arborescence :
  ```
  lib/
  ├── core/
  │   ├── constants/
  │   ├── errors/
  │   ├── theme/
  │   └── utils/
  ├── data/
  │   ├── datasources/
  │   ├── models/
  │   └── repositories/
  ├── domain/
  │   ├── entities/
  │   ├── repositories/
  │   └── usecases/
  └── presentation/
      ├── pages/
      ├── widgets/
      └── providers/
  ```

**✅ Checkpoint Phase 1 :** Projet Flutter qui compile, Supabase accessible ✔️

---

## Phase 2 : Base de données Supabase

### 2.1 Tables principales

#### Table `profiles` (users)
- [ ] 🔴 Créer la table `profiles`
  ```sql
  create table public.profiles (
    id uuid references auth.users primary key,
    email text not null,
    full_name text,
    role text default 'gestionnaire' check (role in ('admin', 'gestionnaire', 'assistant')),
    avatar_url text,
    created_at timestamptz default now()
  );
  ```

#### Table `buildings` (Immeubles)
- [ ] 🔴 Créer la table `buildings`
  ```sql
  create table public.buildings (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    address text not null,
    city text not null,
    postal_code text,
    country text default 'Côte d''Ivoire',
    total_units integer default 0,
    photo_url text,
    notes text,
    created_by uuid references public.profiles(id),
    created_at timestamptz default now(),
    updated_at timestamptz default now()
  );
  ```

#### Table `units` (Lots)
- [ ] 🔴 Créer la table `units`
  ```sql
  create table public.units (
    id uuid primary key default gen_random_uuid(),
    building_id uuid references public.buildings(id) on delete cascade,
    reference text not null,
    type text default 'residential' check (type in ('residential', 'commercial')),
    floor integer,
    surface_area decimal(10,2),
    rooms_count integer,
    base_rent decimal(12,2) not null,
    charges_amount decimal(12,2) default 0,
    charges_included boolean default false,
    status text default 'vacant' check (status in ('vacant', 'occupied', 'maintenance')),
    description text,
    equipment jsonb default '[]',
    photos jsonb default '[]',
    created_at timestamptz default now(),
    updated_at timestamptz default now()
  );
  ```

#### Table `tenants` (Locataires)
- [ ] 🔴 Créer la table `tenants`
  ```sql
  create table public.tenants (
    id uuid primary key default gen_random_uuid(),
    first_name text not null,
    last_name text not null,
    email text,
    phone text not null,
    phone_secondary text,
    id_type text check (id_type in ('cni', 'passport', 'residence_permit')),
    id_number text,
    id_document_url text,
    profession text,
    employer text,
    guarantor_name text,
    guarantor_phone text,
    guarantor_id_url text,
    notes text,
    created_by uuid references public.profiles(id),
    created_at timestamptz default now(),
    updated_at timestamptz default now()
  );
  ```

#### Table `leases` (Baux)
- [ ] 🔴 Créer la table `leases`
  ```sql
  create table public.leases (
    id uuid primary key default gen_random_uuid(),
    unit_id uuid references public.units(id) on delete restrict,
    tenant_id uuid references public.tenants(id) on delete restrict,
    start_date date not null,
    end_date date,
    duration_months integer,
    rent_amount decimal(12,2) not null,
    charges_amount decimal(12,2) default 0,
    deposit_amount decimal(12,2),
    deposit_paid boolean default false,
    payment_day integer default 1 check (payment_day between 1 and 28),
    annual_revision boolean default false,
    revision_rate decimal(5,2),
    status text default 'active' check (status in ('pending', 'active', 'terminated', 'expired')),
    termination_date date,
    termination_reason text,
    document_url text,
    notes text,
    created_by uuid references public.profiles(id),
    created_at timestamptz default now(),
    updated_at timestamptz default now()
  );
  ```

#### Table `rent_schedules` (Échéances)
- [ ] 🔴 Créer la table `rent_schedules`
  ```sql
  create table public.rent_schedules (
    id uuid primary key default gen_random_uuid(),
    lease_id uuid references public.leases(id) on delete cascade,
    due_date date not null,
    period_start date not null,
    period_end date not null,
    amount_due decimal(12,2) not null,
    amount_paid decimal(12,2) default 0,
    balance decimal(12,2) generated always as (amount_due - amount_paid) stored,
    status text default 'pending' check (status in ('pending', 'partial', 'paid', 'overdue')),
    created_at timestamptz default now(),
    updated_at timestamptz default now()
  );
  ```

#### Table `payments` (Paiements)
- [ ] 🔴 Créer la table `payments`
  ```sql
  create table public.payments (
    id uuid primary key default gen_random_uuid(),
    rent_schedule_id uuid references public.rent_schedules(id) on delete restrict,
    amount decimal(12,2) not null,
    payment_date date not null,
    payment_method text not null check (payment_method in ('cash', 'check', 'transfer', 'mobile_money')),
    reference text,
    check_number text,
    bank_name text,
    notes text,
    receipt_number text,
    receipt_url text,
    created_by uuid references public.profiles(id),
    created_at timestamptz default now()
  );
  ```

#### Table `expenses` (Dépenses)
- [ ] 🟡 Créer la table `expenses`
  ```sql
  create table public.expenses (
    id uuid primary key default gen_random_uuid(),
    building_id uuid references public.buildings(id) on delete set null,
    unit_id uuid references public.units(id) on delete set null,
    category text not null check (category in ('repair', 'maintenance', 'tax', 'insurance', 'utilities', 'management', 'other')),
    description text not null,
    amount decimal(12,2) not null,
    expense_date date not null,
    vendor text,
    receipt_url text,
    notes text,
    created_by uuid references public.profiles(id),
    created_at timestamptz default now()
  );
  ```

### 2.2 Indexes et optimisation
- [ ] Créer les index pour les recherches fréquentes
  ```sql
  create index idx_units_building on units(building_id);
  create index idx_units_status on units(status);
  create index idx_leases_unit on leases(unit_id);
  create index idx_leases_tenant on leases(tenant_id);
  create index idx_leases_status on leases(status);
  create index idx_rent_schedules_lease on rent_schedules(lease_id);
  create index idx_rent_schedules_status on rent_schedules(status);
  create index idx_rent_schedules_due_date on rent_schedules(due_date);
  create index idx_payments_schedule on payments(rent_schedule_id);
  create index idx_expenses_building on expenses(building_id);
  ```

### 2.3 Row Level Security (RLS)
- [ ] 🔴 Activer RLS sur toutes les tables
- [ ] 🔴 Créer les policies pour chaque table

### 2.4 Storage Buckets
- [ ] Créer le bucket `documents` (privé)
- [ ] Créer le bucket `photos` (privé)
- [ ] Configurer les policies de storage

### 2.5 Fonctions et Triggers
- [ ] 🟡 Trigger pour mettre à jour `updated_at`
- [ ] 🟡 Trigger pour mettre à jour `total_units` dans buildings
- [ ] 🟡 Fonction pour générer les échéances mensuelles

**✅ Checkpoint Phase 2 :** Base de données créée, RLS configuré, buckets prêts

---

## Phase 3 : Authentification ✅ TERMINÉE

### 3.1 Configuration Supabase Auth
- [X] Configurer les providers (Email/Password)
- [X] Configurer les templates d'email (FR)
- [X] Configurer les URL de redirection

### 3.2 Implémentation Flutter
- [X] 🔴 Créer `lib/core/services/supabase_service.dart` (intégré dans main.dart)
- [X] 🔴 Créer `lib/data/datasources/auth_datasource.dart`
- [X] 🔴 Créer `lib/data/repositories/auth_repository_impl.dart`
- [X] 🔴 Créer les use cases : `sign_in`, `sign_up`, `sign_out`, `get_current_user`
- [X] 🔴 Créer `lib/presentation/providers/auth_provider.dart`

### 3.3 Écrans d'authentification
- [X] 🔴 Page de connexion (`login_page.dart`)
- [X] 🔴 Page d'inscription (`register_page.dart`)
- [X] 🟡 Page mot de passe oublié (`forgot_password_page.dart`)
- [X] 🔴 Gestion de l'état de connexion (AuthGuard)
- [X] Page de réinitialisation mot de passe (`reset_password_page.dart`)
- [X] Gestion des rôles utilisateur (RBAC)
- [X] Page de gestion des utilisateurs (admin)

### 3.4 Navigation
- [X] 🔴 Configurer GoRouter avec les guards d'authentification
- [X] 🔴 Redirection automatique selon l'état de connexion

**✅ Checkpoint Phase 3 :** Connexion/Déconnexion fonctionnelle ✔️

---

## Phase 4 : Module Immeubles ✅ TERMINÉE

### 4.1 Data Layer
- [X] 🔴 Créer `BuildingModel` avec freezed
- [X] 🔴 Créer `BuildingDatasource` (CRUD Supabase)
- [X] 🔴 Créer `BuildingRepository` implementation

### 4.2 Domain Layer
- [X] 🔴 Créer `Building` entity
- [X] 🔴 Créer les use cases CRUD

### 4.3 Presentation Layer
- [X] 🔴 Créer `BuildingsProvider` (Riverpod)
- [X] 🔴 Page liste des immeubles (`buildings_list_page.dart`)
- [X] 🔴 Page détail immeuble (`building_detail_page.dart`)
- [X] 🔴 Formulaire immeuble (`building_form_page.dart`)
- [X] 🟡 Widget `BuildingCard`

### 4.4 Fonctionnalités supplémentaires implémentées
- [X] Upload et compression de photos
- [X] Pagination et lazy loading
- [X] Contrôle d'accès basé sur les rôles (RBAC)
- [X] Dialogue de confirmation de suppression
- [X] Messages d'erreur en français
- [X] Formatage des dates (DD/MM/YYYY)
- [X] Migration SQL avec RLS policies

**✅ Checkpoint Phase 4 :** CRUD Immeubles complet ✔️

---

## Phase 5 : Module Lots/Unités ✅ TERMINÉE

### 5.1 Data Layer
- [X] 🔴 Créer `UnitModel` avec freezed
- [X] 🔴 Créer `UnitDatasource`
- [X] 🔴 Créer `UnitRepository` implementation

### 5.2 Domain Layer
- [X] 🔴 Créer `Unit` entity
- [X] 🔴 Créer les use cases CRUD

### 5.3 Presentation Layer
- [X] 🔴 Créer `UnitsProvider`
- [X] 🔴 Liste des lots (intégrée dans building_detail)
- [X] 🔴 Page détail lot (`unit_detail_page.dart`)
- [X] 🔴 Formulaire lot (`unit_form_page.dart`)
- [X] 🟡 Widget `UnitCard` avec badge statut

### 5.4 Fonctionnalités supplémentaires implémentées
- [X] Migration SQL avec RLS policies et triggers
- [X] Gestion des équipements (EquipmentListEditor)
- [X] Gestion des photos (UnitPhotosManager)
- [X] Badge statut coloré (vacant=rouge, occupied=vert, maintenance=orange)
- [X] Formatage FCFA (165 000 FCFA/mois)
- [X] Affichage étage (RDC, Sous-sol, Étage X)
- [X] Contrôle d'accès basé sur les rôles (RBAC)
- [X] Messages d'erreur en français
- [X] Tests Playwright validés

**✅ Checkpoint Phase 5 :** CRUD Lots complet, liaison avec immeubles ✔️

---

## Phase 6 : Module Locataires ✅ TERMINÉE

### 6.1 Data Layer
- [X] 🔴 Créer `TenantModel`
- [X] 🔴 Créer `TenantDatasource`
- [X] 🔴 Créer `TenantRepository`

### 6.2 Domain Layer
- [X] 🔴 Créer `Tenant` entity
- [X] 🔴 Use cases CRUD

### 6.3 Presentation Layer
- [X] 🔴 Créer `TenantsProvider`
- [X] 🔴 Page liste locataires (`tenants_list_page.dart`)
- [X] 🔴 Page détail locataire (`tenant_detail_page.dart`)
- [X] 🔴 Formulaire locataire (`tenant_form_page.dart`)
- [X] 🟡 Widget `TenantCard`

### 6.4 Fonctionnalités supplémentaires implémentées
- [X] Migration SQL avec RLS policies
- [X] Upload documents (pièce d'identité, garant)
- [X] Validation téléphone Côte d'Ivoire (+225, 07, 05, 01)
- [X] Recherche par nom ou téléphone
- [X] Badge statut (Actif/Inactif)
- [X] Section informations professionnelles
- [X] Section garant avec document
- [X] Section historique des baux (placeholder)
- [X] Contrôle d'accès basé sur les rôles (RBAC)
- [X] Messages d'erreur en français
- [X] Tests Playwright validés

**✅ Checkpoint Phase 6 :** CRUD Locataires complet ✔️

---

## Phase 7 : Module Baux

### 7.1 Data Layer
- [ ] 🔴 Créer `LeaseModel`
- [ ] 🔴 Créer `LeaseDatasource`
- [ ] 🔴 Créer `LeaseRepository`

### 7.2 Domain Layer
- [ ] 🔴 Créer `Lease` entity
- [ ] 🔴 Use cases : CRUD + `TerminateLease`

### 7.3 Presentation Layer
- [ ] 🔴 Créer `LeasesProvider`
- [ ] 🔴 Formulaire bail (`lease_form_page.dart`)
- [ ] 🔴 Affichage bail dans détail lot et locataire
- [ ] 🟡 Modal résiliation

### 7.4 Logique métier
- [ ] 🔴 Mise à jour statut lot à la création/résiliation
- [ ] 🔴 Génération automatique des échéances

**✅ Checkpoint Phase 7 :** Baux fonctionnels, liaison lot-locataire

---

## Phase 8 : Module Échéances et Paiements

### 8.1 Data Layer
- [ ] 🔴 Créer `RentScheduleModel` et `PaymentModel`
- [ ] 🔴 Créer les datasources et repositories

### 8.2 Domain Layer
- [ ] 🔴 Créer les entities
- [ ] 🔴 Use cases : `GetRentSchedules`, `GetOverdueSchedules`, `CreatePayment`

### 8.3 Presentation Layer
- [ ] 🔴 Créer `PaymentsProvider`
- [ ] 🔴 Page paiements (`payments_page.dart`)
- [ ] 🔴 Modal enregistrement paiement (`payment_form_modal.dart`)
- [ ] 🔴 Historique paiements dans fiche locataire/lot
- [ ] 🟡 Widgets : `RentScheduleCard`, `PaymentStatusBadge`

### 8.4 Logique métier
- [ ] 🔴 Calcul automatique du solde
- [ ] 🔴 Mise à jour statut échéance
- [ ] 🔴 Gestion paiements partiels

**✅ Checkpoint Phase 8 :** Enregistrement paiements, suivi impayés

---

## Phase 9 : Génération de Quittances PDF

### 9.1 Service PDF
- [ ] 🔴 Créer `lib/core/services/pdf_service.dart`
- [ ] 🔴 Template quittance de loyer

### 9.2 Implémentation
- [ ] 🔴 Génération du PDF avec package `pdf`
- [ ] 🔴 Prévisualisation avec `printing`
- [ ] 🔴 Téléchargement

### 9.3 Intégration
- [ ] 🔴 Bouton "Générer quittance" après paiement
- [ ] 🟡 Sauvegarde dans Supabase Storage
- [ ] 🟡 Partage (email, WhatsApp)

**✅ Checkpoint Phase 9 :** Quittances PDF générées

---

## Phase 10 : Dashboard

### 10.1 Provider
- [ ] 🔴 Créer `DashboardProvider`
- [ ] 🔴 Requêtes agrégées pour KPIs

### 10.2 Page Dashboard
- [ ] 🔴 KPIs : biens, revenus, impayés, taux occupation
- [ ] 🔴 Liste des impayés (top 5)
- [ ] 🟡 Baux expirant bientôt
- [ ] 🔴 Navigation rapide

### 10.3 Navigation principale
- [ ] 🔴 Bottom navigation bar

**✅ Checkpoint Phase 10 :** Dashboard fonctionnel

---

## Phase 11 : Tests et Corrections MVP

### 11.1 Tests fonctionnels
- [ ] 🔴 Parcours création complet
- [ ] 🔴 Parcours paiement
- [ ] 🔴 Test des calculs

### 11.2 Corrections
- [ ] 🔴 Corriger bugs critiques
- [ ] 🔴 États de chargement et vides
- [ ] 🔴 Messages d'erreur
- [ ] 🟡 Validation formulaires
- [ ] 🟡 Performance

### 11.3 UI/UX
- [ ] 🔴 Cohérence visuelle
- [ ] 🔴 Tests multi-écrans

**✅ CHECKPOINT MVP COMPLET**

---

# SPRINT 2 : États des lieux (Semaine 3)

## Phase 12 : Module États des lieux

### 12.1 Base de données
- [ ] 🔴 Table `inventory_reports`
- [ ] 🔴 Table `inventory_rooms`
- [ ] 🔴 RLS et policies

### 12.2 Data & Domain Layer
- [ ] 🔴 Models, Datasources, Repositories
- [ ] 🔴 Entities et Use cases

### 12.3 Wizard multi-étapes
- [ ] 🔴 Étape 1 : Informations générales
- [ ] 🔴 Étape 2 : Pièces
- [ ] 🔴 Étape 3 : Photos
- [ ] 🔴 Étape 4 : Compteurs
- [ ] 🔴 Étape 5 : Signature

### 12.4 Génération PDF
- [ ] 🔴 Template PDF état des lieux
- [ ] 🔴 Sauvegarde et téléchargement

### 12.5 Fonctionnalités complémentaires
- [ ] 🟡 Liste dans détail lot
- [ ] 🟡 Comparaison entrée/sortie

**✅ CHECKPOINT SPRINT 2**

---

# SPRINT 3 : Rapports et Améliorations (Semaine 4)

## Phase 13 : Rapports comptables

- [ ] 🔴 Rapport revenus par période
- [ ] 🔴 Rapport dépenses
- [ ] 🔴 Bilan net
- [ ] 🔴 État des impayés
- [ ] 🔴 Export PDF
- [ ] 🟡 Export Excel

**✅ Checkpoint Phase 13**

---

## Phase 14 : Gestion des dépenses

- [ ] 🔴 Page liste dépenses
- [ ] 🔴 Formulaire dépense
- [ ] 🟡 Affichage dans détail immeuble/lot

**✅ Checkpoint Phase 14**

---

## Phase 15 : Notifications (optionnel)

- [ ] 🟡 Setup Firebase Cloud Messaging
- [ ] 🟡 Notification loyer en retard
- [ ] 🟡 Notification fin de bail
- [ ] 🟡 Paramètres notifications

**✅ Checkpoint Phase 15**

---

## Phase 16 : Améliorations UX

- [ ] 🟡 Mode hors-ligne
- [ ] 🟡 Import Excel
- [ ] 🟡 Recherche globale
- [ ] 🟢 Thème sombre

**✅ CHECKPOINT SPRINT 3**

---

# SPRINT 4 : Évolutions futures (Backlog)

## Phase 17 : Fonctionnalités avancées
- [ ] Répartition des charges
- [ ] Révision automatique loyers
- [ ] Multi-propriétaires
- [ ] Portail locataire

## Phase 18 : Intégrations
- [ ] Export comptable
- [ ] Google Calendar
- [ ] SMS (Twilio)

## Phase 19 : Publication
- [ ] Build Android release
- [ ] Publication Play Store
- [ ] Build iOS release
- [ ] Publication App Store
- [ ] Déploiement web

---

# Suivi global

## Résumé par sprint

| Sprint | Phases | Durée | Statut | Progression |
|--------|--------|-------|--------|-------------|
| Sprint 1 - MVP | 1-11 | 2 semaines | 🔄 En cours | █████░░░░░ 45% |
| Sprint 2 - États des lieux | 12 | 1 semaine | ⏳ À venir | ░░░░░░░░░░ 0% |
| Sprint 3 - Rapports | 13-16 | 1 semaine | ⏳ À venir | ░░░░░░░░░░ 0% |
| Sprint 4 - Évolutions | 17-19 | TBD | ⏳ Backlog | ░░░░░░░░░░ 0% |

## Checklist des livrables MVP

- [X] Authentification fonctionnelle
- [X] CRUD Immeubles
- [X] CRUD Lots
- [ ] CRUD Locataires
- [ ] CRUD Baux avec génération échéances
- [ ] Enregistrement paiements
- [ ] Génération quittances PDF
- [ ] Dashboard avec KPIs
- [ ] Tests validés

## Progression par phase

| Phase | Nom | Statut |
|-------|-----|--------|
| 1 | Setup Initial | ✅ |
| 2 | Base de données | 🔄 (buildings, units done) |
| 3 | Authentification | ✅ |
| 4 | Module Immeubles | ✅ |
| 5 | Module Lots | ✅ |
| 6 | Module Locataires | ⬜ |
| 7 | Module Baux | ⬜ |
| 8 | Paiements | ⬜ |
| 9 | Quittances PDF | ⬜ |
| 10 | Dashboard | ⬜ |
| 11 | Tests & Corrections | ⬜ |
| 12 | États des lieux | ⬜ |
| 13 | Rapports | ⬜ |
| 14 | Dépenses | ⬜ |
| 15 | Notifications | ⬜ |
| 16 | Améliorations | ⬜ |

---

## Journal de développement

| Date | Phase | Réalisé | Blocages | Notes |
|------|-------|---------|----------|-------|
| 2026-01-06 | Phase 1 | Setup complet | Aucun | Clean Architecture, dépendances installées |
| 2026-01-06 | Phase 3 | Authentification complète | Aucun | Login, Register, Password Reset, RBAC, Logout |
| 2026-01-07 | Phase 4 | Module Immeubles complet | Bug LocaleDataException corrigé | CRUD complet, 44 tâches, migration SQL, RLS, tests Playwright |
| 2026-01-07 | Phase 5 | Module Lots complet | Aucun | 73 tâches, CRUD complet, équipements, photos, migration SQL, RLS, tests Playwright |
| | | | | |

---

## Notes et décisions

### Décisions techniques
- [x] State management : Riverpod
- [x] Navigation : GoRouter
- [x] PDF : package pdf + printing
- [x] Backend : Supabase

### Bugs connus
| ID | Description | Sévérité | Statut |
|----|-------------|----------|--------|
| | | | |

---

## Ressources

- [Supabase Flutter](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Riverpod](https://riverpod.dev/)
- [GoRouter](https://pub.dev/packages/go_router)
- [Package PDF](https://pub.dev/packages/pdf)

### Commandes utiles
```bash
# Générer freezed
flutter pub run build_runner build --delete-conflicting-outputs

# Build
flutter build apk --release
flutter build ios --release
flutter build web --release
```

---

*Dernière mise à jour : 7 Janvier 2026*
