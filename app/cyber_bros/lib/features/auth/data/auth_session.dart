/// Sesión de un usuario autenticado. Las credenciales nunca se guardan:
/// solo los tokens que entrega el proveedor de identidad.
final class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.idToken,
    required this.refreshToken,
    required this.expiresAt,
    this.displayName,
  });

  final String userId;
  final String email;
  final String? displayName;
  final String idToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// Nombre para mostrar: nombre si existe, si no la parte local del correo.
  String get label {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email.split('@').first;
  }

  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 1)));

  AuthSession copyWith({
    String? idToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? displayName,
  }) {
    return AuthSession(
      userId: userId,
      email: email,
      displayName: displayName ?? this.displayName,
      idToken: idToken ?? this.idToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, Object?> toJson() => {
    'user_id': userId,
    'email': email,
    'display_name': displayName,
    'id_token': idToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toIso8601String(),
  };

  static AuthSession? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final userId = raw['user_id'];
    final email = raw['email'];
    final idToken = raw['id_token'];
    final refreshToken = raw['refresh_token'];
    final expiresAt = DateTime.tryParse('${raw['expires_at']}');
    if (userId is! String ||
        email is! String ||
        idToken is! String ||
        refreshToken is! String ||
        expiresAt == null) {
      return null;
    }
    return AuthSession(
      userId: userId,
      email: email,
      displayName: raw['display_name'] as String?,
      idToken: idToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }
}

/// Error de autenticación con mensaje listo para mostrar al usuario.
final class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
