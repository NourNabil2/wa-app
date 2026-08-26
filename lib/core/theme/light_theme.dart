// ==================== Light Theme ====================
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'colors.dart';
import 'text_theme.dart';

/// Instant-swap page transition — no animation at all.
/// Used on web/desktop platforms where slide transitions feel wrong,
/// especially in RTL Arabic layouts.
class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

class LightTheme {
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppTextTheme.fontFamily, // ← global default; all Text() inherits Tajawal
    // Primary Colors
    primaryColor: ColorsManager.primaryColor,
    primaryColorLight: ColorsManager.secondaryColor,
    primaryColorDark: ColorsManager.primaryColor,

    // Card & Surface Colors
    cardColor: ColorsManager.defaultSurface,
    scaffoldBackgroundColor: ColorsManager.backgroundSurface,
    canvasColor: ColorsManager.defaultSurface,

    // Color Scheme
    colorScheme: ColorScheme.light(
      primary: ColorsManager.primaryColor,
      secondary: ColorsManager.secondaryColor,

      // Surface colors
      surface: ColorsManager.defaultSurface,
      surfaceContainerHighest: ColorsManager.backgroundCard,

      // Error colors
      error: ColorsManager.errorFill,
      onError: ColorsManager.errorOnFill,
      errorContainer: ColorsManager.errorSurface,

      // On colors (text on surfaces)
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: ColorsManager.defaultText,
      onSurfaceVariant: ColorsManager.defaultTextSecondary,

      // Outline & Shadow
      outline: ColorsManager.inputBorder,
      shadow: Colors.black.withValues(alpha: 0.1),
    ),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: ColorsManager.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: AppTextTheme.fontFamily,
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: ColorsManager.primary2Color,
      unselectedItemColor: ColorsManager.inputBorder,
      backgroundColor: Colors.white,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontFamily: AppTextTheme.fontFamily,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontFamily: AppTextTheme.fontFamily,
      ),
    ),

    // Bottom App Bar Theme
    bottomAppBarTheme: const BottomAppBarTheme(
      elevation: 0,
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape:  RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsManager.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape:  RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: AppTextTheme.fontFamily,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorsManager.primaryColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: AppTextTheme.fontFamily,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorsManager.inputSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      // Borders
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ColorsManager.inputBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ColorsManager.inputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ColorsManager.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ColorsManager.errorFill, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ColorsManager.errorFill, width: 2),
      ),

      // Text styles
      hintStyle: const TextStyle(
        color: ColorsManager.inputBorder,
        fontFamily: AppTextTheme.fontFamily,
      ),
      labelStyle: const TextStyle(
        color: ColorsManager.defaultTextSecondary,
        fontFamily: AppTextTheme.fontFamily,
      ),
      errorStyle: const TextStyle(
        color: ColorsManager.errorText,
        fontFamily: AppTextTheme.fontFamily,
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: ColorsManager.defaultText,
      size: 24,
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: ColorsManager.inputBorder,
      thickness: 1,
      space: 1,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: ColorsManager.primaryColor.withValues(alpha: 0.1),
      selectedColor: ColorsManager.primaryColor,
      disabledColor: ColorsManager.inputBorder.withValues(alpha: 0.3),
      labelStyle: const TextStyle(
        color: ColorsManager.primaryColor,
        fontFamily: AppTextTheme.fontFamily,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontFamily: AppTextTheme.fontFamily,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape:  RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Text Theme
    textTheme: AppTextTheme.lightTextTheme,

    // Page Transitions
    // Web/desktop: instant swap (no slide) — skeleton on each page handles the
    // loading feel. Mobile keeps native iOS/Android transitions.
    pageTransitionsTheme: PageTransitionsTheme(
      builders: kIsWeb ? {
        for (final p in TargetPlatform.values) p: const _NoTransitionBuilder(),
      } : const {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS:   _NoTransitionBuilder(),
        TargetPlatform.windows: _NoTransitionBuilder(),
        TargetPlatform.linux:   _NoTransitionBuilder(),
      },
    ),
  );
}

