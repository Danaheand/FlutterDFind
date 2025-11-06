import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../repository/local_user_repository.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
      final repo = LocalUserRepository.instance;

      // Depuración: listar usuarios guardados
      final allUsers = await repo.getAll();
      print('--- Usuarios almacenados (${allUsers.length}) ---');
      for (var u in allUsers) {
        print('user id:${u.idUsuario} nombre:"${u.nombreUsuario}" email:"${u.email}" hash:"${u.contrasenaHash}"');
      }

      final inputEmail = _userCtrl.text.trim();
      final user = await repo.findByEmail(inputEmail);

      if (user == null) {
        print('Usuario no encontrado para email: "$inputEmail"');
        setState(() => _error = true);
        return;
      }

      // Verificar contraseña (mismo método de hashing que en registro)
      final inputHash = _sha256Hash(_passCtrl.text);
      print('Comparando hashes -> esperado: ${user.contrasenaHash}, recibido: $inputHash');

      if (inputHash != user.contrasenaHash) {
        setState(() => _error = true);
        return;
      }

      // Guardar usuario actual (json)
      final sp = await SharedPreferences.getInstance();
      await sp.setString('current_user', jsonEncode(user.toJson()));

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/'); // Esto llevará al MainScaffold que tiene AlertsScreen

    } catch (e, st) {
      print('Error en login: $e');
      print(st);
      setState(() => _error = true);
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
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text('DFind', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.blue[700], fontWeight: FontWeight.bold)),
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
                        : !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())
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
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese contraseña' : null,
                  ),
                  if (_error)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text('Usuario o contraseña incorrectos', style: TextStyle(color: Colors.red[700])),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes cuenta?'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/register');
                        },
                        child: const Text('Regístrate'),
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
