import 'package:flutter/material.dart';

import '../../../core/theme/palette.dart';
import '../../../core/widgets/cyberon_brand.dart';
import '../data/auth_service.dart';
import '../data/auth_session.dart';

enum _AuthMode { login, register, reset }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService.instance;

  _AuthMode _mode = _AuthMode.login;
  bool _obscurePassword = true;
  bool _acceptedPrivacy = false;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _error = null;
      _info = null;
    });
  }

  void _continueToPlanner() {
    Navigator.of(context).pushReplacementNamed('/planner');
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_mode == _AuthMode.register && !_acceptedPrivacy) {
      setState(() => _error = 'Acepta la política de privacidad para crear tu cuenta.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final email = _emailController.text.trim();
    try {
      switch (_mode) {
        case _AuthMode.login:
          await _auth.signIn(email: email, password: _passwordController.text);
          if (mounted) _continueToPlanner();
        case _AuthMode.register:
          await _auth.register(
            email: email,
            password: _passwordController.text,
            displayName: _nameController.text,
          );
          if (mounted) _continueToPlanner();
        case _AuthMode.reset:
          await _auth.sendPasswordReset(email);
          if (mounted) {
            setState(() {
              _info =
                  'Si el correo tiene una cuenta, te enviamos un enlace para restablecer tu contraseña.';
            });
          }
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe tu correo.';
    if (!_emailPattern.hasMatch(text)) return 'Escribe un correo válido.';
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Escribe tu contraseña.';
    if (_mode == _AuthMode.register && text.length < 8) {
      return 'Usa al menos 8 caracteres.';
    }
    return null;
  }

  String get _title => switch (_mode) {
    _AuthMode.login => 'Qué bueno verte',
    _AuthMode.register => 'Crea tu cuenta',
    _AuthMode.reset => 'Recupera tu contraseña',
  };

  String get _subtitle => switch (_mode) {
    _AuthMode.login =>
      'Inicia sesión para guardar tus viajes o explora como invitado.',
    _AuthMode.register =>
      'Guarda tu historial y tus preferencias en todos tus dispositivos.',
    _AuthMode.reset => 'Te enviaremos un enlace para elegir una nueva contraseña.',
  };

  String get _submitLabel => switch (_mode) {
    _AuthMode.login => 'Iniciar sesión',
    _AuthMode.register => 'Crear cuenta',
    _AuthMode.reset => 'Enviar enlace',
  };

  @override
  Widget build(BuildContext context) {
    final available = _auth.isAvailable;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CyberonBrand(),
                    const SizedBox(height: 32),
                    Text(
                      _title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Palette.ink,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _subtitle,
                      style: const TextStyle(
                        color: Palette.inkMuted,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!available) ...[
                      const _Notice(
                        icon: Icons.info_outline_rounded,
                        text:
                            'Las cuentas aún no están disponibles en esta versión. Puedes explorar como invitado y guardar viajes en este dispositivo.',
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_mode == _AuthMode.register) ...[
                      TextFormField(
                        controller: _nameController,
                        enabled: available && !_busy,
                        textCapitalization: TextCapitalization.words,
                        maxLength: 40,
                        decoration: const InputDecoration(
                          labelText: 'Nombre (opcional)',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _emailController,
                      enabled: available && !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),
                    if (_mode != _AuthMode.reset) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        enabled: available && !_busy,
                        obscureText: _obscurePassword,
                        autofillHints: [
                          _mode == _AuthMode.login
                              ? AutofillHints.password
                              : AutofillHints.newPassword,
                        ],
                        validator: _validatePassword,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          helperText: _mode == _AuthMode.register
                              ? 'Mínimo 8 caracteres'
                              : null,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_mode == _AuthMode.login)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => _setMode(_AuthMode.reset),
                          child: const Text('Olvidé mi contraseña'),
                        ),
                      ),
                    if (_mode == _AuthMode.register) ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _acceptedPrivacy,
                        onChanged: available && !_busy
                            ? (value) =>
                                  setState(() => _acceptedPrivacy = value ?? false)
                            : null,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Acepto la política de privacidad. Tu ubicación solo se usa para guiarte y no se comparte con otras personas.',
                          style: TextStyle(fontSize: 13, color: Palette.inkMuted),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      _Notice(
                        icon: Icons.error_outline_rounded,
                        text: _error!,
                        isError: true,
                      ),
                    ],
                    if (_info != null) ...[
                      const SizedBox(height: 8),
                      _Notice(icon: Icons.mark_email_read_outlined, text: _info!),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: available && !_busy ? _submit : null,
                      child: _busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : Text(_submitLabel),
                    ),
                    const SizedBox(height: 16),
                    Center(child: _modeSwitcher()),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: _busy ? null : _continueToPlanner,
                        icon: const Icon(Icons.explore_outlined),
                        label: const Text('Explorar sin cuenta'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Como invitado, tu historial se guarda solo en este dispositivo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Palette.inkMuted, fontSize: 12),
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

  Widget _modeSwitcher() {
    return switch (_mode) {
      _AuthMode.login => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('¿Aún no tienes cuenta? '),
          TextButton(
            onPressed: _busy ? null : () => _setMode(_AuthMode.register),
            child: const Text('Regístrate'),
          ),
        ],
      ),
      _ => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('¿Ya tienes cuenta? '),
          TextButton(
            onPressed: _busy ? null : () => _setMode(_AuthMode.login),
            child: const Text('Inicia sesión'),
          ),
        ],
      ),
    };
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.isError = false});

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red.shade700 : Palette.inkMuted;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}

/// Resumen de sesión para mostrar en otras pantallas.
extension AuthSessionLabel on AuthSession {
  String get greeting => 'Sesión iniciada como $label';
}
