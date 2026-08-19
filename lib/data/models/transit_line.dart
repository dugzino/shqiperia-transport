import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum TransitMode { bus, minibus, intercity, train }

class TransitLine {
  const TransitLine({
    required this.id,
    required this.number,
    required this.name,
    required this.cityId,
    required this.color,
    required this.mode,
    required this.stops,
    this.stopSlugs = const [],
    this.destination,
    this.frequencyMinutes = 20,
    this.dailyDepartureMinutes = const [],
    this.frequencyLabelOverride,
  });

  final String id;
  final String number;
  final String name;
  final String cityId;
  final Color color;
  final TransitMode mode;
  final List<LatLng> stops;
  final List<String> stopSlugs;
  final String? destination;
  final int frequencyMinutes;

  /// Minutes from midnight for fixed daily trips. Empty means headway-based.
  final List<int> dailyDepartureMinutes;
  final String? frequencyLabelOverride;

  String get frequencyLabel {
    if (frequencyLabelOverride != null) return frequencyLabelOverride!;
    if (dailyDepartureMinutes.isNotEmpty) {
      final n = dailyDepartureMinutes.length;
      return n == 1 ? '1 trip / day' : '$n trips / day';
    }
    return 'every $frequencyMinutes min';
  }

  String get modeLabel => switch (mode) {
    TransitMode.bus => 'Bus',
    TransitMode.minibus => 'Minibus',
    TransitMode.intercity => 'Intercity bus',
    TransitMode.train => 'Train',
  };

  IconData get modeIcon => switch (mode) {
    TransitMode.bus => Icons.directions_bus_rounded,
    TransitMode.minibus => Icons.airport_shuttle_rounded,
    TransitMode.intercity => Icons.directions_bus_filled_rounded,
    TransitMode.train => Icons.train_rounded,
  };
}
