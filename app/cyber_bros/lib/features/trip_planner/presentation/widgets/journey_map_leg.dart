import 'package:latlong2/latlong.dart';

enum JourneyLegKind { walk, bus, taxi }

final class JourneyMapLeg {
  const JourneyMapLeg(this.from, this.to, this.kind, {this.points});
  final LatLng from;
  final LatLng to;
  final JourneyLegKind kind;
  final List<LatLng>? points;
}
