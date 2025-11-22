import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/font_size_provider.dart';
import 'providers/recordatorio_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/pendientes_state_provider.dart';
import 'screens/pendientes_screen.dart';
import 'screens/recordatorios_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';

import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/session_manager.dart';
import 'services/trash_service.dart';
import 'services/background_notification_service.dart';
import 'widgets/no_internet_banner.dart';

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
      body: Column(
        children: [
          const NoInternetBanner(),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).brightness == Brightness.light
            ? Colors.grey[600]
            : Colors.grey[400],
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Theme.of(context).cardColor,
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

  // Inicializar TrashService
  print('🗑️ Inicializando TrashService...');
  await TrashService.getInstance().loadTrashItems();

  // Solo inicializar notificaciones en dispositivos móviles (no en web)
  try {
    print('🔔 Inicializando NotificationService...');
    await NotificationService().initialize();

    // Inicializar el servicio de notificaciones en background
    print('📱 Inicializando BackgroundNotificationService...');
    await BackgroundNotificationService().initialize();
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
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(),
        ),
        ChangeNotifierProvider<FontSizeProvider>(
          create: (_) => FontSizeProvider(),
        ),
        ChangeNotifierProvider<RecordatorioProvider>(
          create: (_) => RecordatorioProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<PendientesStateProvider>(
          create: (_) => PendientesStateProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'DFind',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AppLoginScreen(),
            routes: {
              '/main': (context) => const MainScaffold(),
              '/login': (context) => const AppLoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/alerts': (context) => const AlertsScreen(),
              '/profile': (context) => const ProfileScreen(),
            },
          );
        },
      ),
    );
  }
}
