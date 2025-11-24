import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TipsProvider extends ChangeNotifier {
  bool _showTips = true;
  bool _isInitialized = false;

  bool get showTips => _showTips;
  bool get isInitialized => _isInitialized;

  /// Inicializar cargando desde SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _showTips = prefs.getBool('show_tips') ?? true;
      print('💡 TipsProvider inicializado: $_showTips');
    } catch (e) {
      print('❌ Error inicializando TipsProvider: $e');
      _showTips = true;
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  void setShowTips(bool value) async {
    print('💡 TipsProvider.setShowTips($_showTips → $value)');
    if (_showTips != value) {
      _showTips = value;
      
      // Guardar en SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('show_tips', value);
        print('💡 TipsProvider guardado en SharedPreferences: $_showTips');
      } catch (e) {
        print('❌ Error guardando en SharedPreferences: $e');
      }
      
      notifyListeners();
      print('💡 TipsProvider notificando cambio: $_showTips');
    } else {
      print('💡 TipsProvider: valor no cambió');
    }
  }

  void toggleTips() {
    setShowTips(!_showTips);
  }
}