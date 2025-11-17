import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trash_item.dart';
import '../models/shopping_item.dart';

class TrashService {
  static const String _trashKey = 'trash_items';
  static TrashService? _instance;
  List<TrashItem> _trashItems = [];
  bool _initialized = false;

  TrashService._();

  static TrashService getInstance() {
    _instance ??= TrashService._();
    return _instance!;
  }

  /// Verificar si ya está inicializado
  bool get isInitialized => _initialized;

  /// Cargar elementos de papelera desde SharedPreferences
  Future<void> loadTrashItems() async {
    if (_initialized) return; // Evitar inicializar dos veces
    
    final prefs = await SharedPreferences.getInstance();
    final trashJson = prefs.getString(_trashKey);
    
    if (trashJson != null) {
      final List<dynamic> trashList = jsonDecode(trashJson);
      _trashItems = trashList.map((item) => TrashItem.fromJson(item)).toList();
    }
    
    _initialized = true;
  }

  // Guardar elementos de papelera en SharedPreferences
  Future<void> _saveTrashItems() async {
    final prefs = await SharedPreferences.getInstance();
    final trashJson = jsonEncode(_trashItems.map((item) => item.toJson()).toList());
    await prefs.setString(_trashKey, trashJson);
  }

  // Agregar elemento a la papelera (con inicialización automática)
  Future<void> addToTrash(TrashItem item) async {
    if (!_initialized) {
      await loadTrashItems();
    }
    _trashItems.add(item);
    await _saveTrashItems();
  }

  // Método específico para agregar ShoppingItem a papelera
  Future<void> addShoppingItemToTrash(ShoppingItem item) async {
    final trashItem = TrashItem.fromShoppingItem(
      item.id,
      item.name,
      item.placeName,
      item.category,
      item.quantity,
    );
    await addToTrash(trashItem);
  }

  // Obtener todos los elementos de papelera
  List<TrashItem> getTrashItems() {
    // Si no está inicializado, retornar lista vacía
    // (La inicialización ocurrirá de forma asincrónica)
    if (!_initialized) {
      return [];
    }
    return List.from(_trashItems);
  }

  // Restaurar elemento (eliminarlo de papelera)
  Future<TrashItem> restoreItem(String itemId) async {
    if (!_initialized) {
      await loadTrashItems();
    }
    final itemIndex = _trashItems.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      final restoredItem = _trashItems.removeAt(itemIndex);
      await _saveTrashItems();
      return restoredItem;
    }
    throw Exception('Item not found in trash');
  }

  // Eliminar permanentemente un elemento
  Future<void> deleteItemPermanently(String itemId) async {
    if (!_initialized) {
      await loadTrashItems();
    }
    _trashItems.removeWhere((item) => item.id == itemId);
    await _saveTrashItems();
  }

  // Vaciar papelera completamente
  Future<void> emptyTrash() async {
    if (!_initialized) {
      await loadTrashItems();
    }
    _trashItems.clear();
    await _saveTrashItems();
  }

  // Convertir TrashItem de vuelta a ShoppingItem para restaurar
  ShoppingItem trashItemToShoppingItem(TrashItem trashItem) {
    return ShoppingItem(
      id: trashItem.id,
      name: trashItem.name,
      placeName: trashItem.placeName,
      category: trashItem.category,
      quantity: trashItem.quantity,
    );
  }
}