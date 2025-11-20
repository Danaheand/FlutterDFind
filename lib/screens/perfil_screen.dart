import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

enum AvatarMode { preset, initial }

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
  bool _isLoading = true;
  AvatarMode _avatarMode = AvatarMode.initial;
  String? _selectedAvatarKey; // 'avatar1'..'avatar5'
  Color _initialColor = const Color(0xFF42A5F5);

  late final TrashService _trashService;

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
          title: const Text('Configuración'),
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
  final nameInitial = _userName.isNotEmpty ? _userName[0].toUpperCase() : '?';

  Widget avatarChild;
  if (_avatarMode == AvatarMode.preset && _selectedAvatarKey != null) {
    avatarChild = CircleAvatar(
      radius: 48,
      backgroundImage:
          AssetImage('assets/avatars/${_selectedAvatarKey!}.png'),
      backgroundColor: Colors.transparent,
    );
  } else {
    avatarChild = CircleAvatar(
      radius: 48,
      backgroundColor: _initialColor,
      child: Text(
        nameInitial,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

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
              BoxShadow(color: Colors.black12, blurRadius: 8),
            ],
          ),
          child: ClipOval(child: avatarChild),
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
                      _buildDialogAvatarPreview(nameController.text, fontSizeProvider),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _showAvatarSelector(context, setState),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.brush,
                              size: 28,
                              color: Colors.blueAccent,
                            ),
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
                            
                            // Detectar si el avatar cambió
                            final currentAvatarTipo = (_currentUser!.avatarTipo == 'preset')
                                ? AvatarMode.preset
                                : AvatarMode.initial;
                            final currentAvatarClave = _currentUser!.avatarClave;
                            
                            final newAvatarTipo =
                                _avatarMode == AvatarMode.preset ? 'preset' : 'initial';
                            final newAvatarClave = _avatarMode == AvatarMode.preset
                                ? (_selectedAvatarKey ?? 'avatar1')
                                : _colorToHex(_initialColor);
                            
                            final avatarChanged = 
                                currentAvatarTipo != _avatarMode ||
                                currentAvatarClave != newAvatarClave;

                            // Debug logs
                            print('🎨 DEBUG AVATAR:');
                            print('  currentAvatarTipo: $currentAvatarTipo');
                            print('  _avatarMode: $_avatarMode');
                            print('  currentAvatarClave: $currentAvatarClave');
                            print('  newAvatarClave: $newAvatarClave');
                            print('  _selectedAvatarKey: $_selectedAvatarKey');
                            print('  _initialColor hex: ${_colorToHex(_initialColor)}');
                            print('  avatarChanged: $avatarChanged');

                            final updatedUser = await RemoteUserRepository
                                .instance
                                .updateProfileByEmail(
                              correoActual: _currentUser!.email,
                              nuevoNombre: nameChanged ? newName : null,
                              nuevoCorreo: emailChanged ? newEmail : null,
                              avatarTipo: avatarChanged ? newAvatarTipo : null,
                              avatarClave: avatarChanged ? newAvatarClave : null,
                            );

                            if (mounted) Navigator.pop(context);

                            setState(() {
                              _currentUser = updatedUser;
                              _userName = updatedUser.nombreUsuario;
                              _userEmail = updatedUser.email; // Actualiza el correo

                              _avatarMode = (updatedUser.avatarTipo == 'preset')
                                  ? AvatarMode.preset
                                  : AvatarMode.initial;

                              if (_avatarMode == AvatarMode.preset) {
                                _selectedAvatarKey = updatedUser.avatarClave;
                              } else {
                                if (updatedUser.avatarClave != null &&
                                    updatedUser.avatarClave!.startsWith('#') &&
                                    updatedUser.avatarClave!.length == 7) {
                                  _initialColor = _colorFromHex(updatedUser.avatarClave!);
                                } else {
                                  _initialColor = const Color(0xFF42A5F5);
                                }
                              }
                            });

                            await SessionManager.instance.setUser(updatedUser);

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Perfil actualizado correctamente'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            if (mounted) Navigator.pop(context);

                            print('Error actualizando perfil: $e');
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Error al actualizar perfil: $e'),
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
  Widget _buildDialogAvatarPreview(
    String currentName, FontSizeProvider fontSizeProvider) {
  final initial =
      currentName.isNotEmpty ? currentName[0].toUpperCase() : '?';

  if (_avatarMode == AvatarMode.preset && _selectedAvatarKey != null) {
    return ClipOval(
      child: Image.asset(
        'assets/avatars/${_selectedAvatarKey!}.png',
        width: 160,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildInitialCircle(initial, fontSizeProvider),
      ),
    );
  }

  return _buildInitialCircle(initial, fontSizeProvider);
}

