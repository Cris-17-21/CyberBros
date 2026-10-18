import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/firebase_config.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/data/auth_session.dart';

/// Error con mensaje listo para mostrar.
final class TaxiException implements Exception {
  const TaxiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// El tramo de taxi puente de un recorrido, que se puede compartir.
final class SharedTaxiRequest {
  const SharedTaxiRequest({
    required this.fromLabel,
    required this.toLabel,
    required this.from,
    required this.to,
    required this.taxiCents,
    required this.distanceMetres,
  });

  final String fromLabel;
  final String toLabel;
  final LatLng from;
  final LatLng to;
  final int taxiCents;
  final int distanceMetres;
}

final class TaxiMember {
  const TaxiMember({required this.uid, required this.name});

  final String uid;
  final String name;
}

/// Sala para repartir el taxi de un tramo entre varias personas.
final class SharedTaxiRoom {
  const SharedTaxiRoom({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    required this.fromLabel,
    required this.toLabel,
    required this.from,
    required this.to,
    required this.taxiCents,
    required this.distanceMetres,
    required this.maxPeople,
    required this.createdAt,
    required this.expiresAt,
    required this.open,
    this.members = const [],
  });

  final String id;
  final String ownerUid;
  final String ownerName;
  final String fromLabel;
  final String toLabel;
  final LatLng from;
  final LatLng to;
  final int taxiCents;
  final int distanceMetres;
  final int maxPeople;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool open;
  final List<TaxiMember> members;

  int get seatsLeft => (maxPeople - members.length).clamp(0, maxPeople);
  bool get full => seatsLeft == 0;
  bool get expired => DateTime.now().isAfter(expiresAt);
  Duration get timeLeft => expiresAt.difference(DateTime.now());

  /// Lo que paga cada persona si van `people` en el taxi (redondeado hacia
  /// arriba al céntimo, para no quedarse corto).
  int shareCents(int people) => (taxiCents / people.clamp(1, 99)).ceil();

  SharedTaxiRoom withMembers(List<TaxiMember> value) => SharedTaxiRoom(
    id: id,
    ownerUid: ownerUid,
    ownerName: ownerName,
    fromLabel: fromLabel,
    toLabel: toLabel,
    from: from,
    to: to,
    taxiCents: taxiCents,
    distanceMetres: distanceMetres,
    maxPeople: maxPeople,
    createdAt: createdAt,
    expiresAt: expiresAt,
    open: open,
    members: value,
  );
}

/// Taxi compartido para el tramo puente (problema de la "movilidad binaria"):
/// varias personas que van al mismo tramo reparten un taxi corto en lugar de
/// pagarlo solas.
///
/// Usa Firestore por REST con el token de la cuenta. Solo participan cuentas
/// con sesión. Las salas guardan paraderos (puntos públicos), nunca la
/// ubicación de las personas. Limitación declarada: el cupo de una sala lo
/// controla el cliente; un servidor lo validaría desde el Incremento A.
final class SharedTaxiStore {
  SharedTaxiStore._();

  static final SharedTaxiStore instance = SharedTaxiStore._();

  static const _timeout = Duration(seconds: 12);
  static const _prefKey = 'cyberon.taxi.myroom';
  static const _documents =
      'https://firestore.googleapis.com/v1/projects/${FirebaseConfig.projectId}'
      '/databases/(default)/documents';

  /// Radios para considerar que dos personas comparten el mismo tramo.
  static const matchFromMetres = 400;
  static const matchToMetres = 700;

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  bool get signedIn => AuthService.instance.isSignedIn;

  String get _myName {
    final label = AuthService.instance.session?.label ?? 'Alguien';
    final first = label.trim().split(RegExp(r'\s+')).first;
    return first.length > 20 ? first.substring(0, 20) : first;
  }

  // ------------------------------------------------------------ consultas

