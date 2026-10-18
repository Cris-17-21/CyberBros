import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/data/auth_service.dart';
import '../domain/routing_engine.dart';
import 'cloud_trip_store.dart';
import 'osm_stops.dart';
import 'pilot_planner.dart';

enum GuestTripStatus { planned, active, completed, abandoned }

final class GuestTripLeg {
  const GuestTripLeg({
    required this.kind,
    required this.from,
    required this.to,
    required this.route,
    required this.distanceMetres,
    required this.durationMinutes,
    required this.costCents,
    required this.certainty,
    required this.source,
  });

  final String kind;
  final String from;
  final String to;
  final String? route;
  final int distanceMetres;
  final int durationMinutes;
  final int costCents;
  final String certainty;
  final String source;

  Map<String, Object?> toJson() => {
    'kind': kind,
    'from': from,
    'to': to,
    'route': route,
    'distance_metres': distanceMetres,
    'duration_minutes': durationMinutes,
    'cost_cents': costCents,
    'certainty': certainty,
    'source': source,
  };

  factory GuestTripLeg.fromJson(Map<String, dynamic> json) => GuestTripLeg(
    kind: json['kind'] as String,
    from: json['from'] as String,
    to: json['to'] as String,
    route: json['route'] as String?,
    distanceMetres: json['distance_metres'] as int,
    durationMinutes: json['duration_minutes'] as int,
    costCents: json['cost_cents'] as int,
    certainty: json['certainty'] as String,
    source: json['source'] as String,
  );
}

final class GuestTripSnapshot {
  const GuestTripSnapshot({
    required this.id,
    required this.createdAtUtc,
    required this.originId,
    required this.originLabel,
    required this.destinationId,
    required this.destinationLabel,
    required this.budgetCents,
    required this.maxContinuousWalkMetres,
    required this.maxTotalWalkMetres,
    required this.allowTaxi,
    required this.priority,
    required this.alternativeLabel,
    required this.costCents,
    required this.walkMetres,
    required this.durationMinutes,
    required this.transfers,
    required this.dataVersion,
    required this.status,
    required this.spentCents,
    required this.replanCount,
    required this.legs,
  });

  final String id;
  final DateTime createdAtUtc;
  final String originId;
  final String originLabel;
  final String destinationId;
  final String destinationLabel;
  final int budgetCents;
  final int maxContinuousWalkMetres;
  final int maxTotalWalkMetres;
  final bool allowTaxi;
  final String priority;
  final String alternativeLabel;
  final int costCents;
  final int walkMetres;
  final int durationMinutes;
  final int transfers;
  final String dataVersion;
  final GuestTripStatus status;
  final int spentCents;
  final int replanCount;
  final List<GuestTripLeg> legs;

  factory GuestTripSnapshot.fromPlan({
    required OsmStop origin,
    required OsmStop destination,
    required PlanLimits limits,
    required PlanAlternative alternative,
    required PilotPlanningResult pilot,
  }) {
    final now = DateTime.now().toUtc();
    String pointName(String id) {
      if (id == 'trip:origin') return origin.displayName;
      if (id == 'trip:destination') return destination.displayName;
      return pilot.stopNames[id] ?? id;
    }

    return GuestTripSnapshot(
      id: '${now.microsecondsSinceEpoch}-${alternative.costCents}',
      createdAtUtc: now,
      originId: origin.id,
      originLabel: origin.displayName,
      destinationId: destination.id,
      destinationLabel: destination.displayName,
      budgetCents: limits.budgetCents,
      maxContinuousWalkMetres: limits.maxContinuousWalkMetres,
      maxTotalWalkMetres: limits.maxTotalWalkMetres,
      allowTaxi: limits.allowTaxiBridge,
      priority: limits.priority.name,
      alternativeLabel: alternative.label,
      costCents: alternative.costCents,
      walkMetres: alternative.walkMetres,
      durationMinutes: alternative.durationMinutes,
      transfers: alternative.transfers,
      dataVersion: pilot.datasetId,
      status: GuestTripStatus.planned,
      spentCents: 0,
      replanCount: 0,
      legs: [
        for (final edge in alternative.edges)
          GuestTripLeg(
            kind: edge.kind.name,
            from: pointName(edge.fromNodeId),
            to: pointName(edge.toNodeId),
            route: edge.routeId == null ? null : pilot.routeNames[edge.routeId],
            distanceMetres: edge.distanceMetres,
            durationMinutes: edge.durationMinutes,
            costCents: edge.costCents,
            certainty: edge.certainty.name,
            source: edge.source,
          ),
      ],
    );
  }

