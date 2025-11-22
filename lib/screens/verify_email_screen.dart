import 'package:flutter/material.dart';

import '../services/api_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String correo;
  final bool alreadySent;

  const VerifyEmailScreen({
    super.key,
    required this.correo,
    this.alreadySent = false,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeCtrl = TextEditingController();

  final List<TextEditingController> _digitCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _digitFocusNodes = List.generate(6, (_) => FocusNode());

  bool _sending = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    if (!widget.alreadySent) {
      _sendCode(initial: true);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    for (final c in _digitCtrls) {
      c.dispose();
    }
    for (final f in _digitFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _composeCode() {
    return _digitCtrls.map((c) => c.text.trim()).join();
  }

  Future<void> _sendCode({bool initial = false}) async {
    setState(() => _sending = true);
    try {
      final result =
          await ApiService.enviarCodigoVerificacion(correo: widget.correo);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['success']
                ? (initial
                    ? 'Se envió un código a ${widget.correo}'
                    : 'Código reenviado a ${widget.correo}')
                : '${result['error']}',
          ),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final code = _composeCode();
    _codeCtrl.text = code;

    setState(() => _verifying = true);
    try {
      final result = await ApiService.verificarCodigoVerificacion(
        correo: widget.correo,
        codigo: _codeCtrl.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message'] ?? 'Correo verificado correctamente.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Código inválido o expirado.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
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
            _verify();
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
        centerTitle: true,
        title: const Text('Verificar correo'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.brightness == Brightness.light
                ? [
                    const Color.fromARGB(255, 133, 118, 155).withValues(alpha: 0.08),
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
            padding: const EdgeInsets.fromLTRB(24, kToolbarHeight + 24, 24, 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(
                    alpha: theme.brightness == Brightness.light ? 0.98 : 0.92),
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
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(39, 106, 76, 147),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: Color(0xFF6A4C93),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Revisa tu correo',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        color: const Color(0xFF6A4C93),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Te enviamos un código de verificación a:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
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
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red.shade500,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Revisa también tu bandeja de spam',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Código de verificación',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.9,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FormField<String>(
                      validator: (_) {
                        final code = _composeCode();
                        if (code.isEmpty) {
                          return 'Ingresa el código de verificación';
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
                                (index) => _buildDigitBox(
                                  index,
                                  theme,
                                  state,
                                ),
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verifying ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 160, 137, 194),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _verifying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Verificar'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed:
                          _sending ? null : () => _sendCode(initial: false),
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6A4C93)),
                      label: Text(
                        _sending ? 'Reenviando...' : 'Reenviar código',
                        style: const TextStyle(color: Color(0xFF6A4C93)),
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
