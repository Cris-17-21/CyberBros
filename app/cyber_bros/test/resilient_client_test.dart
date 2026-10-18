import 'package:cyber_bros/core/network/resilient_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final uri = Uri.parse('https://api.example.com/ruta');

  ResilientClient build(
    http.Client client, {
    DateTime Function()? now,
    int maxRetries = 1,
  }) => ResilientClient(
    client: client,
    retryDelay: Duration.zero,
    maxRetries: maxRetries,
    failureThreshold: 3,
    cooldown: const Duration(seconds: 30),
    now: now,
  );

  test('una respuesta correcta se devuelve sin reintentos', () async {
    var calls = 0;
    final client = build(MockClient((_) async {
      calls++;
      return http.Response('ok', 200);
    }));
    final response = await client.get(uri);
    expect(response?.body, 'ok');
    expect(calls, 1);
  });

  test('reintenta una vez y se recupera de un fallo pasajero', () async {
    var calls = 0;
    final client = build(MockClient((_) async {
      calls++;
      if (calls == 1) throw http.ClientException('corte');
      return http.Response('ok', 200);
    }));
    final response = await client.get(uri);
    expect(response?.statusCode, 200);
    expect(calls, 2);
    expect(client.failuresOf(uri.host), 0);
  });

  test('un error 5xx cuenta como fallo y devuelve null tras reintentar', () async {
    var calls = 0;
    final client = build(MockClient((_) async {
      calls++;
      return http.Response('caído', 503);
    }));
    expect(await client.get(uri), isNull);
    expect(calls, 2); // intento + 1 reintento
  });

  test('un error 4xx no se reintenta y se devuelve tal cual', () async {
    var calls = 0;
    final client = build(MockClient((_) async {
      calls++;
      return http.Response('no existe', 404);
    }));
    final response = await client.get(uri);
    expect(response?.statusCode, 404);
    expect(calls, 1);
  });

  test('tras varios fallos seguidos el circuito se abre y corta las llamadas', () async {
    var calls = 0;
    final client = build(MockClient((_) async {
      calls++;
      throw http.ClientException('caído');
    }));
    for (var i = 0; i < 3; i++) {
      expect(await client.get(uri), isNull);
    }
    expect(client.isOpen(uri.host), isTrue);
    final callsBefore = calls;
    expect(await client.get(uri), isNull);
    expect(calls, callsBefore, reason: 'con el circuito abierto no se llama al servicio');
  });

  test('pasado el enfriamiento vuelve a intentar', () async {
    var clock = DateTime(2026, 10, 18, 5);
    var calls = 0;
    var healthy = false;
    final client = build(
      MockClient((_) async {
        calls++;
        if (!healthy) throw http.ClientException('caído');
        return http.Response('ok', 200);
      }),
      now: () => clock,
    );
    for (var i = 0; i < 3; i++) {
      await client.get(uri);
    }
    expect(client.isOpen(uri.host), isTrue);

    clock = clock.add(const Duration(seconds: 31));
    healthy = true;
    final response = await client.get(uri);
    expect(response?.statusCode, 200);
    expect(client.isOpen(uri.host), isFalse);
    expect(client.failuresOf(uri.host), 0);
    expect(calls, greaterThan(6));
  });

  test('un servidor caído no afecta a los demás', () async {
    final client = build(MockClient((request) async {
      if (request.url.host == 'caido.example.com') {
        throw http.ClientException('caído');
      }
      return http.Response('ok', 200);
    }));
    for (var i = 0; i < 3; i++) {
      await client.get(Uri.parse('https://caido.example.com/x'));
    }
    expect(client.isOpen('caido.example.com'), isTrue);
    final other = await client.get(Uri.parse('https://sano.example.com/x'));
    expect(other?.statusCode, 200);
    expect(client.isOpen('sano.example.com'), isFalse);
  });
}
