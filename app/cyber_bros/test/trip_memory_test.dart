import 'dart:convert';

import 'package:cyber_bros/features/trip_planner/data/trip_memory_service.dart';
import 'package:cyber_bros/features/trip_planner/domain/routing_engine.dart';
import 'package:cyber_bros/features/trip_planner/presentation/trip_conditions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Imita `services/preferences_api`: un recuerdo por token.
final class _FakePreferencesApi {
  final Map<String, Map<String, Object?>> byToken = {};
  final List<String> calls = [];
  int? failWith;

  late final MockClient client = MockClient((request) async {
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    calls.add('${request.method} ${request.url.path}');
    if (failWith != null) return http.Response('{}', failWith!);
    if (token == null) return http.Response('{}', 401);
    switch (request.method) {
      case 'GET':
        final stored = byToken[token];
        return _json(
          stored == null
              ? {'status': 'empty'}
              : {'status': 'found', 'conditions': stored},
        );
      case 'PUT':
        final body = jsonDecode(request.body) as Map<String, Object?>;
        if (body['consent'] != true) return http.Response('{}', 400);
        byToken[token] = body['conditions'] as Map<String, Object?>;
        return _json({'status': 'saved', 'conditions': body['conditions']});
      default:
        return _json({
          'status': byToken.remove(token) == null ? 'empty' : 'deleted',
        });
    }
  });

  TripMemoryService service({String? token = 'token-ana'}) => TripMemoryService(
    baseUrl: 'http://127.0.0.1:8787',
    client: client,
    idToken: () async => token,
  );

