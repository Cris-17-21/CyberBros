import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:web/web.dart' as web;

import '../../../../core/config/mapbox_config.dart';
import '../../data/osm_stops.dart';
import 'journey_map_leg.dart';

Widget buildLeafletMap({
  required bool showDemoRoute,
  String? routeId,
  OsmStop? selectedStop,
  List<JourneyMapLeg> journeyLegs = const [],
  LatLng? originPoint,
  LatLng? destinationPoint,
  ValueChanged<LatLng>? onTap,
}) => _LeafletMapView(
  showDemoRoute: showDemoRoute,
  routeId: routeId,
  selectedStop: selectedStop,
  journeyLegs: journeyLegs,
  originPoint: originPoint,
  destinationPoint: destinationPoint,
  onTap: onTap,
);

class _LeafletMapView extends StatefulWidget {
  const _LeafletMapView({
    required this.showDemoRoute,
    required this.routeId,
    required this.selectedStop,
    required this.journeyLegs,
    required this.originPoint,
    required this.destinationPoint,
    required this.onTap,
  });

  final bool showDemoRoute;
  final String? routeId;
  final OsmStop? selectedStop;
  final List<JourneyMapLeg> journeyLegs;
  final LatLng? originPoint;
  final LatLng? destinationPoint;
  final ValueChanged<LatLng>? onTap;

  @override
  State<_LeafletMapView> createState() => _LeafletMapViewState();
}

class _LeafletMapViewState extends State<_LeafletMapView> {
  late final String _token = DateTime.now().microsecondsSinceEpoch.toString();
  late final JSFunction _listener = _onMessage.toJS;

  @override
  void initState() {
    super.initState();
    web.window.addEventListener('message', _listener);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    super.dispose();
  }

  void _onMessage(web.Event event) {
    if (!event.isA<web.MessageEvent>()) {
      return;
    }
    final message = event as web.MessageEvent;
    final raw = message.data;
    if (message.origin != web.window.location.origin ||
        raw == null ||
        !raw.isA<JSString>()) {
      return;
    }
    try {
      final data = jsonDecode((raw as JSString).toDart);
      if (data is! Map<String, dynamic> ||
          data['type'] != 'cyberon-map-tap' ||
          data['token'] != _token) {
        return;
      }
      final lat = (data['lat'] as num).toDouble();
      final lon = (data['lon'] as num).toDouble();
      if (lat.abs() <= 90 && lon.abs() <= 180) {
        widget.onTap?.call(LatLng(lat, lon));
      }
    } catch (_) {
      // Ignore unrelated or malformed messages from the same origin.
    }
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: (Object element) {
      final frame = element as web.HTMLIFrameElement;
      frame
        ..src = Uri(
          path: 'leaflet_map.html',
          queryParameters: {
            'token': _token,
            if (MapboxConfig.token != 'MAPBOX_TOKEN_PLACEHOLDER')
              'mapboxToken': MapboxConfig.token,
            if (widget.showDemoRoute) 'demo': '1',
            'route': ?widget.routeId,
            'stopLat': ?widget.selectedStop?.point.latitude.toString(),
            'stopLon': ?widget.selectedStop?.point.longitude.toString(),
            'stopName': ?widget.selectedStop?.displayName,
            'originLat': ?widget.originPoint?.latitude.toString(),
            'originLon': ?widget.originPoint?.longitude.toString(),
            'destinationLat': ?widget.destinationPoint?.latitude.toString(),
            'destinationLon': ?widget.destinationPoint?.longitude.toString(),
            if (widget.journeyLegs.isNotEmpty)
              'journey': jsonEncode([
                for (final leg in widget.journeyLegs)
                  {
                    'from': [leg.from.latitude, leg.from.longitude],
                    'to': [leg.to.latitude, leg.to.longitude],
                    'kind': leg.kind.name,
                    if (leg.points != null && leg.points!.isNotEmpty)
                      'points': [
                        for (final p in leg.points!) [p.latitude, p.longitude]
                      ],
                  },
              ]),
          },
        ).toString()
        ..title = 'Mapa de Lima basado en OpenStreetMap'
        ..setAttribute('loading', 'lazy')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '0';
    },
  );
}
