import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trash_item.dart';
import '../models/shopping_item.dart';

class TrashService {
  static const String _trashKey = 'trash_items';
  static TrashService? _instance;
  List<TrashItem> _trashItems = [];

  TrashService._();

  static TrashService getInstance() {
    _instance ??= TrashService._();
    return _instance!;
  }

  // Cargar elementos de papelera desde SharedPreferences
  Future<void> loadTrashItems() async {
    final prefs = await SharedPreferences.getInstance();
    final trashJson = prefs.getString(_trashKey);
    
    if (trashJson != null) {
      final List<dynamic> trashList = jsonDecode(trashJson);
      _trashItems = trashList.map((item) => TrashItem.fromJson(item)).toList();
    }
  }

  // Guardar elementos de papelera en SharedPreferences
  Future<void> _saveTrashItems() async {
    final prefs = await SharedPreferences.getInstance();
    final trashJson = jsonEncode(_trashItems.map((item) => item.toJson()).toList());
    await prefs.setString(_trashKey, trashJson);
  }

  // Agregar elemento a la papelera
  Future<void> addToTrash(TrashItem item) async {
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
    return List.from(_trashItems);
  }

  // Restaurar elemento (eliminarlo de papelera)
  Future<TrashItem> restoreItem(String itemId) async {
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
    _trashItems.removeWhere((item) => item.id == itemId);
    await _saveTrashItems();
  }

  // Vaciar papelera completamente
  Future<void> emptyTrash() async {
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