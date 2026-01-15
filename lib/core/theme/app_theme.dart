import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_styles.dart';
import 'app_typography.dart';

/// LocaGest Theme
///
/// Thème principal de l'application assemblant :
/// - Palette de couleurs (AppColors)
/// - Typographie (AppTypography)
/// - Espacements (AppSpacing)
/// - Styles de composants (AppStyles)
///
/// Direction esthétique : "Afro-Modern Professional"
/// - Moderne et épuré
/// - Touches chaleureuses inspirées de l'Afrique de l'Ouest
/// - Professionnalisme et confiance
abstract class AppTheme {
  AppTheme._();

  /// Thème clair (principal)
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Couleurs
    colorScheme: AppColors.colorScheme,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.surface,
    cardColor: AppColors.surface,
    dividerColor: AppColors.divider,
    disabledColor: AppColors.disabled,
    hintColor: AppColors.textTertiary,

    // Typographie
    textTheme: AppTypography.textTheme,
    primaryTextTheme: AppTypography.textTheme,

    // AppBar
    appBarTheme: AppStyles.appBarTheme,

    // Bottom Navigation
    bottomNavigationBarTheme: AppStyles.bottomNavTheme,

    // FAB
    floatingActionButtonTheme: AppStyles.fabTheme,

    // SnackBar
    snackBarTheme: AppStyles.snackBarTheme,

    // Boutons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: AppStyles.primaryButtonStyle,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: AppStyles.secondaryButtonStyle,
    ),
    textButtonTheme: TextButtonThemeData(
      style: AppStyles.tertiaryButtonStyle,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: AppStyles.iconButtonStyle,
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
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
        borderSide: BorderSide(
          color: AppColors.border,
          width: AppSpacing.borderThin,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: BorderSide(
          color: AppColors.border,
          width: AppSpacing.borderThin,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: BorderSide(
          color: AppColors.primary,
          width: AppSpacing.borderThick,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: BorderSide(
          color: AppColors.error,
          width: AppSpacing.borderThin,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: BorderSide(
          color: AppColors.error,
          width: AppSpacing.borderThick,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: BorderSide(
          color: AppColors.disabled,
          width: AppSpacing.borderThin,
        ),
      ),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: AppSpacing.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.cardRadius,
      ),
      margin: EdgeInsets.zero,
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.background,
      selectedColor: AppColors.primarySurface,
      labelStyle: AppTypography.labelMedium,
      padding: AppSpacing.chipPadding,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.chipRadius,
      ),
      side: BorderSide(color: AppColors.border, width: AppSpacing.borderThin),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: AppSpacing.elevationXl,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.cardRadiusLarge,
      ),
      titleTextStyle: AppTypography.titleLarge,
      contentTextStyle: AppTypography.bodyMedium,
    ),

    // Bottom Sheet
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      elevation: AppSpacing.elevationXl,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.bottomSheetRadius,
      ),
      showDragHandle: true,
      dragHandleColor: AppColors.borderMedium,
      dragHandleSize: const Size(40, 4),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: AppSpacing.borderThin,
      space: AppSpacing.lg,
    ),

    // TabBar
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: AppTypography.labelLarge,
      unselectedLabelStyle: AppTypography.labelMedium,
      indicator: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary,
            width: AppSpacing.borderThick,
          ),
        ),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
    ),

    // ListTile
    listTileTheme: ListTileThemeData(
      contentPadding: AppSpacing.listItemPadding,
      minVerticalPadding: AppSpacing.sm,
      horizontalTitleGap: AppSpacing.md,
      titleTextStyle: AppTypography.titleMedium,
      subtitleTextStyle: AppTypography.bodySmall,
      leadingAndTrailingTextStyle: AppTypography.bodySmall,
      iconColor: AppColors.textSecondary,
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      side: BorderSide(
        color: AppColors.borderMedium,
        width: AppSpacing.borderThick,
      ),
    ),

    // Radio
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.borderMedium;
      }),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.surface;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primarySurface;
        }
        return AppColors.borderMedium;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.border,
      thumbColor: AppColors.primary,
      overlayColor: AppColors.primary.withValues(alpha: 0.12),
      trackHeight: 4,
    ),

    // Progress Indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.primarySurface,
      circularTrackColor: AppColors.primarySurface,
    ),

    // Tooltip
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: AppSpacing.cardRadius,
      ),
      textStyle: AppTypography.bodySmall.copyWith(
        color: AppColors.textOnPrimary,
      ),
      padding: AppSpacing.chipPadding,
    ),

    // Date Picker
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.surface,
      headerBackgroundColor: AppColors.primary,
      headerForegroundColor: AppColors.textOnPrimary,
      dayStyle: AppTypography.bodyMedium,
      weekdayStyle: AppTypography.labelSmall,
      yearStyle: AppTypography.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.cardRadiusLarge,
      ),
    ),

    // Time Picker
    timePickerTheme: TimePickerThemeData(
      backgroundColor: AppColors.surface,
      hourMinuteTextStyle: AppTypography.displaySmall,
      dayPeriodTextStyle: AppTypography.labelLarge,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.cardRadiusLarge,
      ),
    ),

    // Popup Menu
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surface,
      elevation: AppSpacing.elevationMd,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.cardRadius,
      ),
      textStyle: AppTypography.bodyMedium,
    ),

    // Dropdown
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: AppTypography.bodyMedium,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(
            color: AppColors.border,
            width: AppSpacing.borderThin,
          ),
        ),
      ),
    ),

    // Badge
    badgeTheme: BadgeThemeData(
      backgroundColor: AppColors.error,
      textColor: AppColors.textOnPrimary,
      textStyle: AppTypography.labelSmall.copyWith(
        color: AppColors.textOnPrimary,
        fontWeight: FontWeight.w700,
      ),
    ),

    // Navigation Rail (tablet/desktop)
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.surface,
      selectedIconTheme: const IconThemeData(
        color: AppColors.primary,
        size: AppSpacing.iconMd,
      ),
      unselectedIconTheme: const IconThemeData(
        color: AppColors.textTertiary,
        size: AppSpacing.iconMd,
      ),
      selectedLabelTextStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.primary,
      ),
      unselectedLabelTextStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.textTertiary,
      ),
    ),

    // Splash et Highlight
    splashColor: AppColors.primary.withValues(alpha: 0.1),
    highlightColor: AppColors.primary.withValues(alpha: 0.05),

    // Visual Density
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  /// Configuration de la barre de statut système
  static SystemUiOverlayStyle get systemUiOverlayStyle => const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  /// Thème sombre (pour future implémentation)
  static ThemeData get dark {
    // TODO: Implémenter le thème sombre
    return light;
  }
}
