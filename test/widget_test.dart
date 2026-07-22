import 'package:flutter_test/flutter_test.dart';
import 'package:wwngo_app/app.dart';

void main() {
  testWidgets('WWNGO app launches splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WwngoApp());
    await tester.pump();

    expect(find.text('WWNGO'), findsOneWidget);
    expect(find.text('Ship it with someone already going'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });
}
