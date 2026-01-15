import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// LocaGest Component Styles
///
/// Styles prédéfinis pour les composants de l'application :
/// - Décorations de cartes et conteneurs
/// - Ombres portées
/// - Styles de boutons
/// - Styles de champs de formulaire
/// - Styles de badges et chips
abstract class AppStyles {
  AppStyles._();

  // ============================================
  // BOX SHADOWS
  // ============================================

  /// Ombre légère - pour cartes au repos
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Ombre moyenne - pour cartes survolées
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  /// Ombre large - pour modals et éléments flottants
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  /// Ombre extra large - pour bottom sheets
  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: AppColors.shadowStrong,
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  /// Ombre colorée primaire - pour boutons CTA
  static List<BoxShadow> shadowPrimary = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Ombre colorée secondaire - pour boutons accent
  static List<BoxShadow> shadowSecondary = [
    BoxShadow(
      color: AppColors.secondary.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ============================================
  // DÉCORATIONS DE CARTES
  // ============================================

  /// Carte standard avec bordure et ombre légère
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppSpacing.cardRadius,
    border: Border.all(color: AppColors.border, width: AppSpacing.borderThin),
    boxShadow: shadowSm,
  );

  /// Carte sans ombre (flat)
  static BoxDecoration get cardDecorationFlat => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppSpacing.cardRadius,
    border: Border.all(color: AppColors.border, width: AppSpacing.borderThin),
  );

