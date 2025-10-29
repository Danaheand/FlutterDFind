import 'package:flutter/material.dart';

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

  void _login() {
    setState(() => _error = false);
    if (_formKey.currentState?.validate() ?? false) {
      // Demo: usuario: carlos, pass: 12345
  if (_userCtrl.text.trim() == 'Carlos' && _passCtrl.text == '12345') {
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        setState(() => _error = true);
      }
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
                    decoration: const InputDecoration(labelText: 'Usuario'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese usuario' : null,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
