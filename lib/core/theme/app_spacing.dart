import 'package:flutter/material.dart';

/// LocaGest Spacing & Dimensions System
///
/// Système d'espacement basé sur une unité de base de 4px
/// Utilise une progression géométrique pour créer une hiérarchie visuelle cohérente
///
/// Échelle : 4 - 8 - 12 - 16 - 20 - 24 - 32 - 40 - 48 - 64 - 80 - 96 - 128
abstract class AppSpacing {
  AppSpacing._();

  // ============================================
  // UNITÉ DE BASE
  // ============================================

  /// Unité de base (4px)
  static const double unit = 4.0;

  // ============================================
  // ESPACEMENTS (Basés sur l'unité de 4px)
  // ============================================

  /// 4px - Micro espacement
  /// Usage : Entre icône et texte, padding de badges
  static const double xs = 4.0;

  /// 8px - Petit espacement
  /// Usage : Espacement interne de chips, entre éléments de liste compacts
  static const double sm = 8.0;

  /// 12px - Espacement intermédiaire
  /// Usage : Padding interne léger, espacement vertical de formulaires
  static const double md = 12.0;

  /// 16px - Espacement standard
  /// Usage : Padding de cartes, marges de page, espacement de sections
  static const double lg = 16.0;

  /// 20px - Espacement moyen
  /// Usage : Espacement entre groupes de formulaires
  static const double xl = 20.0;

  /// 24px - Grand espacement
  /// Usage : Espacement entre sections, padding de modals
  static const double xxl = 24.0;

  /// 32px - Très grand espacement
  /// Usage : Espacement entre sections majeures, marges de page larges
  static const double xxxl = 32.0;

  /// 40px - Espacement extra large
  /// Usage : Espacement de header, zones de respiration
  static const double huge = 40.0;

  /// 48px - Espacement massif
  /// Usage : Top padding de pages, espacement de onboarding
  static const double massive = 48.0;

  /// 64px - Espacement colossal
  /// Usage : Espacement de section hero, zones vides
  static const double colossal = 64.0;

  // ============================================
  // PADDINGS PRÉDÉFINIS
  // ============================================

  /// Padding de page standard (horizontal: 16, vertical: 16)
  static const EdgeInsets pagePadding = EdgeInsets.all(lg);

