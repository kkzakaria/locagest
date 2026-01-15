# LocaGest Design System

## Direction Esthétique : "Afro-Modern Professional"

Une approche moderne et épurée avec des touches chaleureuses inspirées de l'Afrique de l'Ouest. Le design véhicule confiance et professionnalisme tout en restant accessible et accueillant.

---

## Palette de Couleurs

### Couleurs Primaires (Extraites du Logo)

Le logo LocaGest présente une maison bleue avec une clé dorée, symbolisant la gestion locative et la confiance.

| Couleur | Hex | Usage |
|---------|-----|-------|
| **Bleu Océan** | `#0D7AC4` | Couleur principale - AppBar, boutons, liens |
| Bleu Océan Light | `#4DA3E0` | États hover, accents légers |
| Bleu Océan Dark | `#065A94` | États pressed, texte sur fond clair |
| Bleu Océan Surface | `#E8F4FC` | Fonds de sélection, badges info |

| Couleur | Hex | Usage |
|---------|-----|-------|
| **Orange Doré** | `#F5A623` | CTA importants, notifications, accents |
| Orange Doré Light | `#FFBF4D` | États hover |
| Orange Doré Dark | `#D4870A` | États pressed |
| Orange Doré Surface | `#FFF8E7` | Fonds d'alertes |

### Couleurs de Fond

| Couleur | Hex | Usage |
|---------|-----|-------|
| Background | `#F8FBFD` | Fond principal de l'app |
| Surface | `#FFFFFF` | Cartes, conteneurs |
| Background Accent | `#E3F2FD` | Sections mises en avant |

### Couleurs de Texte

| Couleur | Hex | Usage |
|---------|-----|-------|
| Text Primary | `#1A2B3C` | Titres, contenu important |
| Text Secondary | `#5C6B7A` | Descriptions, labels |
| Text Tertiary | `#94A3B3` | Hints, placeholders |

### Couleurs Sémantiques

| Statut | Couleur | Hex | Usage |
|--------|---------|-----|-------|
| Succès | Vert Forêt | `#2E9F5A` | Payé, occupé, validé |
| Avertissement | Orange Chaud | `#E8912D` | En attente, maintenance |
| Erreur | Rouge Terre | `#D64545` | Impayé, vacant, erreur |
| Info | Bleu Ciel | `#3498DB` | Paiement partiel, info |

### Couleurs de Statut Métier

| Statut | Couleur | Fond | Usage |
|--------|---------|------|-------|
| Vacant | `#D64545` | `#FDECEC` | Lot sans locataire |
| Occupé | `#2E9F5A` | `#E8F5ED` | Lot avec bail actif |
| Maintenance | `#E8912D` | `#FFF3E6` | Lot en travaux |
| Payé | `#2E9F5A` | `#E8F5ED` | Loyer encaissé |
| En attente | `#F5A623` | `#FFF8E7` | Échéance à venir |
| En retard | `#D64545` | `#FDECEC` | Loyer impayé |
| Partiel | `#3498DB` | `#EBF5FB` | Paiement incomplet |

---

## Typographie

### Polices

| Type | Police | Téléchargement |
|------|--------|----------------|
| **Display/Titres** | Plus Jakarta Sans | Google Fonts |
| **Body/Contenu** | Source Sans 3 | Google Fonts |
| **Code/Référence** | Source Code Pro | Google Fonts |

### Échelle Typographique

#### Display (Grands titres)

| Style | Taille | Poids | Usage |
|-------|--------|-------|-------|
| Display Large | 57px | Bold (700) | Écrans de bienvenue |
| Display Medium | 45px | Bold (700) | Grands KPIs |
| Display Small | 36px | SemiBold (600) | Titres majeurs |

#### Headline (Titres de page)

| Style | Taille | Poids | Usage |
|-------|--------|-------|-------|
| Headline Large | 32px | SemiBold (600) | Titres de page |
| Headline Medium | 28px | SemiBold (600) | Noms d'immeubles |
| Headline Small | 24px | SemiBold (600) | Titres de sections |

#### Title (Titres de composants)

| Style | Taille | Poids | Usage |
|-------|--------|-------|-------|
| Title Large | 22px | SemiBold (600) | AppBar, modals |
| Title Medium | 16px | SemiBold (600) | Cartes, noms |
| Title Small | 14px | SemiBold (600) | Labels importants |

#### Body (Contenu)

| Style | Taille | Poids | Usage |
|-------|--------|-------|-------|
| Body Large | 16px | Regular (400) | Paragraphes |
| Body Medium | 14px | Regular (400) | Contenu standard |
| Body Small | 12px | Regular (400) | Métadonnées |

#### Label (UI Elements)

| Style | Taille | Poids | Usage |
|-------|--------|-------|-------|
| Label Large | 14px | SemiBold (600) | Boutons, tabs |
| Label Medium | 12px | SemiBold (600) | Chips, labels |
| Label Small | 11px | Medium (500) | Badges, hints |

---

## Espacements

### Unité de Base : 4px

| Token | Valeur | Usage |
|-------|--------|-------|
| `xs` | 4px | Micro-espacement |
| `sm` | 8px | Espacement compact |
| `md` | 12px | Espacement intermédiaire |
| `lg` | 16px | **Standard** |
| `xl` | 20px | Espacement moyen |
| `xxl` | 24px | Sections |
| `xxxl` | 32px | Sections majeures |
| `huge` | 40px | Headers |
| `massive` | 48px | Top de pages |
| `colossal` | 64px | Zones vides |

