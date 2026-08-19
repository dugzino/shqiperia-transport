import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_albania/app.dart';
import 'package:soar_albania/core/favorites/favorites_controller.dart';
import 'package:soar_albania/core/favorites/favorites_scope.dart';
import 'package:soar_albania/core/theme/app_theme.dart';
import 'package:soar_albania/data/models/saved_address.dart';
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
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.text('Rr. Agim Ramadani - Përballë Teatrit'),
      findsOneWidget,
    );
    expect(
      find.text('No favourite stops yet. Star a stop from Edit favourites.'),
      findsNothing,
    );
  });

  testWidgets('saved addresses appear in the blue block', (tester) async {
    final favorites = FavoritesController();
    favorites.debugSetAddresses(const [
      SavedAddress(id: 'home', name: 'Home', details: 'Prishtinë'),
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

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Prishtinë'), findsOneWidget);
  });
}
