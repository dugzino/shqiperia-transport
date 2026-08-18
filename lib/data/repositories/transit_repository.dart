import '../models/city.dart';
import '../models/stop.dart';
import '../models/transit_line.dart';
import '../sample/sample_data.dart';

/// Local data access. Swap the implementation later for GTFS / live APIs.
class TransitRepository {
  const TransitRepository();

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
}
