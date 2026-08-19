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

    test('returns the next two headways', () {
      final now = DateTime(2026, 8, 18, 8, 7);
      final next = TransitSchedule.nextDepartures(12, count: 2, now: now);
      expect(next, [
        DateTime(2026, 8, 18, 8, 12),
        DateTime(2026, 8, 18, 8, 24),
      ]);
    });

    test('uses Trainkos fixed times for Prishtinë–Pejë', () {
      const times = [5 * 60 + 32, 7 * 60 + 50, 12 * 60 + 10, 16 * 60 + 30];
      expect(
        TransitSchedule.nextDailyDeparture(times, DateTime(2026, 8, 19, 8, 0)),
        DateTime(2026, 8, 19, 12, 10),
      );
      expect(
        TransitSchedule.nextDailyDeparture(times, DateTime(2026, 8, 19, 17, 0)),
        DateTime(2026, 8, 20, 5, 32),
      );
    });
  });

  test('sample data includes the Prishtinë–Pejë train', () {
    const repo = TransitRepository();
    final line = repo.getLine('pr-train-peje');
    expect(line, isNotNull);
    expect(line!.mode.name, 'train');
    expect(line.frequencyLabel, '2 round trips / day');
    expect(line.stopSlugs.first, 'rail-prishtine');
    expect(line.stopSlugs.last, 'rail-peje');
    expect(repo.getStop('rail-peje')?.name, 'Pejë');
    expect(repo.getStop('st-hekurudhor')?.lineIds, contains('pr-train-peje'));
  });

  group('TransitRepository planTrip', () {
    const repo = TransitRepository();

    test('uses a shared line between two stops on the same route', () {
      final line = repo.getLine('pr-1')!;
      final plan = repo.planTrip(
        from: line.stops.first,
        to: line.stops.last,
        destinationLabel: 'Home',
      );

      expect(plan.destinationLabel, 'Home');
      expect(plan.legs.any((leg) => leg.line?.id == 'pr-1'), isTrue);
    });

    test('falls back to a direct walk when no ride connects', () {
      const from = LatLng(42.6629, 21.1655);
      const to = LatLng(41.3275, 19.8187);
      final plan = repo.planTrip(
        from: from,
        to: to,
        destinationLabel: 'Tirana',
      );

      expect(plan.legs, hasLength(1));
      expect(plan.legs.single.isTransit, isFalse);
      expect(plan.legs.single.label, 'To Tirana');
    });
  });

  group('TransitRepository nearby', () {
    const repo = TransitRepository();

    test('ranks Pristina square first from the city center', () {
      const from = LatLng(42.6629, 21.1655);
      final nearby = repo.nearbyStops(from, now: DateTime(2026, 8, 18, 9));
      expect(nearby, isNotEmpty);
      expect(nearby.first.stop.name, 'Rr. Agim Ramadani - Përballë Teatrit');
      expect(nearby.first.meters, lessThan(80));
      expect(nearby.first.departures, isNotEmpty);
    });

    test('keeps nearby stops inside a 1 km diameter', () {
      const from = LatLng(42.6629, 21.1655);
      final nearby = repo.nearbyStops(from);
      expect(nearby, isNotEmpty);
      expect(nearby, hasLength(lessThanOrEqualTo(3)));
      expect(
        nearby.every((stop) => stop.meters <= 500),
        isTrue,
      );
      expect(
        nearby.map((stop) => stop.stop.name),
        isNot(contains('Terminali i Autobusëve')),
      );
    });

    test('can return every stop inside the nearby radius', () {
      const from = LatLng(42.6629, 21.1655);
      final preview = repo.nearbyStops(from);
      final all = repo.nearbyStops(from, limit: null);
      expect(preview, hasLength(3));
      expect(all.length, greaterThan(3));
      expect(
        all.every((stop) => stop.meters <= 500),
        isTrue,
      );
    });

    test('picks Tirana as the nearest city from Skanderbeg Square', () {
      const from = LatLng(41.3275, 19.8187);
      expect(repo.nearestCity(from).id, 'tirana');
    });
  });

  group('TransitRepository favourite lines', () {
    const repo = TransitRepository();
    const pristina = LatLng(42.6629, 21.1655);

    test('keeps only the 3 closest favourites within 10 km', () {
      final closest = repo.closestFavouriteLines(
        const ['pr-1', 'pr-4', 'pr-7', 'pr-ic-prizren', 'tr-l1'],
        pristina,
      );
      expect(closest, hasLength(3));
      expect(closest.map((line) => line.id).toSet(), {'pr-1', 'pr-4', 'pr-7'});
      expect(
        closest.every((line) {
          final meters = repo.closestStopOnLine(line.id, pristina)?.meters;
          return meters != null && meters <= 10000;
        }),
        isTrue,
      );
    });

    test('drops a favourite whose closest stop is beyond 10 km', () {
      final closest = repo.closestFavouriteLines(const ['tr-l1'], pristina);
      expect(closest, isEmpty);
    });
  });
}
