import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/font_size_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;
  bool _darkMode = false;
  bool _showLogoutDialog = false;
  bool _notifHighSound = true;
  bool _notifHighVibration = true;
  bool _notifMediumSound = false;
  bool _notifMediumVibration = true;
  bool _notifLowSound = false;
  bool _notifLowVibration = true;
  bool _notifGeneralSound = false;
  bool _notifGeneralVibration = true;
  String _userName = 'Carlos Rodríguez';
  String _userEmail = 'carlos.r@email.com';
  User? _currentUser;

  void _toggleDarkMode(bool v) {
    setState(() => _darkMode = v);
    // Cambia el tema localmente (no global)
    // Si quieres cambiar global, usa Provider o similar
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
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: ClipOval(
        child: Image.asset(
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
        ), // cierre de Image.asset
      ), // cierre de ClipOval
    ); // cierre de Container
  }

  Widget _buildSectionTitle(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.grey)),
      );

  Widget _buildCard({required Widget child, EdgeInsets? margin}) => Container(
        margin:
            margin ?? const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: child,
      );

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
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
                  _buildSectionTitle('Configuración'),
                  _buildCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading:
                              const Icon(Icons.notifications_active_outlined),
                          title: const Text('Notificaciones'),
                          subtitle:
                              const Text('Controla alertas y avisos de la app'),
                          trailing: Switch(
                            value: _notifications,
                            onChanged: (v) => setState(() {
                              _notifications = v;
                            }),
                          ),
                        ),
                        // Ajustes de notificaciones SIEMPRE visibles
                        if (_notifications)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16, right: 8, bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text('Importancia Alta',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600)),
                                Row(
                                  children: [
                                    Expanded(child: Text('Sonido')),
                                    Switch(
                                      value: _notifHighSound,
                                      onChanged: (v) =>
                                          setState(() => _notifHighSound = v),
                                    ),
                                    Expanded(child: Text('Vibración')),
                                    Switch(
                                      value: _notifHighVibration,
                                      onChanged: (v) => setState(
                                          () => _notifHighVibration = v),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Text('Importancia Media',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600)),
                                Row(
                                  children: [
                                    Expanded(child: Text('Sonido')),
                                    Switch(
                                      value: _notifMediumSound,
                                      onChanged: (v) =>
                                          setState(() => _notifMediumSound = v),
                                    ),
                                    Expanded(child: Text('Vibración')),
                                    Switch(
                                      value: _notifMediumVibration,
                                      onChanged: (v) => setState(
                                          () => _notifMediumVibration = v),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Text('Importancia Baja',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600)),
                                Row(
                                  children: [
                                    Expanded(child: Text('Sonido')),
                                    Switch(
                                      value: _notifLowSound,
                                      onChanged: (v) =>
                                          setState(() => _notifLowSound = v),
                                    ),
                                    Expanded(child: Text('Vibración')),
                                    Switch(
                                      value: _notifLowVibration,
                                      onChanged: (v) => setState(
                                          () => _notifLowVibration = v),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Text('Generales de la App',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600)),
                                Row(
                                  children: [
                                    Expanded(child: Text('Sonido')),
                                    Switch(
                                      value: _notifGeneralSound,
                                      onChanged: (v) => setState(
                                          () => _notifGeneralSound = v),
                                    ),
                                    Expanded(child: Text('Vibración')),
                                    Switch(
                                      value: _notifGeneralVibration,
                                      onChanged: (v) => setState(
                                          () => _notifGeneralVibration = v),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(Icons.dark_mode_outlined),
                          title: const Text('Tema Oscuro'),
                          trailing: Switch(
                            value: _darkMode,
                            onChanged: _toggleDarkMode,
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.format_size),
                          title: const Text('Ajustar tamaño de letra'),
                          trailing: Switch(
                            value: fontSizeProvider.enabled,
                            onChanged: (v) {
                              fontSizeProvider.setEnabled(v);
                            },
                          ),
                        ),
                        if (fontSizeProvider.enabled)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                const Text('A-', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Slider(
                                    min: 12.0,
                                    max: 28.0,
                                    divisions: 8,
                                    value: fontSizeProvider.fontSize,
                                    label: '${fontSizeProvider.fontSize.toInt()}',
                                    onChanged: (v) {
                                      fontSizeProvider.setFontSize(v);
                                    },
                                  ),
                                ),
                                const Text('A+', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
        ), // cierre de ListView
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
