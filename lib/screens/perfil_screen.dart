import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/recordatorio.dart';
import '../providers/font_size_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/recordatorio_provider.dart';
import '../services/trash_service.dart';
import '../services/session_manager.dart';
import '../widgets/custom_text_button.dart';
import '../widgets/palette.dart';
import '../widgets/paletteActual.dart';
import '../theme/app_theme.dart';
import 'pendientes_screen.dart';
import '../repository/remote_user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showLogoutDialog = false;
  bool _notifSound = true;
  bool _notifVibration = true;
  String _userName = '';
  String _userEmail = '';
  User? _currentUser;
  String? _profileImagePath;
  bool _isLoading = true;
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

    showDialog(
      context: context,
      builder: (context) => Consumer<FontSizeProvider>(
        builder: (context, fontSizeProvider, _) => AlertDialog(
          title: Text('Papelera de Reciclaje',
              style: TextStyle(
                  fontSize: fontSizeProvider.getScaledSize(20),
                  fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: trashItems.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline,
                          size: 64, color: AppTheme.getTextSecondary(context)),
                      const SizedBox(height: 12),
                      Text('No hay elementos eliminados',
                          style: TextStyle(
                              fontSize: fontSizeProvider.getScaledSize(14),
                              color: AppTheme.getTextSecondary(context))),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mostrar todos los items de la papelera
                        ...trashItems.map((item) {
                          // Determinar ícono según tipo
                          final icon = item.originalType == 'alert'
                              ? Icons.notifications
                              : Icons.shopping_cart;
                          final color = item.originalType == 'alert'
                              ? Colors.orange
                              : Colors.blue;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.white
                                    : AppTheme.cardDark,
                            child: ListTile(
                              leading: Icon(icon, color: color),
                              title: Text(item.name,
                                  style: TextStyle(
                                      fontSize:
                                          fontSizeProvider.getScaledSize(16),
                                      color: Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.black87
                                          : Colors.white)),
                              subtitle: Text(
                                '${item.placeName} • ${item.deletedAt.day}/${item.deletedAt.month}/${item.deletedAt.year}',
                                style: TextStyle(
                                    fontSize:
                                        fontSizeProvider.getScaledSize(12),
                                    color: AppTheme.getTextSecondary(context)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.restore,
                                        color: Colors.green),
                                    onPressed: () async {
                                      try {
                                        await _trashService
                                            .restoreItem(item.id);

                                        // Si es un recordatorio, restaurarlo al proveedor
                                        if (item.originalType == 'alert') {
                                          try {
                                            final alertData = _trashService
                                                .trashItemToAlertData(item);
                                            final provider = context
                                                .read<RecordatorioProvider>();

                                            // Obtener el idUsuario actual
                                            final userId =
                                                SessionManager.instance.userId;
                                            if (userId != null) {
                                              // Crear un Recordatorio a partir de AlertData
                                              final recordatorio = Recordatorio(
                                                idUsuario: userId,
                                                titulo: alertData.title,
                                                descripcion:
                                                    alertData.description,
                                                fechaHora: alertData.date,
                                                prioridad:
                                                    alertData.priority.name,
                                                ubicacion: alertData.location,
                                                objeto: alertData.object,
                                                esRepetitivo:
                                                    alertData.repetitive,
                                                frecuenciaRepeticion:
                                                    alertData.repeatFrequency,
                                                activo: alertData.active,
                                                rutaImagen: alertData.imagePath,
                                              );

                                              // Crear el recordatorio en el servidor
                                              await provider.crearRecordatorio(
                                                recordatorio,
                                                autoReload: true,
                                              );
                                            }
                                          } catch (e) {
                                            print(
                                                'Error restaurando recordatorio: $e');
                                          }
                                        }

                                        // Si es un item de compra, restaurar al InventoryScreen
                                        if (item.originalType ==
                                            'shopping_item') {
                                          if (InventoryScreen
                                                  .addFromAlertGlobal !=
                                              null) {
                                            InventoryScreen
                                                .addFromAlertGlobal!(item.name);
                                          }
                                        }

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  '✨ ${item.name} restaurado')),
                                        );
                                        Navigator.pop(context);
                                        _showTrashDialog();
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error al restaurar: $e')),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever,
                                        color: Colors.red),
                                    onPressed: () async {
                                      await _trashService
                                          .deleteItemPermanently(item.id);
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
                    ),
                  ),
          ),
          actions: [
            if (trashItems.isNotEmpty)
              CustomTextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => Consumer<FontSizeProvider>(
                      builder: (context, fontSizeProvider, _) => AlertDialog(
                        title: Text('Vaciar Papelera',
                            style: TextStyle(
                                fontSize: fontSizeProvider.getScaledSize(18),
                                fontWeight: FontWeight.bold)),
                        content: Text(
                            '¿Estás seguro de que quieres eliminar permanentemente todos los elementos?',
                            style: TextStyle(
                                fontSize: fontSizeProvider.getScaledSize(14))),
                        actions: [
                          CustomTextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          CustomTextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Eliminar Todo',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  );

                  if (confirmed != true) return;

                  try {
                    await _trashService.emptyTrash();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Papelera vaciada')),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al vaciar: $e')),
                      );
                    }
                  }
                },
                child: Text('Vaciar Papelera',
                    style: TextStyle(
                        fontSize: fontSizeProvider.getScaledSize(14))),
              ),
            CustomTextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppSettingsDialog() {
    final fontSizeProvider =
        Provider.of<FontSizeProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Configuraciones de la aplicación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TEMA OSCURO
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Tema Oscuro'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (v) async {
                      await themeProvider.setDarkMode(v);
                      setState(() {});
                    },
                  ),
                ),
                const Divider(),
                // TAMAÑO DE LETRA
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
                            const Text('A-',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
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
                            const Text('A+',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
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
                const Divider(),
                // VIBRACIÓN
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
                const Divider(),
                // SONIDO
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
              ],
            ),
          ),
          actions: [
            CustomTextButton(
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
    // Limpiar sesión usando SessionManager
    await SessionManager.instance.clearSession();

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
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8)
              ],
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
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Error: No se pudo cargar la información del usuario')),
      );
      return;
    }

    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);
    final fontSizeProvider =
        Provider.of<FontSizeProvider>(context, listen: false);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 160,
                                  height: 160,
                                  color: Colors.blue[100],
                                  child: Center(
                                    child: Text(
                                      nameController.text.isNotEmpty
                                          ? nameController.text[0]
                                          : '?',
                                      style: TextStyle(
                                          fontSize: fontSizeProvider.enabled
                                              ? fontSizeProvider.fontSize * 3
                                              : 60,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
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
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (context) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 24, horizontal: 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt,
                                            color: Colors.blueAccent),
                                        title: const Text('Abrir cámara'),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          await _pickProfileImage(
                                              ImageSource.camera);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo_library,
                                            color: Colors.green),
                                        title: const Text('Abrir galería'),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          await _pickProfileImage(
                                              ImageSource.gallery);
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
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4)
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.edit,
                                size: 28, color: Colors.blueAccent),
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
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSizeProvider.enabled
                            ? fontSizeProvider.fontSize + 4
                            : 18),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                        fontSize: fontSizeProvider.enabled
                            ? fontSizeProvider.fontSize
                            : 14),
                  ),
                  const SizedBox(height: 12),
                  // Mostrar información adicional del usuario
                  if (_currentUser!.fechaCreacionIso.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Miembro desde: ${_formatDate(_currentUser!.fechaCreacionIso)}',
                              style: TextStyle(
                                  fontSize: fontSizeProvider.enabled
                                      ? fontSizeProvider.fontSize
                                      : 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CustomTextButton(
                        onPressed: () async {
                          final newName = nameController.text.trim();
                          final newEmail = emailController.text.trim();

                          if (_currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'No se pudo obtener la información del usuario.')),
                            );
                            return;
                          }

                          if (newName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('El nombre no puede estar vacío.')),
                            );
                            return;
                          }

                          if (newEmail.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('El correo no puede estar vacío.')),
                            );
                            return;
                          }

                          // Si nada cambió, no hacer nada
                          final nameChanged =
                              newName != _currentUser!.nombreUsuario;
                          final emailChanged = newEmail != _currentUser!.email;

                          if (!nameChanged && !emailChanged) {
                            Navigator.pop(context);
                            return;
                          }

                          try {
                            // Mostrar indicador de carga
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            // TODO: Agregar la API para cambiar el correo cuando esté disponible
                            // Llamar a la API para actualizar perfil por correo
                            final updatedUser = await RemoteUserRepository
                                .instance
                                .updateProfileByEmail(
                              correoActual: _currentUser!.email,
                              nuevoNombre: newName,
                              nuevoCorreo: emailChanged ? newEmail : null,
                            );

                            // Cerrar indicador de carga
                            if (mounted) Navigator.pop(context);

                            // Actualizar estado local con la respuesta de la API
                            setState(() {
                              _currentUser = updatedUser;
                              _userName = updatedUser.nombreUsuario;
                              _userEmail = updatedUser.email;
                            });

                            // Guardar en SessionManager
                            await SessionManager.instance.setUser(updatedUser);

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('✅ Perfil actualizado correctamente'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            // Cerrar indicador de carga si está abierto
                            if (mounted) Navigator.pop(context);

                            print('Error actualizando perfil: $e');
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('❌ Error al actualizar perfil: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                        child: const Text('Guardar'),
                      ),
                      CustomTextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ],
              ),
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
  }

  Future<void> _initializeTrash() async {
    await _trashService.loadTrashItems();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener usuario desde SessionManager
      final user = SessionManager.instance.currentUser;

      print('🔍 Cargando usuario desde SessionManager...');

      if (user != null) {
        print('📊 Usuario obtenido: ${user.nombreUsuario} (${user.email})');
        print('📅 Fecha de creación: ${user.fechaCreacionIso}');

        // Usar los datos locales primero para mostrar algo rápidamente
        setState(() {
          _currentUser = user;
          _userName = user.nombreUsuario;
          _userEmail = user.email;
        });

        // Intentar obtener el perfil actualizado desde la API en segundo plano
        try {
          print('🌐 Obteniendo perfil actualizado desde API...');
          final updatedUser =
              await RemoteUserRepository.instance.getUserProfile(
            email: user.email,
          );

          print('✅ Perfil actualizado obtenido: ${updatedUser.nombreUsuario}');

          // Si la API responde, actualizar con los datos más recientes
          setState(() {
            _currentUser = updatedUser;
            _userName = updatedUser.nombreUsuario;
            _userEmail = updatedUser.email;
          });

          // Guardar los datos actualizados en SessionManager
          await SessionManager.instance.setUser(updatedUser);
        } catch (apiError) {
          print(
              '⚠️ Error obteniendo perfil actualizado (usando datos locales): $apiError');
          // Si falla la API, mantener los datos locales ya cargados
        }
      } else {
        print('❌ No hay usuario en sesión');
        // No hay usuario guardado, redirigir al login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
          return;
        }
      }
    } catch (e) {
      print('❌ Error general cargando usuario: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando perfil. Volviendo al login.'),
            backgroundColor: Colors.red,
          ),
        );
        // En caso de error general, ir al login
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  String _formatDate(String isoDateString) {
    try {
      final date = DateTime.parse(isoDateString);
      final months = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre'
      ];
      return '${date.day} de ${months[date.month - 1]} de ${date.year}';
    } catch (e) {
      return isoDateString; // Si no se puede parsear, devolver la cadena original
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    // Mostrar indicador de carga si aún está cargando el usuario
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando perfil...'),
            ],
          ),
        ),
      );
    }

    // Si no hay usuario y no está cargando, mostrar mensaje de error
    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error cargando el perfil'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Ir al Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadCurrentUser,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            children: [
              Container(
                height: 120,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.blue[500]
                    : AppTheme.cardDark,
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
                          color: AppTheme.getTextSecondary(context),
                          fontSize: fontSizeProvider.fontSize,
                        )),
                    const SizedBox(height: 16),
                    // CONFIGURACIONES DE LA APLICACIÓN
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildCard(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: const Text('Configuraciones de la aplicación'),
                          subtitle: const Text('Tema, vibración y sonido'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _showAppSettingsDialog,
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
                          leading: Icon(Icons.delete_outline,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.orange
                                  : AppTheme.warningDark),
                          title: const Text('Papelera'),
                          subtitle: Text(
                              '${_trashService.getTrashItems().length} elementos eliminados'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _showTrashDialog,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // PALETA DE COLORES
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildCard(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: Icon(Icons.palette_outlined,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.purple
                                  : Colors.purpleAccent),
                          title: const Text('Paleta de Colores'),
                          subtitle: const Text('Ver colores del tema actual'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PaletteViewer(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // PALETA PERSONALIZADA
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildCard(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: Icon(Icons.color_lens_outlined,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.deepPurple
                                  : Colors.deepPurpleAccent),
                          title: const Text('Paleta Personalizada'),
                          subtitle: const Text('Ver colores personalizados'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CustomPaletteViewer(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // CERRAR SESIÓN
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.white
                                  : AppTheme.cardDark,
                          foregroundColor:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.red
                                  : AppTheme.errorDark,
                          side: BorderSide(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.redAccent
                                  : AppTheme.errorDark),
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
                          CustomTextButton(
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