  /// Salas abiertas cuyo tramo coincide con el tuyo.
  Future<List<SharedTaxiRoom>> findNearby(SharedTaxiRequest request) async {
    final uid = AuthService.instance.session?.userId;
    final response = await _send(
      'POST',
      '$_documents:runQuery',
      body: {
        'structuredQuery': {
          'from': [
            {'collectionId': 'taxi_pools'},
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'status'},
              'op': 'EQUAL',
              'value': {'stringValue': 'OPEN'},
            },
          },
          'limit': 50,
        },
      },
    );
    final rows = jsonDecode(response.body) as List<dynamic>;
    const distance = Distance();
    final matches = <SharedTaxiRoom>[];
    for (final row in rows) {
      final document = (row as Map<String, dynamic>)['document'];
      if (document == null) continue;
      final room = _roomFrom(document as Map<String, dynamic>);
      if (room == null || room.expired || room.ownerUid == uid) continue;
      final closeStart =
          distance.as(LengthUnit.Meter, room.from, request.from) <=
          matchFromMetres;
      final closeEnd =
          distance.as(LengthUnit.Meter, room.to, request.to) <= matchToMetres;
      if (closeStart && closeEnd) matches.add(room);
    }
    final withMembers = <SharedTaxiRoom>[];
    for (final room in matches) {
      withMembers.add(room.withMembers(await _members(room.id)));
    }
    withMembers.removeWhere((room) => room.full);
    withMembers.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    return withMembers;
  }

  /// La sala en la que estás ahora, o `null` si no estás en ninguna.
  Future<SharedTaxiRoom?> myRoom() async {
    final id = await _prefs.getString(_prefKey);
    if (id == null) return null;
    final uid = AuthService.instance.session?.userId;
    try {
      final room = await refresh(id);
      if (room == null ||
          !room.open ||
          room.expired ||
          !room.members.any((member) => member.uid == uid)) {
        await _prefs.remove(_prefKey);
        return null;
      }
      return room;
    } on TaxiException {
      return null; // sin red: no se descarta la sala
    }
  }

  Future<SharedTaxiRoom?> refresh(String roomId) async {
    final http.Response response;
    try {
      response = await _send('GET', '$_documents/taxi_pools/$roomId');
    } on TaxiException catch (error) {
      if (error.message == _notFound) return null;
      rethrow;
    }
    final room = _roomFrom(jsonDecode(response.body) as Map<String, dynamic>);
    if (room == null) return null;
    return room.withMembers(await _members(roomId));
  }

  // -------------------------------------------------------------- acciones

  Future<SharedTaxiRoom> create(
    SharedTaxiRequest request, {
    required int maxPeople,
    required Duration waitFor,
  }) async {
    final session = _requireSession();
    final now = DateTime.now().toUtc();
    final response = await _send(
      'POST',
      '$_documents/taxi_pools',
      body: {
        'fields': {
          'ownerUid': _string(session.userId),
          'ownerName': _string(_myName),
          'fromLabel': _string(_clip(request.fromLabel)),
          'toLabel': _string(_clip(request.toLabel)),
          'fromLat': _double(request.from.latitude),
          'fromLng': _double(request.from.longitude),
          'toLat': _double(request.to.latitude),
          'toLng': _double(request.to.longitude),
          'distanceMetres': _integer(request.distanceMetres),
          'taxiCents': _integer(request.taxiCents),
          'maxPeople': _integer(maxPeople),
          'status': _string('OPEN'),
          'createdAt': _timestamp(now),
          'expiresAt': _timestamp(now.add(waitFor)),
        },
      },
    );
    final created = _roomFrom(jsonDecode(response.body) as Map<String, dynamic>);
    if (created == null) {
      throw const TaxiException('No pudimos crear la sala. Inténtalo de nuevo.');
    }
    await _addMember(created.id);
    await _prefs.setString(_prefKey, created.id);
    return created.withMembers([
      TaxiMember(uid: session.userId, name: _myName),
    ]);
  }

  Future<SharedTaxiRoom> join(SharedTaxiRoom room) async {
    _requireSession();
    final fresh = await refresh(room.id);
    if (fresh == null || !fresh.open || fresh.expired) {
      throw const TaxiException('Esa sala ya no está disponible.');
    }
    if (fresh.full) {
      throw const TaxiException('La sala se llenó. Busca otra o crea una.');
    }
    await _addMember(room.id);
    await _prefs.setString(_prefKey, room.id);
    return (await refresh(room.id)) ?? fresh;
  }

  /// Sales de la sala. Si eras la dueña y quedan personas, sigue abierta; si
  /// eras la última, se cierra.
  Future<void> leave(SharedTaxiRoom room) async {
    final session = _requireSession();
    await _send(
      'DELETE',
      '$_documents/taxi_pools/${room.id}/members/${session.userId}',
    );
    await _prefs.remove(_prefKey);
    if (room.ownerUid == session.userId) await close(room);
  }

  Future<void> close(SharedTaxiRoom room) async {
    await _send(
      'PATCH',
      '$_documents/taxi_pools/${room.id}?updateMask.fieldPaths=status',
      body: {
        'fields': {'status': _string('CLOSED')},
      },
    );
    await _prefs.remove(_prefKey);
  }

  // ------------------------------------------------------------ internos

  static const _notFound = 'not-found';

  AuthSession _requireSession() {
    final session = AuthService.instance.session;
    if (session == null) {
      throw const TaxiException('Inicia sesión para compartir un taxi.');
    }
    return session;
  }

  Future<void> _addMember(String roomId) async {
    final session = _requireSession();
    await _send(
      'PATCH',
      '$_documents/taxi_pools/$roomId/members/${session.userId}',
      body: {
        'fields': {
          'name': _string(_myName),
          'joinedAt': _timestamp(DateTime.now().toUtc()),
        },
      },
    );
  }

  Future<List<TaxiMember>> _members(String roomId) async {
    final response = await _send(
      'GET',
      '$_documents/taxi_pools/$roomId/members?pageSize=10',
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = body['documents'] as List<dynamic>? ?? const [];
    return [
      for (final document in documents)
        TaxiMember(
          uid: _idOf((document as Map<String, dynamic>)['name'] as String),
          name:
              _read(document['fields'] as Map<String, dynamic>? ?? {}, 'name') ??
              'Alguien',
        ),
    ];
  }

  Future<http.Response> _send(
    String method,
    String url, {
    Map<String, Object?>? body,
  }) async {
    final token = await AuthService.instance.validIdToken();
    if (token == null) {
      throw const TaxiException('Inicia sesión para compartir un taxi.');
    }
    final request = http.Request(method, Uri.parse(url))
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Content-Type'] = 'application/json';
    if (body != null) request.body = jsonEncode(body);
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await request.send().timeout(_timeout),
      );
    } catch (_) {
      throw const TaxiException(
        'No pudimos conectarnos. Revisa tu internet e inténtalo de nuevo.',
      );
    }
    if (response.statusCode == 404) throw const TaxiException(_notFound);
    if (response.statusCode == 403) {
      throw const TaxiException(
        'No tienes permiso para esa acción. Inicia sesión de nuevo.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const TaxiException(
        'El servicio no respondió bien. Inténtalo en unos minutos.',
      );
    }
    return response;
  }

  SharedTaxiRoom? _roomFrom(Map<String, dynamic> document) {
    try {
      final fields = document['fields'] as Map<String, dynamic>;
      return SharedTaxiRoom(
        id: _idOf(document['name'] as String),
        ownerUid: _read(fields, 'ownerUid')!,
        ownerName: _read(fields, 'ownerName') ?? 'Alguien',
        fromLabel: _read(fields, 'fromLabel') ?? '',
        toLabel: _read(fields, 'toLabel') ?? '',
        from: LatLng(_double2(fields, 'fromLat'), _double2(fields, 'fromLng')),
        to: LatLng(_double2(fields, 'toLat'), _double2(fields, 'toLng')),
        taxiCents: int.parse(_read(fields, 'taxiCents')!),
        distanceMetres: int.parse(_read(fields, 'distanceMetres') ?? '0'),
        maxPeople: int.parse(_read(fields, 'maxPeople')!),
        createdAt: DateTime.parse(_read(fields, 'createdAt')!).toLocal(),
        expiresAt: DateTime.parse(_read(fields, 'expiresAt')!).toLocal(),
        open: _read(fields, 'status') == 'OPEN',
      );
    } catch (_) {
      return null;
    }
  }

  static String _idOf(String path) => path.split('/').last;

  static String _clip(String value) =>
      value.length > 120 ? value.substring(0, 120) : value;

  /// Lee el valor de un campo de Firestore como texto.
  static String? _read(Map<String, dynamic> fields, String key) {
    final field = fields[key];
    if (field is! Map) return null;
    for (final type in const [
      'stringValue',
      'integerValue',
      'doubleValue',
      'timestampValue',
    ]) {
      if (field[type] != null) return '${field[type]}';
    }
    return null;
  }

  static double _double2(Map<String, dynamic> fields, String key) =>
      double.parse(_read(fields, key)!);

  static Map<String, Object> _string(String value) => {'stringValue': value};

  static Map<String, Object> _integer(int value) => {'integerValue': '$value'};

  static Map<String, Object> _double(double value) => {'doubleValue': value};

  static Map<String, Object> _timestamp(DateTime utc) => {
    'timestampValue': utc.toIso8601String(),
  };
}
