import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_squiggly_text/flutter_squiggly_text.dart';

void main() {
  test('uses static animation defaults', () {
    const widget = SquigglyText('Hello');

    expect(widget.animationStyle, SquigglyAnimationStyle.none);
    expect(widget.showSquiggle, isFalse);
    expect(widget.speed, 1);
    expect(widget.fluidity, 0.5);
    expect(widget.stagger, 0.2);
    expect(widget.hoverBehavior, SquigglyHoverBehavior.none);
    expect(widget.pauseWhenNotVisible, isTrue);
    expect(widget.respectReducedMotion, isTrue);
  });

  test('enables the squiggle explicitly', () {
    const widget = SquigglyText('Hello', showSquiggle: true);

    expect(widget.showSquiggle, isTrue);
  });

  test('magnetic hover behavior stays enabled for pointer interaction', () {
    const widget = SquigglyText(
      'Hello',
      hoverBehavior: SquigglyHoverBehavior.magnetic,
    );

    expect(widget.hoverBehavior, SquigglyHoverBehavior.magnetic);
  });

  test('supports the expanded hover behaviors', () {
    for (final behavior in [
      SquigglyHoverBehavior.shrink,
      SquigglyHoverBehavior.enlarge,
      SquigglyHoverBehavior.trembleLetter,
      SquigglyHoverBehavior.trembleWord,
      SquigglyHoverBehavior.repel,
    ]) {
      expect(
        SquigglyText('Hello', hoverBehavior: behavior).hoverBehavior,
        behavior,
      );
    }
  });

  test('supports hover animation scopes', () {
    for (final scope in SquigglyHoverScope.values) {
      expect(
        SquigglyText('Hello', hoverScope: scope).hoverScope,
        scope,
      );
    }
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

  test('spellcheck preset resolves a red static underline', () {
    const widget = SquigglyText(
      'x',
      squiggleStyle: SquigglyTextStyle.spellcheck,
    );

    expect(widget.squiggleColor, Colors.red);
    expect(widget.animationStyle, SquigglyAnimationStyle.none);
    expect(widget.amplitude, 2);
    expect(widget.wavelength, 8);
    expect(widget.strokeWidth, 1.5);
    expect(widget.gap, 2);
  });

  test('handwriting preset resolves letter motion without an underline', () {
    const widget = SquigglyText(
      'x',
      squiggleStyle: SquigglyTextStyle.handwriting,
    );

    expect(widget.animationStyle, SquigglyAnimationStyle.letters);
    expect(widget.amplitude, 0);
    expect(widget.speed, 1);
  });

  test('explicit amplitude overrides the handwriting preset', () {
    const widget = SquigglyText(
      'x',
      amplitude: 4,
      squiggleStyle: SquigglyTextStyle.handwriting,
    );

    expect(widget.amplitude, 4);
    expect(widget.animationStyle, SquigglyAnimationStyle.letters);
  });

  test('explicit squiggle color overrides the spellcheck preset', () {
    const widget = SquigglyText(
      'x',
      squiggleColor: Colors.blue,
      squiggleStyle: SquigglyTextStyle.spellcheck,
    );

    expect(widget.squiggleColor, Colors.blue);
    expect(widget.animationStyle, SquigglyAnimationStyle.none);
  });

  test('phase defaults to zero and must be finite', () {
    expect(const SquigglyText('x').phase, 0);
    expect(const SquigglyText('x', phase: 0.25).phase, 0.25);
    expect(const SquigglyText('x', phase: -1.5).phase, -1.5);
    expect(() => SquigglyText('x', phase: double.nan), throwsAssertionError);
    expect(
      () => SquigglyText('x', phase: double.infinity),
      throwsAssertionError,
    );
    expect(
      () => SquigglyText('x', phase: double.negativeInfinity),
      throwsAssertionError,
    );
  });

  testWidgets('a stroke gradient builds, including with a wave',
      (tester) async {
    const gradient = LinearGradient(colors: [Colors.red, Colors.orange]);
    await tester.pumpWidget(
      const MaterialApp(
        home: SquigglyText('Hello', squiggleGradient: gradient),
      ),
    );
    expect(find.byType(SquigglyText), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: SquigglyText(
          'Hello',
          squiggleGradient: gradient,
          animationStyle: SquigglyAnimationStyle.wave,
        ),
      ),
    );
    expect(find.byType(SquigglyText), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  testWidgets('tremble hover animates even when text animation is static',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SquigglyText(
          'Hello',
          hoverBehavior: SquigglyHoverBehavior.trembleLetter,
        ),
      ),
    );

    final center = tester.getCenter(find.byType(SquigglyText));
    tester.binding.handlePointerEvent(
      PointerHoverEvent(position: center),
    );
    await tester.pump(const Duration(milliseconds: 100));

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

  testWidgets('reserves atlas room for hover scaling at text edges',
      (tester) async {
    const text = 'Hello Flutter testing words';
    final staticKey = GlobalKey();
    final highlightKey = GlobalKey();
    final enlargeKey = GlobalKey();

    Widget host(GlobalKey key, SquigglyHoverBehavior behavior) {
      return SquigglyText(
        text,
        key: key,
        style: const TextStyle(fontSize: 40),
        hoverBehavior: behavior,
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: Column(
            children: [
              SquigglyText(
                text,
                key: staticKey,
                style: const TextStyle(fontSize: 40),
              ),
              host(highlightKey, SquigglyHoverBehavior.highlight),
              host(enlargeKey, SquigglyHoverBehavior.enlarge),
            ],
          ),
        ),
      ),
    );

    final staticSize = tester.getSize(find.byKey(staticKey));
    final highlightSize = tester.getSize(find.byKey(highlightKey));
    final enlargeSize = tester.getSize(find.byKey(enlargeKey));
    expect(highlightSize.height, greaterThan(staticSize.height));
    expect(enlargeSize.height, greaterThan(highlightSize.height));
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

  test('letterAmplitude is stored and leaves underline amplitude alone', () {
    const derived = SquigglyText('Hello');
    expect(derived.letterAmplitude, isNull);
    expect(derived.amplitude, 2);
    expect(derived.stagger, 0.2);

    const explicit = SquigglyText(
      'Hello',
      amplitude: 3,
      letterAmplitude: 1.25,
    );
    expect(explicit.letterAmplitude, 1.25);
    expect(explicit.amplitude, 3);
    expect(const SquigglyText('x', letterAmplitude: 0).letterAmplitude, 0);

    expect(
      () => SquigglyText('Hello', letterAmplitude: -0.1),
      throwsAssertionError,
    );
    expect(
      () => SquigglyText('Hello', letterAmplitude: double.nan),
      throwsAssertionError,
    );
    expect(
      () => SquigglyText('Hello', letterAmplitude: double.infinity),
      throwsAssertionError,
    );
  });

  test('font-derived letter peaks follow half the CodePen scale', () {
    expect(squigglyLetterPeakOffset(fontSize: 100, seedIndex: 0), 3);
    expect(squigglyLetterPeakOffset(fontSize: 100, seedIndex: 1), 4);
    expect(squigglyLetterMapScale(fontSize: 100, seedIndex: 0), 6);
    expect(
      squigglyLetterPeakOffset(fontSize: 14, seedIndex: 0),
      closeTo(0.42, 1e-9),
    );
    expect(
      squigglyLetterPeakOffset(fontSize: 14, seedIndex: 1),
      closeTo(0.56, 1e-9),
    );
    expect(squigglyLetterMapScale(fontSize: 14, seedIndex: 0), lessThan(1.5));
    expect(
      squigglyLetterPeakOffset(fontSize: 14, seedIndex: 1),
      lessThanOrEqualTo(14 * 0.06),
    );
    expect(
      squigglyLetterPeakOffset(fontSize: 100, seedIndex: 1),
      lessThanOrEqualTo(100 * 0.06),
    );
    expect(
      squigglyLetterPeakOffset(
        fontSize: 14,
        seedIndex: 0,
        letterAmplitude: 2.5,
      ),
      2.5,
    );
    expect(
      squigglyLetterMapScale(
        fontSize: 14,
        seedIndex: 1,
        letterAmplitude: 2.5,
      ),
      5,
    );
    expect(squigglyLetterDisplacementPad(4), 6);
    expect(squigglyLetterDisplacementPad(0.56), 3);
  });

  test('letter hover does not zero the autonomous scale', () {
    final hovered = squigglyLetterMapScale(
      fontSize: 14,
      seedIndex: 0,
      hoverScope: SquigglyHoverScope.letter,
      pointerActive: true,
    );
    final idle = squigglyLetterMapScale(
      fontSize: 14,
      seedIndex: 0,
      hoverScope: SquigglyHoverScope.all,
      pointerActive: false,
    );

    expect(hovered, idle);
    expect(hovered, isNot(0));
    expect(squigglySeedBlend(0.5), 0);
    expect(squigglySeedBlend(0.75), 0);
    expect(squigglySeedBlend(0.875), closeTo(0.5, 1e-9));
    expect(squigglySeedBlend(1), 1);
  });

  testWidgets('letterAmplitude pumps on the default and explicit paths',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SquigglyText(
          'Hello',
          animationStyle: SquigglyAnimationStyle.letters,
        ),
      ),
    );
    expect(
      tester.widget<SquigglyText>(find.byType(SquigglyText)).letterAmplitude,
      isNull,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: SquigglyText(
          'Hello',
          animationStyle: SquigglyAnimationStyle.letters,
          letterAmplitude: 1.5,
          hoverScope: SquigglyHoverScope.letter,
        ),
      ),
    );
    final widget = tester.widget<SquigglyText>(find.byType(SquigglyText));
    expect(widget.letterAmplitude, 1.5);
    expect(widget.amplitude, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a MediaQuery text scaler of 2.0 lays out taller than a scaler of 1.0',
    (tester) async {
      const style = TextStyle(fontSize: 20);

      Future<double> heightFor(TextScaler scaler) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: scaler),
                child: child!,
              );
            },
            home: const Center(
              child: SquigglyText('Hello', style: style),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        return tester.getSize(find.byType(SquigglyText)).height;
      }

      final atScaleOne = await heightFor(TextScaler.noScaling);
      final atScaleTwo = await heightFor(const TextScaler.linear(2));
      expect(atScaleTwo, greaterThan(atScaleOne));
    },
  );

  testWidgets('accepts textHeightBehavior', (tester) async {
    const behavior = TextHeightBehavior(
      applyHeightToFirstAscent: false,
      applyHeightToLastDescent: false,
    );
    expect(
      const SquigglyText('Hello', textHeightBehavior: behavior)
          .textHeightBehavior,
      behavior,
    );
    expect(const SquigglyText('Hello').textHeightBehavior, isNull);

    Future<double> heightFor(TextHeightBehavior? textHeightBehavior) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SquigglyText(
              'Hello',
              style: const TextStyle(fontSize: 24, height: 2),
              textHeightBehavior: textHeightBehavior,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      return tester.getSize(find.byType(SquigglyText)).height;
    }

    final defaultHeight = await heightFor(null);
    final explicitHeight = await heightFor(behavior);
    expect(explicitHeight, lessThan(defaultHeight));
  });
}
