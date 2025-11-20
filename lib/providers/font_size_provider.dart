import 'package:flutter/material.dart';

class FontSizeProvider extends ChangeNotifier {
  bool _enabled = false;
  double _fontSize = 16.0;

  bool get enabled => _enabled;
  double get fontSize => _fontSize;

  void setEnabled(bool v) {
    _enabled = v;
    notifyListeners();
  }

  void setFontSize(double v) {
    _fontSize = v;
    notifyListeners();
  }

  // Métodos helper para escalar tamaños de fuente según el ajuste de accesibilidad
  double getScaledSize(double baseSize) {
    if (!_enabled) return baseSize;
    // Aplicar un multiplicador basado en el fontSize configurado
    // 16.0 es el default, así que si es mayor, escalamos proporcionalmente
    return baseSize * (_fontSize / 16.0);
  }

  // Helper para textos grandes (títulos)
  double get largeFontSize => getScaledSize(24);

  // Helper para textos medianos (subtítulos, labels)
  double get mediumFontSize => getScaledSize(16);

  // Helper para textos pequeños (helper text, labels pequeños)
  double get smallFontSize => getScaledSize(12);

  // Helper para textos muy pequeños
  double get tinyFontSize => getScaledSize(10);
}
