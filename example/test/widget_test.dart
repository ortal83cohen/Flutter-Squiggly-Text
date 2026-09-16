// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_squiggly_text_example/main.dart';

void main() {
  testWidgets('renders the example app', (WidgetTester tester) async {
    await tester.pumpWidget(const SquigglyTextExampleApp());

    expect(find.text('Interactive text preview'), findsOneWidget);
    expect(find.text('Preview text'), findsOneWidget);
    expect(find.text('Font size'), findsOneWidget);
    expect(find.text('Text animation'), findsOneWidget);
  });
}
