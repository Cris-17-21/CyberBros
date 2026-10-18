import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/mapbox_config.dart';
import '../../../../core/theme/palette.dart';
import '../../data/atu_routes.dart';
import '../../data/osm_stops.dart';
import 'journey_map_leg.dart';
import 'leaflet_map_stub.dart'
    if (dart.library.js_interop) 'leaflet_map_web.dart'
    as web_map;

const limaCenter = LatLng(-12.0678, -77.0365);

class LimaMap extends StatelessWidget {
  const LimaMap({
    super.key,
    this.showDemoRoute = false,
    this.height = 320,
    this.borderRadius = 20,
    this.atuRoute,
    this.selectedStop,
    this.journeyLegs = const [],
    this.originPoint,
    this.destinationPoint,
    this.onTap,
    this.mapController,
  });

  final bool showDemoRoute;
  final double height;
  final double borderRadius;
  final AtuRoute? atuRoute;
  final OsmStop? selectedStop;
  final List<JourneyMapLeg> journeyLegs;
  final LatLng? originPoint;
  final LatLng? destinationPoint;
  final ValueChanged<LatLng>? onTap;
  final MapController? mapController;

  static const _origin = LatLng(-12.0678, -77.0365);
  static const _transfer = LatLng(-12.0781, -77.0418);
  static const _destination = LatLng(-12.0865, -77.0454);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return SizedBox(
        height: height.isFinite ? height : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: web_map.buildLeafletMap(
            showDemoRoute: showDemoRoute,
            routeId: atuRoute?.id,
            selectedStop: selectedStop,
            journeyLegs: journeyLegs,
            originPoint: originPoint,
            destinationPoint: destinationPoint,
            onTap: onTap,
          ),
        ),
      );
    }

    final routePoints = [_origin, _transfer, _destination];
    final journeyPoints = [
      for (final leg in journeyLegs) ...[leg.from, leg.to],
    ];

    return SizedBox(
      height: height.isFinite ? height : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            onTap: onTap == null ? null : (_, point) => onTap!(point),
            initialCenter:
                originPoint ??
                selectedStop?.point ??
                (journeyPoints.isEmpty ? limaCenter : journeyPoints.first),
            initialZoom: (originPoint != null || selectedStop != null)
                ? 15.5
                : journeyPoints.isEmpty
                ? 13.5
                : 14,
            initialCameraFit: journeyPoints.isEmpty
                ? null
                : CameraFit.coordinates(
                    coordinates: journeyPoints,
                    padding: const EdgeInsets.all(42),
                  ),
            minZoom: 5,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=${MapboxConfig.token}',
              userAgentPackageName: 'com.example.cyber_bros',
              maxNativeZoom: 22,
            ),
            if (showDemoRoute)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: Palette.primary,
                    strokeWidth: 5,
                  ),
                ],
              ),
            if (journeyLegs.isNotEmpty)
              PolylineLayer(
                polylines: [
                  for (final leg in journeyLegs)
                    Polyline(
                      points: leg.points ?? [leg.from, leg.to],
                      color: switch (leg.kind) {
                        JourneyLegKind.walk => Palette.inkMuted,
                        JourneyLegKind.bus => Palette.primaryDark,
                        JourneyLegKind.taxi => Palette.taxi,
                      },
                      strokeWidth: leg.kind == JourneyLegKind.walk ? 4 : 5,
                    ),
                ],
              ),
            // Marcadores de origen y destino sueltos (en pantalla de inicio o selección)
            if (journeyLegs.isEmpty && (originPoint != null || destinationPoint != null))
              MarkerLayer(
                markers: [
                  if (originPoint != null)
                    _mapMarker(
                      point: originPoint!,
                      color: Palette.primaryDark,
                      icon: Icons.my_location_rounded,
                    ),
                  if (destinationPoint != null)
                    _mapMarker(
                      point: destinationPoint!,
                      color: Palette.taxi,
                      icon: Icons.flag_rounded,
                    ),
                ],
              ),
            if (journeyLegs.isNotEmpty)
              MarkerLayer(
                markers: [
                  _mapMarker(
                    point: journeyLegs.first.from,
                    color: Palette.primaryDark,
                    icon: Icons.trip_origin_rounded,
                  ),
                  _mapMarker(
                    point: journeyLegs.last.to,
                    color: Palette.taxi,
                    icon: Icons.flag_rounded,
                  ),
                ],
              ),
            if (atuRoute != null)
              PolylineLayer(
                polylines: [
                  for (final segment in atuRoute!.segments)
                    Polyline(
                      points: segment,
                      color: Palette.primary,
                      strokeWidth: 4,
                    ),
                ],
              ),
            if (showDemoRoute)
              MarkerLayer(
                markers: [
                  _mapMarker(
                    point: _origin,
                    color: Palette.primary,
                    icon: Icons.trip_origin_rounded,
                  ),
                  _mapMarker(
                    point: _transfer,
                    color: Palette.confirmed,
                    icon: Icons.directions_bus_rounded,
                  ),
                  _mapMarker(
                    point: _destination,
                    color: Palette.taxi,
                    icon: Icons.flag_rounded,
                  ),
                ],
              ),
            if (selectedStop != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedStop!.point,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_on,
                      color: Palette.confirmed,
                      size: 42,
                    ),
                  ),
                ],
              ),
            if (originPoint != null || destinationPoint != null)
              MarkerLayer(
                markers: [
                  if (originPoint != null)
                    _mapMarker(
                      point: originPoint!,
                      color: Palette.primaryDark,
                      icon: Icons.trip_origin_rounded,
                    ),
                  if (destinationPoint != null)
                    _mapMarker(
                      point: destinationPoint!,
                      color: Palette.taxi,
                      icon: Icons.flag_rounded,
                    ),
                ],
              ),
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
                TextSourceAttribution('flutter_map'),
                if (atuRoute != null) TextSourceAttribution('Rutas SIT © ATU'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Marker _mapMarker({
  required LatLng point,
  required Color color,
  required IconData icon,
}) {
  return Marker(
    point: point,
    width: 42,
    height: 48,
    alignment: Alignment.topCenter,
    child: Icon(icon, color: color, size: 36),
  );
}
