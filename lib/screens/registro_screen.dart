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

  final _nameFieldKey = GlobalKey<FormFieldState>();
  final _emailFieldKey = GlobalKey<FormFieldState>();
  final _passFieldKey = GlobalKey<FormFieldState>();
  final _confirmFieldKey = GlobalKey<FormFieldState>();

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
      vsync: this,
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
                    color: backgroundColor ??
                        const Color.fromARGB(255, 98, 77, 129),
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

  String _normalizeBackendMessage(
    dynamic raw, {
    String fallback = 'Ocurrió un error, intenta nuevamente.',
  }) {
    if (raw == null) return fallback;

    if (raw is Map) {
      final m = raw as Map;

      final directKeys = [
        'mensaje',
        'message',
        'error',
        'detail',
        'detalle',
        'title',
      ];
      for (final k in directKeys) {
        final v = m[k];
        if (v != null && v.toString().trim().isNotEmpty) {
          raw = v;
          break;
        }
      }

      if (raw is Map) {
        final data = raw;
        for (final k in directKeys) {
          final v = data[k];
          if (v != null && v.toString().trim().isNotEmpty) {
            raw = v;
            break;
          }
        }
      }

      if (raw is Map && m['data'] is Map) {
        final data = m['data'] as Map;
        for (final k in directKeys) {
          final v = data[k];
          if (v != null && v.toString().trim().isNotEmpty) {
            raw = v;
            break;
          }
        }
      }
    }

    var text = raw.toString().trim();
    if (text.isEmpty) return fallback;

    final match = RegExp(r'"mensaje"\s*:\s*"([^"]+)"').firstMatch(text);
    if (match != null) {
      text = match.group(1)!;
    }

    final lower = text.toLowerCase();

    final hasCorreoOrEmail =
        lower.contains('correo') || lower.contains('email');
    final hasDuplicateWord = lower.contains('registrad') ||
        lower.contains('ya existe') ||
        lower.contains('ya esta en uso') ||
        lower.contains('ya está en uso') ||
        lower.contains('en uso') ||
        lower.contains('ya fue utilizado') ||
        lower.contains('ya fue usado') ||
        lower.contains('ya se encuentra');

    if (hasCorreoOrEmail && hasDuplicateWord) {
      return 'El correo ya está registrado.';
    }

    if ((lower.contains('codigo') || lower.contains('código')) &&
        (lower.contains('inválido') ||
            lower.contains('invalido') ||
            lower.contains('expirado'))) {
      return 'Código inválido o expirado.';
    }

    return text;
  }

  Future<void> _submit() async {
    if (!mounted) return;

    final nameError = _validateName(_nameCtrl.text);
    if (nameError != null) {
      _nameFieldKey.currentState?.validate();
      _showCuteMessage(
        nameError,
        Icons.warning_rounded,
        backgroundColor: const Color(0xFF6A4C93),
      );
      return;
    }

    final emailError = _validateEmail(_emailCtrl.text);
    if (emailError != null) {
      _emailFieldKey.currentState?.validate();
      _showCuteMessage(
        emailError,
        Icons.warning_rounded,
        backgroundColor: const Color(0xFF6A4C93),
      );
      return;
    }

    final passError = _validatePassword(_passCtrl.text);
    if (passError != null) {
      _passFieldKey.currentState?.validate();
      _showCuteMessage(
        passError,
        Icons.warning_rounded,
        backgroundColor: const Color(0xFF6A4C93),
      );
      return;
    }

    final confirmError = _validateConfirm(_confirmCtrl.text);
    if (confirmError != null) {
      _confirmFieldKey.currentState?.validate();
      _showCuteMessage(
        confirmError,
        Icons.warning_rounded,
        backgroundColor: const Color(0xFF6A4C93),
      );
      return;
    }

    if (!_agreeTerms) {
      _showCuteMessage(
        'Debes aceptar los Términos y la Política de Privacidad',
        Icons.warning_rounded,
        backgroundColor: const Color(0xFF6A4C93),
      );
      return;
    }

    final email = _emailCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      final sendResult =
          await ApiService.enviarCodigoVerificacion(correo: email);

      if (!mounted) return;

      if (sendResult['success'] == true) {
        _showCuteMessage(
          'Te enviamos un código a $email',
          Icons.check_circle_rounded,
          backgroundColor: const Color(0xFF6A4C93),
        );
      } else {
        final errorText = _normalizeBackendMessage(
          sendResult,
          fallback: 'Hubo un problema al enviar el código, intenta nuevamente.',
        );
        _showCuteMessage(
          errorText,
          Icons.warning_rounded,
          backgroundColor: const Color(0xFF6A4C93),
        );
        return;
      }

      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => VerifyEmailScreen(
          correo: email,
          alreadySent: true,
          asDialog: true,
          onVerified: () {
            Navigator.of(ctx).pop(true);
          },
        ),
      );

      if (verified != true) {
        if (!mounted) return;
        _showCuteMessage(
          'Debes verificar tu correo para completar el registro.',
          Icons.warning_rounded,
          backgroundColor: const Color(0xFF6A4C93),
        );
        return;
      }

      final result = await ApiService.registerUser(
        nombreUsuario: _nameCtrl.text.trim(),
        correo: email,
        password: _passCtrl.text,
        aceptoTerminos: true,
        versionTerminos: "1.0",
        ipAceptacion: "192.168.1.1",
      );

      if (!mounted) return;

      final normalizedMsg = _normalizeBackendMessage(
        result,
        fallback: '',
      );
      final lowerNorm = normalizedMsg.toLowerCase();

      final hasCorreoOrEmail =
          lowerNorm.contains('correo') || lowerNorm.contains('email');
      final hasDuplicateWord = lowerNorm.contains('registrad') ||
          lowerNorm.contains('ya existe') ||
          lowerNorm.contains('en uso') ||
          lowerNorm.contains('ya fue utilizado') ||
          lowerNorm.contains('ya fue usado') ||
          lowerNorm.contains('ya se encuentra');

      final isDuplicateEmail = hasCorreoOrEmail && hasDuplicateWord;

      if (isDuplicateEmail) {
        _showCuteMessage(
          'El correo ya está registrado.',
          Icons.warning_rounded,
          backgroundColor: const Color(0xFF6A4C93),
        );
        return;
      }

      if (result['success'] == true) {
        _showCuteMessage(
          'Registro exitoso. Ahora puedes iniciar sesión.',
          Icons.check_circle_rounded,
          backgroundColor: const Color(0xFF6A4C93),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        final errorText = _normalizeBackendMessage(
          result,
          fallback: 'No se pudo completar el registro.',
        );
        _showCuteMessage(
          errorText,
          Icons.warning_rounded,
          backgroundColor: const Color(0xFF6A4C93),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errorText = _normalizeBackendMessage(
        e.toString(),
        fallback: 'Ocurrió un error al registrar. Intenta nuevamente.',
      );
      _showCuteMessage(
        errorText,
        Icons.warning_rounded,
        backgroundColor: const Color(0xFF6A4C93),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Container(
                  padding: const EdgeInsets.all(32),
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
                    autovalidateMode: AutovalidateMode.disabled,
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
                          key: _nameFieldKey,
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
                          onChanged: (_) =>
                              _nameFieldKey.currentState?.validate(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: _emailFieldKey,
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
                          onChanged: (_) {
                            setState(() {});
                            _emailFieldKey.currentState?.validate();
                          },
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
                                  key: _passFieldKey,
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
                                  onChanged: (_) {
                                    _passFieldKey.currentState?.validate();
                                    setState(() {});
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildPasswordRequirements(val),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: _confirmFieldKey,
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
                          onChanged: (_) =>
                              _confirmFieldKey.currentState?.validate(),
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
                              backgroundColor:
                                  const Color.fromARGB(255, 131, 106, 167),
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
                                        Colors.white,
                                      ),
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
