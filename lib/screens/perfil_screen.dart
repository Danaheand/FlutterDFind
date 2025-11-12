import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/user.dart';
import '../providers/font_size_provider.dart';
import '../services/trash_service.dart';
import '../models/trash_item.dart';
import 'recordatorios_screen.dart';
import 'pendientes_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;
  bool _showLogoutDialog = false;
  bool _notifSound = true;
  bool _notifVibration = true;
  String _userName = 'Carlos Rodríguez';
  String _userEmail = 'carlos.r@email.com';
  User? _currentUser;
  String? _profileImagePath;
  List<Map<String, dynamic>> _deletedAlerts = []; // Papelera de recordatorios
  late final TrashService _trashService;
  
  Future<void> _pickProfileImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024);
    if (picked != null) {
      setState(() {
        _profileImagePath = picked.path;
      });
      final sp = await SharedPreferences.getInstance();
      await sp.setString('profile_image_path', picked.path);
    }
  }

  void _showTrashDialog() {
    // Obtener elementos de papelera del servicio
    final trashItems = _trashService.getTrashItems();
    final deletedAlerts = List<Map<String, dynamic>>.from(_deletedAlerts);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Papelera de Reciclaje'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: (trashItems.isEmpty && deletedAlerts.isEmpty)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No hay elementos eliminados'),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección de items de compras eliminados
                      if (trashItems.isNotEmpty) ...[
                        const Text(
                          'Lista de Compras',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ...trashItems.map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.shopping_cart, color: Colors.blue),
                            title: Text(item.name),
                            subtitle: Text('${item.placeName} • ${item.deletedAt.day}/${item.deletedAt.month}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.restore, color: Colors.green),
                                  onPressed: () async {
                                    try {
                                      final restoredItem = await _trashService.restoreItem(item.id);
                                      final shoppingItem = _trashService.trashItemToShoppingItem(restoredItem);
                                      
                                      // Restaurar al InventoryScreen
                                      if (InventoryScreen.addFromAlertGlobal != null) {
                                        InventoryScreen.addFromAlertGlobal!(shoppingItem.name);
                                      }
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${item.name} restaurado')),
                                      );
                                      Navigator.pop(context);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error al restaurar: $e')),
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                                  onPressed: () async {
                                    await _trashService.deleteItemPermanently(item.id);
                                    Navigator.pop(context);
                                    _showTrashDialog();
                                  },
                                ),
                              ],
                            ),
                          ),
                        )),
                        const SizedBox(height: 16),
                      ],
                      // Sección de recordatorios eliminados
                      if (deletedAlerts.isNotEmpty) ...[
                        const Text(
                          'Recordatorios',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ...deletedAlerts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final alert = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.notifications, color: Colors.orange),
                              title: Text(alert['title'] ?? 'Sin título'),
                              subtitle: Text(alert['description'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.restore, color: Colors.green),
                                    onPressed: () {
                                      setState(() {
                                        _deletedAlerts.removeAt(index);
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${alert['title']} restaurado')),
                                      );
                                      Navigator.pop(context);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _deletedAlerts.removeAt(index);
                                      });
                                      Navigator.pop(context);
                                      _showTrashDialog();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
        ),
        actions: [
          if (trashItems.isNotEmpty || deletedAlerts.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Vaciar Papelera'),
                    content: const Text('¿Estás seguro de que quieres eliminar permanentemente todos los elementos?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Eliminar Todo', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  await _trashService.emptyTrash();
                  setState(() {
                    _deletedAlerts.clear();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Papelera vaciada')),
                  );
                }
              },
              child: const Text('Vaciar Papelera', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAccessibilityDialog() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Accesibilidad'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Tema Oscuro'),
                  trailing: Switch(
                    value: _darkMode,
                    onChanged: (v) {
                      this.setState(() => _darkMode = v);
                      setState(() {});
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.format_size),
                  title: const Text('Ajustar tamaño de letra'),
                  trailing: Switch(
                    value: fontSizeProvider.enabled,
                    onChanged: (v) {
                      fontSizeProvider.setEnabled(v);
                      setState(() {});
                    },
                  ),
                ),
                if (fontSizeProvider.enabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        const Divider(),
                        Row(
                          children: [
                            const Text('A-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Expanded(
                              child: Slider(
                                min: 12.0,
                                max: 28.0,
                                divisions: 8,
                                value: fontSizeProvider.fontSize,
                                label: '${fontSizeProvider.fontSize.toInt()}',
                                onChanged: (v) {
                                  fontSizeProvider.setFontSize(v);
                                  setState(() {});
                                },
                              ),
                            ),
                            const Text('A+', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Tamaño actual: ${fontSizeProvider.fontSize.toInt()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Notificaciones'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.volume_up_outlined),
                  title: const Text('Sonido'),
                  trailing: Switch(
                    value: _notifSound,
                    onChanged: (v) {
                      setState(() => _notifSound = v);
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.vibration),
                  title: const Text('Vibración'),
                  trailing: Switch(
                    value: _notifVibration,
                    onChanged: (v) {
                      setState(() => _notifVibration = v);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirm() {
    setState(() => _showLogoutDialog = true);
  }

  void _hideLogoutConfirm() {
    setState(() => _showLogoutDialog = false);
  }

  Future<void> _logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('current_user');
    setState(() => _showLogoutDialog = false);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _showProfileModal,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: ClipOval(
              child: _profileImagePath != null
                  ? Image.file(
                      File(_profileImagePath!),
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/img/profile_placeholder.png',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.blue[100],
                        child: Center(
                          child: Text(
                            _userName.isNotEmpty ? _userName[0] : '?',
                            style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.edit, size: 20, color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileModal() async {
    final nameController = TextEditingController(text: _userName);
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipOval(
                      child: _profileImagePath != null
                          ? Image.file(
                              File(_profileImagePath!),
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/img/profile_placeholder.png',
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 160,
                                height: 160,
                                color: Colors.blue[100],
                                child: Center(
                                  child: Text(
                                    nameController.text.isNotEmpty ? nameController.text[0] : '?',
                                    style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                                      title: const Text('Abrir cámara'),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        await _pickProfileImage(ImageSource.camera);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library, color: Colors.green),
                                      title: const Text('Abrir galería'),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        await _pickProfileImage(ImageSource.gallery);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.edit, size: 28, color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        bool changed = false;
                        setState(() {
                          if (newName.isNotEmpty && newName != _userName) {
                            _userName = newName;
                            changed = true;
                          }
                          if (_currentUser != null) {
                            _currentUser = _currentUser!.copyWith(
                              nombreUsuario: newName.isNotEmpty ? newName : _userName,
                            );
                            changed = true;
                          }
                        });
                        if (changed && _currentUser != null) {
                          final sp = await SharedPreferences.getInstance();
                          await sp.setString('current_user', jsonEncode(_currentUser!.toJson()));
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Guardar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard({required Widget child, EdgeInsets? margin}) => Container(
        margin:
            margin ?? const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: child,
      );

  @override
  void initState() {
    super.initState();
    _trashService = TrashService.getInstance();
    _loadCurrentUser();
    _loadProfileImage();
    _initializeTrash();
    _addTestDeletedAlert();
    
    // Registrar el callback para capturar recordatorios eliminados
    AlertsScreen.onAlertDeleted = (alert) {
      setState(() {
        _deletedAlerts.add({
          'id': alert.id,
          'title': alert.title,
          'description': alert.description,
          'date': alert.date,
          'priority': alert.priority,
          'location': alert.location,
          'object': alert.object,
          'repetitive': alert.repetitive,
          'repeatFrequency': alert.repeatFrequency,
          'active': alert.active,
          'color': alert.color,
          'imagePath': alert.imagePath,
          'selectedWeekdays': alert.selectedWeekdays,
        });
      });
    };
  }

  void _addTestDeletedAlert() {
    // Agregar un recordatorio de prueba en papelera si no existe
    final testExists = _deletedAlerts.any((alert) => alert['id'] == 'test_deleted_alert');
    if (!testExists) {
      setState(() {
        _deletedAlerts.add({
          'id': 'test_deleted_alert',
          'title': 'Recordatorio de Prueba',
          'description': 'Este es un recordatorio eliminado que puedes recuperar desde la papelera',
          'date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'priority': 'Alta',
          'location': 'Casa',
          'object': 'Documentos importantes',
          'repetitive': false,
          'repeatFrequency': '',
          'active': true,
          'color': 'blue',
          'imagePath': null,
          'selectedWeekdays': [],
        });
      });
    }
  }

  Future<void> _initializeTrash() async {
    await _trashService.loadTrashItems();
    await _addTestShoppingItem();
  }

  Future<void> _addTestShoppingItem() async {
    // Agregar un elemento de compras de prueba en papelera si no existe
    final trashItems = _trashService.getTrashItems();
    final testExists = trashItems.any((item) => item.id == 'test_shopping_item');
    
    if (!testExists) {
      final testTrashItem = TrashItem(
        id: 'test_shopping_item',
        name: 'Leche deslactosada',
        placeName: 'Supermercado La Plaza',
        category: 'Lácteos',
        quantity: 2,
        deletedAt: DateTime.now().subtract(const Duration(hours: 2)),
        originalType: 'shopping_item',
      );
      
      await _trashService.addToTrash(testTrashItem);
    }
  }

  Future<void> _loadCurrentUser() async {
    final sp = await SharedPreferences.getInstance();
    final userJson = sp.getString('current_user');
    if (userJson != null) {
      try {
        final userData = jsonDecode(userJson);
        setState(() {
          _currentUser = User.fromJson(userData);
          _userName = _currentUser?.nombreUsuario ?? _userName;
          _userEmail = _currentUser?.email ?? _userEmail;
        });
      } catch (e) {
        print('Error loading user: $e');
      }
    }
  }

  Future<void> _loadProfileImage() async {
    final sp = await SharedPreferences.getInstance();
    final path = sp.getString('profile_image_path');
    if (path != null && path.isNotEmpty) {
      setState(() {
        _profileImagePath = path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          children: [
            Container(
              height: 120,
              color: Colors.blue[500],
              child: null,
            ),
            Transform.translate(
              offset: const Offset(0, -48),
              child: Column(
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 8),
                  Text(_userName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSizeProvider.fontSize + 4,
                      )),
                  Text(_userEmail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: fontSizeProvider.fontSize,
                      )),
                  const SizedBox(height: 16),
                  // NOTIFICACIONES
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCard(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.notifications_active_outlined),
                        title: const Text('Notificaciones'),
                        subtitle: const Text('Controla recordatorios y avisos de la app'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _showNotificationsDialog,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ACCESIBILIDAD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCard(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.accessibility),
                        title: const Text('Accesibilidad'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _showAccessibilityDialog,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // PAPELERA DE RECICLAJE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCard(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.delete_outline, color: Colors.orange),
                        title: const Text('Papelera'),
                        subtitle: Text('${_trashService.getTrashItems().length + _deletedAlerts.length} elementos eliminados'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _showTrashDialog,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // CERRAR SESIÓN
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.redAccent),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _showLogoutConfirm,
                      child: const Text('Cerrar Sesión',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
        if (_showLogoutDialog)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      const Text('¿Cerrar sesión?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text('¿Estás seguro que deseas salir de tu cuenta?',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: _hideLogoutConfirm,
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _logout,
                            child: const Text('Cerrar Sesión'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}