import 'package:flutter_test/flutter_test.dart';
import 'package:campusflow_ai/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusFlowApp());
    expect(find.text('CampusFlow AI'), findsOneWidget);
  });
}
