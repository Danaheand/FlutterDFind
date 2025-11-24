import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Asegúrate de que la ruta sea correcta

class CustomPaletteViewer extends StatelessWidget {
  const CustomPaletteViewer({super.key});

  @override
  Widget build(BuildContext context) {
    // Detectamos el brillo actual para saber qué constante mostrar
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Paleta Personalizada"),
        actions: [
          // Un indicador visual del modo actual
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                isDark ? "Modo Oscuro " : "Modo Claro ",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Header("Colores Base"),
          _ColorRow(
              "Primary", isDark ? AppTheme.primaryDark : AppTheme.primaryLight),
          _ColorRow("Secondary",
              isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight),
          _ColorRow("Background",
              isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight),
          _ColorRow(
              "Surface", isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight),
          _ColorRow("Card", isDark ? AppTheme.cardDark : AppTheme.cardLight),
          const _Header("Textos"),
          _ColorRow("Text Primary",
              isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
          _ColorRow(
              "Text Secondary",
              isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight),
          const _Header("Estados (Semáforo)"),
          _ColorRow(
              "Success", isDark ? AppTheme.successDark : AppTheme.successLight),
          _ColorRow(
              "Warning", isDark ? AppTheme.warningDark : AppTheme.warningLight),
          _ColorRow("Error", isDark ? AppTheme.errorDark : AppTheme.errorLight),
          const _Header("Sugerencias (Custom)"),
          _ColorRow(
              "Background",
              isDark
                  ? AppTheme.suggestionBackgroundDark
                  : AppTheme.suggestionBackgroundLight),
          _ColorRow(
              "Border",
              isDark
                  ? AppTheme.suggestionBorderDark
                  : AppTheme.suggestionBorderLight),
          _ColorRow(
              "Icon",
              isDark
                  ? AppTheme.suggestionIconDark
                  : AppTheme.suggestionIconLight),
          const _Header("Lugares y Categorías"),
          _ColorRow("Place Icon",
              isDark ? AppTheme.placeIconDark : AppTheme.placeIconLight),
          _ColorRow(
              "Badge BG",
              isDark
                  ? AppTheme.placeBadgeBackgroundDark
                  : AppTheme.placeBadgeBackgroundLight),
          _ColorRow(
              "Cat. Header",
              isDark
                  ? AppTheme.categoryHeaderDark
                  : AppTheme.categoryHeaderLight),
          _ColorRow("Cat. Icon",
              isDark ? AppTheme.categoryIconDark : AppTheme.categoryIconLight),
          const _Header("Modo Compras"),
          _ColorRow(
              "Shopping BG",
              isDark
                  ? AppTheme.shoppingModeBackgroundDark
                  : AppTheme.shoppingModeBackgroundLight),
          _ColorRow(
              "Shopping Tile",
              isDark
                  ? AppTheme.shoppingModeTileDark
                  : AppTheme.shoppingModeTileLight),
          _ColorRow("Purchased Item",
              isDark ? AppTheme.purchasedDark : AppTheme.purchasedLight),
          const _Header("Utilidades"),
          _ColorRow(
              "Divider", isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
        ],
      ),
    );
  }
}

// --- Widgets Auxiliares para que se vea bonito ---

class _Header extends StatelessWidget {
  final String title;
  const _Header(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String name;
  final Color color;

  const _ColorRow(this.name, this.color);

  @override
  Widget build(BuildContext context) {
    // Calculamos si el color es oscuro para poner el texto blanco o negro encima
    final isColorDark =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
    final textColor = isColorDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 60,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)), // Borde sutil
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nombre del color
          Text(
            name,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          // Código Hexadecimal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "#${color.value.toRadixString(16).substring(2).toUpperCase()}",
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontFamily: 'Courier', // Fuente tipo código
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
