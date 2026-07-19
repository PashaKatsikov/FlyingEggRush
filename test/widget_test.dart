import 'package:flutter_test/flutter_test.dart';

import 'package:flyingeggrushgame/rookery/flight_deck.dart';

void main() {
  testWidgets('App boots into the flight deck root', (WidgetTester tester) async {
    await tester.pumpWidget(const FlightDeckApp());
    // First frame renders the boot loading label with animated dots.
    expect(find.textContaining('Loading'), findsOneWidget);
  });
}
