# Feature Specification: Module Echeances et Paiements

**Feature Branch**: `006-payment-management`
**Created**: 2026-01-08
**Status**: Draft
**Input**: User description: "implemente la phase Module Echeances et Paiements @PLAN-DEV-LocaGest.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enregistrer un paiement de loyer (Priority: P1)

En tant que gestionnaire immobilier, je veux enregistrer un paiement de loyer recu d'un locataire afin de suivre les encaissements et mettre a jour le statut des echeances.

**Why this priority**: C'est la fonctionnalite principale du module. Sans la capacite d'enregistrer les paiements avec leurs details (methode, reference, date), le suivi financier est impossible.

**Independent Test**: Peut etre entierement teste en enregistrant un paiement pour une echeance existante et en verifiant que le solde et le statut sont mis a jour correctement.

**Acceptance Scenarios**:

1. **Given** une echeance en attente de 150 000 FCFA, **When** j'enregistre un paiement complet de 150 000 FCFA en especes, **Then** l'echeance passe au statut "Paye" et le solde devient 0 FCFA
2. **Given** une echeance en attente de 150 000 FCFA, **When** j'enregistre un paiement partiel de 75 000 FCFA par virement, **Then** l'echeance passe au statut "Partiel" avec un solde de 75 000 FCFA
3. **Given** une echeance en retard avec un solde de 100 000 FCFA, **When** j'enregistre un paiement de 100 000 FCFA par cheque, **Then** l'echeance passe au statut "Paye" et les details du cheque (numero, banque) sont enregistres
4. **Given** un utilisateur avec le role "assistant", **When** il tente d'enregistrer un paiement, **Then** il peut enregistrer le paiement (les assistants ont acces complet aux paiements selon les regles RBAC existantes)

---

### User Story 2 - Consulter l'historique des paiements d'une echeance (Priority: P1)

En tant que gestionnaire, je veux voir l'historique complet des paiements effectues pour une echeance afin de suivre les versements partiels et verifier les details de chaque transaction.

**Why this priority**: Essentiel pour la tracabilite financiere et la resolution de litiges. Permet de justifier les montants recus aupres des locataires.

**Independent Test**: Peut etre teste en consultant les paiements d'une echeance qui a recu plusieurs versements partiels et en verifiant que tous les details sont affiches.

**Acceptance Scenarios**:

1. **Given** une echeance avec 2 paiements partiels, **When** je consulte le detail de l'echeance, **Then** je vois la liste chronologique des paiements avec date, montant, methode et reference pour chacun
2. **Given** une echeance sans paiement, **When** je consulte le detail de l'echeance, **Then** je vois un message indiquant qu'aucun paiement n'a ete enregistre
3. **Given** un paiement par cheque, **When** je consulte ses details, **Then** je vois le numero du cheque et le nom de la banque

---

### User Story 3 - Consulter la page globale des paiements (Priority: P2)

En tant que gestionnaire, je veux acceder a une page centralisee listant toutes les echeances et paiements afin d'avoir une vue d'ensemble de la situation financiere de tous mes baux.

**Why this priority**: Permet une gestion efficace de la tresorerie et l'identification rapide des impayes sans avoir a naviguer dans chaque bail individuellement.

**Independent Test**: Peut etre teste en accedant a la page des paiements et en verifiant que les echeances sont listees avec filtres et recherche fonctionnels.

**Acceptance Scenarios**:

1. **Given** plusieurs baux avec des echeances variees, **When** j'accede a la page des paiements, **Then** je vois toutes les echeances avec leur statut, montant et locataire associe
2. **Given** la page des paiements affichee, **When** je filtre par statut "En retard", **Then** seules les echeances en retard sont affichees
3. **Given** la page des paiements affichee, **When** je recherche par nom de locataire, **Then** seules les echeances de ce locataire sont affichees
4. **Given** la page des paiements affichee, **When** je filtre par periode (mois/annee), **Then** seules les echeances de cette periode sont affichees

