/// Configuración pública del proyecto Firebase `tributo-educa-peru`.
///
/// La clave de API web **no es un secreto**: identifica el proyecto y viaja en
/// cada app web o móvil. La seguridad real la dan Authentication y las reglas
/// de Firestore. Puede reemplazarse al compilar:
///
///   flutter run --dart-define=FIREBASE_API_KEY=otra_clave
abstract final class FirebaseConfig {
  static const projectId = 'tributo-educa-peru';
  static const authDomain = 'tributo-educa-peru.firebaseapp.com';
  static const storageBucket = 'tributo-educa-peru.firebasestorage.app';
  static const messagingSenderId = '368137869256';
  static const appId = '1:368137869256:web:d47782cb3d9a79d02752fd';
  static const measurementId = 'G-7KFJ6RFWM6';

  static const _envApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _defaultApiKey = 'AIzaSyDDesiLqQNcr514_yCwFuTuCJ2TuOBZN7M';

  static String get apiKey => _envApiKey.isNotEmpty ? _envApiKey : _defaultApiKey;

  static bool get isConfigured => apiKey.isNotEmpty;
}
