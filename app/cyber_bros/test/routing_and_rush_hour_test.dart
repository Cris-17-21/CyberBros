import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_bros/features/trip_planner/data/osm_stops.dart';
import 'package:cyber_bros/features/trip_planner/data/pilot_planner.dart';
import 'package:cyber_bros/features/trip_planner/domain/routing_engine.dart';

void main() {
  group('PilotPlanner - Detección de Hora Punta en Lima (Congestión)', () {
    test('Detecta hora punta matutina (miércoles 08:30 Lima = 13:30 UTC)', () {
      final wednesdayMorningUtc = DateTime.utc(2026, 10, 21, 13, 30);
      expect(PilotPlanner.isRushHour(wednesdayMorningUtc), isTrue);
    });

    test('Detecta hora punta vespertina (miércoles 19:15 Lima = 00:15 UTC jueves)', () {
      final wednesdayEveningUtc = DateTime.utc(2026, 10, 22, 0, 15);
      expect(PilotPlanner.isRushHour(wednesdayEveningUtc), isTrue);
    });

    test('Detecta hora valle (miércoles 14:00 Lima = 19:00 UTC)', () {
      final wednesdayNoonUtc = DateTime.utc(2026, 10, 21, 19, 0);
      expect(PilotPlanner.isRushHour(wednesdayNoonUtc), isFalse);
    });

    test('Fin de semana nunca es hora punta (domingo 19:00 Lima = 00:00 UTC lunes)', () {
      final sundayUtc = DateTime.utc(2026, 10, 26, 0, 0);
      expect(PilotPlanner.isRushHour(sundayUtc), isFalse);
    });

    test('Aplica surge 1.20x de UberX en hora punta de Lima', () {
      final offPeakUtc = DateTime.utc(2026, 10, 21, 19, 0);
      final rushUtc = DateTime.utc(2026, 10, 21, 13, 30);

      final normalCents = PilotPlanner.estimateUberXCents(
        distanceMetres: 8000,
        durationMinutes: 25,
        customTime: offPeakUtc,
      );
      final rushCents = PilotPlanner.estimateUberXCents(
        distanceMetres: 8000,
        durationMinutes: 25,
        customTime: rushUtc,
      );

      expect(rushCents, greaterThan(normalCents));
      expect((normalCents * 1.20).round(), equals(rushCents));
    });
  });

  group('LocalPlanner.enrichWithTradeoffs (RF-08 & RNF-15)', () {
    test('Genera explicación para enlace taxi puente reduciendo caminata continua', () {
      final alt = PlanAlternative(
        label: 'Menos caminata',
        edges: [
          const TravelEdge(
            id: 'walk:1',
            fromNodeId: 'A',
            toNodeId: 'B',
            kind: EdgeKind.walk,
            distanceMetres: 90,
            durationMinutes: 2,
            costCents: 0,
            certainty: DataCertainty.estimated,
            source: 'test',
          ),
          const TravelEdge(
            id: 'taxi:1',
            fromNodeId: 'B',
            toNodeId: 'C',
            kind: EdgeKind.taxiBridge,
            distanceMetres: 1400,
            durationMinutes: 5,
            costCents: 850,
            certainty: DataCertainty.estimated,
            source: 'test',
          ),
        ],
        costCents: 850,
        walkMetres: 90,
        longestWalkMetres: 90,
        durationMinutes: 7,
        transfers: 0,
        hasEstimatedData: true,
        hasCommunityData: false,
      );

      final enriched = LocalPlanner.enrichWithTradeoffs([alt]);
      expect(enriched.first.tradeoffText, contains('Enlace taxi de ~1.4 km'));
      expect(enriched.first.tradeoffText, contains('+S/ 8.50'));
      expect(enriched.first.tradeoffText, contains('tu caminata continua baja a 90 m (~1 cuadras)'));
    });

    test('Genera explicación para opción 100% a pie comparada con bus', () {
      final walkAlt = PlanAlternative(
        label: 'A pie',
        edges: [
          const TravelEdge(
            id: 'walk:1',
            fromNodeId: 'A',
            toNodeId: 'B',
            kind: EdgeKind.walk,
            distanceMetres: 650,
            durationMinutes: 9,
            costCents: 0,
            certainty: DataCertainty.estimated,
            source: 'test',
          ),
        ],
        costCents: 0,
        walkMetres: 650,
        longestWalkMetres: 650,
        durationMinutes: 9,
        transfers: 0,
        hasEstimatedData: true,
        hasCommunityData: false,
      );

      final busAlt = PlanAlternative(
        label: 'Más rápida',
        edges: [
          const TravelEdge(
            id: 'board:1',
            fromNodeId: 'A',
            toNodeId: 'A',
            kind: EdgeKind.board,
            routeId: 'R1',
            distanceMetres: 0,
            durationMinutes: 4,
            costCents: 250,
            certainty: DataCertainty.confirmed,
            source: 'test',
          ),
          const TravelEdge(
            id: 'ride:1',
            fromNodeId: 'A',
            toNodeId: 'B',
            kind: EdgeKind.ride,
            routeId: 'R1',
            distanceMetres: 650,
            durationMinutes: 3,
            costCents: 0,
            certainty: DataCertainty.confirmed,
            source: 'test',
          ),
        ],
        costCents: 250,
        walkMetres: 0,
        longestWalkMetres: 0,
        durationMinutes: 7,
        transfers: 0,
        hasEstimatedData: false,
        hasCommunityData: false,
      );

      final enriched = LocalPlanner.enrichWithTradeoffs([walkAlt, busAlt]);
      expect(enriched[0].tradeoffText, contains('Ahorras S/ 2.50 de pasaje caminando ~7 cuadras (650 m)'));
    });

    test('OsmStopCatalog reconoce identificadores con prefijo address', () {
      const catalog = OsmStopCatalog.empty();
      final stop = catalog.findById('address:-12.091957:-77.033347');
      expect(stop, isNotNull);
      expect(stop!.point.latitude, closeTo(-12.091957, 0.00001));
      expect(stop.point.longitude, closeTo(-77.033347, 0.00001));
      expect(stop.source, equals('mapbox:geocoding'));
    });
  });
}
