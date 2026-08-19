import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soar_albania/app.dart';
import 'package:soar_albania/core/favorites/favorites_controller.dart';
import 'package:soar_albania/core/favorites/favorites_scope.dart';
import 'package:soar_albania/core/location/location_controller.dart';
import 'package:soar_albania/core/theme/app_theme.dart';
import 'package:soar_albania/data/models/saved_address.dart';
import 'package:soar_albania/data/repositories/transit_repository.dart';
import 'package:soar_albania/features/shell/main_shell.dart';

void main() {
  testWidgets('opens on Lines even though Transit is the first tab', (
    tester,
  ) async {
    await tester.pumpWidget(const SoarAlbaniaApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Where to?'), findsNothing);
    expect(find.widgetWithText(AppBar, 'Lines'), findsOneWidget);
  });

  testWidgets('Transit tab shows Where to and a grab bar', (tester) async {
    await tester.pumpWidget(const SoarAlbaniaApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Transit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Where to?'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Lines'), findsNothing);
    expect(find.byKey(const Key('saved-address-home')), findsNothing);
    expect(find.byKey(const Key('saved-address-work')), findsNothing);
    expect(find.byIcon(Icons.home_rounded), findsNothing);
    expect(find.byIcon(Icons.work_rounded), findsNothing);
    expect(find.text('No addresses saved yet.'), findsOneWidget);
    expect(find.text('Add a place'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Add a place'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.widgetWithText(AppBar, 'Edit favourites'), findsOneWidget);
    expect(find.text('Add place'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
  });

  testWidgets('grab bar reveals favourite stops on a grey sheet', (
    tester,
  ) async {
    final favorites = FavoritesController();
    favorites.debugSetStops(['rr-agim-ramadani-perballe-teatrit']);

    await tester.pumpWidget(
      FavoritesScope(
        controller: favorites,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MainShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Transit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Rr. Agim Ramadani - Përballë Teatrit'), findsNothing);

    await tester.tap(find.byKey(const Key('transit-sheet-handle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('Rr. Agim Ramadani - Përballë Teatrit'),
      findsOneWidget,
    );
    expect(find.text('Favourite stops'), findsOneWidget);
    expect(find.text('Nearby stops (<1km)'), findsOneWidget);
    expect(find.text('No favourite stops yet'), findsNothing);

    await tester.tap(find.text('Rr. Agim Ramadani - Përballë Teatrit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Favourite stops'), findsOneWidget);
    expect(
      find.text('Rr. Agim Ramadani - Përballë Teatrit'),
      findsOneWidget,
    );
  });

  testWidgets('expanded sheet lists nearby stops like the Stops tab', (
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
        home: MainShell(location: location),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Transit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('transit-sheet-handle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Favourite stops'), findsOneWidget);
    expect(find.text('Nearby stops (<1km)'), findsOneWidget);
    expect(find.text('Bus'), findsOneWidget);
    expect(find.text('Intercity Bus'), findsOneWidget);
    expect(find.text('Train'), findsOneWidget);
    expect(find.text('No favourite stops yet'), findsOneWidget);
    expect(find.byTooltip('Refresh nearby stops'), findsOneWidget);
    expect(find.byTooltip('Edit favourites'), findsOneWidget);
  });

  testWidgets('saved addresses appear as icon and title chips', (tester) async {
    final favorites = FavoritesController();
    favorites.debugSetAddresses(const [
      SavedAddress(id: 'home', name: 'Home', details: 'Prishtinë'),
      SavedAddress(id: 'place-1', name: 'Gym', details: 'Sunny Hill'),
    ]);

    await tester.pumpWidget(
      FavoritesScope(
        controller: favorites,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MainShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Transit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('saved-address-home')), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byKey(const Key('saved-address-work')), findsNothing);
    expect(find.byIcon(Icons.work_rounded), findsNothing);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Work'), findsNothing);
    expect(find.text('Prishtinë'), findsNothing);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Sunny Hill'), findsNothing);
    expect(find.text('No addresses saved yet.'), findsNothing);
    expect(find.text('Add a place'), findsNothing);
  });

  testWidgets('tapping a saved address plans a route there', (tester) async {
    const repo = TransitRepository();
    final line = repo.getLine('pr-1')!;
    final origin = line.stops.first;
    final destination = line.stops.last;

    final location = LocationController();
    location.debugOverride(
      status: LocationStatus.granted,
      position: origin,
    );
    final favorites = FavoritesController();
    favorites.debugSetAddresses([
      SavedAddress(
        id: 'home',
        name: 'Home',
        details: 'Bregu i Diellit',
        lat: destination.latitude,
        lng: destination.longitude,
      ),
    ]);

    await tester.pumpWidget(
      FavoritesScope(
        controller: favorites,
        child: MaterialApp(
          theme: AppTheme.light,
          home: MainShell(location: location),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Transit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('saved-address-home')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('trip-card')), findsOneWidget);
    expect(find.text('To Home'), findsOneWidget);
    expect(find.text('Your location'), findsOneWidget);
  });
}
