import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider with ChangeNotifier {
  late Connectivity _connectivity;
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  ConnectivityProvider() {
    _connectivity = Connectivity();
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
  }

  /// Inicializa el estado de conectividad actual
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result.isNotEmpty) {
        _updateConnectionStatus(result.first);
      }
    } catch (e) {
      print('Error checking connectivity: $e');
    }
  }

  /// Actualiza el estado de conectividad
  void _updateConnectionStatus(ConnectivityResult result) {
    final previousState = _isConnected;
    _isConnected = result != ConnectivityResult.none;

    // Solo notificar si el estado cambió
    if (previousState != _isConnected) {
      notifyListeners();
      print(
          '🌐 Estado de conectividad cambió: ${_isConnected ? "Conectado" : "Desconectado"}');
    }
  }
}
