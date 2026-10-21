import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/firebase_config.dart';
import 'auth_session.dart';

/// Autenticación con Firebase Auth mediante su API REST.
///
/// La app nunca guarda contraseñas: solo viajan al proveedor de identidad.
/// Sin `FIREBASE_API_KEY` las cuentas quedan deshabilitadas y la app sigue
/// funcionando como invitado.
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _storageKey = 'cyberon_auth_session';
  static const _timeout = Duration(seconds: 12);
  static const _maxFailedAttempts = 5;
  static const _lockout = Duration(seconds: 30);

  static String get _identityBase => FirebaseConfig.identityBase;
  static String get _tokenUrl => FirebaseConfig.tokenUrl;

  AuthSession? _session;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  AuthSession? get session => _session;
  bool get isSignedIn => _session != null;
  bool get isAvailable => FirebaseConfig.isConfigured;

  /// Recupera la sesión guardada y la renueva si el token venció.
  Future<void> restore() async {
    if (!isAvailable) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      var stored = AuthSession.fromJson(jsonDecode(raw));
      if (stored == null) {
        await prefs.remove(_storageKey);
        return;
      }
      if (stored.isExpired) {
        stored = await _refresh(stored);
      }
      _session = stored;
      notifyListeners();
    } on AuthException {
      // Token revocado o vencido: se pide iniciar sesión de nuevo.
      await _forget();
    } catch (_) {
      // Almacenamiento bloqueado o sin red: se continúa como invitado.
    }
  }

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    _ensureAvailable();
    _ensureNotLocked();
    try {
      final data = await _post(
        '$_identityBase/accounts:signInWithPassword',
        {'email': email, 'password': password, 'returnSecureToken': true},
      );
      _failedAttempts = 0;
      return await _adopt(_sessionFrom(data));
    } on AuthException {
      _registerFailure();
      rethrow;
    }
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _ensureAvailable();
    final data = await _post('$_identityBase/accounts:signUp', {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    });
    var created = _sessionFrom(data);
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      try {
        final updated = await _post('$_identityBase/accounts:update', {
          'idToken': created.idToken,
          'displayName': name,
          'returnSecureToken': true,
        });
        created = created.copyWith(
          displayName: name,
          idToken: updated['idToken'] as String? ?? created.idToken,
          refreshToken:
              updated['refreshToken'] as String? ?? created.refreshToken,
        );
      } on AuthException {
        // El nombre es opcional: la cuenta ya quedó creada.
      }
    }
    return _adopt(created);
  }

  /// Envía el correo de restablecimiento. Termina igual exista o no la
  /// cuenta, para no revelar qué correos están registrados.
  Future<void> sendPasswordReset(String email) async {
    _ensureAvailable();
    try {
      await _post('$_identityBase/accounts:sendOobCode', {
        'requestType': 'PASSWORD_RESET',
        'email': email,
      });
    } on AuthException catch (error) {
      if (error.message == _networkMessage) rethrow;
    }
  }

  /// Cambia el nombre para mostrar de la cuenta.
  Future<void> updateDisplayName(String name) async {
    final token = await validIdToken();
    final current = _session;
    if (token == null || current == null) {
      throw const AuthException('Tu sesión venció. Inicia sesión de nuevo.');
    }
    final clean = name.trim();
    await _post('$_identityBase/accounts:update', {
      'idToken': token,
      'displayName': clean,
      'returnSecureToken': false,
    });
    final updated = current.copyWith(displayName: clean);
    _session = updated;
    await _persist(updated);
    notifyListeners();
  }

  /// Token de identidad vigente para llamar a Firestore, o `null` si no hay
  /// sesión o no se pudo renovar (sin red, sesión revocada).
  Future<String?> validIdToken() async {
    var current = _session;
    if (current == null) return null;
    if (current.isExpired) {
      try {
        current = await _refresh(current);
        _session = current;
      } catch (_) {
        return null;
      }
    }
    return current.idToken;
  }

  Future<void> signOut() async {
    await _forget();
    _session = null;
    notifyListeners();
  }

  // --- internos ---------------------------------------------------------

  static const _networkMessage =
      'No pudimos conectarnos. Revisa tu internet e inténtalo de nuevo.';

  void _ensureAvailable() {
    if (!isAvailable) {
      throw const AuthException(
        'Las cuentas aún no están disponibles. Puedes continuar como invitado.',
      );
    }
  }

  void _ensureNotLocked() {
    final until = _lockedUntil;
    if (until != null && DateTime.now().isBefore(until)) {
      final seconds = until.difference(DateTime.now()).inSeconds + 1;
      throw AuthException(
        'Demasiados intentos. Espera $seconds s e inténtalo de nuevo.',
      );
    }
  }

  void _registerFailure() {
    _failedAttempts++;
    if (_failedAttempts >= _maxFailedAttempts) {
      _failedAttempts = 0;
      _lockedUntil = DateTime.now().add(_lockout);
    }
  }

  AuthSession _sessionFrom(Map<String, Object?> data) {
    final seconds = int.tryParse('${data['expiresIn']}') ?? 3600;
    return AuthSession(
      userId: data['localId'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      idToken: data['idToken'] as String,
      refreshToken: data['refreshToken'] as String,
      expiresAt: DateTime.now().add(Duration(seconds: seconds)),
    );
  }

  Future<AuthSession> _adopt(AuthSession session) async {
    _session = session;
    await _persist(session);
    notifyListeners();
    return session;
  }

  Future<AuthSession> _refresh(AuthSession stored) async {
    final response = await http
        .post(
          Uri.parse('$_tokenUrl?key=${FirebaseConfig.apiKey}'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'grant_type': 'refresh_token',
            'refresh_token': stored.refreshToken,
          },
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw const AuthException('Tu sesión venció. Inicia sesión de nuevo.');
    }
    final data = jsonDecode(response.body) as Map<String, Object?>;
    final seconds = int.tryParse('${data['expires_in']}') ?? 3600;
    final renewed = stored.copyWith(
      idToken: data['id_token'] as String,
      refreshToken: data['refresh_token'] as String? ?? stored.refreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: seconds)),
    );
    await _persist(renewed);
    return renewed;
  }

  Future<void> _persist(AuthSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(session.toJson()));
    } catch (_) {
      // Incógnito o almacenamiento bloqueado: la sesión vale solo esta visita.
    }
  }

  Future<void> _forget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  Future<Map<String, Object?>> _post(
    String url,
    Map<String, Object?> body,
  ) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$url?key=${FirebaseConfig.apiKey}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const AuthException(_networkMessage);
    } catch (_) {
      throw const AuthException(_networkMessage);
    }
    Map<String, Object?> data;
    try {
      data = jsonDecode(response.body) as Map<String, Object?>;
    } catch (_) {
      throw const AuthException(
        'Ocurrió un problema inesperado. Inténtalo de nuevo.',
      );
    }
    if (response.statusCode == 200) return data;
    final error = data['error'];
    final code = error is Map ? '${error['message']}' : '';
    throw AuthException(_translate(code));
  }

  /// Traduce los códigos del proveedor a mensajes claros, sin revelar si un
  /// correo existe cuando se inicia sesión.
  static String _translate(String code) {
    if (code.startsWith('EMAIL_EXISTS')) {
      return 'Ese correo ya tiene una cuenta. Inicia sesión o recupera tu contraseña.';
    }
    if (code.startsWith('WEAK_PASSWORD')) {
      return 'La contraseña es muy débil. Usa al menos 8 caracteres.';
    }
    if (code.startsWith('TOO_MANY_ATTEMPTS_TRY_LATER')) {
      return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
    }
    if (code.startsWith('INVALID_EMAIL')) {
      return 'Escribe un correo válido.';
    }
    if (code.startsWith('USER_DISABLED')) {
      return 'Esta cuenta está deshabilitada.';
    }
    if (code.startsWith('OPERATION_NOT_ALLOWED')) {
      return 'El registro con correo aún no está activado en el servicio.';
    }
    if (code.startsWith('INVALID_LOGIN_CREDENTIALS') ||
        code.startsWith('EMAIL_NOT_FOUND') ||
        code.startsWith('INVALID_PASSWORD')) {
      return 'Correo o contraseña incorrectos.';
    }
    return 'No pudimos completar la acción. Inténtalo de nuevo.';
  }
}
