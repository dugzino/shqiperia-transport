import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_albania/core/favorites/favorites_controller.dart';
import 'package:soar_albania/core/favorites/favorites_scope.dart';
import 'package:soar_albania/core/theme/app_theme.dart';
import 'package:soar_albania/features/home/home_screen.dart';

void main() {
  Widget app({FavoritesController? favorites}) {
    final controller = favorites ?? FavoritesController();
    if (!controller.isLoaded) controller.debugSet(const []);
    return FavoritesScope(
      controller: controller,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }

  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('edit icon opens a full-screen favourites editor', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byTooltip('Edit favourites'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit favourites'));
    await settleRoute(tester);

    expect(find.text('Edit favourites'), findsOneWidget);
    expect(find.text('Favourite lines'), findsWidgets);
    expect(find.text('Favourite stops'), findsOneWidget);
    expect(find.text('Add line'), findsOneWidget);
    expect(find.text('Add stop'), findsOneWidget);
    expect(
      find.text('No favourite lines yet. Add the routes you take often.'),
      findsOneWidget,
    );
    expect(
      find.text('No favourite stops yet. Pin a stop to find it quickly.'),
      findsOneWidget,
    );
  });

  testWidgets('adds a favourite line from the editor', (tester) async {
    final favorites = FavoritesController();
    favorites.debugSet(const []);

    await tester.pumpWidget(app(favorites: favorites));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Edit favourites'));
    await settleRoute(tester);

    await tester.tap(find.text('Add line'));
    await settleRoute(tester);

    expect(find.text('Add a line'), findsOneWidget);
    await tester.tap(find.text('Royal Mall – St. Hekurudhor'));
    await settleRoute(tester);

    expect(favorites.lineIds, ['pr-1']);
    expect(find.text('Royal Mall – St. Hekurudhor'), findsOneWidget);
    expect(find.byTooltip('Remove line'), findsOneWidget);
  });

  testWidgets('adds a favourite stop from the editor', (tester) async {
    final favorites = FavoritesController();
    favorites.debugSet(const []);

    await tester.pumpWidget(app(favorites: favorites));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Edit favourites'));
    await settleRoute(tester);

    await tester.tap(find.text('Add stop'));
    await settleRoute(tester);

    expect(find.text('Add a stop'), findsOneWidget);
    await tester.tap(find.text('"AlfaTrade" (Pompa)'));
    await settleRoute(tester);

    expect(favorites.stopIds, ['alfatrade-pompa']);
    expect(find.text('"AlfaTrade" (Pompa)'), findsOneWidget);
    expect(find.byTooltip('Remove stop'), findsOneWidget);
  });

  testWidgets('removes a favourite line from the editor', (tester) async {
    final favorites = FavoritesController();
    favorites.debugSet(['pr-1']);

    await tester.pumpWidget(app(favorites: favorites));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Edit favourites'));
    await settleRoute(tester);

    expect(find.text('Royal Mall – St. Hekurudhor'), findsWidgets);
    await tester.tap(find.byTooltip('Remove line'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(favorites.lineIds, isEmpty);
    expect(
      find.text('No favourite lines yet. Add the routes you take often.'),
      findsOneWidget,
    );
  });
}
