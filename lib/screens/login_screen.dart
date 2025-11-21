import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../providers/font_size_provider.dart';
import 'verify_email_screen.dart';

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
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _error = false;
      _isLoading = true;
    });
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      print('Probando conectividad...');
      final hasConnection = await ApiService.testConnection();
      if (!hasConnection) {
        throw Exception(
            'No se puede conectar al servidor. Verifica tu conexión a internet.');
      }

      final email = _userCtrl.text.trim();
      final password = _passCtrl.text.trim();

      print('Iniciando login...');
      final result = await ApiService.loginUser(
        correo: email,
        password: password,
      );

      if (result['success'] == true) {
        await SessionManager.instance.setUserSession(result['data']);

        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        setState(() {
          _error = true;
          _isLoading = false;
        });

        if (!mounted) return;

        final errorText = (result['error'] ?? '').toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorText'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );

        final lower = errorText.toLowerCase();
        if (lower.contains('verificar') || lower.contains('no verificado')) {
          final email = _userCtrl.text.trim();

          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Correo no verificado'),
              content: Text(
                'Tu correo aún no está verificado.\n\n'
                '¿Quieres que te enviemos un nuevo código a $email?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final sendResult =
                        await ApiService.enviarCodigoVerificacion(
                      correo: email,
                    );

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(sendResult['success'] == true
                            ? 'Enviamos un nuevo código a $email'
                            : '${sendResult['error']}'),
                        backgroundColor: sendResult['success'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    );

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VerifyEmailScreen(
                            correo: email,
                            alreadySent: sendResult['success'] == true),
                      ),
                    );
                  },
                  child: const Text('Verificar ahora'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e, st) {
      print('❌ Error login: $e');
      print('📍 Stack trace: $st');
      setState(() {
        _error = true;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $e'),
          duration: const Duration(seconds: 6),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? Colors.blue[50]
          : theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? Colors.white
                  : theme.cardColor,
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
                          color: theme.brightness == Brightness.light
                              ? Colors.blue[700]
                              : theme.colorScheme.primary,
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
                          style: TextStyle(
                              color: theme.brightness == Brightness.light
                                  ? Colors.red[700]
                                  : Colors.red[400])),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Entrar',
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
