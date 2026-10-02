import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_squiggly_text/flutter_squiggly_text.dart';

void main() {
  testWidgets('explicit preview activates a hover-only animation',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SquigglyText(
          'Preview',
          animationStyle: SquigglyAnimationStyle.wave,
          hoverOnly: true,
          hoverPreview: true,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('focus supplies an active target for tremble interaction',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SquigglyText(
            'Focus',
            hoverBehavior: SquigglyHoverBehavior.trembleLetter,
            hoverOnly: true,
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 50));
    final dynamic painter = tester
        .widget<CustomPaint>(
          find.descendant(
              of: find.byType(SquigglyText),
              matching: find.byType(CustomPaint)),
        )
        .painter;
    expect(painter.hoverPreview, isTrue);
    expect(painter.hoverScope, SquigglyHoverScope.letter);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('touch pointer matches hover and clears when the finger lifts',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SquigglyText(
            'Hello',
            hoverBehavior: SquigglyHoverBehavior.trembleLetter,
          ),
        ),
      ),
    );

    Offset? pointer() {
      final dynamic painter = tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(SquigglyText),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter;
      return painter.pointerPosition.value as Offset?;
    }

    expect(pointer(), isNull);
    expect(tester.binding.transientCallbackCount, 0);

    final center = tester.getCenter(find.byType(SquigglyText));
    final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await hover.addPointer(location: center);
    await hover.moveTo(center);
    await tester.pump();
    final hovered = pointer();
    expect(hovered, isNotNull);
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await hover.moveTo(center + const Offset(0, 800));
    await tester.pump();
    expect(pointer(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
    await hover.removePointer();

    final touch = await tester.createGesture(kind: PointerDeviceKind.touch);
    await touch.down(center);
    await tester.pump();
    expect(pointer(), hovered);
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    const delta = Offset(12, -4);
    await touch.moveTo(center + delta);
    await tester.pump();
    expect(pointer(), hovered! + delta);
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await touch.up();
    await tester.pump();
    expect(pointer(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
      'mouse button up keeps the hover point while the pointer is inside',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SquigglyText(
          'Hello',
          hoverBehavior: SquigglyHoverBehavior.liftLetters,
        ),
      ),
    );

    final center = tester.getCenter(find.byType(SquigglyText));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: center);
    await mouse.moveTo(center);
    await tester.pump();

    final dynamic painter = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byType(SquigglyText),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;
    final hovered = painter.pointerPosition.value as Offset?;
    expect(hovered, isNotNull);

    await mouse.down(center);
    await mouse.up();
    await tester.pump();
    expect(painter.pointerPosition.value, hovered);
    await mouse.removePointer();
  });

  testWidgets('runtime range and preview changes invalidate painting',
      (tester) async {
    Widget sample(SquigglyHoverScope scope, bool preview) => MaterialApp(
          home: SquigglyText('A short word',
              speed: 0,
              hoverBehavior: SquigglyHoverBehavior.enlarge,
              hoverScope: scope,
              hoverPreview: preview),
        );
    dynamic painter() => tester
        .widget<CustomPaint>(find.descendant(
            of: find.byType(SquigglyText), matching: find.byType(CustomPaint)))
        .painter;
    await tester.pumpWidget(sample(SquigglyHoverScope.word, true));
    final first = painter();
    await tester.pumpWidget(sample(SquigglyHoverScope.letter, true));
    final second = painter();
    expect(second.hoverScope, SquigglyHoverScope.letter);
    expect(second.shouldRepaint(first), isTrue);
    await tester.pumpWidget(sample(SquigglyHoverScope.letter, false));
    final third = painter();
    expect(third.hoverPreview, isFalse);
    expect(third.shouldRepaint(second), isTrue);
  });

  testWidgets('named tremble modes own their scope', (tester) async {
    for (final behavior in [
      SquigglyHoverBehavior.trembleLetter,
      SquigglyHoverBehavior.trembleWord
    ]) {
      for (final scope in SquigglyHoverScope.values) {
        await tester.pumpWidget(MaterialApp(
            home: SquigglyText('One two',
                hoverBehavior: behavior, hoverScope: scope)));
        final dynamic painter = tester
            .widget<CustomPaint>(find.descendant(
                of: find.byType(SquigglyText),
                matching: find.byType(CustomPaint)))
            .painter;
        expect(
            painter.hoverScope,
            behavior == SquigglyHoverBehavior.trembleLetter
                ? SquigglyHoverScope.letter
                : SquigglyHoverScope.word);
      }
    }
  });

  testWidgets('scaling margins fit narrow and multiline preview widths',
      (tester) async {
    for (final behavior in [
      SquigglyHoverBehavior.none,
      SquigglyHoverBehavior.highlight,
      SquigglyHoverBehavior.enlarge
    ]) {
      for (final width in [240.0, 440.0]) {
        await tester.pumpWidget(MaterialApp(
            home: SingleChildScrollView(
                child: Center(
          child: SizedBox(
              width: width,
              child: SquigglyText(
                  'Hello Flutter testing words across several lines',
                  style: const TextStyle(fontSize: 40),
                  animationStyle: SquigglyAnimationStyle.letters,
                  hoverBehavior: behavior,
                  hoverPreview: true)),
        ))));
        final target = find.descendant(
            of: find.byType(SquigglyText), matching: find.byType(CustomPaint));
        final dynamic painter = tester.widget<CustomPaint>(target).painter;
        final double paintedWidth =
            painter.textPainter.width + painter.horizontalPadding * 2;
        expect(paintedWidth, lessThanOrEqualTo(width + 0.001));
        expect(tester.getSize(target).width, width);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
