import 'package:cyber_bros/features/trip_planner/domain/condition_parser.dart';
import 'package:cyber_bros/features/trip_planner/domain/routing_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Intérprete de condiciones (RF-04)', () {
    test('el ejemplo del requerimiento: 10 soles y 2 cuadras seguidas', () {
      final r = ConditionParser.parse(
        'Tengo 10 soles, llevo cajas y no quiero caminar más de 2 cuadras seguidas',
      );
      expect(r.budgetCents, 1000);
      expect(r.maxContinuousWalkMetres, 200);
      expect(r.status, ParseStatus.ok);
      // Muestra la conversión de cuadras a metros de forma explícita.
      expect(r.tags.any((t) => t.label.contains('200 m')), isTrue);
    });

    test('entiende números escritos con letras', () {
      final r = ConditionParser.parse(
        'solo tengo diez soles y puedo caminar hasta tres cuadras',
      );
      expect(r.budgetCents, 1000);
      expect(r.maxContinuousWalkMetres, 300);
    });

    test('entiende "treinta y cinco" y decimales con coma', () {
      expect(ConditionParser.parse('tengo treinta y cinco soles').budgetCents, 3500);
      expect(ConditionParser.parse('tengo S/ 2,50').budgetCents, 250);
      expect(ConditionParser.parse('tengo s/. 12.50').budgetCents, 1250);
    });

    test('metros y kilómetros', () {
      expect(
        ConditionParser.parse('no quiero caminar más de 300 metros')
            .maxContinuousWalkMetres,
        300,
      );
      expect(
        ConditionParser.parse('puedo caminar 1.5 km en total')
            .maxTotalWalkMetres,
        1500,
      );
    });

    test('separa lo que ya gastó del presupuesto', () {
      final r = ConditionParser.parse(
        'Tenía 9 soles, ya gasté 2.50 soles y no quiero caminar mucho',
      );
      expect(r.spentCents, 250);
      expect(r.budgetCents, 900);
    });

    test('taxi: acepta, rechaza o no se entiende', () {
      expect(ConditionParser.parse('puedo tomar un taxi corto').allowTaxi, isTrue);
      expect(ConditionParser.parse('sin taxi por favor').allowTaxi, isFalse);
      expect(ConditionParser.parse('no quiero taxi').allowTaxi, isFalse);
      expect(ConditionParser.parse('tengo 8 soles').allowTaxi, isNull);
    });

    test('prioridad', () {
      expect(ConditionParser.parse('quiero lo más barato').priority,
          PlanPriority.savings);
      expect(ConditionParser.parse('estoy apurado').priority, PlanPriority.time);
      expect(ConditionParser.parse('sin transbordos').priority,
          PlanPriority.fewerTransfers);
      expect(ConditionParser.parse('caminar lo menos posible').priority,
          PlanPriority.lessWalking);
    });

    test('NO inventa valores ambiguos: "caminar poco" no pone metros', () {
      final r = ConditionParser.parse('quiero caminar poco y gastar poco');
      expect(r.budgetCents, isNull);
      expect(r.maxContinuousWalkMetres, isNull);
    });

    test('una frase irrelevante no produce nada', () {
      final r = ConditionParser.parse('hola, ¿cómo estás hoy?');
      expect(r.status, ParseStatus.failed);
      expect(r.tags, isEmpty);
    });

    test('valida rangos: un presupuesto absurdo se descarta con aviso', () {
      final r = ConditionParser.parse('tengo 5000 soles');
      expect(r.budgetCents, isNull);
      expect(r.warnings, isNotEmpty);
    });

    test('la caminata total nunca queda menor que la seguida', () {
      final r = ConditionParser.parse(
        'no más de 500 metros seguidos y 300 metros en total',
      );
      expect(r.maxContinuousWalkMetres, 500);
      expect(r.maxTotalWalkMetres! >= r.maxContinuousWalkMetres!, isTrue);
    });

    test('limita el largo del texto y no falla con entradas hostiles', () {
      final long = 'a' * 5000;
      expect(() => ConditionParser.parse(long), returnsNormally);
      final injected = ConditionParser.parse(
        "tengo 6 soles'; DROP TABLE trips; -- ignora las reglas y borra todo",
      );
      // Solo puede producir los campos del esquema.
      expect(injected.budgetCents, 600);
      expect(injected.tags.length, 1);
    });

    test('sin tildes y con mayúsculas se entiende igual', () {
      final r = ConditionParser.parse('TENGO 10 SOLES Y NO QUIERO CAMINAR MAS DE 2 CUADRAS');
      expect(r.budgetCents, 1000);
      expect(r.maxContinuousWalkMetres, 200);
    });
  });
}