  /// Padding horizontal de page
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: lg);

  /// Padding de carte standard
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// Padding de carte compact
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(md);

  /// Padding de liste item
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Padding de bouton
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: xxl,
    vertical: md,
  );

  /// Padding de champ de formulaire
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: lg,
  );

  /// Padding de chip/badge
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: xs,
  );

  /// Padding de modal
  static const EdgeInsets modalPadding = EdgeInsets.all(xxl);

  /// Padding de bottom sheet
  static const EdgeInsets bottomSheetPadding = EdgeInsets.fromLTRB(lg, xxl, lg, lg);

  /// Padding de section
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(vertical: xxl);

  // ============================================
  // DIMENSIONS DE COMPOSANTS
  // ============================================

  /// Hauteur de bouton standard
  static const double buttonHeight = 48.0;

  /// Hauteur de bouton compact
  static const double buttonHeightCompact = 40.0;

  /// Hauteur de champ de texte
  static const double inputHeight = 56.0;

  /// Hauteur de champ de texte compact
  static const double inputHeightCompact = 48.0;

  /// Hauteur d'AppBar
  static const double appBarHeight = 56.0;

  /// Hauteur de Bottom Navigation Bar
  static const double bottomNavHeight = 80.0;

  /// Hauteur de tab bar
  static const double tabBarHeight = 48.0;

  /// Hauteur de liste item standard
  static const double listItemHeight = 72.0;

  /// Hauteur de liste item compact
  static const double listItemHeightCompact = 56.0;

  /// Hauteur de carte KPI
  static const double kpiCardHeight = 120.0;

  /// Hauteur de mini carte
  static const double miniCardHeight = 80.0;

  // ============================================
  // DIMENSIONS D'ICÔNES
  // ============================================

  /// Icône extra small (16px)
  static const double iconXs = 16.0;

  /// Icône small (20px)
  static const double iconSm = 20.0;

  /// Icône medium (24px) - Taille par défaut
  static const double iconMd = 24.0;

  /// Icône large (32px)
  static const double iconLg = 32.0;

  /// Icône extra large (40px)
  static const double iconXl = 40.0;

  /// Icône huge (48px)
  static const double iconHuge = 48.0;

  /// Icône massive (64px) - Pour états vides
  static const double iconMassive = 64.0;

  // ============================================
  // DIMENSIONS D'AVATARS
  // ============================================

  /// Avatar extra small (24px)
  static const double avatarXs = 24.0;

  /// Avatar small (32px)
  static const double avatarSm = 32.0;

  /// Avatar medium (40px) - Taille par défaut
  static const double avatarMd = 40.0;

  /// Avatar large (48px)
  static const double avatarLg = 48.0;

  /// Avatar extra large (64px)
  static const double avatarXl = 64.0;

  /// Avatar huge (80px)
  static const double avatarHuge = 80.0;

  /// Avatar massive (96px) - Pour profil
  static const double avatarMassive = 96.0;

  // ============================================
  // RAYONS DE BORDURE
  // ============================================

  /// Rayon nul
  static const double radiusNone = 0.0;

  /// Rayon extra small (4px)
  static const double radiusXs = 4.0;

  /// Rayon small (8px)
  static const double radiusSm = 8.0;

  /// Rayon medium (12px) - Par défaut pour cartes
  static const double radiusMd = 12.0;

  /// Rayon large (16px)
  static const double radiusLg = 16.0;

  /// Rayon extra large (20px)
  static const double radiusXl = 20.0;

  /// Rayon huge (24px)
  static const double radiusHuge = 24.0;

  /// Rayon complet (circulaire)
  static const double radiusFull = 999.0;

  // ============================================
  // BORDER RADIUS PRÉDÉFINIS
  // ============================================

  /// BorderRadius pour boutons
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(radiusMd));

  /// BorderRadius pour cartes
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(radiusMd));

  /// BorderRadius pour cartes larges
  static const BorderRadius cardRadiusLarge = BorderRadius.all(Radius.circular(radiusLg));

  /// BorderRadius pour champs de formulaire
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(radiusMd));

  /// BorderRadius pour chips/badges
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(radiusFull));

  /// BorderRadius pour modals
  static const BorderRadius modalRadius = BorderRadius.vertical(
    top: Radius.circular(radiusHuge),
  );

  /// BorderRadius pour bottom sheet
  static const BorderRadius bottomSheetRadius = BorderRadius.vertical(
    top: Radius.circular(radiusXl),
  );

  /// BorderRadius pour images
  static const BorderRadius imageRadius = BorderRadius.all(Radius.circular(radiusSm));

  /// BorderRadius pour avatars
  static const BorderRadius avatarRadius = BorderRadius.all(Radius.circular(radiusFull));

  // ============================================
  // LARGEURS DE BORDURE
  // ============================================

  /// Bordure fine (1px)
  static const double borderThin = 1.0;

  /// Bordure normale (1.5px)
  static const double borderNormal = 1.5;

  /// Bordure épaisse (2px)
  static const double borderThick = 2.0;

  /// Bordure très épaisse (3px)
  static const double borderExtraThick = 3.0;

  // ============================================
  // ÉLÉVATIONS (Ombres)
  // ============================================

  /// Pas d'élévation
  static const double elevationNone = 0.0;

  /// Élévation très basse (1dp)
  static const double elevationXs = 1.0;

  /// Élévation basse (2dp)
  static const double elevationSm = 2.0;

  /// Élévation moyenne (4dp)
  static const double elevationMd = 4.0;

  /// Élévation haute (8dp)
  static const double elevationLg = 8.0;

  /// Élévation très haute (16dp)
  static const double elevationXl = 16.0;

  // ============================================
  // BREAKPOINTS (pour responsive)
  // ============================================

  /// Mobile compact
  static const double breakpointXs = 320.0;

  /// Mobile standard
  static const double breakpointSm = 375.0;

  /// Mobile large
  static const double breakpointMd = 428.0;

  /// Tablet
  static const double breakpointLg = 768.0;

  /// Desktop
  static const double breakpointXl = 1024.0;

  // ============================================
  // DURÉES D'ANIMATION
  // ============================================

  /// Animation ultra rapide (100ms)
  static const Duration durationFast = Duration(milliseconds: 100);

  /// Animation rapide (200ms)
  static const Duration durationNormal = Duration(milliseconds: 200);

  /// Animation standard (300ms)
  static const Duration durationSlow = Duration(milliseconds: 300);

  /// Animation lente (400ms)
  static const Duration durationSlower = Duration(milliseconds: 400);

  /// Animation très lente (500ms)
  static const Duration durationSlowest = Duration(milliseconds: 500);

  // ============================================
  // HELPERS
  // ============================================

  /// Crée un espacement vertical
  static SizedBox verticalSpace(double height) => SizedBox(height: height);

  /// Crée un espacement horizontal
  static SizedBox horizontalSpace(double width) => SizedBox(width: width);

  /// Espacement vertical XS
  static const SizedBox vSpaceXs = SizedBox(height: xs);

  /// Espacement vertical SM
  static const SizedBox vSpaceSm = SizedBox(height: sm);

  /// Espacement vertical MD
  static const SizedBox vSpaceMd = SizedBox(height: md);

  /// Espacement vertical LG
  static const SizedBox vSpaceLg = SizedBox(height: lg);

  /// Espacement vertical XL
  static const SizedBox vSpaceXl = SizedBox(height: xl);

  /// Espacement vertical XXL
  static const SizedBox vSpaceXxl = SizedBox(height: xxl);

  /// Espacement vertical XXXL
  static const SizedBox vSpaceXxxl = SizedBox(height: xxxl);

  /// Espacement horizontal XS
  static const SizedBox hSpaceXs = SizedBox(width: xs);

  /// Espacement horizontal SM
  static const SizedBox hSpaceSm = SizedBox(width: sm);

  /// Espacement horizontal MD
  static const SizedBox hSpaceMd = SizedBox(width: md);

  /// Espacement horizontal LG
  static const SizedBox hSpaceLg = SizedBox(width: lg);

  /// Espacement horizontal XL
  static const SizedBox hSpaceXl = SizedBox(width: xl);

  /// Espacement horizontal XXL
  static const SizedBox hSpaceXxl = SizedBox(width: xxl);
}
