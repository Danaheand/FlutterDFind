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

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

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
            content: Text(errorText),
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
                          alreadySent: sendResult['success'] == true,
                        ),
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
      print('Error login: $e');
      print('Stack trace: $st');
      setState(() {
        _error = true;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.brightness == Brightness.light
                ? [
                    theme.colorScheme.primary.withOpacity(0.15),
                    theme.colorScheme.secondary.withOpacity(0.08),
                    theme.colorScheme.background,
                  ]
                : [
                    theme.colorScheme.surface,
                    theme.colorScheme.background,
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(
                    theme.brightness == Brightness.light ? 0.98 : 0.92),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: theme.colorScheme.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'DFind',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.brightness == Brightness.light
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Organiza tus cosas sin perder nada',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.75),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _userCtrl,
                      keyboardType: TextInputType.emailAddress,
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
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Ingrese contraseña' : null,
                    ),
                    if (_error)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Usuario o contraseña incorrectos',
                            style: TextStyle(
                              color: theme.brightness == Brightness.light
                                  ? Colors.red[700]
                                  : Colors.red[400],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes cuenta?',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Material(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pushNamed('/register');
                            },
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'Regístrate',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
