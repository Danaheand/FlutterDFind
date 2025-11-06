// lib/register_screen.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repository/local_user_repository.dart';
import '../models/user.dart';

/// Pantalla principal de registro (mejorada UI/UX).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
    if (!mounted) return; // Agregar al inicio del método

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Debes aceptar los Términos y la Política de Privacidad')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verificar si email ya existe (local)
      final repo = LocalUserRepository.instance;
      final existing = await repo.findByEmail(_emailCtrl.text.trim());
      if (existing != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El email ya está registrado (demo).')),
        );
        return;
      }

      // Crear hash de contraseña
      final password = _passCtrl.text;
      final hash = sha256.convert(utf8.encode(password)).toString();

      // Agregar usuario localmente
      final newUser = await repo.addUser(
        nombreUsuario: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        contrasenaHash: hash,
      );

      // Guarda current_user igual que en login para persistencia
      final sp = await SharedPreferences.getInstance();
      await sp.setString('current_user', jsonEncode(newUser.toJson()));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario creado (id: ${newUser.idUsuario})')),
      );

      // Opcional: limpiar formulario y navegar a lista
      _formKey.currentState?.reset();
      _nameCtrl.clear();
      _emailCtrl.clear();
      _passCtrl.clear();
      _confirmCtrl.clear();
      setState(() => _agreeTerms = false);

      // Ir a pantalla con lista de usuarios (opcional)
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UsersListScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    theme.colorScheme.primary.withOpacity(0.12),
                              ),
                              child: Icon(Icons.person_add_alt_1,
                                  color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Regístrate',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Nombre
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            hintText: 'Ej.: Juan Pérez',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: _validateName,
                        ),
                        const SizedBox(height: 12),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'tucorreo@dominio.com',
                            prefixIcon: const Icon(Icons.alternate_email),
                            suffixIcon: _emailCtrl.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _emailCtrl.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 12),

                        // Contraseña con fuerza
                        Builder(builder: (context) {
                          final val = _passCtrl.text;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: _validatePassword,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              _buildPasswordRequirements(val),
                            ],
                          );
                        }),
                        const SizedBox(height: 12),

                        // Confirm
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: const Icon(Icons.lock_person),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: _validateConfirm,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Checkbox(
                                value: _agreeTerms,
                                onChanged: (v) =>
                                    setState(() => _agreeTerms = v ?? false)),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Acepto los ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                        text: 'Términos',
                                        style: TextStyle(
                                            color: theme.colorScheme.primary)),
                                    const TextSpan(text: ' y la '),
                                    TextSpan(
                                        text: 'Política de privacidad',
                                        style: TextStyle(
                                            color: theme.colorScheme.primary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Crear cuenta',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),

                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const UsersListScreen())),
                          icon: const Icon(Icons.list),
                          label: const Text('Ver usuarios registrados'),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () async {
                            await LocalUserRepository.instance.clearAll();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Lista de usuarios limpiada')));
                            setState(() {});
                          },
                          child: const Text('Limpiar lista de usuarios'),
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

/// Pantalla para listar usuarios guardados (solo demo).
class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  late Future<List<User>> _future;

  @override
  void initState() {
    super.initState();
    _future = LocalUserRepository.instance.getAll();
  }

  Future<void> _refresh() async {
    setState(() => _future = LocalUserRepository.instance.getAll());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios Registrados')),
      body: FutureBuilder<List<User>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_off_outlined,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No hay usuarios guardados (demo)'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Volver')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final u = list[i];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                        child: Text(u.nombreUsuario.isNotEmpty
                            ? u.nombreUsuario[0].toUpperCase()
                            : 'U')),
                    title: Text(u.nombreUsuario),
                    subtitle: Text(u.email),
                    trailing: Text(u.fechaCreacionIso.split('T').first),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(u.nombreUsuario),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${u.idUsuario}'),
                              const SizedBox(height: 6),
                              Text('Email: ${u.email}'),
                              const SizedBox(height: 6),
                              Text(
                                  'Hash (SHA256): ${u.contrasenaHash.substring(0, 12)}...'),
                              const SizedBox(height: 6),
                              Text('Creado: ${u.fechaCreacionIso}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cerrar')),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isValid ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isValid ? Colors.green : Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
