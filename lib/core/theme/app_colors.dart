import 'package:flutter/material.dart';

/// LocaGest Color Palette
///
/// Palette extraite du logo de l'application :
/// - Bleu océan (maison) : confiance, stabilité, professionnalisme
/// - Orange doré (clé) : chaleur, prospérité, énergie africaine
/// - Bleu ciel (fond) : légèreté, accessibilité, ouverture
///
/// Direction esthétique : "Afro-Modern Professional"
abstract class AppColors {
  AppColors._();

  // ============================================
  // COULEURS PRIMAIRES (Extraites du logo)
  // ============================================

  /// Bleu océan - Couleur principale
  /// Utilisé pour : AppBar, boutons primaires, liens, éléments d'accent
  static const Color primary = Color(0xFF0D7AC4);
  static const Color primaryLight = Color(0xFF4DA3E0);
  static const Color primaryDark = Color(0xFF065A94);
  static const Color primarySurface = Color(0xFFE8F4FC);

  /// Orange doré - Couleur secondaire/accent
  /// Utilisé pour : CTA importants, notifications, badges, highlights
  static const Color secondary = Color(0xFFF5A623);
  static const Color secondaryLight = Color(0xFFFFBF4D);
  static const Color secondaryDark = Color(0xFFD4870A);
  static const Color secondarySurface = Color(0xFFFFF8E7);

  // ============================================
  // COULEURS DE FOND
  // ============================================

  /// Fond principal de l'application
  static const Color background = Color(0xFFF8FBFD);

  /// Surface des cartes et conteneurs
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface surélevée (modals, bottom sheets)
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  /// Fond bleu ciel subtil (inspiré du logo)
  static const Color backgroundAccent = Color(0xFFE3F2FD);

  // ============================================
  // COULEURS DE TEXTE
  // ============================================

  /// Texte principal (titres, contenu important)
  static const Color textPrimary = Color(0xFF1A2B3C);

  /// Texte secondaire (descriptions, labels)
  static const Color textSecondary = Color(0xFF5C6B7A);

  /// Texte tertiaire (hints, placeholders)
  static const Color textTertiary = Color(0xFF94A3B3);

  /// Texte sur fond coloré (primary/secondary)
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF1A2B3C);

  // ============================================
  // COULEURS SÉMANTIQUES (Statuts)
  // ============================================

  /// Succès - Vert forêt (inspiré de la nature ivoirienne)
  static const Color success = Color(0xFF2E9F5A);
  static const Color successLight = Color(0xFFE8F5ED);
  static const Color successDark = Color(0xFF1E7A3F);

  /// Avertissement - Orange chaud
  static const Color warning = Color(0xFFE8912D);
  static const Color warningLight = Color(0xFFFFF3E6);
  static const Color warningDark = Color(0xFFC47515);

  /// Erreur - Rouge terre
  static const Color error = Color(0xFFD64545);
  static const Color errorLight = Color(0xFFFDECEC);
  static const Color errorDark = Color(0xFFB82D2D);

  /// Information - Bleu ciel
  static const Color info = Color(0xFF3498DB);
  static const Color infoLight = Color(0xFFEBF5FB);
  static const Color infoDark = Color(0xFF2475A8);

  // ============================================
  // COULEURS DE STATUT MÉTIER
  // ============================================

  /// Lot vacant
  static const Color statusVacant = Color(0xFFD64545);
  static const Color statusVacantBg = Color(0xFFFDECEC);

  /// Lot occupé
  static const Color statusOccupied = Color(0xFF2E9F5A);
  static const Color statusOccupiedBg = Color(0xFFE8F5ED);

  /// En maintenance
  static const Color statusMaintenance = Color(0xFFE8912D);
  static const Color statusMaintenanceBg = Color(0xFFFFF3E6);

  /// Paiement en attente
  static const Color statusPending = Color(0xFFF5A623);
  static const Color statusPendingBg = Color(0xFFFFF8E7);

  /// Paiement en retard
  static const Color statusOverdue = Color(0xFFD64545);
  static const Color statusOverdueBg = Color(0xFFFDECEC);

  /// Paiement partiel
  static const Color statusPartial = Color(0xFF3498DB);
  static const Color statusPartialBg = Color(0xFFEBF5FB);

  /// Paiement complet
  static const Color statusPaid = Color(0xFF2E9F5A);
  static const Color statusPaidBg = Color(0xFFE8F5ED);

  // ============================================
  // COULEURS DE BORDURE ET DIVIDERS
  // ============================================

  /// Bordure légère
  static const Color border = Color(0xFFE5EBF0);

  /// Bordure moyenne
  static const Color borderMedium = Color(0xFFD0D9E0);

  /// Bordure forte (focus)
  static const Color borderStrong = Color(0xFF94A3B3);

  /// Divider
  static const Color divider = Color(0xFFE5EBF0);

  // ============================================
  // COULEURS D'OVERLAY ET OMBRES
  // ============================================

  /// Overlay sombre (modals)
  static const Color overlay = Color(0x80000000);

  /// Ombre
  static const Color shadow = Color(0x1A000000);
  static const Color shadowMedium = Color(0x29000000);
  static const Color shadowStrong = Color(0x3D000000);

  // ============================================
  // COULEURS SPÉCIALES
  // ============================================

  /// Shimmer/Skeleton loading
  static const Color shimmerBase = Color(0xFFE5EBF0);
  static const Color shimmerHighlight = Color(0xFFF5F8FA);

  /// Disabled
  static const Color disabled = Color(0xFFD0D9E0);
  static const Color disabledText = Color(0xFF94A3B3);

  // ============================================
  // GRADIENTS
  // ============================================

  /// Gradient principal (bleu océan)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// Gradient secondaire (orange doré)
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary],
  );

  /// Gradient de fond subtil
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundAccent, background],
  );

  /// Gradient pour les cartes KPI
  static const LinearGradient kpiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D7AC4), Color(0xFF4DA3E0)],
  );

  /// Gradient orange pour les alertes
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5A623), Color(0xFFFFBF4D)],
  );

  // ============================================
  // COLOR SCHEME (Material 3)
  // ============================================

  static ColorScheme get colorScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: textOnPrimary,
    primaryContainer: primarySurface,
    onPrimaryContainer: primaryDark,
    secondary: secondary,
    onSecondary: textOnSecondary,
    secondaryContainer: secondarySurface,
    onSecondaryContainer: secondaryDark,
    tertiary: info,
    onTertiary: textOnPrimary,
    tertiaryContainer: infoLight,
    onTertiaryContainer: infoDark,
    error: error,
    onError: textOnPrimary,
    errorContainer: errorLight,
    onErrorContainer: errorDark,
    surface: surface,
    onSurface: textPrimary,
    surfaceContainerHighest: backgroundAccent,
    onSurfaceVariant: textSecondary,
    outline: border,
    outlineVariant: borderMedium,
    shadow: shadow,
    scrim: overlay,
    inverseSurface: textPrimary,
    onInverseSurface: surface,
    inversePrimary: primaryLight,
  );
}
