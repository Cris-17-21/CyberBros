/// Configuración pública del proyecto Firebase `cyberon-lima`.
///
/// La clave de API web **no es un secreto**: identifica el proyecto y viaja en
/// cada app web o móvil. La seguridad real la dan Authentication y las reglas
/// de `firebase/firestore.rules`. Puede reemplazarse al compilar:
///
///   flutter run --dart-define=FIREBASE_API_KEY=otra_clave
abstract final class FirebaseConfig {
  static const projectId = 'cyberon-lima';
  static const authDomain = 'cyberon-lima.firebaseapp.com';
  static const storageBucket = 'cyberon-lima.firebasestorage.app';
  static const messagingSenderId = '804595898595';
  static const appId = '1:804595898595:web:809b8d3ec350cfd6930dd6';

  static const _envApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _defaultApiKey = 'AIzaSyA_ccEJr6Xq8cJ5Z3W6rqCykd5U2_4ga_8';

  static String get apiKey =>
      _envApiKey.isNotEmpty ? _envApiKey : _defaultApiKey;

  static bool get isConfigured => apiKey.isNotEmpty;

  /// Emuladores locales de Firebase (`firebase.json`), solo para desarrollo:
  ///
  ///   --dart-define=FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
  ///   --dart-define=FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
  static const _authEmulatorHost = String.fromEnvironment(
    'FIREBASE_AUTH_EMULATOR_HOST',
  );
  static const _firestoreEmulatorHost = String.fromEnvironment(
    'FIRESTORE_EMULATOR_HOST',
  );

  static String get identityBase => _authEmulatorHost.isEmpty
      ? 'https://identitytoolkit.googleapis.com/v1'
      : 'http://$_authEmulatorHost/identitytoolkit.googleapis.com/v1';

  static String get tokenUrl => _authEmulatorHost.isEmpty
      ? 'https://securetoken.googleapis.com/v1/token'
      : 'http://$_authEmulatorHost/securetoken.googleapis.com/v1/token';

  static String get firestoreDocuments =>
      '${_firestoreEmulatorHost.isEmpty ? 'https://firestore.googleapis.com' : 'http://$_firestoreEmulatorHost'}'
      '/v1/projects/$projectId/databases/(default)/documents';
}
