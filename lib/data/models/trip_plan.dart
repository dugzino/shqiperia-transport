import 'package:latlong2/latlong.dart';

import 'stop.dart';
import 'transit_line.dart';

class TripLeg {
  const TripLeg({
    required this.label,
    required this.points,
    this.meters,
    this.line,
    this.fromStop,
    this.toStop,
  });

  final String label;
  final List<LatLng> points;
  final double? meters;
  final TransitLine? line;
  final Stop? fromStop;
  final Stop? toStop;

  bool get isTransit => line != null;
}

class TripPlan {
  const TripPlan({
    required this.origin,
    required this.destination,
    required this.destinationLabel,
    required this.legs,
  });

  final LatLng origin;
  final LatLng destination;
  final String destinationLabel;
  final List<TripLeg> legs;

  List<LatLng> get path {
    return [
      origin,
      for (final leg in legs) ...leg.points,
      destination,
    ];
  }
}
