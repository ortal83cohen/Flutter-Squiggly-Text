import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_squiggly_text/flutter_squiggly_text.dart';

void main() {
  test('uses static animation defaults', () {
    const widget = SquigglyText('Hello');

    expect(widget.animationStyle, SquigglyAnimationStyle.none);
    expect(widget.speed, 1);
    expect(widget.fluidity, 0.5);
    expect(widget.stagger, 0.2);
    expect(widget.hoverBehavior, SquigglyHoverBehavior.none);
    expect(widget.pauseWhenNotVisible, isTrue);
    expect(widget.respectReducedMotion, isTrue);
  });

  test('magnetic hover behavior stays enabled for pointer interaction', () {
    const widget = SquigglyText(
      'Hello',
      hoverBehavior: SquigglyHoverBehavior.magnetic,
    );

    expect(widget.hoverBehavior, SquigglyHoverBehavior.magnetic);
  });

  test('validates animation parameters', () {
    expect(() => SquigglyText('Hello', speed: -1), throwsAssertionError);
    expect(() => SquigglyText('Hello', fluidity: 1.1), throwsAssertionError);
    expect(() => SquigglyText('Hello', stagger: -1), throwsAssertionError);
    expect(() => SquigglyText('Hello', hoverRadius: 0), throwsAssertionError);
    expect(
        () => SquigglyText('Hello', speed: double.nan), throwsAssertionError);
    expect(() => SquigglyText('Hello', amplitude: double.infinity),
        throwsAssertionError);
  });

  testWidgets('renders text with its configured semantics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SquigglyText(
            'Hello Flutter',
            squiggleColor: Colors.red,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Hello Flutter'), findsOneWidget);
  });

  testWidgets('adds pointer interaction only when configured', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SquigglyText('Hello')),
    );
    expect(
      find.descendant(
        of: find.byType(SquigglyText),
        matching: find.byType(MouseRegion),
      ),
      findsNothing,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SquigglyText(
          'Hello',
          hoverBehavior: SquigglyHoverBehavior.highlight,
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(SquigglyText),
        matching: find.byType(MouseRegion),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Hello'), findsOneWidget);
  });

  testWidgets('magnetic hover participates in pointer activation',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SquigglyText(
          'Hello',
          animationStyle: SquigglyAnimationStyle.waveAndLetters,
          hoverBehavior: SquigglyHoverBehavior.magnetic,
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(SquigglyText),
        matching: find.byType(MouseRegion),
      ),
      findsOneWidget,
    );

    final center = tester.getCenter(find.byType(SquigglyText));
    tester.binding.handlePointerEvent(
      PointerHoverEvent(position: center + const Offset(10, 0)),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.binding.transientCallbackCount, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hoverOnly does not opt static text into interaction',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SquigglyText('Hello', hoverOnly: true),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(SquigglyText),
        matching: find.byType(MouseRegion),
      ),
      findsNothing,
    );
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('supports multiline text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 100,
          child: SquigglyText('A longer piece of text that wraps'),
        ),
      ),
    );

    expect(find.byType(SquigglyText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out without wrapping when softWrap is false',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                key: Key('wrapped'),
                width: 100,
                child: SquigglyText('A longer piece of text that wraps'),
              ),
              SizedBox(
                key: Key('unwrapped'),
                width: 100,
                child: SquigglyText(
                  'A longer piece of text that wraps',
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('unwrapped'))).height,
      lessThan(tester.getSize(find.byKey(const Key('wrapped'))).height),
    );
  });

  testWidgets('wave animation advances while static mode does not tick',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SquigglyText('Hello')));
    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(
      const MaterialApp(
        home: SquigglyText(
          'Hello',
          animationStyle: SquigglyAnimationStyle.wave,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('letters and waveAndLetters animate without splitting graphemes',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 120,
          child: SquigglyText(
            'Cafe\u0301 👩‍🚀',
            animationStyle: SquigglyAnimationStyle.letters,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    expect(find.bySemanticsLabel('Cafe\u0301 👩‍🚀'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: SquigglyText(
          'A longer line that wraps safely',
          animationStyle: SquigglyAnimationStyle.waveAndLetters,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });

  testWidgets('ambiguous shaping falls back to full text painting',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SquigglyText(
            'שלום',
            animationStyle: SquigglyAnimationStyle.letters,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('שלום'), findsOneWidget);
  });

  testWidgets('hover-only wave waits for hover activation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SquigglyText(
          'Hello',
          animationStyle: SquigglyAnimationStyle.wave,
          hoverOnly: true,
        ),
      ),
    );

    expect(tester.binding.transientCallbackCount, 0);

    final center = tester.getCenter(find.byType(SquigglyText));
    tester.binding.handlePointerEvent(
      PointerHoverEvent(position: center + const Offset(1, 0)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });

  testWidgets('configured interaction participates in keyboard focus',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SquigglyText(
            'Hello',
            animationStyle: SquigglyAnimationStyle.wave,
            hoverBehavior: SquigglyHoverBehavior.liftLetters,
            hoverOnly: true,
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNotNull);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });

  testWidgets('reduced motion disables the animation ticker', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: SquigglyText(
            'Hello',
            animationStyle: SquigglyAnimationStyle.wave,
          ),
        ),
      ),
    );

    expect(tester.binding.transientCallbackCount, 0);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    final center = tester.getCenter(find.byType(SquigglyText));
    await gesture.addPointer(location: center);
    await gesture.moveTo(center);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    await gesture.removePointer();
  });
}