  /// Carte avec ombre prononcée (elevated)
  static BoxDecoration get cardDecorationElevated => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppSpacing.cardRadius,
    boxShadow: shadowMd,
  );

  /// Carte sélectionnée/active
  static BoxDecoration get cardDecorationSelected => BoxDecoration(
    color: AppColors.primarySurface,
    borderRadius: AppSpacing.cardRadius,
    border: Border.all(color: AppColors.primary, width: AppSpacing.borderThick),
  );

  /// Carte avec gradient primaire
  static BoxDecoration get cardDecorationGradient => const BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: AppSpacing.cardRadius,
  );

  /// Carte KPI avec gradient
  static BoxDecoration get kpiCardDecoration => const BoxDecoration(
    gradient: AppColors.kpiGradient,
    borderRadius: AppSpacing.cardRadius,
    boxShadow: shadowMd,
  );

  // ============================================
  // DÉCORATIONS DE CONTENEURS
  // ============================================

  /// Conteneur de page avec fond subtil
  static BoxDecoration get pageBackground => const BoxDecoration(
    gradient: AppColors.backgroundGradient,
  );

  /// Conteneur de section
  static BoxDecoration get sectionContainer => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppSpacing.cardRadius,
  );

  /// Conteneur de modal
  static BoxDecoration get modalDecoration => const BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppSpacing.modalRadius,
    boxShadow: shadowXl,
  );

  /// Conteneur de bottom sheet
  static BoxDecoration get bottomSheetDecoration => const BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppSpacing.bottomSheetRadius,
    boxShadow: shadowXl,
  );

  // ============================================
  // DÉCORATIONS D'INPUT
  // ============================================

  /// Décoration de champ de texte standard
  static InputDecoration inputDecoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) => InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    errorText: errorText,
    filled: true,
    fillColor: AppColors.background,
    labelStyle: AppTypography.bodyMedium.copyWith(
      color: AppColors.textSecondary,
    ),
    hintStyle: AppTypography.hint,
    errorStyle: AppTypography.error,
    contentPadding: AppSpacing.inputPadding,
    border: OutlineInputBorder(
      borderRadius: AppSpacing.inputRadius,
      borderSide: BorderSide(color: AppColors.border, width: AppSpacing.borderThin),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppSpacing.inputRadius,
      borderSide: BorderSide(color: AppColors.border, width: AppSpacing.borderThin),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppSpacing.inputRadius,
      borderSide: BorderSide(color: AppColors.primary, width: AppSpacing.borderThick),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppSpacing.inputRadius,
      borderSide: BorderSide(color: AppColors.error, width: AppSpacing.borderThin),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppSpacing.inputRadius,
      borderSide: BorderSide(color: AppColors.error, width: AppSpacing.borderThick),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: AppSpacing.inputRadius,
      borderSide: BorderSide(color: AppColors.disabled, width: AppSpacing.borderThin),
    ),
  );

  /// Décoration de champ de recherche
  static InputDecoration searchInputDecoration({
    String hintText = 'Rechercher...',
  }) => InputDecoration(
    hintText: hintText,
    prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
    filled: true,
    fillColor: AppColors.surface,
    hintStyle: AppTypography.hint,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: AppSpacing.chipRadius,
      borderSide: BorderSide(color: AppColors.border, width: AppSpacing.borderThin),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppSpacing.chipRadius,
      borderSide: BorderSide(color: AppColors.border, width: AppSpacing.borderThin),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppSpacing.chipRadius,
      borderSide: BorderSide(color: AppColors.primary, width: AppSpacing.borderThick),
    ),
  );

  // ============================================
  // STYLES DE BOUTONS
  // ============================================

  /// Style de bouton primaire (ElevatedButton)
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
    padding: AppSpacing.buttonPadding,
    shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
    textStyle: AppTypography.button,
    elevation: 0,
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return AppColors.primaryDark;
      }
      return null;
    }),
  );

  /// Style de bouton secondaire (OutlinedButton)
  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
    padding: AppSpacing.buttonPadding,
    shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
    side: BorderSide(color: AppColors.primary, width: AppSpacing.borderThick),
    textStyle: AppTypography.button,
  );

  /// Style de bouton tertiaire (TextButton)
  static ButtonStyle get tertiaryButtonStyle => TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    minimumSize: const Size(48, AppSpacing.buttonHeight),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
    textStyle: AppTypography.button,
  );

  /// Style de bouton accent (orange)
  static ButtonStyle get accentButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.textOnSecondary,
    minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
    padding: AppSpacing.buttonPadding,
    shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
    textStyle: AppTypography.button,
    elevation: 0,
  );

  /// Style de bouton danger
  static ButtonStyle get dangerButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: AppColors.textOnPrimary,
    minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
    padding: AppSpacing.buttonPadding,
    shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
    textStyle: AppTypography.button,
    elevation: 0,
  );

  /// Style de bouton icon (IconButton)
  static ButtonStyle get iconButtonStyle => IconButton.styleFrom(
    minimumSize: const Size(AppSpacing.buttonHeight, AppSpacing.buttonHeight),
    shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
    padding: const EdgeInsets.all(AppSpacing.md),
  );

  /// Style de bouton FAB
  static FloatingActionButtonThemeData get fabTheme => FloatingActionButtonThemeData(
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.textOnSecondary,
    elevation: AppSpacing.elevationMd,
    shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
  );

  // ============================================
  // STYLES DE BADGES ET CHIPS
  // ============================================

  /// Badge de statut - Succès (payé, occupé)
  static BoxDecoration get badgeSuccess => BoxDecoration(
    color: AppColors.statusPaidBg,
    borderRadius: AppSpacing.chipRadius,
  );

  /// Badge de statut - Avertissement (en attente)
  static BoxDecoration get badgeWarning => BoxDecoration(
    color: AppColors.statusPendingBg,
    borderRadius: AppSpacing.chipRadius,
  );

  /// Badge de statut - Erreur (impayé, vacant)
  static BoxDecoration get badgeDanger => BoxDecoration(
    color: AppColors.statusOverdueBg,
    borderRadius: AppSpacing.chipRadius,
  );

  /// Badge de statut - Info (partiel)
  static BoxDecoration get badgeInfo => BoxDecoration(
    color: AppColors.statusPartialBg,
    borderRadius: AppSpacing.chipRadius,
  );

  /// Badge de statut - Maintenance
  static BoxDecoration get badgeMaintenance => BoxDecoration(
    color: AppColors.statusMaintenanceBg,
    borderRadius: AppSpacing.chipRadius,
  );

  // ============================================
  // STYLES D'APPBAR
  // ============================================

  /// Style d'AppBar transparent
  static AppBarTheme get appBarTheme => AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: AppSpacing.elevationSm,
    centerTitle: true,
    titleTextStyle: AppTypography.titleLarge,
    iconTheme: const IconThemeData(
      color: AppColors.textPrimary,
      size: AppSpacing.iconMd,
    ),
    actionsIconTheme: const IconThemeData(
      color: AppColors.textPrimary,
      size: AppSpacing.iconMd,
    ),
  );

  // ============================================
  // STYLES DE BOTTOM NAV
  // ============================================

  /// Style de Bottom Navigation Bar
  static BottomNavigationBarThemeData get bottomNavTheme => BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textTertiary,
    type: BottomNavigationBarType.fixed,
    elevation: AppSpacing.elevationMd,
    selectedLabelStyle: AppTypography.labelSmall.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
    ),
    unselectedLabelStyle: AppTypography.labelSmall.copyWith(
      color: AppColors.textTertiary,
    ),
  );

  // ============================================
  // STYLES DE SNACKBAR
  // ============================================

  /// SnackBar de succès
  static SnackBarThemeData get snackBarTheme => SnackBarThemeData(
    backgroundColor: AppColors.textPrimary,
    contentTextStyle: AppTypography.bodyMedium.copyWith(
      color: AppColors.textOnPrimary,
    ),
    shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
    behavior: SnackBarBehavior.floating,
    insetPadding: AppSpacing.pagePadding,
  );

  // ============================================
  // STYLES DE DIVIDER
  // ============================================

  /// Divider standard
  static const Divider divider = Divider(
    height: AppSpacing.lg,
    thickness: AppSpacing.borderThin,
    color: AppColors.divider,
  );

  /// Divider avec espacement
  static const Divider dividerWithSpace = Divider(
    height: AppSpacing.xxl,
    thickness: AppSpacing.borderThin,
    color: AppColors.divider,
  );

  // ============================================
  // STYLES D'IMAGE
  // ============================================

  /// Décoration d'image (thumbnail)
  static BoxDecoration get imageDecoration => BoxDecoration(
    borderRadius: AppSpacing.imageRadius,
    color: AppColors.shimmerBase,
  );

  /// Décoration d'avatar
  static BoxDecoration get avatarDecoration => BoxDecoration(
    shape: BoxShape.circle,
    color: AppColors.primarySurface,
    border: Border.all(
      color: AppColors.primary,
      width: AppSpacing.borderThick,
    ),
  );

  // ============================================
  // STYLES DE LOADING/SKELETON
  // ============================================

  /// Décoration de skeleton
  static BoxDecoration get skeletonDecoration => BoxDecoration(
    color: AppColors.shimmerBase,
    borderRadius: AppSpacing.cardRadius,
  );
}
