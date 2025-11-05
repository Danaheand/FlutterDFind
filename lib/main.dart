import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import 'screens/inventory_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/properties_screen.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'theme/app_theme.dart';
import 'repository/local_user_repository.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    AlertsScreen(),
    InventoryScreen(),
    ProfileScreen(),
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
            label: 'Alertas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Lista de compras',
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
  await LocalUserRepository.instance.init(); // Asegura usuario de prueba
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/login',
      routes: {
        '/': (context) => const MainScaffold(), // Cambiar esto
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/alerts': (context) => const AlertsScreen(), // Agregar esta ruta
        '/profile': (context) => const ProfileScreen(),
        '/properties': (context) => const PropertiesScreen(),
        '/categories': (context) => const CategoriesScreen(),
      },
    );
  }
}