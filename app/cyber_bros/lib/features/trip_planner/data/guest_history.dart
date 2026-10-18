import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/routing_engine.dart';
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

/// Guest-only local history. Storage failures keep the current visit usable.
final class GuestHistoryRepository {
  GuestHistoryRepository._();

  static final GuestHistoryRepository instance = GuestHistoryRepository._();
  static const _key = 'cyberon.guest.history.v1';
  final SharedPreferencesAsync _storage = SharedPreferencesAsync();
  List<GuestTripSnapshot> _trips = [];
  bool _loaded = false;
  bool storageAvailable = true;

  Future<List<GuestTripSnapshot>> list() async {
    if (!_loaded) {
      _loaded = true;
      try {
        final raw = await _storage.getString(_key);
        if (raw != null) {
          final payload = jsonDecode(raw) as Map<String, dynamic>;
          if (payload['schema_version'] == 1) {
            for (final item in payload['trips'] as List<dynamic>) {
              try {
                _trips.add(
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
      } catch (_) {
        storageAvailable = false;
      }
    }
    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 30));
    _trips.removeWhere((trip) => trip.createdAtUtc.isBefore(cutoff));
    _trips.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    return List.unmodifiable(_trips);
  }

  Future<bool> save(GuestTripSnapshot trip) async {
    await list();
    _trips.removeWhere((existing) => existing.id == trip.id);
    _trips.insert(0, trip);
    if (_trips.length > 100) _trips = _trips.take(100).toList();
    return _persist();
  }

  Future<bool> delete(String id) async {
    await list();
    _trips.removeWhere((trip) => trip.id == id);
    return _persist();
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
