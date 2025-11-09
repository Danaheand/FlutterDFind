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
}
