import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_albania/core/favorites/favorites_controller.dart';
import 'package:soar_albania/core/favorites/favorites_scope.dart';
import 'package:soar_albania/core/theme/app_theme.dart';
import 'package:soar_albania/data/models/saved_address.dart';
import 'package:soar_albania/features/home/edit_favourites_screen.dart';
import 'package:soar_albania/features/shell/main_shell.dart';

void main() {
  FavoritesController controllerWithAddresses([
    List<SavedAddress> addresses = const [],
  ]) {
    final favorites = FavoritesController();
    favorites.debugSetAddresses(addresses);
    return favorites;
  }

  Widget wrapEditor(FavoritesController favorites) {
    return FavoritesScope(
      controller: favorites,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const EditFavouritesScreen(initialTab: FavouritesTab.places),
      ),
    );
  }

  Widget wrapShell(FavoritesController favorites) {
    return FavoritesScope(
      controller: favorites,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const MainShell(),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  test('displayAddresses always starts with empty Home and Work', () {
    final favorites = controllerWithAddresses();

    expect(
      favorites.displayAddresses.map((address) => address.id),
      [SavedAddress.homeId, SavedAddress.workId],
    );
    expect(favorites.displayAddresses.every((address) => !address.isSet), isTrue);
    expect(favorites.addresses, isEmpty);
  });

  test('custom places follow Home and Work', () {
    final favorites = controllerWithAddresses(const [
      SavedAddress(id: 'place-1', name: 'Gym', details: 'Sunny Hill'),
      SavedAddress(id: 'home', name: 'Home', details: 'Prishtinë'),
    ]);

    expect(
      favorites.displayAddresses.map((address) => address.id),
      [SavedAddress.homeId, SavedAddress.workId, 'place-1'],
    );
    expect(favorites.displayAddresses[0].details, 'Prishtinë');
    expect(favorites.displayAddresses[1].isSet, isFalse);
    expect(favorites.displayAddresses[2].name, 'Gym');
  });

  testWidgets('Home can be set from Edit favourites', (tester) async {
    final favorites = controllerWithAddresses();
    await tester.pumpWidget(wrapEditor(favorites));
    await tester.pump();

    await tester.tap(find.text('Home'));
    await settle(tester);

    expect(find.widgetWithText(AppBar, 'Home'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('address-details-field')),
      'Bregu i Diellit',
    );
    await tester.tap(find.byKey(const Key('address-save')));
    await settle(tester);

    expect(favorites.addresses.single.id, SavedAddress.homeId);
    expect(favorites.addresses.single.details, 'Bregu i Diellit');
    expect(find.widgetWithText(AppBar, 'Edit favourites'), findsOneWidget);
    expect(find.text('Bregu i Diellit'), findsOneWidget);
    expect(find.text('Set address'), findsOneWidget);
  });

  testWidgets('custom place can be added and removed', (tester) async {
    final favorites = controllerWithAddresses();
    await tester.pumpWidget(wrapEditor(favorites));
    await tester.pump();

    await tester.tap(find.text('Add place'));
    await settle(tester);

    expect(find.widgetWithText(AppBar, 'New place'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('address-name-field')), 'Gym');
    await tester.enterText(
      find.byKey(const Key('address-details-field')),
      'Sunny Hill',
    );
    await tester.tap(find.byKey(const Key('address-save')));
    await settle(tester);

    expect(favorites.displayAddresses.map((address) => address.name), [
      'Home',
      'Work',
      'Gym',
    ]);
    expect(find.widgetWithText(AppBar, 'Edit favourites'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Sunny Hill'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove place'));
    await tester.pump();

    expect(favorites.addresses, isEmpty);
    expect(find.text('Gym'), findsNothing);
  });

  testWidgets('Transit shows Home and Work as icons and custom titles', (
    tester,
  ) async {
    final favorites = controllerWithAddresses(const [
      SavedAddress(id: 'place-1', name: 'Parents', details: 'Prizren'),
    ]);
    await tester.pumpWidget(wrapShell(favorites));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Transit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('saved-address-home')), findsNothing);
    expect(find.byKey(const Key('saved-address-work')), findsNothing);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Work'), findsNothing);
    expect(find.text('Parents'), findsOneWidget);
    expect(find.text('Prizren'), findsNothing);
    expect(find.text('Add a place'), findsNothing);
  });
}
