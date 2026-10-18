import 'dart:convert';
import 'dart:io';
import 'package:latlong2/latlong.dart';

import '../../../core/config/mapbox_config.dart';
import 'osm_stops.dart';

/// Fetches turn-by-turn road geometry from Mapbox Directions API so routes follow streets.
final class MapboxRoadService {
  static String get _token => MapboxConfig.token;

  // In-memory cache to avoid duplicate network roundtrips for the same segment
  static final _cache = <String, List<LatLng>>{};

  // Shared HTTP client with connection pooling and keep-alive
  static final _httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 4);

  /// Returns a detailed polyline following actual street geometry between [origin] and [destination].
  /// [mode] can be 'walking' or 'driving'.
  static Future<List<LatLng>> getRoadRoute({
    required LatLng origin,
    required LatLng destination,
    required String mode, // 'walking' | 'driving'
  }) async {
    final cacheKey =
        '$mode:${origin.latitude.toStringAsFixed(5)},${origin.longitude.toStringAsFixed(5)}->${destination.latitude.toStringAsFixed(5)},${destination.longitude.toStringAsFixed(5)}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final url =
        'https://api.mapbox.com/directions/v5/mapbox/$mode/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?geometries=geojson&overview=full&access_token=$_token';

    try {
      final request = await _httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        return [origin, destination];
      }
      final responseBody = await response.transform(utf8.decoder).join();

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        return [origin, destination];
      }

      final geometry = routes[0]['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.isEmpty) {
        return [origin, destination];
      }

      final points = <LatLng>[];
      for (final coord in coordinates) {
        if (coord is List && coord.length >= 2) {
          final lon = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          points.add(LatLng(lat, lon));
        }
      }

      if (points.isNotEmpty) {
        _cache[cacheKey] = points;
        return points;
      }
    } catch (_) {}

    return [origin, destination];
  }

  // In-memory cache for reverse geocoding results
  static final _geoCache = <String, String>{};

  /// Returns the human-readable address or landmark name for [point].
  static Future<String> reverseGeocode(LatLng point) async {
    final key = '${point.latitude.toStringAsFixed(4)},${point.longitude.toStringAsFixed(4)}';
    if (_geoCache.containsKey(key)) {
      return _geoCache[key]!;
    }

    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/'
        '${point.longitude},${point.latitude}.json'
        '?types=address,poi,neighborhood,locality&language=es&access_token=$_token';

    try {
      final request = await _httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>?;
        if (features != null && features.isNotEmpty) {
          final placeName = features[0]['place_name'] as String?;
          if (placeName != null && placeName.isNotEmpty) {
            // Shorten to street and district (e.g. "Avenida Arequipa 381, Lima")
            final parts = placeName.split(',');
            final clean = parts.length > 2
                ? '${parts[0].trim()}, ${parts[1].trim()}'
                : placeName;
            _geoCache[key] = clean;
            return clean;
          }
        }
      }
    } catch (_) {}

    final fallback = 'Punto (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
    return fallback;
  }

  // In-memory cache for address search queries
  static final _searchCache = <String, List<OsmStop>>{};

  /// Searches streets, avenues, and landmarks in Lima using Mapbox Places forward geocoding.
  static Future<List<OsmStop>> searchAddresses(
    String query, {
    int limit = 5,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return const [];

    final cacheKey = cleanQuery.toLowerCase();
    if (_searchCache.containsKey(cacheKey)) {
      return _searchCache[cacheKey]!;
    }

    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/'
        '${Uri.encodeComponent(cleanQuery)}.json'
        '?country=pe&bbox=-77.25,-12.35,-76.70,-11.70&proximity=-77.0369,-12.0464'
        '&types=address,poi,neighborhood,locality,place&language=es&access_token=$_token';

    try {
      final request = await _httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>?;
        if (features != null && features.isNotEmpty) {
          final results = <OsmStop>[];
          for (final feature in features.take(limit)) {
            final center = feature['center'] as List<dynamic>?;
            final placeName = feature['place_name'] as String?;
            if (center != null && center.length >= 2 && placeName != null) {
              final lon = (center[0] as num).toDouble();
              final lat = (center[1] as num).toDouble();
              final parts = placeName.split(',');
              final shortName = parts.length > 2
                  ? '${parts[0].trim()}, ${parts[1].trim()}'
                  : placeName;
              results.add(
                OsmStop(
                  id: 'address:${lat.toStringAsFixed(6)}:${lon.toStringAsFixed(6)}',
                  name: shortName,
                  point: LatLng(lat, lon),
                  source: 'mapbox:geocoding',
                ),
              );
            }
          }
          if (results.isNotEmpty) {
            _searchCache[cacheKey] = results;
            return results;
          }
        }
      }
    } catch (_) {}

    return const [];
  }
}