---

### User Story 4 - Visualiser les impayes (Priority: P2)

En tant que gestionnaire, je veux identifier rapidement les loyers en retard afin de pouvoir prendre des mesures de relance aupres des locataires concernes.

**Why this priority**: La gestion des impayes est critique pour la rentabilite. Identifier rapidement les retards permet d'agir avant que la situation ne s'aggrave.

**Independent Test**: Peut etre teste en consultant la liste des impayes et en verifiant que seules les echeances depassant leur date d'echeance avec un solde positif sont affichees.

**Acceptance Scenarios**:

1. **Given** des echeances dont la date d'echeance est depassee et non payees, **When** je consulte les impayes, **Then** je vois la liste de ces echeances triees par anciennete (plus ancien en premier)
2. **Given** une echeance en retard, **When** je consulte ses details, **Then** je vois le nombre de jours de retard et le montant total du (loyer + charges)
3. **Given** la liste des impayes, **When** je clique sur une echeance, **Then** j'accede au detail du bail correspondant pour enregistrer un paiement

---

### User Story 5 - Modifier un paiement (Priority: P3)

En tant que gestionnaire, je veux pouvoir modifier ou supprimer un paiement enregistre par erreur afin de corriger les erreurs de saisie.

**Why this priority**: Moins frequent mais necessaire pour maintenir l'integrite des donnees. Les erreurs de saisie arrivent et doivent pouvoir etre corrigees.

**Independent Test**: Peut etre teste en modifiant le montant ou la methode d'un paiement existant et en verifiant que le solde de l'echeance est recalcule.

**Acceptance Scenarios**:

1. **Given** un paiement de 75 000 FCFA enregistre par erreur, **When** je modifie le montant a 100 000 FCFA, **Then** le solde de l'echeance est mis a jour correctement
2. **Given** un paiement enregistre, **When** je supprime ce paiement, **Then** le montant est retire du total paye et le statut de l'echeance est recalcule
3. **Given** un utilisateur avec le role "admin", **When** il supprime un paiement, **Then** la suppression est effectuee
4. **Given** un utilisateur avec le role "gestionnaire" qui n'a pas cree le paiement, **When** il tente de supprimer ce paiement, **Then** l'action est refusee

---

### User Story 6 - Consulter l'historique des paiements dans la fiche locataire (Priority: P3)

En tant que gestionnaire, je veux voir l'historique des paiements d'un locataire directement dans sa fiche afin d'evaluer son comportement de paiement.

**Why this priority**: Utile pour evaluer la fiabilite d'un locataire lors de decisions (renouvellement de bail, references), mais pas bloquant pour les operations quotidiennes.

**Independent Test**: Peut etre teste en accedant a la fiche d'un locataire avec des paiements et en verifiant que le resume et l'historique sont affiches.

**Acceptance Scenarios**:

1. **Given** un locataire avec un bail actif et des paiements, **When** je consulte sa fiche, **Then** je vois un resume (total paye, echeances en cours, impayes)
2. **Given** la fiche locataire, **When** je clique sur la section paiements, **Then** je vois l'historique chronologique des paiements

---

### Edge Cases

