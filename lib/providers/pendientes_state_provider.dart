import 'package:flutter/material.dart';

class PendientesStateProvider extends ChangeNotifier {
  final Map<String, bool> _expandedPlaces = {};

  /// Obtiene el estado de expansión de una categoría
  bool isExpanded(String place) => _expandedPlaces[place] ?? true;

  /// Alterna el estado de expansión de una categoría
  void togglePlace(String place) {
    final currentState = _expandedPlaces[place] ?? true;
    _expandedPlaces[place] = !currentState;
    notifyListeners();
  }

  /// Establece el estado de expansión de una categoría
  void setExpanded(String place, bool expanded) {
    _expandedPlaces[place] = expanded;
    notifyListeners();
  }

  /// Obtiene todos los lugares expandidos
  Map<String, bool> get expandedPlaces => _expandedPlaces;

  /// Limpia todos los estados (si lo necesitas)
  void clear() {
    _expandedPlaces.clear();
    notifyListeners();
  }
}
