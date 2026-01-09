# Feature Specification: Dashboard avec KPIs

**Feature Branch**: `008-dashboard`
**Created**: 2026-01-09
**Status**: Draft
**Input**: User description: "Implement Phase 10 Dashboard - KPIs, rental income, unpaid rents, occupancy rates, expiring leases, quick navigation"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter les indicateurs clés de performance (KPIs) (Priority: P1)

En tant que gestionnaire immobilier, je veux voir un apercu rapide de mes indicateurs cles (nombre de biens, revenus, impayes, taux d'occupation) des que j'ouvre l'application afin de prendre des decisions eclairees rapidement.

**Why this priority**: Les KPIs sont la raison principale d'existence du tableau de bord. Sans ces indicateurs, le gestionnaire ne peut pas avoir une vue d'ensemble de son portefeuille immobilier. C'est la fonctionnalite la plus demandee par les gestionnaires pour leur travail quotidien.

**Independent Test**: Peut etre teste en se connectant et en verifiant que les 4 cartes KPI affichent des valeurs reelles issues de la base de donnees (immeubles, locataires, revenus du mois, impayes).

**Acceptance Scenarios**:

1. **Given** un gestionnaire authentifie avec des donnees existantes (immeubles, locataires, baux, paiements), **When** il accede au tableau de bord, **Then** il voit 4 cartes KPI affichant : nombre total d'immeubles, nombre total de locataires actifs, revenus collectes ce mois (en FCFA), et montant total des impayes (en FCFA).

2. **Given** un gestionnaire authentifie avec un portefeuille vide (aucune donnee), **When** il accede au tableau de bord, **Then** il voit les 4 cartes KPI affichant "0" ou "0 FCFA" avec un message l'invitant a commencer par ajouter des immeubles.

3. **Given** un gestionnaire authentifie, **When** les donnees changent dans la base (nouveau paiement enregistre par exemple), **Then** les KPIs se rafraichissent lors d'un pull-to-refresh ou a la prochaine visite du tableau de bord.

---

### User Story 2 - Voir la liste des impayes prioritaires (Priority: P1)

En tant que gestionnaire immobilier, je veux voir la liste des loyers impayes les plus urgents (top 5) directement sur le tableau de bord afin de pouvoir agir rapidement sur les retards de paiement.

**Why this priority**: Les impayes representent un risque financier majeur pour le gestionnaire. Avoir une visibilite immediate sur les retards de paiement est critique pour la tresorerie et constitue une action quotidienne du gestionnaire.

**Independent Test**: Peut etre teste en creant des echeances en retard et en verifiant qu'elles apparaissent dans la section "Impayes" du tableau de bord avec les informations pertinentes.

**Acceptance Scenarios**:

1. **Given** un gestionnaire avec plusieurs echeances en retard (status 'overdue' ou 'partial' avec due_date passee), **When** il consulte le tableau de bord, **Then** il voit une section "Impayes" affichant les 5 echeances les plus anciennes avec : nom du locataire, reference du lot, montant du, nombre de jours de retard.

2. **Given** un gestionnaire avec aucun impaye, **When** il consulte le tableau de bord, **Then** la section "Impayes" affiche un message positif "Aucun impaye - Felicitations !" avec une icone de validation.

3. **Given** un gestionnaire consultant la liste des impayes, **When** il appuie sur une ligne d'impaye, **Then** il est redirige vers la page de detail du bail correspondant pour agir (enregistrer un paiement, contacter le locataire).

4. **Given** un gestionnaire avec plus de 5 impayes, **When** il consulte le tableau de bord, **Then** il voit un lien "Voir tous les impayes (X)" qui le redirige vers la page des paiements filtree sur les impayes.

---

### User Story 3 - Voir les baux expirant bientot (Priority: P2)

En tant que gestionnaire immobilier, je veux etre informe des baux qui arrivent a echeance dans les 30 prochains jours afin d'anticiper les renouvellements ou les departs de locataires.

**Why this priority**: Bien que moins urgent que les impayes, anticiper les fins de baux permet d'eviter des pertes de revenus (lots vacants) et de planifier les actions necessaires (renouvellement, recherche de nouveaux locataires).

**Independent Test**: Peut etre teste en creant des baux avec des dates de fin dans les 30 prochains jours et en verifiant leur affichage dans la section dediee.

**Acceptance Scenarios**:

1. **Given** un gestionnaire avec des baux dont la date de fin est dans les 30 prochains jours, **When** il consulte le tableau de bord, **Then** il voit une section "Baux a renouveler" affichant les baux concernes avec : nom du locataire, reference du lot, date de fin, nombre de jours restants.

2. **Given** un gestionnaire avec aucun bail expirant dans les 30 jours, **When** il consulte le tableau de bord, **Then** la section "Baux a renouveler" n'est pas affichee ou affiche "Aucun bail a renouveler prochainement".

3. **Given** un gestionnaire consultant la liste des baux expirant, **When** il appuie sur une ligne, **Then** il est redirige vers la page de detail du bail pour gerer le renouvellement.

4. **Given** un gestionnaire avec des baux a differentes echeances, **When** il consulte la section, **Then** les baux sont tries par date de fin croissante (le plus urgent en premier).

---

### User Story 4 - Calculer et afficher le taux d'occupation (Priority: P2)

En tant que gestionnaire immobilier, je veux voir le taux d'occupation de mon portefeuille (pourcentage de lots occupes) afin d'evaluer la performance globale de ma gestion locative.

**Why this priority**: Le taux d'occupation est un indicateur strategique important pour evaluer la rentabilite du portefeuille, mais il est moins actionnable au quotidien que les impayes ou les KPIs financiers.

**Independent Test**: Peut etre teste en creant des lots avec differents statuts (vacant, occupied, maintenance) et en verifiant que le taux calcule correspond au ratio lots occupes / total lots.

**Acceptance Scenarios**:

1. **Given** un gestionnaire avec 10 lots dont 8 occupes, **When** il consulte le tableau de bord, **Then** il voit un indicateur "Taux d'occupation : 80%" avec une representation visuelle (jauge ou pourcentage colore).

2. **Given** un gestionnaire avec aucun lot, **When** il consulte le tableau de bord, **Then** le taux d'occupation affiche "N/A" ou "0%" avec un message explicatif.

3. **Given** un taux d'occupation superieur a 85%, **When** le gestionnaire consulte le tableau de bord, **Then** l'indicateur est affiche en vert (bonne performance).

4. **Given** un taux d'occupation entre 70% et 85%, **When** le gestionnaire consulte le tableau de bord, **Then** l'indicateur est affiche en orange (performance moyenne).

5. **Given** un taux d'occupation inferieur a 70%, **When** le gestionnaire consulte le tableau de bord, **Then** l'indicateur est affiche en rouge (performance a ameliorer).

---

### User Story 5 - Navigation rapide vers les modules principaux (Priority: P3)

En tant que gestionnaire immobilier, je veux pouvoir acceder rapidement aux differentes sections de l'application (immeubles, locataires, baux, paiements) depuis le tableau de bord afin de naviguer efficacement dans l'application.

**Why this priority**: La navigation rapide est une commodite qui ameliore l'experience utilisateur mais n'est pas bloquante car les utilisateurs peuvent deja naviguer via le menu existant.

**Independent Test**: Peut etre teste en cliquant sur chaque bouton d'action rapide et en verifiant la redirection vers la page correspondante.

**Acceptance Scenarios**:

1. **Given** un gestionnaire sur le tableau de bord, **When** il clique sur "Voir les immeubles", **Then** il est redirige vers la page liste des immeubles.

2. **Given** un gestionnaire sur le tableau de bord, **When** il clique sur "Voir les locataires", **Then** il est redirige vers la page liste des locataires.

3. **Given** un gestionnaire sur le tableau de bord, **When** il clique sur "Voir les baux", **Then** il est redirige vers la page liste des baux.

4. **Given** un gestionnaire sur le tableau de bord, **When** il clique sur "Paiements", **Then** il est redirige vers la page des paiements.

5. **Given** un gestionnaire avec le role admin, **When** il consulte le tableau de bord, **Then** il voit egalement un raccourci "Gerer les utilisateurs" menant a la page de gestion des utilisateurs.

6. **Given** un assistant (role assistant), **When** il consulte le tableau de bord, **Then** il ne voit pas le raccourci "Ajouter un immeuble" car il n'a pas les permissions necessaires.

---

### User Story 6 - Barre de navigation inferieure (Bottom Navigation Bar) (Priority: P3)

En tant que gestionnaire immobilier, je veux pouvoir naviguer entre les sections principales de l'application via une barre de navigation fixe en bas de l'ecran afin d'acceder rapidement aux fonctionnalites les plus utilisees.

**Why this priority**: La navigation inferieure est un standard UX mobile qui ameliore l'ergonomie mais n'est pas critique pour le fonctionnement du MVP.

**Independent Test**: Peut etre teste en verifiant la presence de la barre de navigation sur les ecrans principaux et en cliquant sur chaque onglet.

**Acceptance Scenarios**:

1. **Given** un gestionnaire sur le tableau de bord, **When** il regarde en bas de l'ecran, **Then** il voit une barre de navigation avec les onglets : Accueil, Immeubles, Locataires, Paiements.

2. **Given** un gestionnaire sur n'importe quel ecran principal, **When** il clique sur l'onglet "Accueil", **Then** il est redirige vers le tableau de bord.

3. **Given** un gestionnaire sur n'importe quel ecran principal, **When** il clique sur l'onglet "Immeubles", **Then** il est redirige vers la liste des immeubles.

4. **Given** un gestionnaire sur la page des immeubles, **When** il regarde la barre de navigation, **Then** l'onglet "Immeubles" est visuellement selectionne (mis en surbrillance).

---

### Edge Cases

- **Donnees volumineuses** : Que se passe-t-il si le gestionnaire a plus de 1000 lots ou 500 impayes ? Les KPIs doivent rester performants (temps de chargement < 3 secondes).

- **Utilisateur deconnecte** : Que se passe-t-il si la session expire pendant la consultation du tableau de bord ? L'utilisateur doit etre redirige vers la page de connexion.

- **Erreur de chargement des donnees** : Que se passe-t-il si une erreur survient lors du calcul des KPIs ? Un message d'erreur clair doit etre affiche avec une option "Reessayer".

- **Pas de connexion internet** : Que se passe-t-il si l'utilisateur n'a pas de connexion ? Un message d'erreur doit etre affiche invitant a verifier la connexion.

- **Permissions restreintes** : Comment le tableau de bord s'adapte-t-il pour un assistant qui a un acces en lecture seule aux immeubles ? Les actions non autorisees ne doivent pas etre visibles.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT afficher une carte KPI "Nombre d'immeubles" montrant le total des immeubles du portefeuille.

- **FR-002**: Le systeme DOIT afficher une carte KPI "Nombre de locataires" montrant le nombre de locataires avec au moins un bail actif.

- **FR-003**: Le systeme DOIT afficher une carte KPI "Revenus du mois" montrant le total des paiements recus pendant le mois en cours (format FCFA).

- **FR-004**: Le systeme DOIT afficher une carte KPI "Impayes" montrant le nombre total d'echeances en retard ou partiellement payees.

- **FR-005**: Le systeme DOIT afficher une section "Impayes" listant les 5 echeances les plus anciennes en retard avec : nom du locataire, reference du lot, montant du, jours de retard.

- **FR-006**: Le systeme DOIT afficher une section "Baux a renouveler" listant les baux expirant dans les 30 prochains jours.

- **FR-007**: Le systeme DOIT calculer et afficher le taux d'occupation (lots occupes / total lots * 100) avec un code couleur (vert > 85%, orange 70-85%, rouge < 70%).

- **FR-008**: Le systeme DOIT fournir des boutons de navigation rapide vers les modules : Immeubles, Locataires, Baux, Paiements.

- **FR-009**: Le systeme DOIT adapter les actions rapides selon le role de l'utilisateur (admin, gestionnaire, assistant).

- **FR-010**: Le systeme DOIT permettre le rafraichissement des donnees via un geste pull-to-refresh.

- **FR-011**: Le systeme DOIT afficher un etat vide encourage l'utilisateur a ajouter des donnees lorsque le portefeuille est vide.

- **FR-012**: Le systeme DOIT implementer une barre de navigation inferieure avec 4 onglets : Accueil, Immeubles, Locataires, Paiements.

- **FR-013**: Le systeme DOIT afficher un indicateur de chargement pendant le calcul des KPIs.

- **FR-014**: Le systeme DOIT afficher un message d'erreur clair avec option de reessayer en cas d'echec de chargement des donnees.

- **FR-015**: Le systeme DOIT permettre la navigation vers le detail d'un bail depuis la liste des impayes ou des baux expirant.

### Key Entities

- **DashboardStats**: Represente les statistiques agregees du tableau de bord (nombre d'immeubles, nombre de locataires actifs, revenus du mois, nombre d'impayes, montant total des impayes, taux d'occupation).

- **OverdueRent**: Represente une echeance en retard avec les informations du locataire, du lot et du bail associes (id echeance, nom locataire, reference lot, montant du, date echeance, jours de retard, id bail).

- **ExpiringLease**: Represente un bail arrivant a echeance (id bail, nom locataire, reference lot, date de fin, jours restants).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Les gestionnaires peuvent visualiser leurs 4 KPIs principaux en moins de 3 secondes apres l'ouverture du tableau de bord.

- **SC-002**: Le tableau de bord charge correctement pour un portefeuille contenant jusqu'a 100 immeubles, 500 lots et 1000 echeances.

- **SC-003**: Les gestionnaires peuvent acceder a n'importe quel module principal (Immeubles, Locataires, Baux, Paiements) en 1 clic depuis le tableau de bord.

- **SC-004**: Les impayes affiches sur le tableau de bord correspondent a 100% aux donnees reelles de la base (pas de decalage).

- **SC-005**: 90% des gestionnaires reussissent a identifier les actions prioritaires (impayes, baux expirant) lors de leur premiere visite du tableau de bord.

- **SC-006**: Le taux d'occupation affiche est calcule en temps reel avec une precision de 100%.

- **SC-007**: La navigation inferieure permet de basculer entre les 4 sections principales en moins d'1 seconde.

---

## Assumptions

- Les donnees existantes (immeubles, lots, locataires, baux, echeances, paiements) sont deja disponibles via les modules implementes dans les phases precedentes.

- Le systeme d'authentification et de gestion des roles (RBAC) est deja fonctionnel et permet de filtrer les actions selon les permissions.

- La devise utilisee est le Franc CFA (FCFA) conformement au contexte Cote d'Ivoire.

- Un locataire est considere "actif" s'il a au moins un bail avec le statut 'active'.

- Un lot est considere "occupe" s'il a le statut 'occupied'.

- Une echeance est consideree "en retard" si sa date d'echeance (due_date) est anterieure a la date du jour ET son statut est 'pending' ou 'partial'.

- Le seuil pour les baux expirant bientot est fixe a 30 jours.

- La limite d'affichage des impayes sur le tableau de bord est de 5 elements (les plus anciens en premier).
