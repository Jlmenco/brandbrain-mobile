import 'package:flutter_test/flutter_test.dart';
import 'package:brandbrain_mobile/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const BrandBrainApp());
    expect(find.byType(BrandBrainApp), findsOneWidget);
  });
}
