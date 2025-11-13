import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../repository/local_user_repository.dart';
import '../repository/remote_user_repository.dart';


class AppLoginScreen extends StatefulWidget {
  const AppLoginScreen({super.key});

  @override
  State<AppLoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<AppLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _error = false;

  String _sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _login() async {
  setState(() => _error = false);
  if (!(_formKey.currentState?.validate() ?? false)) return;

  try {
    final email = _userCtrl.text.trim();

    final remoteRepo = RemoteUserRepository.instance;
    final user = await remoteRepo.login(
      email: email,
      contrasenaHash: _passCtrl.text.trim(), // ej: "hash123"
    );

    final sp = await SharedPreferences.getInstance();
    await sp.setString('current_user', jsonEncode(user.toJson()));

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/main');
  } catch (e, st) {
    print('Error en login remoto: $e');
    print(st);
    setState(() => _error = true);

    if (!mounted) return;
    // 👇 aquí mostramos el error COMPLETO en la app (APK/web/emulador)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 12)
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text('DFind',
                      style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _userCtrl,
                    keyboardType: TextInputType.emailAddress, // Agregar esto
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'tucorreo@dominio.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Ingrese su email'
                        : !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(v.trim())
                            ? 'Email no válido'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese contraseña' : null,
                  ),
                  if (_error)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text('Usuario o contraseña incorrectos',
                          style: TextStyle(color: Colors.red[700])),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      child: const Text('Entrar',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes cuenta?'),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pushNamed('/register');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: const Text(
                              'Regístrate',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
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
  }
}
