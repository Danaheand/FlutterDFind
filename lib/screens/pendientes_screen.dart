import 'dart:convert';
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

// 👇 CAMBIO AQUÍ: de SingleTickerProviderStateMixin a TickerProviderStateMixin
class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin {
  final List<ShoppingItem> _items = [];
  final Map<String, bool> _expandedPlaces = {};
  late final TrashService _trashService;

  bool _loading = false;

  /// Correo del usuario logueado
  late String _correoUsuario;

  /// URL base de la API
  final String baseUrl = 'https://dfindapi-yfcq.onrender.com';

  // 🎉 Controladores globales de confeti
  late final ConfettiController _taskConfettiController;
  late final ConfettiController _placeConfettiController;

  @override
  void initState() {
    super.initState();
    InventoryScreen.addFromAlertGlobal = addFromAlert;
    _trashService = TrashService.getInstance();

    _taskConfettiController = ConfettiController(
      duration: const Duration(milliseconds: 900),
    );
    _placeConfettiController = ConfettiController(
      duration: const Duration(milliseconds: 1200),
    );

    _initialize();
  }

  @override
  void dispose() {
    InventoryScreen.addFromAlertGlobal = null;
    _taskConfettiController.dispose();
    _placeConfettiController.dispose();
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

  /// GET — Cargar pendientes desde API
  Future<void> _loadItemsFromAPI() async {
    setState(() => _loading = true);
    debugPrint("GET pendientes desde API...");

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

    debugPrint("URL POST Pendiente: $url");
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

  /// PUT — Marcar comprado/no comprado (solo sincroniza con API)
  Future<void> _toggleAPI(ShoppingItem item, bool expectedValue) async {
    debugPrint("TOGGLE pendiente API: ${item.name}");

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
        // Podrías usar la respuesta si quisieras forzar el valor del servidor.
        return;
      }

      if (res.statusCode == 204) {
        // Servidor hizo toggle sin body.
        return;
      }

      debugPrint(
        "Error TOGGLE API: Código ${res.statusCode} | Body: ${res.body}",
      );
    } catch (e, st) {
      debugPrint("Excepción TOGGLE API: $e");
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

  /// Maneja: estado local + confeti + mensaje SIEMPRE
  void _toggleItem(ShoppingItem item) async {
    final wasPurchased = item.isPurchased;
    final newValue = !wasPurchased;

    // 1) Actualizar UI de inmediato
    setState(() {
      item.isPurchased = newValue;
    });

    // 2) Si acaba de pasar a realizado → SIEMPRE confeti + mensaje
    if (!wasPurchased && newValue) {
      _showItemCompletedMessage();
      _playTaskConfetti();
    }

    // 3) Revisar si el lugar quedó completado
    _checkPlaceCompletion(item.placeName);

    // 4) Sincronizar con API (aunque falle, ya mostramos UX)
    await _toggleAPI(item, newValue);
  }

  void _removeItem(ShoppingItem item) async {
    await _deleteAPI(item);
  }

  /// Verifica si todos los items de una categoría (lugar) están completos
  void _checkPlaceCompletion(String place) {
    final itemsInPlace = _items.where((i) => i.placeName == place).toList();
    if (itemsInPlace.isEmpty) return;

    final allCompleted = itemsInPlace.every((i) => i.isPurchased);

    if (allCompleted) {
      // ✅ Cuando TODO el lugar está realizado: mensaje + MÁS confeti
      _showPlaceCompletedMessage(place);
      _playPlaceConfetti();
    }
  }

  void _playConfettiForPlace(String place) {
    if (!_confettiControllers.containsKey(place)) {
      _confettiControllers[place] = ConfettiController(
        duration: const Duration(milliseconds: 600),
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
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildNormalView(),

          // 🎉 Confeti pequeño (tarea completada)
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _taskConfettiController,
                blastDirectionality: BlastDirectionality.explosive,
                blastDirection: -pi / 2, // hacia arriba
                emissionFrequency: 0.08,
                numberOfParticles: 30,
                maxBlastForce: 55, // sube alto, pasa media pantalla
                minBlastForce: 20,
                gravity: 0.25, // cae suave
                particleDrag: 0.02,
                shouldLoop: false,
                minimumSize: const Size(6, 6),
                maximumSize: const Size(12, 12),
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

          // 🎉🎉 Confeti grande (lugar completado)
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _placeConfettiController,
                blastDirectionality: BlastDirectionality.explosive,
                blastDirection: -pi / 2,
                emissionFrequency: 0.09,
                numberOfParticles: 50,
                maxBlastForce: 65,
                minBlastForce: 25,
                gravity: 0.23,
                particleDrag: 0.015,
                shouldLoop: false,
                minimumSize: const Size(7, 7),
                maximumSize: const Size(14, 14),
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
      ),
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
        duration: const Duration(milliseconds: 600),
      );
    }

    return Stack(
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
        // Confetti widget
        Align(
          alignment: Alignment.center,
          child: IgnorePointer(
            child: ConfettiWidget(
              confettiController: _confettiControllers[place]!,
              blastDirection: 0, // Explosión en todas direcciones
              emissionFrequency: 0.85,
              numberOfParticles: 50,
              maxBlastForce: 200,
              minBlastForce: 100,
              gravity: 0.5,
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
