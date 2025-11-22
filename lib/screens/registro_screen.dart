import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'terminos_screen.dart';
import 'politicas_privacidad_screen.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreeTerms = false;

  final _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showCuteMessage(String text, IconData icon, {Color? backgroundColor}) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    final controller = AnimationController(
      vsync: this as TickerProvider,
      duration: const Duration(milliseconds: 320),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );

    entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          left: 16,
          right: 16,
          bottom: 80,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: backgroundColor ?? const Color.fromARGB(255, 98, 77, 129),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () async {
      try {
        await controller.reverse();
      } catch (_) {}
      entry.remove();
      controller.dispose();
    });
  }

  bool _hasLower(String s) => RegExp(r'[a-z]').hasMatch(s);
  bool _hasUpper(String s) => RegExp(r'[A-Z]').hasMatch(s);
  bool _hasDigit(String s) => RegExp(r'\d').hasMatch(s);

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingrese su nombre';
    if (v.trim().length < 3) return 'Mínimo 3 caracteres';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingrese su email';
    if (!_emailRegExp.hasMatch(v.trim())) return 'Email no válido';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Ingrese una contraseña';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    if (!_hasLower(v)) return 'Debe incluir minúscula';
    if (!_hasUpper(v)) return 'Debe incluir mayúscula';
    if (!_hasDigit(v)) return 'Debe incluir un número';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Repita la contraseña';
    if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  Future<void> _submit() async {
    if (!mounted) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (!_agreeTerms) {
      _showCuteMessage(
        'Debes aceptar los Términos y la Política de Privacidad',
        Icons.warning_rounded,
        backgroundColor: const Color(0xFF6A4C93),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hasConnection = await ApiService.testConnection();
      if (!hasConnection) {
        throw Exception(
          'No se puede conectar al servidor. Verifica tu conexión a internet.',
        );
      }

      final result = await ApiService.registerUser(
        nombreUsuario: _nameCtrl.text.trim(),
        correo: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        aceptoTerminos: true,
        versionTerminos: "1.0",
        ipAceptacion: "192.168.1.1",
      );

      final email = _emailCtrl.text.trim();

      if (result['success'] == true) {
        final data = result['data'];
        bool backendAlreadySent = false;
        try {
          if (data is Map) {
            final msg = ((data['mensaje'] ?? data['message'] ?? '') as String)
                .toLowerCase();
            if (msg.contains('envi') ||
                msg.contains('codigo') ||
                msg.contains('correo')) {
              backendAlreadySent = true;
            }
          }
        } catch (_) {
          backendAlreadySent = false;
        }

        bool navigatedWithAlreadySent = false;

        if (!backendAlreadySent) {
          final sendResult =
              await ApiService.enviarCodigoVerificacion(correo: email);

          if (!mounted) return;

          _showCuteMessage(
            sendResult['success'] == true
                ? 'Registro exitoso. Te enviamos un código a $email'
                : 'Hubo un problema al enviar el código: ${sendResult['error']}',
            sendResult['success'] == true
                ? Icons.check_circle_rounded
                : Icons.warning_rounded,
            backgroundColor: const Color(0xFF6A4C93),
          );

          navigatedWithAlreadySent = sendResult['success'] == true;
        } else {
          if (!mounted) return;
          _showCuteMessage(
            'Registro exitoso. Te enviamos un código a $email',
            Icons.check_circle_rounded,
            backgroundColor: const Color(0xFF6A4C93),
          );

          navigatedWithAlreadySent = true;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(
              correo: email,
              alreadySent: navigatedWithAlreadySent,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        
        // Limpiar el mensaje de error
        String errorMsg = '${result['error']}';
        
        // Si contiene "correo ya está registrado", simplificar el mensaje
        if (errorMsg.toLowerCase().contains('correo') && 
            errorMsg.toLowerCase().contains('registrado')) {
          errorMsg = 'El correo ya está registrado.';
        }
        
        _showCuteMessage(
          errorMsg,
          Icons.error_rounded,
          backgroundColor: const Color(0xFF6A4C93),
        );
      }
    } catch (e) {
      _showCuteMessage(
        '$e',
        Icons.error_rounded,
        backgroundColor: const Color(0xFF6A4C93),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordRequirements(String password) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'La contraseña debe contener:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _RequirementItem(
          text: 'Mínimo 8 caracteres',
          isValid: password.length >= 8,
        ),
        _RequirementItem(
          text: 'Al menos una minúscula',
          isValid: _hasLower(password),
        ),
        _RequirementItem(
          text: 'Al menos una mayúscula',
          isValid: _hasUpper(password),
        ),
        _RequirementItem(
          text: 'Al menos un número',
          isValid: _hasDigit(password),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onBackground,
      ),
      body: Container(
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(
                      alpha: isLight ? 0.98 : 0.92,
                    ),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.fromARGB(39, 106, 76, 147),
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: Color(0xFF6A4C93),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Crear cuenta',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                      color: const Color(0xFF6A4C93),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Configura tu cuenta para empezar a organizar todo con DFind.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.75),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            hintText: 'Ej.: Juan Pérez',
                            prefixIcon: const Icon(Icons.badge_outlined),
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
                          validator: _validateName,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'tucorreo@dominio.com',
                            prefixIcon:
                                const Icon(Icons.alternate_email_rounded),
                            suffixIcon: _emailCtrl.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _emailCtrl.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.clear_rounded),
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
                          onChanged: (_) => setState(() {}),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final val = _passCtrl.text;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                  validator: _validatePassword,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 12),
                                _buildPasswordRequirements(val),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: const Icon(
                              Icons.lock_person_outlined,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
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
                          validator: _validateConfirm,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _agreeTerms,
                                onChanged: (v) =>
                                    setState(() => _agreeTerms = v ?? false),
                                activeColor: const Color(0xFF6A4C93),
                                checkColor: Colors.white,
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Acepto los ',
                                    style: theme.textTheme.bodyMedium,
                                    children: [
                                      TextSpan(
                                        text: 'Términos',
                                        style: const TextStyle(
                                          color: Color(0xFF6A4C93),
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const TermsScreen(),
                                              ),
                                            );
                                          },
                                      ),
                                      const TextSpan(text: ' y la '),
                                      TextSpan(
                                        text: 'Política de privacidad',
                                        style: const TextStyle(
                                          color: Color(0xFF6A4C93),
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const PrivacyPolicyScreen(),
                                              ),
                                            );
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 131, 106, 167),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                  : const Text(
                                    'Crear cuenta',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String text;
  final bool isValid;

  const _RequirementItem({
    required this.text,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: isValid
                ? Colors.green
                : (isLight ? Colors.grey : Colors.grey[400]),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isValid
                  ? Colors.green
                  : (isLight ? Colors.grey : Colors.grey[400]),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
