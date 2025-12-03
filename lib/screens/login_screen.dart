import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../widgets/no_internet_banner.dart';
import 'verify_email_screen.dart';
import 'forgot_password_screen.dart';

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
        throw Exception('Verifica tu conexión a internet.');
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
        final lower = errorText.toLowerCase();

        // Verificar si el usuario no existe
        if (lower.contains('no existe') || 
            lower.contains('no encontrado') || 
            lower.contains('usuario no') ||
            lower.contains('correo no')) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Usuario no registrado'),
              content: const Text(
                'El correo que ingresaste no está registrado en la aplicación.\n\n'
                '¿Quieres crear una cuenta nueva?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushNamed('/register');
                  },
                  child: const Text('Registrarse'),
                ),
              ],
            ),
          );
        } else if (lower.contains('verificar') || lower.contains('no verificado')) {
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
                        content: Text(
                          sendResult['success'] == true
                              ? 'Enviamos un nuevo código a $email'
                              : '${sendResult['error']}',
                        ),
                        backgroundColor: sendResult['success'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    );

                    if (sendResult['success'] == true) {
                      final verified = await showDialog<bool>(
                        context: context,
                        barrierDismissible: true,
                        builder: (dialogCtx) => VerifyEmailScreen(
                          correo: email,
                          alreadySent: true,
                          asDialog: true,
                          onVerified: () {
                            Navigator.of(dialogCtx).pop(true);
                          },
                        ),
                      );

                      if (verified == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Correo verificado. Intenta iniciar sesión de nuevo.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
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
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const NoInternetBanner(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLight
                      ? [
                          const Color(0xFF6A4C93).withValues(alpha: 0.08),
                          const Color(0xFF9D84B7).withValues(alpha: 0.05),
                          theme.colorScheme.surface,
                        ]
                      : [
                          const Color(0xFF6A4C93).withValues(alpha: 0.15),
                          const Color(0xFF2C1B47),
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: theme.cardColor
                          .withValues(alpha: isLight ? 0.98 : 0.92),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6A4C93).withValues(alpha: 0.1),
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
                              color: const Color(0xFF6A4C93)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: Color(0xFF6A4C93),
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'DFind',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: const Color(0xFF6A4C93),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _userCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'tucorreo@dominio.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6A4C93),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6A4C93),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Ingrese su email'
                                : !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(v.trim())
                                    ? 'Email no válido'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6A4C93),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6A4C93),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Ingrese contraseña'
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordRequestScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                  color: Color(0xFF6A4C93),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
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
                                backgroundColor: const Color(0xFF6A4C93),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
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
                                    Navigator.of(context)
                                        .pushNamed('/register');
                                  },
                                  borderRadius: BorderRadius.circular(999),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      'Regístrate',
                                      style: const TextStyle(
                                        color: Color(0xFF6A4C93),
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
          ),
        ],
      ),
    );
  }
}