Widget _buildInitialCircle(
    String initial, FontSizeProvider fontSizeProvider) {
  return Container(
    width: 160,
    height: 160,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _initialColor,
    ),
    child: Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize:
              fontSizeProvider.enabled ? fontSizeProvider.fontSize * 3 : 60,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
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

      print('Cargando usuario desde SessionManager...');

      if (user != null) {
        print('Usuario obtenido: ${user.nombreUsuario} (${user.email})');
        print('Fecha de creación: ${user.fechaCreacionIso}');

        setState(() {
          _currentUser = user;
          _userName = user.nombreUsuario;
          _userEmail = user.email;

          // 👇 NUEVO: cargar avatar desde el usuario
          _avatarMode = (user.avatarTipo == 'preset')
              ? AvatarMode.preset
              : AvatarMode.initial;

          if (_avatarMode == AvatarMode.preset) {
            _selectedAvatarKey = user.avatarClave; // 'avatar1'..'avatar5'
          } else {
            if (user.avatarClave != null &&
                user.avatarClave!.startsWith('#') &&
                user.avatarClave!.length == 7) {
              _initialColor = _colorFromHex(user.avatarClave!);
            } else {
              _initialColor = const Color(0xFF42A5F5);
            }
          }
        });
        } else {
        print('No hay usuario en sesión');
        // No hay usuario guardado, redirigir al login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
          return;
        }
      }
    } catch (e) {
      print('Error general cargando usuario: $e');
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
  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff'); // agrega alpha si es #RRGGBB
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _colorToHex(Color color) {
    final value = color.value.toRadixString(16).padLeft(8, '0'); // aarrggbb
    return '#${value.substring(2)}'; // rrggbb
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
                          title: const Text('Configuración'),
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
  
  void _showAvatarSelector(BuildContext context, void Function(void Function()) setStateDialog) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final presetKeys = ['avatar1', 'avatar2', 'avatar3', 'avatar4', 'avatar5'];
      final colorOptions = <Color>[
        const Color(0xFFEF5350),
        const Color(0xFFFFA726),
        const Color(0xFFFFEB3B),
        const Color(0xFF66BB6A),
        const Color(0xFF42A5F5),
        const Color(0xFFAB47BC),
        const Color(0xFF8D6E63),
        const Color(0xFF607D8B),
      ];

      return StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Elige tu estilo de avatar',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Avatares divertidos'),
                          selected: _avatarMode == AvatarMode.preset,
                          onSelected: (_) {
                            setStateModal(() {
                              _avatarMode = AvatarMode.preset;
                            });
                            setStateDialog(() {
                              _avatarMode = AvatarMode.preset;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Inicial + color'),
                          selected: _avatarMode == AvatarMode.initial,
                          onSelected: (_) {
                            setStateModal(() {
                              _avatarMode = AvatarMode.initial;
                            });
                            setStateDialog(() {
                              _avatarMode = AvatarMode.initial;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_avatarMode == AvatarMode.preset) ...[
                    Text('Avatares divertidos disponibles:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: presetKeys.map((key) {
                        final selected = _selectedAvatarKey == key;
                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              _selectedAvatarKey = key;
                            });
                            setStateModal(() {
                              _selectedAvatarKey = key;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected ? Colors.blue : Colors.grey.shade300,
                                    width: 3,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          const BoxShadow(
                                            color: Colors.blue,
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: CircleAvatar(
                                  radius: 36,
                                  backgroundImage: AssetImage('assets/avatars/$key.png'),
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getAvatarName(key),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    Text('Colores disponibles:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: colorOptions.map((c) {
                        final selected = _initialColor.value == c.value;
                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              _initialColor = c;
                            });
                            setStateModal(() {
                              _initialColor = c;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c,
                              border: Border.all(
                                color: selected ? Colors.black : Colors.white,
                                width: 3,
                              ),
                              boxShadow: selected
                                  ? [
                                      const BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

String _getAvatarName(String key) {
  final names = {
    'avatar1': '😎 Cool Boy',
    'avatar2': '🤩 Star Eyes',
    'avatar3': '😸 Happy Cat',
    'avatar4': '🐶 Puppy',
    'avatar5': '🦄 Unicorn',
  };
  return names[key] ?? key;
}
}
