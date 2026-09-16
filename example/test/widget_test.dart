import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_squiggly_text/flutter_squiggly_text.dart';
import 'package:flutter_squiggly_text_example/main.dart';

void main() {
  testWidgets('layout samples animate and follow the shared controls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SquigglyTextExampleApp());

    void checkSamples() {
      final samples =
          tester.widgetList<SquigglyText>(find.byType(SquigglyText)).toList();
      expect(samples, hasLength(4));
      final main = samples.first;
      for (final sample in samples.skip(1)) {
        expect(sample.animationStyle, SquigglyAnimationStyle.letters);
        expect(sample.speed, main.speed);
        expect(sample.hoverBehavior, main.hoverBehavior);
        expect(sample.hoverScope, main.hoverScope);
        expect(sample.hoverOnly, main.hoverOnly);
        expect(sample.hoverPreview, main.hoverPreview);
        expect(sample.respectReducedMotion, main.respectReducedMotion);
        expect(sample.style!.fontSize, main.style!.fontSize! / 2);
      }
    }

    checkSamples();
    await tester.drag(find.byType(Slider).first, const Offset(80, 0));
    await tester.drag(find.byType(Slider).last, const Offset(-80, 0));
    await tester.tap(find.text('Automatic preview'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Hover or keyboard focus').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Respect reduced-motion settings'));
    await tester.pump();
    checkSamples();

    final rtl = find.byWidgetPredicate((widget) =>
        widget is SquigglyText && widget.textDirection == TextDirection.rtl);
    expect(tester.getSize(rtl).width, 960);
    expect(tester.widget<SquigglyText>(rtl).textAlign, TextAlign.right);
    final multiline = find.byWidgetPredicate((widget) =>
        widget is SquigglyText && widget.text.startsWith('A longer sentence'));
    expect(tester.getSize(multiline).width, 420);
    expect(tester.getSize(multiline).height, greaterThan(100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the current controls', (WidgetTester tester) async {
    await tester.pumpWidget(const SquigglyTextExampleApp());

    expect(find.text('Interactive text preview'), findsOneWidget);
    expect(find.text('Preview text'), findsOneWidget);
    expect(find.text('Font size'), findsOneWidget);
    expect(find.text('Animation speed'), findsOneWidget);
    expect(find.text('Pointer range'), findsOneWidget);
    expect(find.text('Pointer interaction'), findsOneWidget);
    expect(find.text('Activation'), findsOneWidget);
    expect(find.text('Automatic preview'), findsOneWidget);
    expect(find.text('Respect reduced-motion settings'), findsOneWidget);
    expect(find.text('Text animation'), findsNothing);
    expect(find.text('Amplitude'), findsNothing);
    expect(find.text('Wavelength'), findsNothing);
    expect(find.text('Gap'), findsNothing);
  });

  testWidgets('wires text, sliders, dropdowns, and switches',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SquigglyTextExampleApp());

    await tester.enterText(find.byType(TextField), 'Animated example');
    expect(find.text('Animated example'), findsOneWidget);

    final sliders = find.byType(Slider);
    expect(sliders, findsNWidgets(2));
    await tester.drag(sliders.at(0), const Offset(80, 0));
    await tester.drag(sliders.at(1), const Offset(-80, 0));
    await tester.pump();

    await tester.tap(find.byWidgetPredicate(
      (widget) => widget is DropdownButtonFormField<SquigglyHoverScope>,
    ));
    await tester.pump();
    await tester.tap(find.text('hovered letter').last);
    await tester.pump();
    expect(find.text('hovered letter'), findsOneWidget);

    await tester.tap(find.byWidgetPredicate(
      (widget) => widget is DropdownButtonFormField<SquigglyHoverBehavior>,
    ));
    await tester.pump();
    await tester.tap(find.text('pull like a magnet'));
    await tester.pump();
    expect(find.text('pull like a magnet'), findsOneWidget);

    await tester.tap(find.text('Automatic preview'));
    await tester.pump();
    await tester.tap(find.text('Hover or keyboard focus'));
    await tester.pump();
    expect(find.text('Hover or keyboard focus'), findsOneWidget);
    await tester.tap(find.text('Respect reduced-motion settings'));
    await tester.pump();
    expect(find.byType(SwitchListTile), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('exposes the custom semantics label once',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SquigglyTextExampleApp());
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SquigglyText &&
            widget.semanticsLabel == 'Accessible animated greeting',
      ),
      findsOneWidget,
    );
  });
  testWidgets(
      'tremble effects show their fixed range and restore the chosen range',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SquigglyTextExampleApp());
    final behavior = find.byWidgetPredicate(
        (widget) => widget is DropdownButtonFormField<SquigglyHoverBehavior>);
    final range = find.byWidgetPredicate(
        (widget) => widget is DropdownButtonFormField<SquigglyHoverScope>);
    await tester.tap(behavior);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('tremble hovered word').last);
    await tester.pump(const Duration(milliseconds: 300));
    final field =
        tester.widget<DropdownButtonFormField<SquigglyHoverScope>>(range);
    expect(field.initialValue, SquigglyHoverScope.word);
    expect(field.onChanged, isNull);
    expect(find.text('This effect always targets one word.'), findsOneWidget);
    await tester.tap(behavior);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('none').last);
    await tester.pump(const Duration(milliseconds: 300));
    final restored =
        tester.widget<DropdownButtonFormField<SquigglyHoverScope>>(range);
    expect(restored.initialValue, SquigglyHoverScope.all);
    expect(restored.onChanged, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
