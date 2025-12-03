import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String correo;
  final bool alreadySent;
  final bool asDialog;
  final VoidCallback? onVerified;

  const VerifyEmailScreen({
    super.key,
    required this.correo,
    this.alreadySent = false,
    this.asDialog = false,
    this.onVerified,
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

  String _normalizeBackendMessage(
    dynamic raw, {
    String fallback = 'Ocurrió un error, intenta nuevamente.',
  }) {
    if (raw == null) return fallback;

    if (raw is Map) {
      final m = raw as Map;
      raw = m['mensaje'] ?? m['message'] ?? m['error'] ?? raw.toString();
    }

    var text = raw.toString().trim();
    if (text.isEmpty) return fallback;

    final match = RegExp(r'"mensaje"\s*:\s*"([^"]+)"').firstMatch(text);
    if (match != null) {
      text = match.group(1)!;
    }

    final lower = text.toLowerCase();

    if ((lower.contains('codigo') || lower.contains('código')) &&
        (lower.contains('inválido') ||
            lower.contains('invalido') ||
            lower.contains('expirado'))) {
      return 'Código inválido o expirado.';
    }

    return text;
  }

  void _showPurpleBar(String text, IconData icon) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        backgroundColor: const Color(0xFF6A4C93),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendCode({bool initial = false}) async {
    setState(() => _sending = true);
    try {
      final result =
          await ApiService.enviarCodigoVerificacion(correo: widget.correo);

      if (!mounted) return;

      if (result['success'] == true) {
        final text = initial
            ? 'Te enviamos un código a ${widget.correo}'
            : 'Reenviamos el código a ${widget.correo}';
        _showPurpleBar(text, Icons.check_circle_rounded);
      } else {
        final errorText = _normalizeBackendMessage(
          result['error'] ?? result['message'],
          fallback: 'No se pudo enviar el código, intenta nuevamente.',
        );
        _showPurpleBar(errorText, Icons.warning_rounded);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  String _composeCode() {
    final buffer = StringBuffer();
    for (final c in _digitCtrls) {
      buffer.write(c.text.trim());
    }
    return buffer.toString();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final code = _composeCode();
    _codeCtrl.text = code;

    setState(() => _verifying = true);
    try {
      final result = await ApiService.verificarCodigoVerificacion(
        correo: widget.correo,
        codigo: _codeCtrl.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        final msg = _normalizeBackendMessage(
          result['message'] ?? result['data']?['mensaje'],
          fallback: 'Correo verificado correctamente.',
        );

        _showPurpleBar(msg, Icons.check_circle_rounded);

        widget.onVerified?.call();

        if (widget.asDialog) {
          Navigator.of(context).maybePop(true);
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        final raw = result['error'] ?? result['message'] ?? result['data'];
        final errorText = _normalizeBackendMessage(
          raw,
          fallback: 'Código inválido o expirado.',
        );

        _showPurpleBar(errorText, Icons.warning_rounded);
      }
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  Widget _buildDigitBox(
    int index,
    ThemeData theme,
  ) {
    return SizedBox(
      width: 48,
      child: TextFormField(
        controller: _digitCtrls[index],
        focusNode: _digitFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
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
              color: theme.colorScheme.outline.withOpacity(0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.6,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.length == 1 && index < _digitFocusNodes.length - 1) {
            _digitFocusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _digitFocusNodes[index - 1].requestFocus();
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '';
          }
          if (int.tryParse(value) == null) {
            return '';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, {required bool insideDialog}) {
    final theme = Theme.of(context);
    final codeSentText = widget.alreadySent
        ? 'Ingresa el código que enviamos a'
        : 'Te enviamos un código a';

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (insideDialog)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(false),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Verificar correo',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6A4C93),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$codeSentText\n${widget.correo}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mail_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  'Si no lo ves, revisa la carpeta de spam',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                6,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildDigitBox(index, theme),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A4C93),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _verifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                        ),
                      )
                    : const Text(
                        'Verificar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _sending ? null : () => _sendCode(initial: false),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Reenviar código',
                      style: TextStyle(
                        color: Color(0xFF6A4C93),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asDialog) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 420,
            minWidth: 320,
          ),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(24),
            color: Theme.of(context).colorScheme.surface,
            child: _buildContent(
              context,
              insideDialog: true,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar correo'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: _buildContent(
              context,
              insideDialog: false,
            ),
          ),
        ),
      ),
    );
  }
}
