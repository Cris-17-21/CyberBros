import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preferences_api/preferences_api.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

import 'support/atomic_memory_fixture.dart';

/// Tokens de prueba → uid, como lo haría Firebase Auth.
final class _FakeIdentity implements IdentityVerifier {
  bool unavailable = false;

  @override
  Future<String?> verify(String idToken) async {
    if (unavailable) throw const IdentityUnavailable();
    return const {'token-ana': 'uid-ana', 'token-beto': 'uid-beto'}[idToken];
  }
}

const _conditions = {
  'budgetCents': 800,
  'maxContinuousWalkMetres': 300,
  'maxTotalWalkMetres': 800,
  'allowTaxiBridge': true,
  'priority': 'lessWalking',
};

void main() {
  late AtomicMemoryFixture fixture;
  late HttpServer fixtureServer;
  late _FakeIdentity identity;
  late Handler handler;

  setUp(() async {
    fixture = AtomicMemoryFixture();
    fixtureServer = await shelf_io.serve(
      fixture.handler,
      InternetAddress.loopbackIPv4,
      0,
    );
    identity = _FakeIdentity();
    handler = createPreferencesHandler(
      identity: identity,
      store: AtomicMemoryStore(
        baseUrl: Uri.parse('http://127.0.0.1:${fixtureServer.port}'),
        apiKey: fixture.apiKey,
        timeout: const Duration(milliseconds: 300),
      ),
      allowedOrigins: {'http://127.0.0.1:4711'},
    );
  });

  tearDown(() => fixtureServer.close(force: true));

  Future<(int, Map<String, Object?>)> call(
    String method, {
    String? token,
    Object? body,
    Handler? using,
  }) async {
    final response = await (using ?? handler)(
      Request(
        method,
        Uri.parse('http://localhost/v1/trip-conditions'),
        headers: {'authorization': ?(token == null ? null : 'Bearer $token')},
        body: body == null ? null : jsonEncode(body),
      ),
    );
    final text = await response.readAsString();
    return (
      response.statusCode,
      (text.isEmpty ? <String, Object?>{} : jsonDecode(text))
          as Map<String, Object?>,
    );
  }

  test('guarda con consentimiento y lo recuerda en la misma cuenta', () async {
    expect((await call('GET', token: 'token-ana')).$2, {'status': 'empty'});

    final (status, saved) = await call(
      'PUT',
      token: 'token-ana',
      body: {'consent': true, 'conditions': _conditions},
    );
    expect(status, 200);
    expect(saved['status'], 'saved');

    final (_, recalled) = await call('GET', token: 'token-ana');
    expect(recalled['status'], 'found');
    expect(recalled['conditions'], _conditions);

    final row = fixture.rows.values.single;
    expect(row['user_id'], 'rutealo-firebase-uid-ana');
    expect(row['content'], contains('S/ 8.00'));
    expect(row['content'], contains('300 m seguidos'));
  });

  test('una cuenta nunca ve ni borra lo de otra', () async {
    await call(
      'PUT',
      token: 'token-ana',
      body: {'consent': true, 'conditions': _conditions},
    );

    expect((await call('GET', token: 'token-beto')).$2, {'status': 'empty'});
    expect((await call('DELETE', token: 'token-beto')).$2, {'status': 'empty'});
    expect((await call('GET', token: 'token-ana')).$2['status'], 'found');
  });

  test('el cliente no puede elegir el sujeto de memoria', () async {
    await call(
      'PUT',
      token: 'token-beto',
      body: {
        'consent': true,
        'conditions': _conditions,
        'user_id': 'rutealo-firebase-uid-ana',
      },
    );
    expect(fixture.rows.values.single['user_id'], 'rutealo-firebase-uid-beto');
    expect((await call('GET', token: 'token-ana')).$2, {'status': 'empty'});
  });

  test('corregir actualiza el mismo recuerdo en lugar de duplicarlo', () async {
    await call(
      'PUT',
      token: 'token-ana',
      body: {'consent': true, 'conditions': _conditions},
    );
    final corrected = {
      ..._conditions,
      'budgetCents': 550,
      'allowTaxiBridge': false,
    };
    await call(
      'PUT',
      token: 'token-ana',
      body: {'consent': true, 'conditions': corrected},
    );

    expect(fixture.rows, hasLength(1));
    expect((await call('GET', token: 'token-ana')).$2['conditions'], corrected);
    expect(fixture.rows.values.single['content'], contains('no acepta'));
  });

  test('sin ids confirmados no informa éxito ni borra lo anterior', () async {
    await call(
      'PUT',
      token: 'token-ana',
      body: {'consent': true, 'conditions': _conditions},
    );
    fixture.mode = FixtureMode.noIds;
    final (status, body) = await call(
      'PUT',
      token: 'token-ana',
      body: {
        'consent': true,
        'conditions': {..._conditions, 'budgetCents': 550},
      },
    );
    expect(status, 503);
    expect(body['error'], 'MEMORY_UNAVAILABLE');
    fixture.mode = FixtureMode.normal;
    expect(
      (await call('GET', token: 'token-ana')).$2['conditions'],
      _conditions,
    );
  });

  test('si no se puede borrar lo anterior, corregir no se confirma', () async {
    await call(
      'PUT',
      token: 'token-ana',
      body: {'consent': true, 'conditions': _conditions},
    );
    fixture.mode = FixtureMode.failingDeletes;
    final (status, _) = await call(
      'PUT',
      token: 'token-ana',
      body: {
        'consent': true,
        'conditions': {..._conditions, 'budgetCents': 550},
      },
    );
    expect(status, 503);

    // Al reintentar, quedan las condiciones nuevas y ninguna copia.
    fixture.mode = FixtureMode.normal;
    final corrected = {..._conditions, 'budgetCents': 600};
    expect(
      (await call(
        'PUT',
        token: 'token-ana',
        body: {'consent': true, 'conditions': corrected},
      )).$1,
      200,
    );
    expect((await call('DELETE', token: 'token-ana')).$2, {
      'status': 'deleted',
    });
    expect(fixture.rows, isEmpty);
  });

  test('si el borrado falla, olvidar no se confirma', () async {
    await call(
      'PUT',
      token: 'token-ana',
      body: {'consent': true, 'conditions': _conditions},
    );
    fixture.mode = FixtureMode.failingDeletes;
    final (status, body) = await call('DELETE', token: 'token-ana');
    expect(status, 503);
    expect(body['error'], 'MEMORY_UNAVAILABLE');
    expect(fixture.rows, hasLength(1));
  });

  test('un registro ilegible es un fallo, no "vacío"', () async {
    fixture.rows['bad'] = {
      'id': 'bad',
      'user_id': 'rutealo-firebase-uid-ana',
      'metadata': {
        'externalId': AtomicMemoryStore.externalId,
        'rutealoConditions': {'budgetCents': 'mucho'},
      },
    };
    final (status, body) = await call('GET', token: 'token-ana');
    expect(status, 503);
    expect(body['error'], 'MEMORY_UNAVAILABLE');
    // Olvidar sí puede borrarlo.
    expect((await call('DELETE', token: 'token-ana')).$2, {
      'status': 'deleted',
    });
  });

  test('el plazo total corta la solicitud completa', () async {
    fixture
      ..mode = FixtureMode.hanging
      ..hangFor = const Duration(seconds: 2);
    final slow = createPreferencesHandler(
      identity: identity,
      store: AtomicMemoryStore(
        baseUrl: Uri.parse('http://127.0.0.1:${fixtureServer.port}'),
        apiKey: fixture.apiKey,
        timeout: const Duration(seconds: 1),
      ),
      deadline: const Duration(milliseconds: 300),
    );
    final watch = Stopwatch()..start();
    final (status, body) = await call('GET', token: 'token-ana', using: slow);
    expect(status, 503);
    expect(body['error'], 'MEMORY_UNAVAILABLE');
    expect(watch.elapsed, lessThan(const Duration(milliseconds: 900)));
  });

  test('olvidar borra el recuerdo', () async {
    await call(
      'PUT',
      token: 'token-ana',
      body: {'consent': true, 'conditions': _conditions},
    );
    expect((await call('DELETE', token: 'token-ana')).$2, {
      'status': 'deleted',
    });
    expect(fixture.rows, isEmpty);
    expect((await call('GET', token: 'token-ana')).$2, {'status': 'empty'});
  });

  test('sin consentimiento explícito no se guarda nada', () async {
    final (status, body) = await call(
      'PUT',
      token: 'token-ana',
      body: {'conditions': _conditions},
    );
    expect(status, 400);
    expect(body['error'], 'CONSENT_REQUIRED');
    expect(fixture.requests, isEmpty);
  });

  test('rechaza condiciones fuera de los rangos de la app', () async {
    final (status, body) = await call(
      'PUT',
      token: 'token-ana',
      body: {
        'consent': true,
        'conditions': {..._conditions, 'maxContinuousWalkMetres': 5000},
      },
    );
    expect(status, 400);
    expect(body['error'], 'INVALID_CONDITIONS');
    expect(fixture.rows, isEmpty);
  });

  test('sin token válido responde 401 y no consulta la memoria', () async {
    expect((await call('GET')).$1, 401);
    final (status, body) = await call('GET', token: 'token-falso');
    expect(status, 401);
    expect(body['error'], 'UNAUTHENTICATED');
    expect(fixture.requests, isEmpty);
  });

  test('si Firebase no responde, informa 503 en lugar de 401', () async {
    identity.unavailable = true;
    final (status, body) = await call('GET', token: 'token-ana');
    expect(status, 503);
    expect(body['error'], 'IDENTITY_UNAVAILABLE');
  });

  test('sin Atomic Memory configurado la función queda apagada', () async {
    final disabled = createPreferencesHandler(identity: identity);
    final (status, body) = await call(
      'GET',
      token: 'token-ana',
      using: disabled,
    );
    expect(status, 503);
    expect(body['error'], 'MEMORY_DISABLED');
  });

  test('un fallo del proveedor se informa como no guardado', () async {
    fixture.mode = FixtureMode.failing;
    final (status, body) = await call(
      'PUT',
      token: 'token-ana',
      body: {'consent': true, 'conditions': _conditions},
    );
    expect(status, 503);
    expect(body['error'], 'MEMORY_UNAVAILABLE');
  });

  test('un proveedor colgado se corta por tiempo', () async {
    fixture
      ..mode = FixtureMode.hanging
      ..hangFor = const Duration(seconds: 1);
    final watch = Stopwatch()..start();
    final (status, body) = await call('GET', token: 'token-ana');
    expect(status, 503);
    expect(body['error'], 'MEMORY_UNAVAILABLE');
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
  });

  test('acepta 201 Created al guardar y lo confirma leyendo', () async {
    fixture.mode = FixtureMode.created;
    final (status, body) = await call(
      'PUT',
      token: 'token-ana',
      body: {'consent': true, 'conditions': _conditions},
    );
    expect(status, 200);
    expect(body['status'], 'saved');
    fixture.mode = FixtureMode.normal;
    expect(
      (await call('GET', token: 'token-ana')).$2['conditions'],
      _conditions,
    );
  });

  test(
    'un 200 al borrar que deja el registro no se informa como olvidado',
    () async {
      await call(
        'PUT',
        token: 'token-ana',
        body: {'consent': true, 'conditions': _conditions},
      );
      fixture.mode = FixtureMode.deleteRetains;
      final (status, body) = await call('DELETE', token: 'token-ana');
      expect(status, 503);
      expect(body['error'], 'MEMORY_UNAVAILABLE');
      expect(fixture.rows, hasLength(1));
    },
  );

  test(
    'corregir no se confirma si el anterior no se pudo borrar de verdad',
    () async {
      await call(
        'PUT',
        token: 'token-ana',
        body: {'consent': true, 'conditions': _conditions},
      );
      fixture.mode = FixtureMode.deleteRetains;
      final (status, _) = await call(
        'PUT',
        token: 'token-ana',
        body: {
          'consent': true,
          'conditions': {..._conditions, 'budgetCents': 550},
        },
      );
      expect(status, 503);
    },
  );

  test('nunca sigue redirecciones: la clave no llega a otro destino', () async {
    final seen = <String?>[];
    final elsewhere = await shelf_io.serve(
      (Request request) {
        seen.add(request.headers['authorization']);
        return Response.ok('{"status":"empty"}');
      },
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() => elsewhere.close(force: true));
    fixture
      ..mode = FixtureMode.redirecting
      ..redirectTo = Uri.parse('http://127.0.0.1:${elsewhere.port}/steal');

    final (status, body) = await call('GET', token: 'token-ana');
    expect(status, 503);
    expect(body['error'], 'MEMORY_UNAVAILABLE');
    final (saveStatus, _) = await call(
      'PUT',
      token: 'token-ana',
      body: {'consent': true, 'conditions': _conditions},
    );
    expect(saveStatus, 503);
    expect(seen, isEmpty);
  });

  group('configuración de Atomic Memory', () {
    test('solo HTTPS, o HTTP hacia la propia máquina', () {
      expect(parseMemoryBaseUrl('https://api.atomicstrata.ai'), isNotNull);
      expect(
        parseMemoryBaseUrl('https://api.atomicstrata.ai/')!.toString(),
        'https://api.atomicstrata.ai',
      );
      expect(parseMemoryBaseUrl('http://127.0.0.1:4721'), isNotNull);
      expect(parseMemoryBaseUrl('http://localhost:4721'), isNotNull);
      expect(parseMemoryBaseUrl('http://api.atomicstrata.ai'), isNull);
      expect(parseMemoryBaseUrl('ftp://api.atomicstrata.ai'), isNull);
      expect(parseMemoryBaseUrl('api.atomicstrata.ai'), isNull);
      expect(parseMemoryBaseUrl(''), isNull);
    });

    test('rechaza usuario, consulta y fragmento', () {
      expect(parseMemoryBaseUrl('https://user:pw@api.atomicstrata.ai'), isNull);
      expect(parseMemoryBaseUrl('https://api.atomicstrata.ai?x=1'), isNull);
      expect(parseMemoryBaseUrl('https://api.atomicstrata.ai#x'), isNull);
    });

    test('una configuración incompleta o inválida solo apaga la memoria', () {
      final warnings = <String>[];
      void warn(String message) => warnings.add(message);

      expect(AtomicMemoryStore.fromEnvironment({}, warn: warn), isNull);
      expect(warnings, isEmpty);

      expect(
        AtomicMemoryStore.fromEnvironment({
          'ATOMICMEMORY_API_URL': 'https://api.atomicstrata.ai',
        }, warn: warn),
        isNull,
      );
      expect(
        AtomicMemoryStore.fromEnvironment({
          'ATOMICMEMORY_API_URL': 'http://memoria.example',
          'ATOMICMEMORY_API_KEY': 'k',
        }, warn: warn),
        isNull,
      );
      expect(warnings, hasLength(2));

      final store = AtomicMemoryStore.fromEnvironment({
        'ATOMICMEMORY_API_URL': 'https://api.atomicstrata.ai/',
        'ATOMICMEMORY_API_KEY': 'k',
      }, warn: warn);
      expect(store?.baseUrl.toString(), 'https://api.atomicstrata.ai');
      expect(warnings, hasLength(2));
    });

    test('el emulador de Auth solo se acepta en la propia máquina', () {
      expect(isLoopbackHostPort('127.0.0.1:9455'), isTrue);
      expect(isLoopbackHostPort('localhost:9099'), isTrue);
      expect(isLoopbackHostPort('10.0.0.5:9099'), isFalse);
      expect(isLoopbackHostPort('127.0.0.1'), isFalse);
      expect(isLoopbackHostPort('127.0.0.1:99999'), isFalse);
    });
  });

  test('CORS solo para orígenes permitidos', () async {
    final allowed = await handler(
      Request(
        'OPTIONS',
        Uri.parse('http://localhost/v1/trip-conditions'),
        headers: {'origin': 'http://127.0.0.1:4711'},
      ),
    );
    expect(allowed.statusCode, 204);
    expect(
      allowed.headers['access-control-allow-origin'],
      'http://127.0.0.1:4711',
    );

    final other = await handler(
      Request(
        'OPTIONS',
        Uri.parse('http://localhost/v1/trip-conditions'),
        headers: {'origin': 'https://otro.example'},
      ),
    );
    expect(other.statusCode, 403);
    expect(other.headers['access-control-allow-origin'], isNull);
  });

  group('FirebaseIdentityVerifier', () {
    FirebaseIdentityVerifier verifier(int status, Object body) =>
        FirebaseIdentityVerifier(
          apiKey: 'web-key',
          emulatorHost: '127.0.0.1:9099',
          client: MockClient((request) async {
            expect(
              request.url.toString(),
              'http://127.0.0.1:9099/identitytoolkit.googleapis.com'
              '/v1/accounts:lookup?key=web-key',
            );
            expect(jsonDecode(request.body), {'idToken': 'abc'});
            expect(request.followRedirects, isFalse);
            return http.Response(jsonEncode(body), status);
          }),
        );

    test('toma el uid de la respuesta de Firebase', () async {
      final uid = await verifier(200, {
        'users': [
          {'localId': 'uid-ana'},
        ],
      }).verify('abc');
      expect(uid, 'uid-ana');
    });

    test('un token rechazado no identifica a nadie', () async {
      expect(
        await verifier(400, {
          'error': {'message': 'INVALID_ID_TOKEN'},
        }).verify('abc'),
        isNull,
      );
    });

    test('una respuesta sin un único usuario no identifica a nadie', () async {
      expect(await verifier(200, {'users': []}).verify('abc'), isNull);
      expect(
        await verifier(200, {
          'users': [
            {'localId': 42},
          ],
        }).verify('abc'),
        isNull,
      );
    });

    test('una redirección no se sigue y no cuenta como sesión', () {
      expect(
        verifier(307, {}).verify('abc'),
        throwsA(isA<IdentityUnavailable>()),
      );
    });

    test('un error del proveedor no se confunde con sesión inválida', () {
      expect(
        verifier(500, {}).verify('abc'),
        throwsA(isA<IdentityUnavailable>()),
      );
    });
  });
}