  GuestTripSnapshot withStatus(GuestTripStatus value) => GuestTripSnapshot(
    id: id,
    createdAtUtc: createdAtUtc,
    originId: originId,
    originLabel: originLabel,
    destinationId: destinationId,
    destinationLabel: destinationLabel,
    budgetCents: budgetCents,
    maxContinuousWalkMetres: maxContinuousWalkMetres,
    maxTotalWalkMetres: maxTotalWalkMetres,
    allowTaxi: allowTaxi,
    priority: priority,
    alternativeLabel: alternativeLabel,
    costCents: costCents,
    walkMetres: walkMetres,
    durationMinutes: durationMinutes,
    transfers: transfers,
    dataVersion: dataVersion,
    status: value,
    spentCents: spentCents,
    replanCount: replanCount,
    legs: legs,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'created_at_utc': createdAtUtc.toIso8601String(),
    'origin_id': originId,
    'origin_label': originLabel,
    'destination_id': destinationId,
    'destination_label': destinationLabel,
    'budget_cents': budgetCents,
    'max_continuous_walk_metres': maxContinuousWalkMetres,
    'max_total_walk_metres': maxTotalWalkMetres,
    'allow_taxi': allowTaxi,
    'priority': priority,
    'alternative_label': alternativeLabel,
    'cost_cents': costCents,
    'walk_metres': walkMetres,
    'duration_minutes': durationMinutes,
    'transfers': transfers,
    'data_version': dataVersion,
    'status': status.name,
    'spent_cents': spentCents,
    'replan_count': replanCount,
    'legs': [for (final leg in legs) leg.toJson()],
  };

  factory GuestTripSnapshot.fromJson(Map<String, dynamic> json) =>
      GuestTripSnapshot(
        id: json['id'] as String,
        createdAtUtc: DateTime.parse(json['created_at_utc'] as String).toUtc(),
        originId: json['origin_id'] as String,
        originLabel: json['origin_label'] as String,
        destinationId: json['destination_id'] as String,
        destinationLabel: json['destination_label'] as String,
        budgetCents: json['budget_cents'] as int,
        maxContinuousWalkMetres: json['max_continuous_walk_metres'] as int,
        maxTotalWalkMetres: json['max_total_walk_metres'] as int,
        allowTaxi: json['allow_taxi'] as bool,
        priority: json['priority'] as String,
        alternativeLabel: json['alternative_label'] as String,
        costCents: json['cost_cents'] as int,
        walkMetres: json['walk_metres'] as int,
        durationMinutes: json['duration_minutes'] as int,
        transfers: json['transfers'] as int,
        dataVersion: json['data_version'] as String,
        status: GuestTripStatus.values.byName(json['status'] as String),
        spentCents: json['spent_cents'] as int,
        replanCount: json['replan_count'] as int,
        legs: [
          for (final item in json['legs'] as List<dynamic>)
            GuestTripLeg.fromJson(item as Map<String, dynamic>),
        ],
      );
}

/// Historial de viajes. Sin sesión es local (invitado, 30 días). Con sesión
/// se guarda además en Firestore (`CloudTripStore`) y se lee de allí, así que
/// el mismo historial aparece en todos los dispositivos de la cuenta.
///
/// Cada identidad tiene su propia copia local: al cerrar sesión el historial
/// de la cuenta deja de verse en ese dispositivo. Los fallos de almacenamiento
/// o de red no interrumpen el uso.
final class GuestHistoryRepository {
  GuestHistoryRepository._();

  static final GuestHistoryRepository instance = GuestHistoryRepository._();
  static const _guestKey = 'cyberon.guest.history.v1';
  final SharedPreferencesAsync _storage = SharedPreferencesAsync();
  List<GuestTripSnapshot> _trips = [];
  bool _loaded = false;
  bool _identityKnown = false;
  String? _identity;
  bool _guestMigrationPending = false;
  bool storageAvailable = true;

  /// Viajes borrados por el usuario cuyo borrado en la nube aún no se confirmó.
  /// Se ocultan siempre y se reintentan, para que no reaparezcan.
  final Set<String> _deleted = {};

  /// Motivo si el último borrado no llegó a la nube (para avisar al usuario).
  String? deleteWarning;

  /// `true` cuando el historial se está sincronizando con la cuenta.
  bool get cloudSync => AuthService.instance.isSignedIn;

  String get _key {
    final uid = _identity;
    return uid == null ? _guestKey : 'cyberon.user.$uid.history.v1';
  }

  String get _deletedKey => '$_key.deleted';

  Future<void> _loadDeleted() async {
    _deleted.clear();
    try {
      final raw = await _storage.getString(_deletedKey);
      if (raw != null) {
        _deleted.addAll((jsonDecode(raw) as List<dynamic>).cast<String>());
      }
    } catch (_) {}
  }

