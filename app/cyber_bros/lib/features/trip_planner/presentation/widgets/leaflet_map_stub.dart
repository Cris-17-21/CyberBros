import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

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
}) {
  return const ColoredBox(
    color: Color(0xFFE8E6E1),
    child: Center(
      child: Text('El mapa web solo está disponible en navegador.'),
    ),
  );
}