- Que se passe-t-il si un paiement depasse le montant du solde restant de l'echeance? Le paiement est accepte et l'echeance passe en statut "Paye" (trop-percu eventuel signale)
- Comment gerer un paiement couvrant plusieurs echeances? Chaque paiement est lie a une seule echeance - le gestionnaire doit enregistrer plusieurs paiements
- Que se passe-t-il si on supprime un bail avec des paiements? Les paiements sont supprimes en cascade avec les echeances (ON DELETE CASCADE)
- Comment gerer une echeance annulee apres un paiement? Les paiements existants sont conserves, le statut de l'echeance reste "Annule"
- Que se passe-t-il si la date de paiement est dans le futur? La date est acceptee (paiement anticipe ou planifie)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT permettre d'enregistrer un paiement avec les informations suivantes: montant, date de paiement, methode de paiement (especes, cheque, virement, mobile money), reference optionnelle, et notes optionnelles
- **FR-002**: Le systeme DOIT mettre a jour automatiquement le montant paye et le statut de l'echeance lors de l'enregistrement d'un paiement
- **FR-003**: Le systeme DOIT calculer automatiquement le solde restant de l'echeance (montant_du - montant_paye)
- **FR-004**: Le systeme DOIT permettre d'enregistrer les details specifiques aux paiements par cheque (numero de cheque, nom de la banque)
- **FR-005**: Le systeme DOIT generer un numero de quittance unique pour chaque paiement enregistre
- **FR-006**: Le systeme DOIT permettre de consulter l'historique des paiements pour une echeance donnee
- **FR-007**: Le systeme DOIT afficher une page centralisee listant toutes les echeances avec possibilite de filtrage (statut, periode, locataire)
- **FR-008**: Le systeme DOIT permettre d'identifier et lister les echeances en retard (date d'echeance depassee avec solde positif)
- **FR-009**: Le systeme DOIT afficher le nombre de jours de retard pour les echeances impayees
- **FR-010**: Le systeme DOIT permettre la modification d'un paiement existant avec recalcul automatique du solde
- **FR-011**: Le systeme DOIT permettre la suppression d'un paiement avec recalcul automatique du solde et du statut de l'echeance
- **FR-012**: Le systeme DOIT afficher les montants au format local (XXX XXX FCFA avec separateur d'espaces)
- **FR-013**: Le systeme DOIT afficher les dates au format francais (JJ/MM/AAAA)
- **FR-014**: Le systeme DOIT respecter les regles RBAC: admin a acces complet, gestionnaire a acces a ses propres donnees, assistant peut lire et enregistrer des paiements
- **FR-015**: Le systeme DOIT afficher un resume des paiements dans la fiche locataire (total paye, echeances en cours, impayes)

### Key Entities

- **Payment (Paiement)**: Represente une transaction financiere enregistree pour une echeance. Attributs: montant, date, methode de paiement, reference, numero de quittance. Relation: lie a une echeance unique (plusieurs paiements possibles par echeance)
- **RentSchedule (Echeance)**: Represente une obligation de paiement mensuelle. Attributs existants: montant du, montant paye, solde, statut, periode. Enrichi par la relation avec les paiements
- **PaymentMethod (Methode de paiement)**: Enumeration des methodes acceptees: especes (cash), cheque (check), virement (transfer), mobile money (mobile_money)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Les gestionnaires peuvent enregistrer un paiement en moins de 30 secondes (3 champs minimum: montant, methode, date)
- **SC-002**: Le statut et le solde de l'echeance sont mis a jour instantanement apres l'enregistrement d'un paiement
- **SC-003**: La page des paiements affiche les echeances en moins de 2 secondes pour un portefeuille de 50 baux
- **SC-004**: Les filtres (statut, periode, locataire) retournent des resultats en moins de 1 seconde
- **SC-005**: 100% des impayes sont identifies correctement (echeances dont la date est depassee avec solde > 0)
- **SC-006**: L'historique complet des paiements d'une echeance est accessible en 1 clic depuis le detail du bail
- **SC-007**: Le systeme supporte l'enregistrement de paiements partiels multiples jusqu'a couvrir le montant total de l'echeance

## Assumptions

- La devise utilisee est le Franc CFA (FCFA) sans decimales
- Les paiements sont enregistres manuellement par le gestionnaire (pas de synchronisation bancaire automatique)
- Un numero de quittance est genere automatiquement au format QUI-AAAAMM-XXXX
- Les paiements mobiles (Mobile Money) incluent Orange Money, MTN Money, Wave, et autres operateurs ivoiriens
- Le trop-percu eventuel est signale mais n'est pas automatiquement reporte sur l'echeance suivante
- Les echeances sont generees automatiquement a la creation du bail (fonctionnalite existante)
