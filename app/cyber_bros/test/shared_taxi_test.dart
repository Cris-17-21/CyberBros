import 'package:cyber_bros/features/trip_planner/data/shared_taxi_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

SharedTaxiRoom _room({
  int taxiCents = 900,
  int maxPeople = 3,
  List<TaxiMember> members = const [],
  Duration validFor = const Duration(minutes: 20),
}) => SharedTaxiRoom(
  id: 'sala',
  ownerUid: 'a',
  ownerName: 'Ana',
  fromLabel: 'Paradero A',
  toLabel: 'Paradero B',
  from: const LatLng(-12.07, -77.04),
  to: const LatLng(-12.09, -77.03),
  taxiCents: taxiCents,
  distanceMetres: 1400,
  maxPeople: maxPeople,
  createdAt: DateTime.now(),
  expiresAt: DateTime.now().add(validFor),
  open: true,
  members: members,
);

void main() {
  group('Taxi compartido: reparto de costos', () {
    test('entre una persona paga todo', () {
      expect(_room().shareCents(1), 900);
    });

    test('se reparte en partes iguales', () {
      expect(_room(taxiCents: 900).shareCents(3), 300);
    });

    test('redondea hacia arriba para no quedarse corto', () {
      // S/ 8.50 entre 3 = 283.33 céntimos -> 284 cada una (suma 852 >= 850).
      final room = _room(taxiCents: 850);
      expect(room.shareCents(3), 284);
      expect(room.shareCents(3) * 3, greaterThanOrEqualTo(850));
    });

    test('compartir nunca sale más caro que ir solo', () {
      final room = _room(taxiCents: 1234);
      for (var people = 2; people <= 4; people++) {
        expect(room.shareCents(people), lessThan(room.shareCents(1)));
      }
    });
  });

  group('Taxi compartido: cupos y vigencia', () {
    test('cuenta los lugares libres', () {
      final room = _room(
        maxPeople: 3,
        members: const [TaxiMember(uid: 'a', name: 'Ana')],
      );
      expect(room.seatsLeft, 2);
      expect(room.full, isFalse);
    });

    test('una sala llena no tiene lugares', () {
      final room = _room(
        maxPeople: 2,
        members: const [
          TaxiMember(uid: 'a', name: 'Ana'),
          TaxiMember(uid: 'b', name: 'Beto'),
        ],
      );
      expect(room.seatsLeft, 0);
      expect(room.full, isTrue);
    });

    test('detecta una sala vencida', () {
      expect(_room(validFor: const Duration(minutes: -1)).expired, isTrue);
      expect(_room().expired, isFalse);
    });
  });
}
