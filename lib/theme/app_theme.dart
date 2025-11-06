import 'package:flutter/material.dart';

class AppTheme {
  // Colores primarios
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF42A5F5);

  static const Color secondaryLight = Color(0xFFFF9800);
  static const Color secondaryDark = Color(0xFFFFB74D);

  // Colores de superficie
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121212);

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);

  // Colores de fondo
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);

  // Colores de texto
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Colores de sugerencias
  static const Color suggestionBackgroundLight = Color(0xFFFFF8E1);
  static const Color suggestionBackgroundDark = Color(0xFF3E2723);

  static const Color suggestionBorderLight = Color(0xFFFFD54F);
  static const Color suggestionBorderDark = Color(0xFFFFA726);

  static const Color suggestionIconLight = Color(0xFFF57C00);
  static const Color suggestionIconDark = Color(0xFFFFB74D);

  // Colores de estado
  static const Color successLight = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF66BB6A);

  static const Color errorLight = Color(0xFFF44336);
  static const Color errorDark = Color(0xFFEF5350);

  static const Color warningLight = Color(0xFFFF9800);
  static const Color warningDark = Color(0xFFFFB74D);

  // Colores para agrupación
  static const Color placeIconLight = Color(0xFF1976D2);
  static const Color placeIconDark = Color(0xFF42A5F5);

  static const Color placeBadgeBackgroundLight = Color(0xFFBBDEFB);
  static const Color placeBadgeBackgroundDark = Color(0xFF1565C0);

  static const Color categoryHeaderLight = Color(0xFFF5F5F5);
  static const Color categoryHeaderDark = Color(0xFF2C2C2C);

  static const Color categoryIconLight = Color(0xFF616161);
  static const Color categoryIconDark = Color(0xFF9E9E9E);

  // Colores de modo compras
  static const Color shoppingModeBackgroundLight = Color(0xFFE3F2FD);
  static const Color shoppingModeBackgroundDark = Color(0xFF0D47A1);

  static const Color shoppingModeTileLight = Color(0xFFBBDEFB);
  static const Color shoppingModeTileDark = Color(0xFF1565C0);

  // Colores de items comprados
  static const Color purchasedLight = Color(0xFF9E9E9E);
  static const Color purchasedDark = Color(0xFF616161);

  // Divisores y bordes
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        surface: surfaceLight,
        error: errorLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundLight,
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: surfaceLight,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryLight;
          }
          return null;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryLight;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryLight.withOpacity(0.5);
          }
          return null;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerLight,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        surface: surfaceDark,
        error: errorDark,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimaryDark,
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: backgroundDark,
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.black,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: const BorderSide(color: primaryDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: cardDark,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryDark;
          }
          return null;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryDark;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryDark.withOpacity(0.5);
          }
          return null;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerDark,
        thickness: 1,
      ),
    );
  }

  // Helpers para obtener colores según el tema actual
  static Color getSuggestionBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? suggestionBackgroundLight
        : suggestionBackgroundDark;
  }

  static Color getSuggestionBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? suggestionBorderLight
        : suggestionBorderDark;
  }

  static Color getSuggestionIcon(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? suggestionIconLight
        : suggestionIconDark;
  }

  static Color getPlaceIcon(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? placeIconLight
        : placeIconDark;
  }

  static Color getPlaceBadgeBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? placeBadgeBackgroundLight
        : placeBadgeBackgroundDark;
  }

  static Color getCategoryHeader(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? categoryHeaderLight
        : categoryHeaderDark;
  }

  static Color getCategoryIcon(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? categoryIconLight
        : categoryIconDark;
  }

  static Color getShoppingModeBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? shoppingModeBackgroundLight
        : shoppingModeBackgroundDark;
  }

  static Color getShoppingModeTile(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? shoppingModeTileLight
        : shoppingModeTileDark;
  }

  static Color getPurchasedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? purchasedLight
        : purchasedDark;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? textSecondaryLight
        : textSecondaryDark;
  }
}
