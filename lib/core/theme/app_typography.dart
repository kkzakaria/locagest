import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// LocaGest Typography System
///
/// Polices choisies :
/// - Display/Titres : Plus Jakarta Sans
///   Moderne, géométrique avec du caractère, professionnelle
/// - Body : Source Sans 3
///   Excellente lisibilité, neutre mais élégante
///
/// Échelle typographique basée sur un ratio de 1.25 (Major Third)
abstract class AppTypography {
  AppTypography._();

  // ============================================
  // FONT FAMILIES
  // ============================================

  /// Police pour les titres et éléments d'accroche
  static String get displayFontFamily => GoogleFonts.plusJakartaSans().fontFamily!;

  /// Police pour le contenu et la lecture
  static String get bodyFontFamily => GoogleFonts.sourceSans3().fontFamily!;

  // ============================================
  // DISPLAY STYLES (Grands titres)
  // ============================================

  /// Display Large - 57px
  /// Usage : Écrans de bienvenue, pages d'erreur
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.12,
    color: AppColors.textPrimary,
  );

  /// Display Medium - 45px
  /// Usage : Grands KPIs, montants importants
  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.16,
    color: AppColors.textPrimary,
  );

  /// Display Small - 36px
  /// Usage : Titres de sections majeures
  static TextStyle get displaySmall => GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.22,
    color: AppColors.textPrimary,
  );

  // ============================================
  // HEADLINE STYLES (Titres de page)
  // ============================================

  /// Headline Large - 32px
  /// Usage : Titres de page principaux
  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  /// Headline Medium - 28px
  /// Usage : Sous-titres importants, noms d'immeubles
  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
    color: AppColors.textPrimary,
  );

  /// Headline Small - 24px
  /// Usage : Titres de cartes, sections
  static TextStyle get headlineSmall => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
    color: AppColors.textPrimary,
  );

  // ============================================
  // TITLE STYLES (Titres de composants)
  // ============================================

  /// Title Large - 22px
  /// Usage : Titres d'AppBar, modals
  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
    color: AppColors.textPrimary,
  );

  /// Title Medium - 16px
  /// Usage : Titres de cartes, noms de locataires
  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Title Small - 14px
  /// Usage : Labels importants, badges
  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.textPrimary,
  );

  // ============================================
  // BODY STYLES (Contenu)
  // ============================================

  /// Body Large - 16px
  /// Usage : Paragraphes principaux, descriptions
  static TextStyle get bodyLarge => GoogleFonts.sourceSans3(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Body Medium - 14px
  /// Usage : Contenu standard, listes
  static TextStyle get bodyMedium => GoogleFonts.sourceSans3(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.textPrimary,
  );

  /// Body Small - 12px
  /// Usage : Texte secondaire, métadonnées
  static TextStyle get bodySmall => GoogleFonts.sourceSans3(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.textSecondary,
  );

  // ============================================
  // LABEL STYLES (UI Elements)
  // ============================================

  /// Label Large - 14px
  /// Usage : Boutons, tabs, navigation
  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.textPrimary,
  );

  /// Label Medium - 12px
  /// Usage : Labels de formulaires, chips
  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
    color: AppColors.textPrimary,
  );

  /// Label Small - 11px
  /// Usage : Badges, timestamps, hints
  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  // ============================================
  // STYLES SPÉCIAUX
  // ============================================

  /// Montant en devise (FCFA)
  static TextStyle get currency => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// Grand montant (KPI)
  static TextStyle get currencyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.12,
    color: AppColors.textPrimary,
  );

  /// Pourcentage (taux d'occupation)
  static TextStyle get percentage => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// Numéro de référence
  static TextStyle get reference => GoogleFonts.sourceCodePro(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// Texte de bouton
  static TextStyle get button => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.43,
  );

  /// Texte de lien
  static TextStyle get link => GoogleFonts.sourceSans3(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.primary,
  );

  /// Texte d'erreur
  static TextStyle get error => GoogleFonts.sourceSans3(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.error,
  );

  /// Placeholder/Hint
  static TextStyle get hint => GoogleFonts.sourceSans3(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.textTertiary,
  );

  // ============================================
  // TEXT THEME (Material 3)
  // ============================================

  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
