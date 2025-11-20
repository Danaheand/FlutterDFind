import 'package:flutter/material.dart';

class PaletteViewer extends StatelessWidget {
  const PaletteViewer({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Paleta de Colores Actual")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Header("Colores Principales (Marca)"),
          _ColorRow("Primary", scheme.primary, scheme.onPrimary),
          _ColorRow("Primary Container", scheme.primaryContainer,
              scheme.onPrimaryContainer),
          const _Header("Colores Secundarios"),
          _ColorRow("Secondary", scheme.secondary, scheme.onSecondary),
          _ColorRow("Secondary Container", scheme.secondaryContainer,
              scheme.onSecondaryContainer),
          const _Header("Colores Terciarios (Sugerencias/Extras)"),
          _ColorRow("Tertiary", scheme.tertiary, scheme.onTertiary),
          _ColorRow("Tertiary Container", scheme.tertiaryContainer,
              scheme.onTertiaryContainer),
          const _Header("Estado de Error"),
          _ColorRow("Error", scheme.error, scheme.onError),
          _ColorRow("Error Container", scheme.errorContainer,
              scheme.onErrorContainer),
          const _Header("Superficies y Fondos"),
          _ColorRow(
              "Surface (Fondo General)", scheme.surface, scheme.onSurface),
          _ColorRow("Surface Container (Tarjetas)", scheme.surfaceContainer,
              scheme.onSurface),
          _ColorRow("Surface Container High", scheme.surfaceContainerHigh,
              scheme.onSurface),
          const _Header("Utilidades"),
          _ColorRow("Outline (Bordes)", scheme.outline, scheme.surface),
          _ColorRow("Inverse Surface (Snackbars)", scheme.inverseSurface,
              scheme.onInverseSurface),
        ],
      ),
    );
  }
}

// Widget auxiliar para dibujar cada fila
class _ColorRow extends StatelessWidget {
  final String name;
  final Color color;
  final Color onColor;

  const _ColorRow(this.name, this.color, this.onColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style: TextStyle(color: onColor, fontWeight: FontWeight.bold)),
          Text(
            "#${color.value.toRadixString(16).substring(2).toUpperCase()}",
            style: TextStyle(color: onColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}
