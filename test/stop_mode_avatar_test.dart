import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_albania/core/theme/app_theme.dart';
import 'package:soar_albania/data/repositories/transit_repository.dart';
import 'package:soar_albania/features/widgets/stop_mode_avatar.dart';

void main() {
  const repo = TransitRepository();

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }

  test('classifies bus, intercity, and train stops', () {
    expect(
      transportKindsForStop(repo.getStop('rr-agim-ramadani-perballe-teatrit')!),
      [StopTransportKind.bus],
    );
    expect(
      transportKindsForStop(repo.getStop('rail-prishtine')!),
      [StopTransportKind.train],
    );
    expect(
      transportKindsForStop(repo.getStop('tr-skanderbeg')!),
      [StopTransportKind.bus, StopTransportKind.intercity],
    );
    expect(
      transportKindsForStop(repo.getStop('st-hekurudhor')!),
      [StopTransportKind.bus, StopTransportKind.train],
    );
  });

  testWidgets('single-mode stop shows one icon', (tester) async {
    await tester.pumpWidget(
      wrap(StopModeAvatar.forStop(repo.getStop('rail-prishtine')!)),
    );

    expect(find.byKey(const Key('stop-mode-train')), findsOneWidget);
    expect(find.byKey(const Key('stop-mode-bus')), findsNothing);
    expect(find.byIcon(Icons.train_rounded), findsOneWidget);
  });

  testWidgets('shared stop splits bus and train icons', (tester) async {
    await tester.pumpWidget(
      wrap(StopModeAvatar.forStop(repo.getStop('st-hekurudhor')!)),
    );

    expect(find.byKey(const Key('stop-mode-bus')), findsOneWidget);
    expect(find.byKey(const Key('stop-mode-train')), findsOneWidget);
    expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);
    expect(find.byIcon(Icons.train_rounded), findsOneWidget);
  });

  testWidgets('shared stop splits bus and intercity icons', (tester) async {
    await tester.pumpWidget(
      wrap(StopModeAvatar.forStop(repo.getStop('tr-skanderbeg')!)),
    );

    expect(find.byKey(const Key('stop-mode-bus')), findsOneWidget);
    expect(find.byKey(const Key('stop-mode-intercity')), findsOneWidget);
    expect(find.byIcon(Icons.directions_bus_filled_rounded), findsOneWidget);
  });
}
