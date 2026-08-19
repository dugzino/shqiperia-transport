import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soar_albania/core/favorites/favorites_controller.dart';
import 'package:soar_albania/core/favorites/favorites_scope.dart';
import 'package:soar_albania/core/location/location_controller.dart';
import 'package:soar_albania/core/location/location_scope.dart';
import 'package:soar_albania/core/theme/app_theme.dart';
import 'package:soar_albania/data/repositories/transit_repository.dart';
import 'package:soar_albania/features/home/home_screen.dart';

void main() {
  testWidgets('asks for location to show nearby stops', (tester) async {
    final location = LocationController();
    location.debugOverride(status: LocationStatus.denied);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LocationScope(
          controller: location,
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nearby stops (<1km)'), findsOneWidget);
    expect(find.byTooltip('Refresh nearby stops'), findsOneWidget);
    expect(find.text('See nearby stops'), findsOneWidget);
    expect(find.text('Allow location'), findsOneWidget);
  });

  testWidgets('keeps the nearby title while searching for a GPS fix', (
    tester,
  ) async {
    final location = LocationController();
    location.debugOverride(status: LocationStatus.requesting);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LocationScope(
          controller: location,
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nearby stops (<1km)'), findsOneWidget);
    expect(find.text('Finding nearby stops…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('lists nearby stop and next departure after a GPS fix', (
    tester,
  ) async {
    final location = LocationController();
    location.debugOverride(
      status: LocationStatus.granted,
      position: const LatLng(42.6629, 21.1655),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LocationScope(
          controller: location,
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nearby stops (<1km)'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.text('Rr. Agim Ramadani - Përballë Teatrit'), findsOneWidget);
  });

  testWidgets('shows more nearby stops after tapping Show more', (
    tester,
  ) async {
    const from = LatLng(42.6629, 21.1655);
    const repo = TransitRepository();
    final all = repo.nearbyStops(from, limit: null);
    expect(all.length, greaterThan(3));
    final extra = all[3].stop.name;

    final location = LocationController();
    location.debugOverride(
      status: LocationStatus.granted,
      position: from,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LocationScope(
          controller: location,
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Show more'), findsOneWidget);
    expect(find.text(extra), findsNothing);

    await tester.ensureVisible(find.text('Show more'));
    await tester.pump();
    await tester.tap(find.text('Show more'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.ensureVisible(find.text(extra));
    expect(find.text(extra), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('shows favourite lines in the same list style as nearby stops', (
    tester,
  ) async {
    final favorites = FavoritesController();
    favorites.debugSet(['pr-1']);
    final location = LocationController();
    location.debugOverride(
      status: LocationStatus.granted,
      position: const LatLng(42.6629, 21.1655),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: FavoritesScope(
          controller: favorites,
          child: LocationScope(
            controller: location,
            child: const HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Favourite lines'), findsOneWidget);
    expect(find.byTooltip('Edit favourites'), findsOneWidget);
    expect(find.text('Royal Mall – St. Hekurudhor'), findsWidgets);
    expect(find.text('Next departure'), findsOneWidget);
    expect(find.text('Then'), findsOneWidget);
    expect(find.text('No favourite lines yet'), findsNothing);
    expect(find.text('Cities'), findsNothing);
    expect(find.textContaining('Lines in'), findsNothing);
  });

  testWidgets('shows only the 3 closest favourite lines within 10 km', (
    tester,
  ) async {
    final favorites = FavoritesController();
    favorites.debugSet(['tr-l1', 'pr-1', 'pr-4', 'pr-7', 'pr-ic-prizren']);
    final location = LocationController();
    location.debugOverride(
      status: LocationStatus.granted,
      position: const LatLng(42.6629, 21.1655),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: FavoritesScope(
          controller: favorites,
          child: LocationScope(
            controller: location,
            child: const HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Kombinat – Kinostudio'), findsNothing);
    expect(find.text('Pristina – Prizren'), findsNothing);
    expect(find.text('Royal Mall – St. Hekurudhor'), findsWidgets);
    expect(find.text('Xhamia në Mat – Parku i Gërmisë'), findsWidgets);
    expect(find.text('Kolovica – 7 Marsi'), findsWidgets);
  });

  testWidgets('prompts to star a line when there are no favourites', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Favourite lines'), findsOneWidget);
    expect(find.text('No favourite lines yet'), findsOneWidget);
  });
}
