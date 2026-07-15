import 'package:flutter_test/flutter_test.dart';

import 'package:flyingeggrushgame/main.dart';

void main() {
  testWidgets('App boots to the loading screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ChickenTimesApp());
    // The loading label with animated dots should be visible on first frame.
    expect(find.textContaining('Loading'), findsOneWidget);
  });
}
