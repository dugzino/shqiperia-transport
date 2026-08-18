import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soar_albania/core/location/location_controller.dart';
import 'package:soar_albania/core/location/location_scope.dart';
import 'package:soar_albania/core/theme/app_theme.dart';
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

    expect(find.text('See nearby stops'), findsOneWidget);
    expect(find.text('Allow location'), findsOneWidget);
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

    expect(find.text('Nearby stops'), findsOneWidget);
    expect(find.text('Sheshi Skënderbeu'), findsOneWidget);
  });
}