### Paddings Prédéfinis

| Token | Valeur | Usage |
|-------|--------|-------|
| Page | 16px all | Contenu de page |
| Card | 16px all | Intérieur de cartes |
| Card Compact | 12px all | Cartes compactes |
| List Item | 16px h / 12px v | Items de liste |
| Button | 24px h / 12px v | Boutons |
| Input | 16px all | Champs de formulaire |
| Chip | 12px h / 4px v | Badges |

---

## Rayons de Bordure

| Token | Valeur | Usage |
|-------|--------|-------|
| `radiusNone` | 0px | Éléments carrés |
| `radiusXs` | 4px | Petits éléments |
| `radiusSm` | 8px | Images |
| `radiusMd` | 12px | **Cartes, boutons** |
| `radiusLg` | 16px | Cartes larges |
| `radiusXl` | 20px | Bottom sheets |
| `radiusHuge` | 24px | Modals |
| `radiusFull` | 999px | Chips, avatars |

---

## Dimensions de Composants

### Boutons

| Type | Hauteur | Usage |
|------|---------|-------|
| Standard | 48px | Boutons principaux |
| Compact | 40px | Boutons secondaires |

### Champs de Formulaire

| Type | Hauteur | Usage |
|------|---------|-------|
| Standard | 56px | Formulaires |
| Compact | 48px | Recherche |

### Icônes

| Taille | Valeur | Usage |
|--------|--------|-------|
| XS | 16px | Indicateurs |
| SM | 20px | Boutons compacts |
| MD | 24px | **Standard** |
| LG | 32px | Headers |
| XL | 40px | Actions |
| Huge | 48px | Illustrations |
| Massive | 64px | États vides |

### Avatars

| Taille | Valeur | Usage |
|--------|--------|-------|
| XS | 24px | Mentions |
| SM | 32px | Listes compactes |
| MD | 40px | **Standard** |
| LG | 48px | Headers |
| XL | 64px | Détails |
| Huge | 80px | Profil |
| Massive | 96px | Profil large |

---

## Élévation et Ombres

| Token | Blur | Offset | Usage |
|-------|------|--------|-------|
| Shadow SM | 4px | 0, 2 | Cartes au repos |
| Shadow MD | 8px | 0, 4 | Cartes hover |
| Shadow LG | 16px | 0, 8 | Modals |
| Shadow XL | 24px | 0, 12 | Bottom sheets |

---

## Animations

### Durées

| Token | Durée | Usage |
|-------|-------|-------|
| Fast | 100ms | Feedback immédiat |
| Normal | 200ms | Transitions légères |
| Slow | 300ms | **Standard** |
| Slower | 400ms | Modals |
| Slowest | 500ms | Pages |

### Courbes

- **Standard** : `Curves.easeInOut`
- **Enter** : `Curves.easeOut`
- **Exit** : `Curves.easeIn`
- **Bounce** : `Curves.elasticOut`

---

## Utilisation dans le Code

### Import du Design System

```dart
import 'package:locagest/core/theme/theme.dart';
```

### Exemples

#### Couleurs

```dart
Container(
  color: AppColors.primary,
  child: Text(
    'Texte',
    style: TextStyle(color: AppColors.textOnPrimary),
  ),
)
```

#### Typographie

```dart
Text(
  'Titre',
  style: AppTypography.headlineMedium,
)

Text(
  '150 000 FCFA',
  style: AppTypography.currency,
)
```

#### Espacements

```dart
Padding(
  padding: AppSpacing.cardPadding,
  child: Column(
    children: [
      Text('Item 1'),
      AppSpacing.vSpaceMd,
      Text('Item 2'),
    ],
  ),
)
```

#### Styles de Composants

```dart
Container(
  decoration: AppStyles.cardDecoration,
  child: ...,
)

ElevatedButton(
  style: AppStyles.primaryButtonStyle,
  onPressed: () {},
  child: Text('Action'),
)
```

#### Badge de Statut

```dart
Container(
  padding: AppSpacing.chipPadding,
  decoration: AppStyles.badgeSuccess,
  child: Text(
    'Payé',
    style: AppTypography.labelSmall.copyWith(
      color: AppColors.statusPaid,
    ),
  ),
)
```

---

## Structure des Fichiers

```
lib/core/theme/
├── app_colors.dart      # Palette de couleurs
├── app_typography.dart  # Styles typographiques
├── app_spacing.dart     # Espacements et dimensions
├── app_styles.dart      # Styles de composants
├── app_theme.dart       # Thème Material complet
└── theme.dart           # Export centralisé
```

---

## Principes de Design

### 1. Cohérence
Utiliser les tokens du design system plutôt que des valeurs hardcodées.

### 2. Accessibilité
- Contraste minimum de 4.5:1 pour le texte
- Zones tactiles minimum de 48x48px
- Labels clairs pour les formulaires

### 3. Hiérarchie Visuelle
- Utiliser la taille et le poids pour la hiérarchie
- Limiter à 2-3 niveaux de hiérarchie par écran
- Mettre en évidence les actions principales

### 4. Espacement Généreux
- Donner de l'air au contenu
- Grouper les éléments liés
- Séparer les sections distinctes

### 5. Feedback Immédiat
- États visuels clairs (hover, pressed, disabled)
- Animations subtiles pour le feedback
- Messages d'erreur contextuels

---

*Design System LocaGest v1.0 - Janvier 2026*
