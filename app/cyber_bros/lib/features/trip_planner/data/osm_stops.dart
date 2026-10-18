import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// Community mapped point. Its operating status and route membership are unknown.
class OsmStop {
  const OsmStop({
    required this.id,
    required this.name,
    required this.point,
    required this.source,
  });

  final String id;
  final String? name;
  final LatLng point;
  final String source;

  String get displayName =>
      name?.isNotEmpty == true ? name! : 'Paradero sin nombre';

  /// A user-selected coordinate is a planning point, not an OSM stop.
  factory OsmStop.mapPoint(
    LatLng point, {
    bool currentLocation = false,
  }) => OsmStop(
    id: '${currentLocation ? 'location' : 'map'}:${point.latitude.toStringAsFixed(6)}:${point.longitude.toStringAsFixed(6)}',
    name: currentLocation
        ? 'Mi ubicación al elegirla'
        : '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
    point: point,
    source: currentLocation ? 'device-location' : 'user-map-selection',
  );
}

class OsmStopCatalog {
  const OsmStopCatalog._(this.stops);

  final List<OsmStop> stops;

  static Future<OsmStopCatalog> load() async {
    final text = await rootBundle.loadString('assets/data/osm_stops.json');
    final data = jsonDecode(text) as Map<String, dynamic>;
    return OsmStopCatalog._([
      for (final item in data['stops'] as List<dynamic>)
        OsmStop(
          id: item['id'] as String,
          name: item['name'] as String?,
          point: LatLng(
            (item['lat'] as num).toDouble(),
            (item['lon'] as num).toDouble(),
          ),
          source: item['source'] as String,
        ),
    ]);
  }

  List<OsmStop> search(String query, {int limit = 20}) {
    final needle = query.trim().toLowerCase();
    if (needle.length < 2) return const [];
    return stops
        .where((stop) => stop.name?.toLowerCase().contains(needle) ?? false)
        .take(limit)
        .toList();
  }

  OsmStop? findById(String id) {
    final parts = id.split(':');
    if (parts.length == 3 && (parts[0] == 'map' || parts[0] == 'location')) {
      final lat = double.tryParse(parts[1]);
      final lon = double.tryParse(parts[2]);
      if (lat != null && lon != null && lat.abs() <= 90 && lon.abs() <= 180) {
        return OsmStop.mapPoint(
          LatLng(lat, lon),
          currentLocation: parts[0] == 'location',
        );
      }
    }
    for (final stop in stops) {
      if (stop.id == id) return stop;
    }
    return null;
  }
}
