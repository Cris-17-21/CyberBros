import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// `true` para `127.0.0.1:<puerto>` o `localhost:<puerto>`: el emulador de
/// Auth habla HTTP sin cifrar, así que solo se admite en la propia máquina.
bool isLoopbackHostPort(String value) {
  final match = RegExp(r'^(127\.0\.0\.1|localhost):(\d{1,5})$')
      .firstMatch(value);
  if (match == null) return false;
  final port = int.parse(match.group(2)!);
  return port > 0 && port < 65536;
}

/// Resuelve quién llama a partir del token de Firebase Auth que envía la app.
abstract interface class IdentityVerifier {
  /// Devuelve el `uid` de la cuenta, o `null` si el token no es válido.
  /// Lanza [IdentityUnavailable] si no se pudo consultar al proveedor.
  Future<String?> verify(String idToken);
}

final class IdentityUnavailable implements Exception {
  const IdentityUnavailable();
}

/// Verifica el token con Firebase Auth (`accounts:lookup`). El `uid` sale de
/// la respuesta de Google, nunca de un campo que mande el cliente. Con
/// `emulatorHost` apunta al Firebase Auth Emulator local.
final class FirebaseIdentityVerifier implements IdentityVerifier {
  FirebaseIdentityVerifier({
    required this.apiKey,
    this.emulatorHost,
    http.Client? client,
    this.timeout = const Duration(seconds: 3),
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String? emulatorHost;
  final Duration timeout;
  final http.Client _client;

  Uri get _lookupUri {
    final host = emulatorHost;
    final base = host == null || host.isEmpty
        ? 'https://identitytoolkit.googleapis.com'
        : 'http://$host/identitytoolkit.googleapis.com';
    return Uri.parse('$base/v1/accounts:lookup?key=$apiKey');
  }

  @override
  Future<String?> verify(String idToken) async {
    if (idToken.isEmpty) return null;
    // Sin redirecciones: el token de la persona solo va a Firebase.
    final request = http.Request('POST', _lookupUri)
      ..followRedirects = false
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'idToken': idToken});
    final http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } catch (_) {
      throw const IdentityUnavailable();
    }
    final status = response.statusCode;
    if (status >= 500 || (status >= 300 && status < 400)) {
      throw const IdentityUnavailable();
    }
    if (status != 200) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const IdentityUnavailable();
    }
    return switch (decoded) {
      {'users': [{'localId': final String uid}]} when uid.isNotEmpty => uid,
      _ => null,
    };
  }
}