  static http.Response _json(Object body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
}

const _remembered = {
  'budgetCents': 550,
  'maxContinuousWalkMetres': 200,
  'maxTotalWalkMetres': 600,
  'allowTaxiBridge': false,
  'priority': 'savings',
};

Future<void> _pumpConditions(
  WidgetTester tester,
  TripMemoryService service,
) async {
  // Ancho de un teléfono grande; alto suficiente para ver todo el formulario.
  await tester.binding.setSurfaceSize(const Size(430, 3200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: TripConditionsScreen(
        origin: 'Av. Brasil cdra. 12, Jesús María',
        destination: 'Plaza Bolognesi, Lima',
        isDemo: true,
        tripMemory: service,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// El campo de presupuesto es el único TextField centrado de la pantalla.
String _budgetText(WidgetTester tester) => tester
    .widget<TextField>(
      find.byWidgetPredicate(
        (widget) => widget is TextField && widget.textAlign == TextAlign.center,
      ),
    )
    .controller!
    .text;

void main() {
  group('TripMemoryService', () {
    test('apagado por defecto: no hace ninguna llamada', () async {
      final api = _FakePreferencesApi();
      final service = TripMemoryService(baseUrl: '', client: api.client);
      expect(service.isEnabled, isFalse);
      expect(await service.recall(), isA<TripMemoryUnavailable>());
      expect(api.calls, isEmpty);
    });

    test('sin sesión no consulta el servicio', () async {
      final api = _FakePreferencesApi();
      final result = await api.service(token: null).recall();
      expect(result, isA<TripMemorySignedOut>());
      expect(api.calls, isEmpty);
    });

    test('guarda con consentimiento y recuerda lo guardado', () async {
      final api = _FakePreferencesApi();
      final service = api.service();
      const limits = PlanLimits(
        budgetCents: 800,
        maxContinuousWalkMetres: 300,
        maxTotalWalkMetres: 800,
        allowTaxiBridge: true,
        priority: PlanPriority.lessWalking,
      );
      expect(await service.save(limits), isA<TripMemorySaved>());
      final recalled = await service.recall();
      expect(recalled, isA<TripMemoryFound>());
      final found = recalled as TripMemoryFound;
      expect(found.limits.budgetCents, 800);
      expect(found.limits.priority, PlanPriority.lessWalking);
    });

    test('cada cuenta recuerda solo lo suyo', () async {
      final api = _FakePreferencesApi()..byToken['token-ana'] = _remembered;
      expect(
        await api.service(token: 'token-beto').recall(),
        isA<TripMemoryEmpty>(),
      );
    });

    test('un fallo o una demora se informan como no disponible', () async {
      final failing = _FakePreferencesApi()..failWith = 503;
      expect(
        await failing.service().save(
          const PlanLimits(
            budgetCents: 800,
            maxContinuousWalkMetres: 300,
            maxTotalWalkMetres: 800,
            allowTaxiBridge: true,
          ),
        ),
        isA<TripMemoryUnavailable>(),
      );
      expect(await failing.service().forget(), isA<TripMemoryUnavailable>());

      final slow = TripMemoryService(
        baseUrl: 'http://127.0.0.1:8787',
        timeout: const Duration(milliseconds: 50),
        idToken: () async => 'token-ana',
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          return http.Response('{"status":"empty"}', 200);
        }),
      );
      expect(await slow.recall(), isA<TripMemoryUnavailable>());
    });

    test(
      'una respuesta malformada no se toma como vacía ni guardada',
      () async {
        TripMemoryService answering(String body) => TripMemoryService(
          baseUrl: 'http://127.0.0.1:8787',
          idToken: () async => 'token-ana',
          client: MockClient((request) async {
            expect(request.followRedirects, isFalse);
            return http.Response(body, 200);
          }),
        );
        expect(
          await answering('no es json').recall(),
          isA<TripMemoryUnavailable>(),
        );
        expect(await answering('{}').recall(), isA<TripMemoryUnavailable>());
        expect(
          await answering('{"status":"found","conditions":{"budgetCents":"8"}}')
              .recall(),
          isA<TripMemoryUnavailable>(),
        );
        // Una prioridad desconocida no se convierte en "equilibrada".
        expect(
          await answering(
            '{"status":"found","conditions":{"budgetCents":800,'
            '"maxContinuousWalkMetres":300,"maxTotalWalkMetres":800,'
            '"allowTaxiBridge":true,"priority":"rapidez"}}',
          ).recall(),
          isA<TripMemoryUnavailable>(),
        );
        // "Guardado" sin las condiciones confirmadas no es un guardado.
        expect(
          await answering('{"status":"saved"}').save(
            const PlanLimits(
              budgetCents: 800,
              maxContinuousWalkMetres: 300,
              maxTotalWalkMetres: 800,
              allowTaxiBridge: true,
            ),
          ),
          isA<TripMemoryUnavailable>(),
        );
        // Un "deleted" en respuesta a una lectura no cuenta.
        expect(
          await answering('{"status":"deleted"}').recall(),
          isA<TripMemoryUnavailable>(),
        );
      },
    );
  });

  group('Tus Condiciones', () {
    testWidgets('sin configurar no aparece la tarjeta', (tester) async {
      await _pumpConditions(
        tester,
        TripMemoryService(baseUrl: '', client: _FakePreferencesApi().client),
      );
      expect(find.text('Tus condiciones de siempre'), findsNothing);
      expect(find.text('Ver opciones'), findsOneWidget);
    });

    testWidgets('sin sesión invita a iniciar sesión', (tester) async {
      await _pumpConditions(tester, _FakePreferencesApi().service(token: null));
      expect(
        find.textContaining('Inicia sesión para guardar tus condiciones'),
        findsOneWidget,
      );
    });

    testWidgets('recuerda, aplica solo al confirmar y permite olvidar', (
      tester,
    ) async {
      final api = _FakePreferencesApi()..byToken['token-ana'] = _remembered;
      await _pumpConditions(tester, api.service());

      expect(find.text('Recordamos tus condiciones:'), findsOneWidget);
      expect(
        find.text(
          'S/ 5.50 · 200 m seguidos · 600 m en total · sin taxi · Ahorro',
        ),
        findsOneWidget,
      );
      // Nada cambia en los controles hasta que la persona lo pide.
      expect(_budgetText(tester), '8');

      await tester.tap(find.text('Usar estas'));
      await tester.pump();
      expect(_budgetText(tester), '5.50');
      expect(find.text('200 m ≈ 2 cuadras'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

      await tester.tap(find.text('Olvidar'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Olvidamos tus condiciones guardadas.'), findsOneWidget);
      expect(api.byToken, isEmpty);
      expect(find.text('Guardar mis condiciones'), findsOneWidget);
    });

    testWidgets('guardar envía las condiciones de los controles', (
      tester,
    ) async {
      final api = _FakePreferencesApi();
      await _pumpConditions(tester, api.service());
      expect(
        find.textContaining('Se guardan en Atomic Memory solo para tu cuenta'),
        findsOneWidget,
      );

      await tester.tap(find.text('Guardar mis condiciones'));
      await tester.pump();
      await tester.pump();

      expect(api.byToken['token-ana'], {
        'budgetCents': 800,
        'maxContinuousWalkMetres': 300,
        'maxTotalWalkMetres': 800,
        'allowTaxiBridge': true,
        'priority': 'lessWalking',
      });
      expect(find.textContaining('Guardado.'), findsOneWidget);
      expect(find.text('Recordamos tus condiciones:'), findsOneWidget);
    });

    testWidgets('si el servicio falla no confirma el guardado', (tester) async {
      final api = _FakePreferencesApi();
      await _pumpConditions(tester, api.service());
      api.failWith = 503;

      await tester.tap(find.text('Guardar mis condiciones'));
      await tester.pump();
      await tester.pump();

      expect(
        find.textContaining('No pudimos confirmar que se guardó'),
        findsOneWidget,
      );
      expect(find.text('Recordamos tus condiciones:'), findsNothing);
    });

    testWidgets('si no puede consultar, el formulario sigue igual', (
      tester,
    ) async {
      final api = _FakePreferencesApi()..failWith = 503;
      await _pumpConditions(tester, api.service());
      expect(
        find.textContaining('No pudimos consultar tus condiciones'),
        findsOneWidget,
      );
      expect(_budgetText(tester), '8');
    });
  });
}
