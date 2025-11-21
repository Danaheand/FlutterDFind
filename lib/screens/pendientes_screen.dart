import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:confetti/confetti.dart';

import '../providers/font_size_provider.dart';
import '../models/shopping_item.dart';
import '../theme/app_theme.dart';
import '../services/trash_service.dart';
import '../services/session_manager.dart';
import 'widgets/modal_pendientes.dart';
import 'widgets/tips_section.dart';

typedef AddToShoppingList = void Function(String name);

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  static AddToShoppingList? addFromAlertGlobal;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<ShoppingItem> _items = [];
  final Map<String, bool> _expandedPlaces = {};
  final Map<String, ConfettiController> _confettiControllers = {};
  late final TrashService _trashService;

  bool _loading = false;

  /// ✔ CORREO DEL USUARIO LOGUEADO
  late String _correoUsuario;

  /// ✔ URL BASE DE LA API
  final String baseUrl = 'https://dfindapi-yfcq.onrender.com';

  @override
  void initState() {
    super.initState();
    InventoryScreen.addFromAlertGlobal = addFromAlert;
    _trashService = TrashService.getInstance();
    _initialize();
  }

  @override
  void dispose() {
    InventoryScreen.addFromAlertGlobal = null;
    for (var controller in _confettiControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    debugPrint("Inicializando pantalla Pendientes...");

    try {
      _correoUsuario = SessionManager.instance.userEmail ?? "";

      if (_correoUsuario.isEmpty) {
        debugPrint("ERROR: correoUsuario está vacío");
        return;
      }

      debugPrint("Usuario logueado: $_correoUsuario");

      await _trashService.loadTrashItems();
      await _loadItemsFromAPI();
    } catch (e, st) {
      debugPrint("ERROR en init(): $e");
      debugPrint("$st");
    }
  }

  // ================================================================
  //                            API CALLS
  // ================================================================

  /// GET — Cargar pendientes desde API (TRAER TODOS, sin soloComprados)
  Future<void> _loadItemsFromAPI() async {
    setState(() => _loading = true);
    debugPrint(" GET pendientes desde API...");

    final url = Uri.parse(
      "$baseUrl/api/Pendientes/by-email/$_correoUsuario",
    );

    debugPrint("URL GET Pendientes: $url");

    try {
      final res = await http.get(url);
      debugPrint("GET status: ${res.statusCode}");
      debugPrint("GET body: ${res.body}");

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);

        _items.clear();
        for (var p in data) {
          _items.add(
            ShoppingItem(
              id: p["idPendiente"],
              name: p["nombre"],
              placeName: p["lugar"],
              category: p["categoria"],
              quantity: p["cantidad"],
              isPurchased: p["estaComprado"],
            ),
          );
        }
        debugPrint("Items cargados en memoria: ${_items.length}");
        setState(() {});
      } else {
        debugPrint("Error GET: ${res.body}");
      }
    } catch (e, st) {
      debugPrint("Excepción en GET: $e");
      debugPrint("$st");
    }

    setState(() => _loading = false);
  }

  /// POST — Crear un pendiente
  Future<void> _createItem(String name, String place, int quantity) async {
    debugPrint("POST creando pendiente: $name");

    final url = Uri.parse("$baseUrl/api/Pendientes");

    final body = {
      "correoUsuario": _correoUsuario,
      "nombre": name,
      "lugar": place,
      "categoria": "General",
      "cantidad": quantity,
    };

    debugPrint(" URL POST Pendiente: $url");
    debugPrint("Body POST: $body");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      debugPrint("POST status: ${res.statusCode}");
      debugPrint("POST body: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        final p = jsonDecode(res.body);

        setState(() {
          _items.add(
            ShoppingItem(
              id: p["idPendiente"],
              name: p["nombre"],
              placeName: p["lugar"],
              category: p["categoria"],
              quantity: p["cantidad"],
              isPurchased: p["estaComprado"],
            ),
          );
        });
        debugPrint("Items tras crear: ${_items.length}");
      } else {
        debugPrint("Error POST: ${res.body}");
      }
    } catch (e, st) {
      debugPrint("Excepción POST: $e");
      debugPrint("$st");
    }
  }

  /// PUT — Marcar comprado/no comprado (maneja 200/204)
  Future<void> _toggleAPI(ShoppingItem item) async {
    debugPrint("TOGGLE pendiente: ${item.name}");

    final url = Uri.parse(
      "$baseUrl/api/Pendientes/by-email/$_correoUsuario/toggle-comprado-por-nombre"
      "?nombre=${Uri.encodeComponent(item.name)}"
      "&lugar=${Uri.encodeComponent(item.placeName)}",
    );

    debugPrint("URL TOGGLE: $url");

    try {
      final res = await http.put(url);

      debugPrint("TOGGLE status: ${res.statusCode}");
      debugPrint("TOGGLE body: ${res.body}");

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);

        setState(() {
          item.isPurchased = data["estaComprado"];
        });
        _checkPlaceCompletion(item.placeName);
        return;
      }

      if (res.statusCode == 204) {
        debugPrint("TOGGLE 204 sin body, cambio local de estado.");
        setState(() {
          item.isPurchased = !item.isPurchased;
        });
        _checkPlaceCompletion(item.placeName);
        return;
      }

      debugPrint(
        "Error TOGGLE: Código ${res.statusCode} | Body: ${res.body}",
      );
    } catch (e, st) {
      debugPrint("Excepción TOGGLE: $e");
      debugPrint("$st");
    }
  }

  /// PUT — Eliminar pendiente
  Future<void> _deleteAPI(ShoppingItem item) async {
    debugPrint("DELETE (lógico) pendiente: ${item.name}");

    final url = Uri.parse(
      "$baseUrl/api/Pendientes/by-email/$_correoUsuario/eliminar-por-nombre"
      "?nombre=${Uri.encodeComponent(item.name)}"
      "&lugar=${Uri.encodeComponent(item.placeName)}",
    );

    debugPrint("URL DELETE: $url");

    try {
      final res = await http.put(url);

      debugPrint("DELETE status: ${res.statusCode}");
      debugPrint("DELETE body: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() => _items.remove(item));
        debugPrint("Items tras eliminar: ${_items.length}");
      } else {
        debugPrint("Error DELETE: ${res.body}");
      }
    } catch (e, st) {
      debugPrint("Excepción DELETE: $e");
      debugPrint("$st");
    }
  }

  // ================================================================
  //                     LÓGICA LOCAL
  // ================================================================

  void addFromAlert(String name) async {
    await _createItem(name, "Supermercado", 1);
  }

  void _addItemManually(String name, String placeName, int quantity) async {
    await _createItem(name, placeName, quantity);
  }

  void _toggleItem(ShoppingItem item) async {
    await _toggleAPI(item);
  }

  void _removeItem(ShoppingItem item) async {
    await _deleteAPI(item);
  }

  /// Verifica si todos los items de una categoría están completos
  void _checkPlaceCompletion(String place) {
    final itemsInPlace = _items.where((i) => i.placeName == place).toList();

    if (itemsInPlace.isEmpty) return;

    final allCompleted = itemsInPlace.every((i) => i.isPurchased);

    if (allCompleted) {
      _playConfettiForPlace(place);
    }
  }

  void _playConfettiForPlace(String place) {
    if (!_confettiControllers.containsKey(place)) {
      _confettiControllers[place] = ConfettiController(
        duration: const Duration(milliseconds: 1200),
      );
    }
    _confettiControllers[place]!.play();
  }

  // ================================================================
  //                            UI
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pendientes'),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildNormalView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => ModalPendientes(
              onAdd: _addItemManually,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNormalView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TipsSection(),
          const SizedBox(height: 16),
          _buildPendingSection(),
        ],
      ),
    );
  }

  // --------------------- POR COMPRAR ---------------------

  Widget _buildPendingSection() {
    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.grey[100]
              : AppTheme.categoryHeaderDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: AppTheme.getTextSecondary(context),
            ),
            const SizedBox(height: 8),
            Consumer<FontSizeProvider>(
              builder: (context, fontSizeProvider, _) => Text(
                '¡Tu lista de compras está vacía!',
                style: TextStyle(
                  fontSize: fontSizeProvider.fontSize,
                  color: AppTheme.getTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupItemsByPlace(_items);
    final places = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<FontSizeProvider>(
          builder: (context, fontSizeProvider, _) => Text(
            'Pendientes',
            style: TextStyle(
              fontSize: fontSizeProvider.fontSize + 4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...places.map((place) => _buildPlaceGroup(place, grouped[place]!)),
      ],
    );
  }

  Map<String, List<ShoppingItem>> _groupItemsByPlace(List<ShoppingItem> items) {
    final grouped = <String, List<ShoppingItem>>{};
    for (var item in items) {
      grouped.putIfAbsent(item.placeName, () => []);
      grouped[item.placeName]!.add(item);
    }
    return grouped;
  }

  Widget _buildPlaceGroup(String place, List<ShoppingItem> items) {
    final isExpanded = _expandedPlaces[place] ?? true;
    final totalItems = items.length;
    
    // Crear controlador si no existe
    if (!_confettiControllers.containsKey(place)) {
      _confettiControllers[place] = ConfettiController(
        duration: const Duration(milliseconds: 1200),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedPlaces[place] = !isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.store, color: AppTheme.getPlaceIcon(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Consumer<FontSizeProvider>(
                          builder: (context, fontSizeProvider, _) => Text(
                            place,
                            style: TextStyle(
                              fontSize: fontSizeProvider.fontSize + 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.getPlaceBadgeBackground(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalItems',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.light
                                ? AppTheme.placeIconLight
                                : AppTheme.textPrimaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                const Divider(height: 1),
                ...items.map(
                  (item) => ListTile(
                    leading: Checkbox(
                      value: item.isPurchased,
                      onChanged: (_) => _toggleItem(item),
                    ),
                    title: Consumer<FontSizeProvider>(
                      builder: (context, fontSizeProvider, _) => Text(
                        item.name,
                        style: TextStyle(
                          fontSize: fontSizeProvider.fontSize + 2,
                          decoration: item.isPurchased 
                              ? TextDecoration.lineThrough 
                              : TextDecoration.none,
                          color: item.isPurchased 
                              ? AppTheme.getPurchasedColor(context)
                              : null,
                        ),
                      ),
                    ),
                    subtitle: item.quantity != null && item.quantity! > 1
                        ? Consumer<FontSizeProvider>(
                            builder: (context, fontSizeProvider, _) => Text(
                              'Cantidad: ${item.quantity}',
                              style: TextStyle(
                                fontSize: fontSizeProvider.fontSize - 2,
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => _removeItem(item),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Confetti widget - positioned absolutely to fill the entire space
        Positioned.fill(
          child: IgnorePointer(
            child: ConfettiWidget(
              confettiController: _confettiControllers[place]!,
              blastDirection: pi / 2,
              emissionFrequency: 0.85,
              numberOfParticles: 150,
              maxBlastForce: 400,
              minBlastForce: 200,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                Color(0xFF2196F3),
                Color(0xFFFF5722),
                Color(0xFF4CAF50),
                Color(0xFFFFC107),
                Color(0xFF9C27B0),
                Color(0xFFFF9800),
                Color(0xFFE91E63),
                Color(0xFF00BCD4),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
