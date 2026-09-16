// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:flutter_squiggly_text_example/main.dart';

void main() {
  testWidgets('renders the example app', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SquigglyTextExampleApp());

    expect(find.text('Interactive preview'), findsOneWidget);
    expect(find.text('Animated glyph preview'), findsOneWidget);
    expect(find.text('Layout and accessibility'), findsOneWidget);
  });
}
