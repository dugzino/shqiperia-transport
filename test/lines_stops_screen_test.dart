import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soar_albania/core/favorites/favorites_controller.dart';
import 'package:soar_albania/core/favorites/favorites_scope.dart';
import 'package:soar_albania/core/location/location_controller.dart';
import 'package:soar_albania/core/location/location_scope.dart';
import 'package:soar_albania/core/theme/app_theme.dart';
import 'package:soar_albania/features/lines/lines_screen.dart';
import 'package:soar_albania/features/stops/stops_screen.dart';

void main() {
  Widget wrap({
    required Widget home,
    FavoritesController? favorites,
    LocationController? location,
  }) {
    final favs = favorites ?? (FavoritesController()..debugSet(const []));
    Widget child = FavoritesScope(
      controller: favs,
      child: MaterialApp(theme: AppTheme.light, home: home),
    );
    if (location != null) {
      child = FavoritesScope(
        controller: favs,
        child: MaterialApp(
          theme: AppTheme.light,
          home: LocationScope(controller: location, child: home),
        ),
      );
    }
    return child;
  }

  testWidgets('Lines shows favourite and nearby sections with vehicle tabs', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(home: const LinesScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Favourite lines'), findsOneWidget);
    expect(find.text('Nearby lines (<1km)'), findsOneWidget);
    expect(find.byTooltip('Edit favourites'), findsOneWidget);
    expect(find.byTooltip('Refresh nearby lines'), findsOneWidget);
    expect(find.text('Bus'), findsOneWidget);
    expect(find.text('Intercity Bus'), findsOneWidget);
    expect(find.text('Train'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('Stops shows favourite and nearby sections with vehicle tabs', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(home: const StopsScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Favourite stops'), findsOneWidget);
    expect(find.text('Nearby stops (<1km)'), findsOneWidget);
    expect(find.byTooltip('Edit favourites'), findsOneWidget);
    expect(find.byTooltip('Refresh nearby stops'), findsOneWidget);
    expect(find.text('Bus'), findsOneWidget);
    expect(find.text('Intercity Bus'), findsOneWidget);
    expect(find.text('Train'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('Lines previews 3 nearby bus lines then Show more', (
    tester,
  ) async {
    final location = LocationController();
    location.debugOverride(
      status: LocationStatus.granted,
      position: const LatLng(42.6629, 21.1655),
    );

    await tester.pumpWidget(
      wrap(home: const LinesScreen(), location: location),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Show more'), findsOneWidget);
  });

  testWidgets('Stops previews 3 nearby bus stops then Show more', (
    tester,
  ) async {
    final location = LocationController();
    location.debugOverride(
      status: LocationStatus.granted,
      position: const LatLng(42.6629, 21.1655),
    );

    await tester.pumpWidget(
      wrap(home: const StopsScreen(), location: location),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Show more'), findsOneWidget);
  });

  testWidgets('Train tab filters nearby only, not favourites', (tester) async {
    final favorites = FavoritesController();
    favorites.debugSet(['pr-1']);
    final location = LocationController();
    location.debugOverride(
      status: LocationStatus.granted,
      position: const LatLng(42.6629, 21.1655),
    );

    await tester.pumpWidget(
      wrap(
        home: const LinesScreen(),
        favorites: favorites,
        location: location,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Royal Mall – St. Hekurudhor'), findsWidgets);

    await tester.ensureVisible(find.text('Train'));
    await tester.tap(find.text('Train'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Royal Mall – St. Hekurudhor'), findsOneWidget);
    expect(find.text('No lines nearby'), findsOneWidget);
    expect(find.text('Show more'), findsNothing);
  });
}
