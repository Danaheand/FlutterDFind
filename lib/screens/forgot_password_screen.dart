import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForgotPasswordRequestScreen extends StatefulWidget {
  const ForgotPasswordRequestScreen({super.key});

  @override
  State<ForgotPasswordRequestScreen> createState() =>
      _ForgotPasswordRequestScreenState();
}

class _ForgotPasswordRequestScreenState
    extends State<ForgotPasswordRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  final _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingrese su email';
    if (!_emailRegExp.hasMatch(v.trim())) return 'Email no válido';
    return null;
  }

  Future<void> _sendRecovery() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final email = _emailCtrl.text.trim();

    try {
      final result = await ApiService.solicitarRecuperacion(correo: email);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Te enviamos un código de recuperación a $email',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ForgotPasswordCodeScreen(correo: email),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            colors: theme.brightness == Brightness.light
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
                      alpha: theme.brightness == Brightness.light ? 0.98 : 0.92,
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 52,
                              width: 52,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(39, 106, 76, 147),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_reset_rounded,
                                color: Color(0xFF6A4C93),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recuperar contraseña',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                      color: const Color(0xFF6A4C93),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ingresa el correo asociado a tu cuenta para enviarte un código de recuperación.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withOpacity(0.75),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailCtrl,
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
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendRecovery,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A4C93),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Enviar código',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                      color: Colors.white,
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

class ForgotPasswordCodeScreen extends StatefulWidget {
  final String correo;

  const ForgotPasswordCodeScreen({super.key, required this.correo});

  @override
  State<ForgotPasswordCodeScreen> createState() =>
      _ForgotPasswordCodeScreenState();
}

class _ForgotPasswordCodeScreenState extends State<ForgotPasswordCodeScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<TextEditingController> _digitCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _digitFocusNodes = List.generate(6, (_) => FocusNode());

  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _digitCtrls) {
      c.dispose();
    }
    for (final f in _digitFocusNodes) {
      f.dispose();
    }
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _composeCode() {
    return _digitCtrls.map((c) => c.text.trim()).join();
  }

  bool _hasLower(String s) => RegExp(r'[a-z]').hasMatch(s);
  bool _hasUpper(String s) => RegExp(r'[A-Z]').hasMatch(s);
  bool _hasDigit(String s) => RegExp(r'\d').hasMatch(s);

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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final code = _composeCode();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa los 6 dígitos del código'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final verifyResult = await ApiService.verificarCodigoRecuperacion(
        correo: widget.correo,
        codigo: code,
      );

      if (!mounted) return;

      if (verifyResult['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(verifyResult['error'] ?? 'Código inválido o expirado.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final resetResult = await ApiService.restablecerContrasena(
        correo: widget.correo,
        codigo: code,
        nuevaContrasena: _passCtrl.text,
      );

      if (!mounted) return;

      if (resetResult['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resetResult['error'] ?? 'No se pudo restablecer.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDigitBox(
    int index,
    ThemeData theme,
    FormFieldState<String> state,
  ) {
    return SizedBox(
      width: 48,
      child: TextField(
        controller: _digitCtrls[index],
        focusNode: _digitFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: state.hasError
                  ? theme.colorScheme.error
                  : const Color(0xFF9D84B7),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: state.hasError
                  ? theme.colorScheme.error
                  : const Color(0xFF6A4C93),
              width: 1.8,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.length > 1) {
            _digitCtrls[index].text = value.characters.last;
            _digitCtrls[index].selection = TextSelection.fromPosition(
              TextPosition(offset: _digitCtrls[index].text.length),
            );
          }

          if (value.isNotEmpty && index < _digitFocusNodes.length - 1) {
            _digitFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _digitFocusNodes[index - 1].requestFocus();
          }

          state.didChange(_composeCode());
        },
        onSubmitted: (_) {
          if (index == _digitFocusNodes.length - 1) {
            _submit();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            colors: theme.brightness == Brightness.light
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
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
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(39, 106, 76, 147),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_open_rounded,
                        color: Color(0xFF6A4C93),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ingresa tu código',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Te enviamos un código de recuperación a:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.correo,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Código de recuperación',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FormField<String>(
                      validator: (_) {
                        final code = _composeCode();
                        if (code.isEmpty) {
                          return 'Ingresa el código de recuperación';
                        }
                        if (code.length < 6) {
                          return 'Completa los 6 dígitos';
                        }
                        return null;
                      },
                      builder: (state) {
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                6,
                                (index) => _buildDigitBox(index, theme, state),
                              ),
                            ),
                            if (state.hasError)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8.0, left: 4),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    state.errorText ?? '',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nueva contraseña',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
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
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirmar nueva contraseña',
                        prefixIcon: const Icon(Icons.lock_person_outlined),
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A4C93),
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
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Cambiar contraseña',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                  color: Colors.white,
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
    );
  }
}
