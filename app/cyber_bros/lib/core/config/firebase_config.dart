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
}
