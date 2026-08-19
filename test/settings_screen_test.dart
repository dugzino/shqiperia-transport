import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_albania/core/favorites/favorites_controller.dart';
import 'package:soar_albania/core/favorites/favorites_scope.dart';
import 'package:soar_albania/core/location/location_controller.dart';
import 'package:soar_albania/core/location/location_scope.dart';
import 'package:soar_albania/core/theme/app_theme.dart';
import 'package:soar_albania/features/settings/settings_screen.dart';

void main() {
  Widget wrap({String version = '0.1.2'}) {
    final favorites = FavoritesController()..debugSet(const []);
    final location = LocationController();
    return FavoritesScope(
      controller: favorites,
      child: LocationScope(
        controller: location,
        child: MaterialApp(
          theme: AppTheme.light,
          home: SettingsScreen(appVersion: version),
        ),
      ),
    );
  }

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('Settings lists grouped items, login, and copyright version', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('My account settings'), findsOneWidget);
    expect(find.text('Edit my profile'), findsOneWidget);

    expect(find.text('App Settings'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Manage my favourites'), findsOneWidget);
    expect(find.text('Permissions'), findsOneWidget);

    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Features overview'), findsOneWidget);
    expect(find.text('How to use the app'), findsOneWidget);
    expect(find.text('Accessibility for PRM'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.text('Rate the app'), findsOneWidget);

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Terms of use'), findsOneWidget);
    expect(find.text('Accessibility compliance statement'), findsOneWidget);
    expect(find.text('Third-party licenses'), findsOneWidget);

    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    expect(find.text('Copyright Soar Albania @ 2026 v0.1.2'), findsOneWidget);
  });

  testWidgets('Manage my favourites opens the existing editor', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Manage my favourites'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Edit favourites'), findsOneWidget);
  });

  testWidgets('Third-party licenses lists OSM, not every package', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Third-party licenses'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.widgetWithText(AppBar, 'Third-party licenses'), findsOneWidget);
    expect(find.text('OpenStreetMap'), findsOneWidget);
    expect(find.text('Open Database License (ODbL)'), findsOneWidget);
    expect(find.text('Plus Jakarta Sans'), findsOneWidget);
    expect(find.text('collection'), findsNothing);
    expect(find.text('async'), findsNothing);
  });

  testWidgets('Log in shows a not-yet notice', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Log in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Sign-in is not available yet.'), findsOneWidget);
  });
}
