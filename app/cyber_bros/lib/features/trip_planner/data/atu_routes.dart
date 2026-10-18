import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// Published SIT centerlines. They do not contain ordered stops or fares.
class AtuRoute {
  const AtuRoute({
    required this.id,
    required this.name,
    required this.service,
    required this.segments,
  });

  final String id;
  final String name;
  final String service;
  final List<List<LatLng>> segments;
}

class AtuRouteCatalog {
  const AtuRouteCatalog._(this.routes);

  final List<AtuRoute> routes;

  static Future<AtuRouteCatalog> load() async {
    final text = await rootBundle.loadString('assets/data/atu_sit_routes.json');
    final data = jsonDecode(text) as Map<String, dynamic>;
    final entries = data['routes'] as List<dynamic>;
    return AtuRouteCatalog._([
      for (final entry in entries)
        AtuRoute(
          id: entry['id'] as String,
          name: entry['name'] as String,
          service: entry['service'] as String,
          segments: [
            for (final segment
                in (entry['geometry']['coordinates'] as List<dynamic>))
              [
                for (final coordinate in segment as List<dynamic>)
                  LatLng(
                    (coordinate[1] as num).toDouble(),
                    (coordinate[0] as num).toDouble(),
                  ),
              ],
          ],
        ),
    ]);
  }
}
