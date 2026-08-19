import 'package:latlong2/latlong.dart';

import '../models/city.dart';
import '../models/nearby_stop.dart';
import '../models/stop.dart';
import '../models/transit_line.dart';
import '../models/trip_plan.dart';
import '../models/vehicle_filter.dart';
import '../sample/sample_data.dart';
import '../schedule.dart';

/// Local data access. Swap the implementation later for GTFS / live APIs.
class TransitRepository {
  const TransitRepository();

  static const _distance = Distance();

  /// Nearby stops sit inside a 1 km diameter around the user (500 m radius).
  static const nearbyRadiusMeters = 500.0;
  static const nearbyStopLimit = 3;

  /// Home favourite lines: 3 closest within 10 km.
  static const favouriteLineRadiusMeters = 10000.0;
  static const favouriteLineLimit = 3;

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

  Stop? getStop(String id) {
    try {
      return SampleData.stops.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

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
    int? limit = nearbyStopLimit,
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
                  at: TransitSchedule.nextDeparture(
                    line.frequencyMinutes,
                    at,
                    line.dailyDepartureMinutes,
                  ),
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
    if (limit == null) return ranked;
    return ranked.take(limit).toList();
  }

  ({Stop stop, double meters})? closestStopOnLine(String lineId, LatLng from) {
    ({Stop stop, double meters})? best;
    for (final stop in getStops()) {
      if (!stop.lineIds.contains(lineId)) continue;
      final meters = _distance.as(LengthUnit.Meter, from, stop.location);
      if (best == null || meters < best.meters) {
        best = (stop: stop, meters: meters);
      }
    }
    return best;
  }

  List<TransitLine> closestFavouriteLines(
    Iterable<String> lineIds,
    LatLng from, {
    int limit = favouriteLineLimit,
    double maxMeters = favouriteLineRadiusMeters,
  }) {
    final ranked = <({TransitLine line, double meters})>[];
    for (final id in lineIds) {
      final line = getLine(id);
      if (line == null) continue;
      final closest = closestStopOnLine(line.id, from);
      if (closest == null || closest.meters > maxMeters) continue;
      ranked.add((line: line, meters: closest.meters));
    }
    ranked.sort((a, b) {
      final byDistance = a.meters.compareTo(b.meters);
      if (byDistance != 0) return byDistance;
      return a.line.name.compareTo(b.line.name);
    });
    return [for (final item in ranked.take(limit)) item.line];
  }

  List<TransitLine> linesMatching(VehicleFilter filter) {
    return getLines().where(filter.matchesLine).toList();
  }

  bool stopMatches(Stop stop, VehicleFilter filter) {
    if (filter == VehicleFilter.all) return true;
    return stop.lineIds
        .map(getLine)
        .whereType<TransitLine>()
        .any(filter.matchesLine);
  }

  /// Lines with a stop inside [maxMeters], closest first.
  List<({TransitLine line, double meters})> nearbyLines(
    LatLng from, {
    double maxMeters = nearbyRadiusMeters,
    VehicleFilter filter = VehicleFilter.all,
  }) {
    final ranked = <({TransitLine line, double meters})>[];
    for (final line in linesMatching(filter)) {
      final closest = closestStopOnLine(line.id, from);
      if (closest == null || closest.meters > maxMeters) continue;
      ranked.add((line: line, meters: closest.meters));
    }
    ranked.sort((a, b) {
      final byDistance = a.meters.compareTo(b.meters);
      if (byDistance != 0) return byDistance;
      return a.line.name.compareTo(b.line.name);
    });
    return ranked;
  }

  List<TransitLine> favouriteLinesMatching(
    Iterable<String> lineIds,
    VehicleFilter filter, {
    LatLng? from,
  }) {
    final lines = [
      for (final id in lineIds)
        if (getLine(id) case final line? when filter.matchesLine(line)) line,
    ];
    if (from == null) return lines;
    lines.sort((a, b) {
      final aMeters = closestStopOnLine(a.id, from)?.meters ?? double.infinity;
      final bMeters = closestStopOnLine(b.id, from)?.meters ?? double.infinity;
      final byDistance = aMeters.compareTo(bMeters);
      if (byDistance != 0) return byDistance;
      return a.name.compareTo(b.name);
    });
    return lines;
  }

  List<Stop> favouriteStopsMatching(
    Iterable<String> stopIds,
    VehicleFilter filter, {
    LatLng? from,
  }) {
    final stops = [
      for (final id in stopIds)
        if (getStop(id) case final stop? when stopMatches(stop, filter)) stop,
    ];
    if (from == null) return stops;
    stops.sort((a, b) {
      final aMeters = _distance.as(LengthUnit.Meter, from, a.location);
      final bMeters = _distance.as(LengthUnit.Meter, from, b.location);
      return aMeters.compareTo(bMeters);
    });
    return stops;
  }

  List<NearbyStop> nearbyStopsMatching(
    LatLng from,
    VehicleFilter filter, {
    DateTime? now,
  }) {
    return nearbyStops(from, limit: null, now: now)
        .where((item) => stopMatches(item.stop, filter))
        .toList();
  }

  Stop? closestStop(LatLng from, {double? maxMeters}) {
    Stop? best;
    var bestMeters = maxMeters ?? double.infinity;
    for (final stop in getStops()) {
      final meters = _distance.as(LengthUnit.Meter, from, stop.location);
      if (meters < bestMeters) {
        best = stop;
        bestMeters = meters;
      }
    }
    return best;
  }

  /// Walk + optional one-seat ride from [from] to [to].
  TripPlan planTrip({
    required LatLng from,
    required LatLng to,
    required String destinationLabel,
  }) {
    const maxWalkMeters = 1500.0;
    final board = closestStop(from, maxMeters: maxWalkMeters);
    final alight = closestStop(to, maxMeters: maxWalkMeters);

    TransitLine? shared;
    List<LatLng> ridePoints = const [];
    if (board != null &&
        alight != null &&
        board.id != alight.id) {
      for (final lineId in board.lineIds) {
        if (!alight.lineIds.contains(lineId)) continue;
        final line = getLine(lineId);
        if (line == null) continue;
        final segment = _segmentOnLine(line, board.location, alight.location);
        if (segment.length < 2) continue;
        shared = line;
        ridePoints = segment;
        break;
      }
    }

    final legs = <TripLeg>[];
    if (shared != null && board != null && alight != null) {
      final walkTo = _distance.as(LengthUnit.Meter, from, board.location);
      final walkFrom = _distance.as(LengthUnit.Meter, alight.location, to);
      if (walkTo > 30) {
        legs.add(
          TripLeg(
            label: 'Walk to ${board.name}',
            points: [from, board.location],
            meters: walkTo,
          ),
        );
      }
      legs.add(
        TripLeg(
          label: '${shared.modeLabel} ${shared.number}',
          points: ridePoints,
          line: shared,
          fromStop: board,
          toStop: alight,
        ),
      );
      if (walkFrom > 30) {
        legs.add(
          TripLeg(
            label: 'Walk to $destinationLabel',
            points: [alight.location, to],
            meters: walkFrom,
          ),
        );
      }
    } else {
      final meters = _distance.as(LengthUnit.Meter, from, to);
      legs.add(
        TripLeg(
          label: 'To $destinationLabel',
          points: [from, to],
          meters: meters,
        ),
      );
    }

    return TripPlan(
      origin: from,
      destination: to,
      destinationLabel: destinationLabel,
      legs: legs,
    );
  }

  List<LatLng> _segmentOnLine(TransitLine line, LatLng start, LatLng end) {
    if (line.stops.length < 2) return [start, end];

    int nearest(LatLng point) {
      var best = 0;
      var bestMeters = double.infinity;
      for (var i = 0; i < line.stops.length; i++) {
        final meters = _distance.as(LengthUnit.Meter, point, line.stops[i]);
        if (meters < bestMeters) {
          best = i;
          bestMeters = meters;
        }
      }
      return best;
    }

    final fromIndex = nearest(start);
    final toIndex = nearest(end);
    if (fromIndex == toIndex) return [line.stops[fromIndex]];
    if (fromIndex < toIndex) {
      return line.stops.sublist(fromIndex, toIndex + 1);
    }
    return line.stops.sublist(toIndex, fromIndex + 1).reversed.toList();
  }
}
