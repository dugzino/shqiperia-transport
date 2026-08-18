import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soar_albania/data/repositories/transit_repository.dart';
import 'package:soar_albania/data/schedule.dart';

void main() {
  group('TransitSchedule', () {
    test('returns the next headway after now', () {
      final now = DateTime(2026, 8, 18, 8, 7);
      final next = TransitSchedule.nextDeparture(12, now);
      expect(next, DateTime(2026, 8, 18, 8, 12));
      expect(TransitSchedule.formatTime(next), '08:12');
      expect(TransitSchedule.minutesUntilLabel(next, now), '5 min');
    });

    test('rolls to the next morning after service ends', () {
      final now = DateTime(2026, 8, 18, 23, 10);
      final next = TransitSchedule.nextDeparture(15, now);
      expect(next, DateTime(2026, 8, 19, 5));
    });

    test('formats walking distance', () {
      expect(TransitSchedule.distanceLabel(180), '180 m');
      expect(TransitSchedule.distanceLabel(1500), '1.5 km');
    });
  });

  group('TransitRepository nearby', () {
    const repo = TransitRepository();

    test('ranks Pristina square first from the city center', () {
      const from = LatLng(42.6629, 21.1655);
      final nearby = repo.nearbyStops(from, now: DateTime(2026, 8, 18, 9));
      expect(nearby, isNotEmpty);
      expect(nearby.first.stop.name, 'Sheshi Skënderbeu');
      expect(nearby.first.meters, lessThan(50));
      expect(nearby.first.departures, isNotEmpty);
    });

    test('picks Tirana as the nearest city from Skanderbeg Square', () {
      const from = LatLng(41.3275, 19.8187);
      expect(repo.nearestCity(from).id, 'tirana');
    });
  });
}
