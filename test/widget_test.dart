import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_albania/app.dart';

void main() {
  testWidgets('App boots on Lines with the new tab bar', (tester) async {
    await tester.pumpWidget(const SoarAlbaniaApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Lines'), findsWidgets);
    expect(find.text('Transit'), findsOneWidget);
    expect(find.text('Stops'), findsOneWidget);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Search'), findsNothing);
    expect(find.text('Map'), findsNothing);
  });

  testWidgets('Tickets stays greyed and shows a not-yet notice', (tester) async {
    await tester.pumpWidget(const SoarAlbaniaApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Tickets'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Tickets are not available yet.'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Lines'), findsOneWidget);
  });
}
