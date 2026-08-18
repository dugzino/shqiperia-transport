import 'package:latlong2/latlong.dart';

import '../models/city.dart';
import '../models/nearby_stop.dart';
import '../models/stop.dart';
import '../models/transit_line.dart';
import '../sample/sample_data.dart';
import '../schedule.dart';

/// Local data access. Swap the implementation later for GTFS / live APIs.
class TransitRepository {
  const TransitRepository();

  static const _distance = Distance();
  static const nearbyRadiusMeters = 15000.0;

  List<City> getCities() => SampleData.cities;

  City? getCity(String id) {
    try {
      return SampleData.cities.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<TransitLine> getLines({String? cityId}) {
    if (cityId == null) return SampleData.lines;
    return SampleData.lines.where((l) => l.cityId == cityId).toList();
  }

  TransitLine? getLine(String id) {
    try {
      return SampleData.lines.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Stop> getStops() => SampleData.stops;

  List<Stop> searchStops(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return SampleData.stops;
    return SampleData.stops
        .where((s) => s.name.toLowerCase().contains(q))
        .toList();
  }

  List<TransitLine> searchLines(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return SampleData.lines;
    return SampleData.lines.where((l) {
      return l.number.toLowerCase().contains(q) ||
          l.name.toLowerCase().contains(q) ||
          (l.destination?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<City> searchCities(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return SampleData.cities;
    return SampleData.cities.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.nameLocal.toLowerCase().contains(q) ||
          c.countryLabel.toLowerCase().contains(q);
    }).toList();
  }

  City nearestCity(LatLng from) {
    final cities = getCities();
    return cities.reduce((best, city) {
      final bestMeters = _distance.as(LengthUnit.Meter, from, best.center);
      final cityMeters = _distance.as(LengthUnit.Meter, from, city.center);
      return cityMeters < bestMeters ? city : best;
    });
  }

  List<NearbyStop> nearbyStops(
    LatLng from, {
    int limit = 6,
    double maxMeters = nearbyRadiusMeters,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final ranked = getStops()
        .map((stop) {
          final meters = _distance.as(LengthUnit.Meter, from, stop.location);
          final departures = stop.lineIds
              .map(getLine)
              .whereType<TransitLine>()
              .map(
                (line) => StopDeparture(
                  line: line,
                  at: TransitSchedule.nextDeparture(line.frequencyMinutes, at),
                ),
              )
              .toList()
            ..sort((a, b) => a.at.compareTo(b.at));
          return NearbyStop(
            stop: stop,
            meters: meters,
            departures: departures,
          );
        })
        .where((stop) => stop.meters <= maxMeters)
        .toList()
      ..sort((a, b) => a.meters.compareTo(b.meters));
    return ranked.take(limit).toList();
  }
}
