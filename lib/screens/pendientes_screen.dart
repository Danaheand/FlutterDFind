import 'dart:convert';
import 'dart:math'; // Para pi en el confeti
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:confetti/confetti.dart';

import '../providers/font_size_provider.dart';
import '../providers/pendientes_state_provider.dart';
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

// 👇 TickerProviderStateMixin para animaciones múltiples
class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin {
  final List<ShoppingItem> _items = [];
  late final TrashService _trashService;

  bool _loading = false;

  /// Correo del usuario logueado
  late String _correoUsuario;

  /// URL base de la API
  final String baseUrl = 'https://dfindapi-yfcq.onrender.com';

  // 🎉 Controladores globales de confeti
  late final ConfettiController _taskConfettiController;
  late final ConfettiController _placeConfettiController;

  // 🗑️ Modo selección para eliminar categorías
  bool _selectionMode = false;
  Set<String> _selectedPlaces = {};

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

    // 2) Si acaba de pasar a realizado → SOLO confeti (sin mensaje)
    if (!wasPurchased && newValue) {
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

  /// 🔹 NUEVO: abrir el mismo modal, pero con lugar predefinido
  void _openAddItemForPlace(String place) {
    showDialog(
      context: context,
      builder: (context) => ModalPendientes(
        onAdd: _addItemManually,
        predefinedPlace: place,
      ),
    );
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

  /// Confeti para cada tarea completada
  void _playTaskConfetti() {
    _taskConfettiController.stop();
    _taskConfettiController.play();
  }

  /// Confeti grande (doble explosión) para lugar completado
  void _playPlaceConfetti() {
    _placeConfettiController.stop();
    _placeConfettiController.play();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _placeConfettiController.play();
    });
  }

  // ================================================================
  //           MENSAJES SUPER CUTE (CUADRO VERDE, OVERLAY)
  // ================================================================

  void _showCuteMessage(String text, IconData icon) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );

    entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          left: 16,
          right: 16,
          bottom: 80, // un poco más arriba de abajo
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0.0), // entra desde la izquierda
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: AppTheme.primaryLight, // morado azulado
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    controller.forward();

    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await controller.reverse();
      } catch (_) {}
      entry.remove();
      controller.dispose();
    });
  }

  void _showPlaceCompletedMessage(String place) {
    _showCuteMessage(
        'Compras en $place terminadas', Icons.shopping_bag_rounded);
  }

  // ================================================================
  //                     SELECCIÓN Y ELIMINACIÓN
  // ================================================================

  Future<void> _deleteSelectedPlaces() async {
    if (_selectedPlaces.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categorías'),
        content: Text(
            '¿Eliminar ${_selectedPlaces.length} categoría(s) y todos sus elementos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Eliminar todos los items que pertenecen a las categorías seleccionadas
    final itemsToDelete = _items
        .where((item) => _selectedPlaces.contains(item.placeName))
        .toList();

    for (var item in itemsToDelete) {
      await _deleteAPI(item);
    }

    final categoriesCount = _selectedPlaces.length;

    setState(() {
      _selectionMode = false;
      _selectedPlaces.clear();
    });

    if (mounted) {
      _showCuteMessage(
        categoriesCount == 1
            ? 'Categoría eliminada'
            : '$categoriesCount categorías eliminadas',
        Icons.delete_outline,
      );
    }
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
        actions: [
          // Botón de selección
          IconButton(
            icon: Icon(
                _selectionMode ? Icons.close : Icons.check_box_outline_blank),
            tooltip: _selectionMode ? 'Cancelar selección' : 'Seleccionar',
            onPressed: () {
              setState(() {
                _selectionMode = !_selectionMode;
                if (!_selectionMode) _selectedPlaces.clear();
              });
            },
          ),
          // Botón de eliminar (solo visible en modo selección)
          if (_selectionMode && _selectedPlaces.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Eliminar seleccionadas',
              onPressed: _deleteSelectedPlaces,
            ),
        ],
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
              Icons.check_box,
              size: 48,
              color: AppTheme.getTextSecondary(context),
            ),
            const SizedBox(height: 8),
            Consumer<FontSizeProvider>(
              builder: (context, fontSizeProvider, _) => Text(
                '¡Tu lista de pendientes está vacía!',
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
    return Consumer<PendientesStateProvider>(
      builder: (context, pendientesState, _) {
        final isExpanded = pendientesState.isExpanded(place);
        final totalItems = items.length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  if (_selectionMode) {
                    // En modo selección, seleccionar/deseleccionar la categoría
                    setState(() {
                      if (_selectedPlaces.contains(place)) {
                        _selectedPlaces.remove(place);
                      } else {
                        _selectedPlaces.add(place);
                      }
                    });
                  } else {
                    // Modo normal, expandir/contraer
                    pendientesState.togglePlace(place);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Checkbox si está en modo selección
                      if (_selectionMode)
                        Checkbox(
                          value: _selectedPlaces.contains(place),
                          onChanged: (_) {
                            setState(() {
                              if (_selectedPlaces.contains(place)) {
                                _selectedPlaces.remove(place);
                              } else {
                                _selectedPlaces.add(place);
                              }
                            });
                          },
                        )
                      else
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
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.placeIconLight
                                    : AppTheme.textPrimaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 🔹 Botón + que abre el MISMO modal, con lugar predefinido (solo en modo normal)
                      if (!_selectionMode)
                        IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: 'Agregar pendiente aquí',
                          onPressed: () => _openAddItemForPlace(place),
                        ),
                    ],
                  ),
                ),
              ),
              if (isExpanded && !_selectionMode) ...[
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
        );
      },
    );
  }
}