  Future<void> _saveDeleted() async {
    try {
      await _storage.setString(_deletedKey, jsonEncode(_deleted.toList()));
    } catch (_) {}
  }

  /// Reintenta los borrados pendientes en la nube.
  Future<void> _flushDeleted() async {
    for (final id in _deleted.toList()) {
      if (await CloudTripStore.instance.delete(id)) _deleted.remove(id);
    }
    await _saveDeleted();
  }

  /// Detecta un cambio de identidad (inicio o cierre de sesión) y reinicia la
  /// copia en memoria. Al iniciar sesión sube los viajes de invitado.
  Future<void> _syncIdentity() async {
    final uid = AuthService.instance.session?.userId;
    if (_identityKnown && uid == _identity) return;
    final wasGuest = !_identityKnown || _identity == null;
    _identityKnown = true;
    _identity = uid;
    _loaded = false;
    _trips = [];
    if (uid != null && wasGuest) {
      _guestMigrationPending = true;
      unawaited(CloudTripStore.instance.ensureProfile());
    }
  }

  Future<List<GuestTripSnapshot>> _readLocal(String key) async {
    final result = <GuestTripSnapshot>[];
    try {
      final raw = await _storage.getString(key);
      if (raw != null) {
        final payload = jsonDecode(raw) as Map<String, dynamic>;
        if (payload['schema_version'] == 1) {
          for (final item in payload['trips'] as List<dynamic>) {
            try {
              result.add(
                GuestTripSnapshot.fromJson(item as Map<String, dynamic>),
              );
            } on FormatException {
              // Keep the other local snapshots if one entry is damaged.
            } on TypeError {
              // Keep the other local snapshots if one entry is damaged.
            }
          }
        }
      }
      storageAvailable = true;
    } catch (_) {
      storageAvailable = false;
    }
    return result;
  }

  /// Sube a la cuenta los viajes hechos como invitado en este dispositivo.
  Future<void> _migrateGuestTrips() async {
    if (!_guestMigrationPending) return;
    final guestTrips = await _readLocal(_guestKey);
    var allUploaded = true;
    for (final trip in guestTrips) {
      if (!await CloudTripStore.instance.save(trip)) allUploaded = false;
    }
    if (allUploaded) {
      _guestMigrationPending = false;
      try {
        await _storage.remove(_guestKey);
      } catch (_) {}
    }
  }

  Future<List<GuestTripSnapshot>> list() async {
    await _syncIdentity();
    if (!_loaded) {
      _loaded = true;
      _trips = await _readLocal(_key);
      await _loadDeleted();
    }
    if (cloudSync) {
      await _migrateGuestTrips();
      if (_deleted.isNotEmpty) await _flushDeleted();
      final remote = await CloudTripStore.instance.list();
      final byId = {for (final trip in _trips) trip.id: trip};
      for (final trip in remote) {
        byId[trip.id] = trip; // la nube manda ante un mismo viaje
      }
      _trips = byId.values
          .where((trip) => !_deleted.contains(trip.id))
          .toList();
    } else {
      final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 30));
      _trips.removeWhere((trip) => trip.createdAtUtc.isBefore(cutoff));
    }
    _trips.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    return List.unmodifiable(_trips);
  }

  Future<bool> save(GuestTripSnapshot trip) async {
    await list();
    _trips.removeWhere((existing) => existing.id == trip.id);
    _trips.insert(0, trip);
    if (_trips.length > 100) _trips = _trips.take(100).toList();
    final local = await _persist();
    if (!cloudSync) return local;
    final remote = await CloudTripStore.instance.save(trip);
    return local || remote;
  }

  Future<bool> delete(String id) async {
    await list();
    deleteWarning = null;
    _trips.removeWhere((trip) => trip.id == id);
    final local = await _persist();
    if (!cloudSync) return local;
    final remote = await CloudTripStore.instance.delete(id);
    if (!remote) {
      _deleted.add(id);
      await _saveDeleted();
      deleteWarning =
          'No se pudo borrar en la nube (${CloudTripStore.instance.lastError ?? 'error'}). Se ocultó aquí y lo reintentaremos.';
    }
    return local || remote;
  }

  Future<bool> _persist() async {
    try {
      await _storage.setString(
        _key,
        jsonEncode({
          'schema_version': 1,
          'trips': [for (final trip in _trips) trip.toJson()],
        }),
      );
      storageAvailable = true;
      return true;
    } catch (_) {
      storageAvailable = false;
      return false;
    }
  }
}
