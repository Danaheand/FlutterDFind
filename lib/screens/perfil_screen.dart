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
import '../theme/app_theme.dart';
import 'pendientes_screen.dart';
import '../repository/remote_user_repository.dart';

enum AvatarMode { preset, initial }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  bool _showLogoutDialog = false;
  bool _notifSound = true;
  bool _notifVibration = true;
  String _userName = '';
  String _userEmail = '';
  User? _currentUser;
  bool _isLoading = true;
  AvatarMode _avatarMode = AvatarMode.initial;
  String? _selectedAvatarKey; // 'avatar1'..'avatar5'
  Color _initialColor = const Color(0xFF6A4C93);

  late final TrashService _trashService;

  void _showCuteMessage(String text, IconData icon, {Color? backgroundColor}) {
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
          bottom: 80,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
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
                    color: backgroundColor ?? AppTheme.primaryLight,
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
                          size: 64, color: AppTheme.primaryLight),
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

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? [
                                        Colors.white,
                                        Colors.grey[50]!,
                                      ]
                                    : [
                                        AppTheme.cardDark,
                                        AppTheme.cardDark.withOpacity(0.8),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, color: AppTheme.primaryLight),
                              ),
                              title: Text(item.name,
                                  style: TextStyle(
                                      fontSize:
                                          fontSizeProvider.getScaledSize(16),
                                      fontWeight: FontWeight.w600,
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
                                    icon: Icon(Icons.restore,
                                        color: AppTheme.primaryLight),
                                    tooltip: 'Restaurar',
                                    splashRadius: 24,
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
                                        _showCuteMessage(
                                          'Recordatorio restaurado',
                                          Icons.restore_rounded,
                                        );
                                      } catch (e) {
                                        _showCuteMessage(
                                          'Error al restaurar',
                                          Icons.error_rounded,
                                          backgroundColor: Colors.red.shade600,
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever,
                                        color: Colors.red),
                                    tooltip: 'Eliminar permanentemente',
                                    splashRadius: 24,
                                    onPressed: () async {
                                      await _trashService
                                          .deleteItemPermanently(item.id);
                                      Navigator.pop(context);
                                      _showTrashDialog();
                                      _showCuteMessage(
                                        'Recordatorio eliminado',
                                        Icons.delete_rounded,
                                        backgroundColor: Colors.red.shade600,
                                      );
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
                            '¿Eliminar todos los elementos permanentemente?',
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
                      Navigator.pop(context);
                      _showCuteMessage(
                        'Papelera vaciada',
                        Icons.delete_sweep_rounded,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      _showCuteMessage(
                        'Error al vaciar papelera',
                        Icons.error_rounded,
                        backgroundColor: Colors.red.shade600,
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
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.brightness == Brightness.light
                    ? [
                        AppTheme.primaryLight.withOpacity(0.08),
                        AppTheme.primaryLight.withOpacity(0.05),
                      ]
                    : [
                        AppTheme.primaryDark.withOpacity(0.1),
                        AppTheme.primaryDark.withOpacity(0.05),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Configuración',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.light
                          ? AppTheme.primaryLight
                          : Colors.white,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        const Divider(),
                        // TAMAÑO DE LETRA
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.format_size),
                          title: const Text('Tamaño de letra'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('A-',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                  Expanded(
                                    child: Slider(
                                      min: 12.0,
                                      max: 28.0,
                                      divisions: 8,
                                      value: fontSizeProvider.fontSize,
                                      label:
                                          '${fontSizeProvider.fontSize.toInt()}',
                                      onChanged: (v) {
                                        fontSizeProvider.setEnabled(true);
                                        fontSizeProvider.setFontSize(v);
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                  const Text('A+',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: fontSizeProvider.fontSize == 16.0
                                      ? AppTheme.primaryLight.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: fontSizeProvider.fontSize == 16.0
                                        ? AppTheme.primaryLight.withOpacity(0.3)
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Text(
                                  'Tamaño actual: ${fontSizeProvider.fontSize.toInt()}px ${fontSizeProvider.fontSize == 16.0 ? '✓ Recomendado' : ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: fontSizeProvider.fontSize == 16.0
                                        ? AppTheme.primaryLight
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.brightness == Brightness.light
                          ? AppTheme.primaryLight
                          : AppTheme.primaryDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await _saveConfigurationSettings(
                        themeProvider.isDarkMode,
                        fontSizeProvider.fontSize.toInt(),
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Guardar y Cerrar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        radius: 70,
        backgroundImage:
            AssetImage('assets/avatars/${_selectedAvatarKey!}.png'),
        backgroundColor: Colors.transparent,
      );
    } else {
      avatarChild = CircleAvatar(
        radius: 70,
        backgroundColor: _initialColor,
        child: Text(
          nameInitial,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 72,
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
            width: 140,
            height: 140,
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
              child: const Icon(Icons.edit, size: 20, color: Color(0xFF6A4C93)),
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
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.light
                      ? [
                          Colors.white,
                          Colors.grey[50]!,
                        ]
                      : [
                          AppTheme.cardDark,
                          AppTheme.backgroundDark,
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildDialogAvatarPreview(
                              nameController.text, fontSizeProvider),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () =>
                                  _showAvatarSelector(context, setState),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? AppTheme.primaryLight
                                      : AppTheme.primaryDark,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.edit,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nombre',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? const Color(0xFF94A3B8)
                                  : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameController,
                            textAlign: TextAlign.center,
                            onChanged: (val) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Tu nombre',
                              hintStyle: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.grey[50]
                                  : AppTheme.cardDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? const Color(0xFFE2E8F0)
                                      : Colors.grey[700]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? const Color(0xFFE2E8F0)
                                      : Colors.grey[700]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? AppTheme.primaryLight
                                      : AppTheme.primaryDark,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSizeProvider.enabled
                                  ? fontSizeProvider.fontSize + 2
                                  : 16,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Correo Electrónico',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? const Color(0xFF94A3B8)
                                  : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: emailController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'tu@email.com',
                              hintStyle: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.grey[50]
                                  : AppTheme.cardDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? const Color(0xFFE2E8F0)
                                      : Colors.grey[700]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? const Color(0xFFE2E8F0)
                                      : Colors.grey[700]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? AppTheme.primaryLight
                                      : AppTheme.primaryDark,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              fontSize: fontSizeProvider.enabled
                                  ? fontSizeProvider.fontSize
                                  : 14,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? const Color(0xFF475569)
                                  : Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
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
                                      content: Text(
                                          'El nombre no puede estar vacío.')),
                                );
                                return;
                              }

                              if (newEmail.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'El correo no puede estar vacío.')),
                                );
                                return;
                              }

                              // Si nada cambió, no hacer nada
                              final nameChanged =
                                  newName != _currentUser!.nombreUsuario;
                              final emailChanged =
                                  newEmail != _currentUser!.email;

                              // Detectar si el avatar cambió
                              final currentAvatarTipo =
                                  (_currentUser!.avatarTipo == 'preset')
                                      ? AvatarMode.preset
                                      : AvatarMode.initial;
                              final currentAvatarClave =
                                  _currentUser!.avatarClave;

                              final newAvatarTipo =
                                  _avatarMode == AvatarMode.preset
                                      ? 'preset'
                                      : 'initial';
                              final newAvatarClave =
                                  _avatarMode == AvatarMode.preset
                                      ? (_selectedAvatarKey ?? 'avatar1')
                                      : _colorToHex(_initialColor);

                              final avatarChanged =
                                  currentAvatarTipo != _avatarMode ||
                                      currentAvatarClave != newAvatarClave;

                              if (!nameChanged &&
                                  !emailChanged &&
                                  !avatarChanged) {
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

                                // Debug logs
                                print('🎨 DEBUG AVATAR:');
                                print(
                                    '  currentAvatarTipo: $currentAvatarTipo');
                                print('  _avatarMode: $_avatarMode');
                                print(
                                    '  currentAvatarClave: $currentAvatarClave');
                                print('  newAvatarClave: $newAvatarClave');
                                print(
                                    '  _selectedAvatarKey: $_selectedAvatarKey');
                                print(
                                    '  _initialColor hex: ${_colorToHex(_initialColor)}');
                                print('  avatarChanged: $avatarChanged');

                                final updatedUser = await RemoteUserRepository
                                    .instance
                                    .updateProfileByEmail(
                                  correoActual: _currentUser!.email,
                                  nuevoNombre: nameChanged ? newName : null,
                                  nuevoCorreo: emailChanged ? newEmail : null,
                                  avatarTipo:
                                      avatarChanged ? newAvatarTipo : null,
                                  avatarClave:
                                      avatarChanged ? newAvatarClave : null,
                                );

                                await SessionManager.instance
                                    .setUser(updatedUser);

                                if (!mounted) return;

                                // Cerrar loading
                                Navigator.pop(context);

                                // Cerrar el modal de edición de perfil
                                Navigator.pop(context);

                                // Recargar completamente el perfil desde el servidor
                                await _loadCurrentUser();

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Perfil actualizado correctamente'),
                                    backgroundColor: AppTheme.primaryLight,
                                  ),
                                );
                              } catch (e) {
                                if (mounted)
                                  Navigator.pop(context); // Cerrar loading

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
                        ],
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
  }

  Widget _buildDialogAvatarPreview(
      String currentName, FontSizeProvider fontSizeProvider) {
    final initial = currentName.isNotEmpty ? currentName[0].toUpperCase() : '?';

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
        print(
            '🎨 DEBUG AVATAR al cargar: ${user.avatarTipo} - ${user.avatarClave}');

        // Sincronizar providers con valores del usuario
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        final fontSizeProvider =
            Provider.of<FontSizeProvider>(context, listen: false);

        // Aplicar tema oscuro desde el usuario
        if (themeProvider.isDarkMode != user.modoOscuro) {
          await themeProvider.setDarkMode(user.modoOscuro);
        }

        // Aplicar tamaño de fuente desde el usuario
        if (user.tamanoFuente > 0) {
          fontSizeProvider.setEnabled(true);
          fontSizeProvider.setFontSize(user.tamanoFuente.toDouble());
        }

        setState(() {
          _currentUser = user;
          _userName = user.nombreUsuario;
          _userEmail = user.email;

          // Cargar configuraciones de notificaciones
          _notifSound = user.notificacionesSonido;
          _notifVibration = user.notificacionesVibracion;

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
              _initialColor = const Color(0xFF6A4C93);
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

  Future<void> _saveConfigurationSettings(
    bool modoOscuro,
    int tamanoFuente,
  ) async {
    if (_currentUser == null) return;

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Verificar si algo cambió
      final configChanged = _currentUser!.notificacionesSonido != _notifSound ||
          _currentUser!.notificacionesVibracion != _notifVibration ||
          _currentUser!.modoOscuro != modoOscuro ||
          _currentUser!.tamanoFuente != tamanoFuente;

      if (!configChanged) {
        Navigator.pop(context); // Cerrar loading
        return;
      }

      // Actualizar configuraciones en el servidor
      final updatedUser =
          await RemoteUserRepository.instance.updateProfileByEmail(
        correoActual: _currentUser!.email,
        modoOscuro: modoOscuro,
        notificacionesSonido: _notifSound,
        notificacionesVibracion: _notifVibration,
        tamanoFuente: tamanoFuente,
      );

      // Actualizar usuario en SessionManager
      await SessionManager.instance.setUser(updatedUser);

      setState(() {
        _currentUser = updatedUser;
      });

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Configuración guardada correctamente'),
          backgroundColor: AppTheme.primaryLight,
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Cerrar loading

      print('Error guardando configuración: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar configuración: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;

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
              // Header con gradient - ocupa la mitad de la pantalla
              Container(
                height: screenHeight * 0.45,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: theme.brightness == Brightness.light
                        ? [
                            AppTheme.primaryLight.withOpacity(0.25),
                            AppTheme.primaryLight.withOpacity(0.15),
                          ]
                        : [
                            AppTheme.primaryDark.withOpacity(0.3),
                            AppTheme.primaryDark.withOpacity(0.2),
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 16),
                      Text(
                        _userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSizeProvider.fontSize + 6,
                          color: theme.brightness == Brightness.light
                              ? AppTheme.primaryLight
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _userEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: theme.brightness == Brightness.light
                              ? Colors.black54
                              : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Contenido - formularios y opciones
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    // CONFIGURACIONES DE LA APLICACIÓN
                    _buildCard(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Configuración'),
                        subtitle: const Text('Tema, vibración y sonido'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _showAppSettingsDialog,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // PAPELERA DE RECICLAJE
                    _buildCard(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Icon(Icons.delete_outline,
                            color: AppTheme.primaryLight),
                        title: const Text('Papelera'),
                        subtitle: Text(
                            '${_trashService.getTrashItems().length} elementos eliminados'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _showTrashDialog,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // CERRAR SESIÓN
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.brightness == Brightness.light
                            ? Colors.white
                            : AppTheme.cardDark,
                        foregroundColor: theme.brightness == Brightness.light
                            ? Colors.red
                            : AppTheme.errorDark,
                        side: BorderSide(
                            color: theme.brightness == Brightness.light
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

  void _showAvatarSelector(
      BuildContext context, void Function(void Function()) setStateDialog) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final presetKeys = [
          'avatar1',
          'avatar2',
          'avatar3',
          'avatar4',
          'avatar5'
        ];
        final colorOptions = <Color>[
          const Color(0xFF6A4C93),
          const Color(0xFFFFA726),
          const Color(0xFFFFEB3B),
          const Color(0xFF66BB6A),
          const Color(0xFF6A4C93),
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
                      'Personaliza tu Perfil',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Elige tu Avatar'),
                            selected: _avatarMode == AvatarMode.preset,
                            onSelected: (_) {
                              setStateModal(() {
                                _avatarMode = AvatarMode.preset;
                              });
                              setStateDialog(() {
                                _avatarMode = AvatarMode.preset;
                              });
                              setState(() {
                                _avatarMode = AvatarMode.preset;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Elige el color de tu Inicial'),
                            selected: _avatarMode == AvatarMode.initial,
                            onSelected: (_) {
                              setStateModal(() {
                                _avatarMode = AvatarMode.initial;
                              });
                              setStateDialog(() {
                                _avatarMode = AvatarMode.initial;
                              });
                              setState(() {
                                _avatarMode = AvatarMode.initial;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_avatarMode == AvatarMode.preset) ...[
                      Text('Avatars Disponibles:',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                              setStateModal(() {
                                _selectedAvatarKey = key;
                              });
                              setStateDialog(() {
                                _selectedAvatarKey = key;
                              });
                              setState(() {
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
                                      color: selected
                                          ? AppTheme.primaryLight
                                          : Colors.grey.shade300,
                                      width: 3,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primaryLight
                                                  .withOpacity(0.4),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: CircleAvatar(
                                    radius: 36,
                                    backgroundImage:
                                        AssetImage('assets/avatars/$key.png'),
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  )),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 8,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: colorOptions.map((c) {
                          final selected = _initialColor.value == c.value;
                          return GestureDetector(
                            onTap: () {
                              setStateModal(() {
                                _initialColor = c;
                              });
                              setStateDialog(() {
                                _initialColor = c;
                              });
                              setState(() {
                                _initialColor = c;
                              });
                              Navigator.pop(ctx);
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: c,
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: c.withOpacity(0.6),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : [],
                                  ),
                                ),
                                if (selected)
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                              ],
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
      'avatar1': 'Luli Panda',
      'avatar2': 'Rulo Oru',
      'avatar3': 'Papir Tapi',
      'avatar4': 'Morsa Chorsa',
      'avatar5': 'Zebra Debra',
    };
    return names[key] ?? key;
  }
}
