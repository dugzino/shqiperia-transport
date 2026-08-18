import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum TransitMode { bus, minibus, intercity }

class TransitLine {
  const TransitLine({
    required this.id,
    required this.number,
    required this.name,
    required this.cityId,
    required this.color,
    required this.mode,
    required this.stops,
    this.destination,
    this.frequencyMinutes = 20,
  });

  final String id;
  final String number;
  final String name;
  final String cityId;
  final Color color;
  final TransitMode mode;
  final List<LatLng> stops;
  final String? destination;
  final int frequencyMinutes;

  String get modeLabel => switch (mode) {
    TransitMode.bus => 'Bus',
    TransitMode.minibus => 'Minibus',
    TransitMode.intercity => 'Intercity',
  };

  IconData get modeIcon => switch (mode) {
    TransitMode.bus => Icons.directions_bus_rounded,
    TransitMode.minibus => Icons.airport_shuttle_rounded,
    TransitMode.intercity => Icons.directions_bus_filled_rounded,
  };
}
