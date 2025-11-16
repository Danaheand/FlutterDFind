import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/font_size_provider.dart';
import 'providers/recordatorio_provider.dart';
import 'screens/pendientes_screen.dart';
import 'screens/recordatorios_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';

import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/session_manager.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AlertsScreen(),
    const InventoryScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Recordatorios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Pendientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar el gestor de sesión
  print('🔧 Inicializando SessionManager...');
  await SessionManager.instance.initialize();

  // Solo inicializar notificaciones en dispositivos móviles (no en web)
  try {
    await NotificationService().initialize();
  } catch (e) {
    print('Error inicializando notificaciones (probablemente web): $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FontSizeProvider>(
          create: (_) => FontSizeProvider(),
        ),
        ChangeNotifierProvider<RecordatorioProvider>(
          create: (_) => RecordatorioProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'DFind',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AppLoginScreen(),
        routes: {
          '/main': (context) => const MainScaffold(),
          '/login': (context) => const AppLoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/alerts': (context) => const AlertsScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
