import 'package:flutter_test/flutter_test.dart';
import 'package:kosova_transit/app.dart';

void main() {
  testWidgets('App boots with home shell', (tester) async {
    await tester.pumpWidget(const KosovaTransitApp());
    await tester.pump(); // first frame
    // Allow google_fonts / async settle without hanging on network fonts.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Kosova Transit'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Lines'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });
}
