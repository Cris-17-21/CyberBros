import 'dart:io';

import 'package:preferences_api/preferences_api.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Arranca la API de condiciones recordadas. Variables (ver README):
///
/// * `FIREBASE_API_KEY` (obligatoria) y `FIREBASE_AUTH_EMULATOR_HOST`
///   (opcional, solo `127.0.0.1:<puerto>` o `localhost:<puerto>`).
/// * `ATOMICMEMORY_API_URL` y `ATOMICMEMORY_API_KEY`: sin ellas, o si son
///   inválidas, la función queda apagada y la API responde `MEMORY_DISABLED`.
/// * `ALLOWED_ORIGINS`: orígenes web separados por comas.
/// * `HOST` (por defecto 127.0.0.1) y `PORT` (por defecto 8787).
Future<void> main() async {
  final env = Platform.environment;
  final firebaseKey = env['FIREBASE_API_KEY'] ?? '';
  if (firebaseKey.isEmpty) {
    stderr.writeln('Falta FIREBASE_API_KEY.');
    exit(64);
  }
  final emulatorHost = (env['FIREBASE_AUTH_EMULATOR_HOST'] ?? '').trim();
  if (emulatorHost.isNotEmpty && !isLoopbackHostPort(emulatorHost)) {
    stderr.writeln(
      'FIREBASE_AUTH_EMULATOR_HOST debe ser 127.0.0.1:<puerto> o '
      'localhost:<puerto>.',
    );
    exit(64);
  }
  final store = AtomicMemoryStore.fromEnvironment(
    env,
    warn: (message) => stderr.writeln('Aviso: $message'),
  );

  final handler = createPreferencesHandler(
    identity: FirebaseIdentityVerifier(
      apiKey: firebaseKey,
      emulatorHost: emulatorHost.isEmpty ? null : emulatorHost,
    ),
    store: store,
    allowedOrigins: {
      for (final origin in (env['ALLOWED_ORIGINS'] ?? '').split(','))
        if (origin.trim().isNotEmpty) origin.trim(),
    },
  );

  final host = env['HOST'] ?? '127.0.0.1';
  final port = int.tryParse(env['PORT'] ?? '') ?? 8787;
  final server = await shelf_io.serve(handler, host, port);
  stdout.writeln(
    'preferences_api en http://${server.address.host}:${server.port} '
    '(memoria ${store == null ? 'apagada' : 'activa'}'
    '${emulatorHost.isEmpty ? '' : ', Auth Emulator $emulatorHost'})',
  );
}
