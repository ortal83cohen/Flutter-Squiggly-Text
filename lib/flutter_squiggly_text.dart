/// A customizable squiggly underline for Flutter text.
///
/// Use [SquigglyText] for static or animated underlines, optional grapheme
/// animation, and pointer interaction while retaining Flutter text layout and
/// accessibility semantics.
library flutter_squiggly_text;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Selects the animation applied to a [SquigglyText].
enum SquigglyAnimationStyle {
  /// Keeps the text and underline static.
  none,

  /// Animates the underline wave.
  wave,

  /// Animates individual letters.
  letters,

  /// Animates both the underline and individual letters.
  waveAndLetters,
}

/// Selects the pointer interaction applied to a [SquigglyText].
enum SquigglyHoverBehavior {
  /// Does not respond to pointer input.
  none,

  /// Highlights the text under the pointer.
  highlight,

  /// Lifts letters near the pointer.
  liftLetters,

  /// Applies a magnetic response near the pointer.
  magnetic,
}

/// Displays [text] with a customizable squiggly underline.
class SquigglyText extends StatefulWidget {
  /// Creates a squiggly text widget.
  const SquigglyText(
    this.text, {
    super.key,
    this.style,
    this.squiggleColor,
    this.amplitude = 2,
    this.wavelength = 8,
    this.strokeWidth = 1.5,
    this.gap = 2,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.locale,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.strutStyle,
    this.semanticsLabel,
    this.animationStyle = SquigglyAnimationStyle.none,
    this.speed = 1,
    this.fluidity = 0.5,
    this.stagger = 0.2,
    this.hoverBehavior = SquigglyHoverBehavior.none,
    this.hoverRadius = 48,
    this.hoverOnly = false,
    this.pauseWhenNotVisible = true,
    this.respectReducedMotion = true,
  })  : assert(amplitude >= 0),
        assert(amplitude == amplitude && amplitude != double.infinity),
        assert(wavelength > 0),
        assert(wavelength == wavelength && wavelength != double.infinity),
        assert(strokeWidth > 0),
        assert(strokeWidth == strokeWidth && strokeWidth != double.infinity),
        assert(gap >= 0),
        assert(gap == gap && gap != double.infinity),
        assert(maxLines == null || maxLines > 0),
        assert(speed >= 0),
        assert(speed == speed && speed != double.infinity),
        assert(fluidity >= 0 && fluidity <= 1),
        assert(fluidity == fluidity && fluidity != double.infinity),
        assert(stagger >= 0),
        assert(stagger == stagger && stagger != double.infinity),
        assert(hoverRadius > 0),
        assert(hoverRadius == hoverRadius && hoverRadius != double.infinity);

  /// The text to display.
  final String text;

  /// The text style. Its color is also used for the squiggle by default.
  final TextStyle? style;

  /// The squiggle color. Defaults to [style]'s color or the current theme.
  final Color? squiggleColor;

  /// The height of the wave in logical pixels.
  final double amplitude;

  /// The distance between matching points in consecutive waves.
  final double wavelength;

  /// The width of the squiggle stroke.
  final double strokeWidth;

  /// The distance between the text baseline and the squiggle.
  final double gap;

  /// How the text is aligned within its available width.
  final TextAlign textAlign;

  /// The direction in which the text is read.
  final TextDirection? textDirection;

  /// The locale used when laying out the text.
  final Locale? locale;

  /// Whether the text should wrap when it reaches the available width.
  final bool softWrap;

  /// How overflowing text is handled.
  final TextOverflow overflow;

  /// The maximum number of lines to display.
  final int? maxLines;

  /// The strut style used for line layout.
  final StrutStyle? strutStyle;

  /// An alternative label for accessibility services.
  final String? semanticsLabel;

  /// The animation style. Defaults to static rendering.
  final SquigglyAnimationStyle animationStyle;

  /// The number of wave cycles per second.
  final double speed;

  /// The normalized smoothing amount reserved for interactive animation.
  final double fluidity;

  /// The phase offset between neighboring graphemes.
  final double stagger;

  /// The pointer interaction style.
  final SquigglyHoverBehavior hoverBehavior;

  /// The pointer influence radius in logical pixels.
  final double hoverRadius;

  /// Whether automatic animation waits for pointer input.
  final bool hoverOnly;

  /// Whether animation should pause when the widget is not visible.
  final bool pauseWhenNotVisible;

  /// Whether platform reduced-motion preferences disable animation.
  final bool respectReducedMotion;

  @override
  State<SquigglyText> createState() => _SquigglyTextState();
}

class _SquigglyTextState extends State<SquigglyText>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  bool _isAnimating = false;
  bool _isFocused = false;
  bool _isAppVisible = true;
  late final ValueNotifier<Offset?> _pointerPosition =
      ValueNotifier<Offset?>(null);

  bool get _interactionConfigured =>
      widget.hoverBehavior != SquigglyHoverBehavior.none ||
      (widget.hoverOnly &&
          widget.animationStyle != SquigglyAnimationStyle.none);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppVisible = state == AppLifecycleState.resumed;
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant SquigglyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationStyle != widget.animationStyle ||
        oldWidget.speed != widget.speed ||
        oldWidget.hoverOnly != widget.hoverOnly ||
        oldWidget.hoverBehavior != widget.hoverBehavior ||
        oldWidget.pauseWhenNotVisible != widget.pauseWhenNotVisible ||
        oldWidget.respectReducedMotion != widget.respectReducedMotion) {
      _updateAnimation();
    }
  }

  void _setPointerPosition(Offset? position) {
    if (!_interactionConfigured) {
      return;
    }
    _pointerPosition.value = position;
    _updateAnimation();
  }

  void _setFocus(bool focused) {
    _isFocused = focused;
    _updateAnimation();
  }

  void _updateAnimation() {
    if (!mounted) {
      return;
    }
    final reducedMotion =
        widget.respectReducedMotion && MediaQuery.of(context).disableAnimations;
    final shouldAnimate =
        widget.animationStyle != SquigglyAnimationStyle.none &&
            widget.speed > 0 &&
            (widget.hoverOnly
                ? _pointerPosition.value != null || _isFocused
                : true) &&
            (!widget.pauseWhenNotVisible || _isAppVisible) &&
            !reducedMotion;
    if (shouldAnimate == _isAnimating) {
      return;
    }
    _isAnimating = shouldAnimate;
    if (_isAnimating) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pointerPosition.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        widget.respectReducedMotion && MediaQuery.of(context).disableAnimations;
    final animation = _isAnimating ? _controller : null;
    final effectiveStyle =
        DefaultTextStyle.of(context).style.merge(widget.style);
    final effectiveColor = widget.squiggleColor ??
        effectiveStyle.color ??
        Theme.of(context).textTheme.bodyMedium?.color ??
        Colors.black;
    final direction = widget.textDirection ?? Directionality.of(context);
    final painter = _SquigglyTextPainter(
      text: widget.text,
      style: effectiveStyle,
      color: effectiveColor,
      amplitude: widget.amplitude,
      wavelength: widget.wavelength,
      strokeWidth: widget.strokeWidth,
      gap: widget.gap,
      textAlign: widget.textAlign,
      textDirection: direction,
      locale: widget.locale,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      strutStyle: widget.strutStyle,
      animation: animation,
      speed: widget.speed,
      animationStyle: widget.animationStyle,
      fluidity: widget.fluidity,
      stagger: widget.stagger,
      pointerPosition: _pointerPosition,
      hoverBehavior:
          reducedMotion ? SquigglyHoverBehavior.none : widget.hoverBehavior,
      hoverRadius: widget.hoverRadius,
    );

    Widget child = Semantics(
      label: widget.semanticsLabel ?? widget.text,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.hasBoundedWidth
              ? (widget.softWrap ? constraints.maxWidth : double.infinity)
              : double.infinity;
          painter.layout(maxWidth: maxWidth);
          return SizedBox(
            width: constraints.hasBoundedWidth
                ? constraints.maxWidth
                : painter.textPainter.width,
            height: painter.height,
            child: CustomPaint(painter: painter),
          );
        },
      ),
    );
    if (_interactionConfigured) {
      child = MouseRegion(
        onHover: (event) => _setPointerPosition(event.localPosition),
        onExit: (_) => _setPointerPosition(null),
        child: child,
      );
    }
    return Focus(
      canRequestFocus: _interactionConfigured,
      onFocusChange: _setFocus,
      child: child,
    );
  }
}

class _SquigglyTextPainter extends CustomPainter {
  _SquigglyTextPainter({
    required this.text,
    required this.style,
    required this.color,
    required this.amplitude,
    required this.wavelength,
    required this.strokeWidth,
    required this.gap,
    required TextAlign textAlign,
    required TextDirection textDirection,
    required Locale? locale,
    required int? maxLines,
    required TextOverflow overflow,
    required StrutStyle? strutStyle,
    required this.animation,
    required this.speed,
    required this.animationStyle,
    required this.fluidity,
    required this.stagger,
    required this.pointerPosition,
    required this.hoverBehavior,
    required this.hoverRadius,
  })  : textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          maxLines: maxLines,
          ellipsis: overflow == TextOverflow.ellipsis ? '\u2026' : null,
          strutStyle: strutStyle,
        ),
        super(
          repaint: Listenable.merge(<Listenable>[
            if (animation != null) animation,
            pointerPosition,
          ]),
        );

  final TextPainter textPainter;
  final String text;
  final TextStyle style;
  final Color color;
  final double amplitude;
  final double wavelength;
  final double strokeWidth;
  final double gap;
  final Animation<double>? animation;
  final double speed;
  final SquigglyAnimationStyle animationStyle;
  final double fluidity;
  final double stagger;
  final ValueListenable<Offset?> pointerPosition;
  final SquigglyHoverBehavior hoverBehavior;
  final double hoverRadius;

  List<_GraphemeLayout> _graphemes = const [];
  bool _canPaintLetters = false;

  double get height => textPainter.height + gap + amplitude + strokeWidth;

  void layout({required double maxWidth}) {
    textPainter.layout(maxWidth: maxWidth);
    _graphemes = const [];
    _canPaintLetters = false;
    if (animationStyle == SquigglyAnimationStyle.letters ||
        animationStyle == SquigglyAnimationStyle.waveAndLetters ||
        hoverBehavior != SquigglyHoverBehavior.none) {
      final graphemes = _buildGraphemeLayout();
      if (graphemes != null) {
        _graphemes = graphemes;
        _canPaintLetters = true;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_canPaintLetters) {
      _paintLetters(canvas);
    } else {
      textPainter.paint(canvas, Offset.zero);
    }
    final metrics = textPainter.computeLineMetrics();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final line in metrics) {
      final width = line.width;
      if (width <= 0 || amplitude == 0) {
        continue;
      }
      final path = Path();
      final startX = _lineStart(line, size.width);
      final baseline = line.baseline + gap + strokeWidth / 2;
      final phase = _phase;
      final step = wavelength / 2;
      path.moveTo(startX, baseline);
      for (var x = 0.0; x < width; x += step) {
        final endX = math.min(x + step, width);
        final controlX = x + (endX - x) / 2;
        final direction = animation == null
            ? (((x / step).round().isEven) ? 1 : -1).toDouble()
            : math.sin(2 * math.pi * controlX / wavelength + phase);
        path.quadraticBezierTo(
          startX + controlX,
          baseline + amplitude * direction,
          startX + endX,
          baseline,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  double get _phase => (animation?.value ?? 0) * 2 * math.pi * speed;

  void _paintLetters(Canvas canvas) {
    for (final grapheme in _graphemes) {
      final center = grapheme.offset +
          Offset(grapheme.painter.width / 2, grapheme.painter.height / 2);
      final letterPhase = _phase + grapheme.index * stagger;
      final targetOffset = math.sin(letterPhase) * grapheme.amplitude;
      final influence = _influence(center);
      final pointerOffset = _pointerOffsetForGrapheme(grapheme, center, influence);
      final offset = targetOffset * (1 - fluidity * 0.35) + pointerOffset.dy;
      canvas.save();
      canvas.translate(pointerOffset.dx, offset);
      if (hoverBehavior == SquigglyHoverBehavior.highlight && influence > 0) {
        final highlightedPainter = TextPainter(
          text: TextSpan(
            text: grapheme.text,
            style: style.copyWith(
              color: Color.lerp(
                style.color ?? color,
                Colors.white,
                influence * 0.45,
              ),
            ),
          ),
          textDirection: textPainter.textDirection,
          locale: textPainter.locale,
          strutStyle: textPainter.strutStyle,
        )..layout();
        highlightedPainter.paint(canvas, grapheme.offset);
      } else {
        grapheme.painter.paint(canvas, grapheme.offset);
      }
      canvas.restore();
    }
  }

  Offset _pointerOffsetForGrapheme(
    _GraphemeLayout grapheme,
    Offset center,
    double influence,
  ) {
    final pointer = pointerPosition.value;
    if (pointer == null || hoverBehavior == SquigglyHoverBehavior.none) {
      return Offset.zero;
    }

    if (hoverBehavior == SquigglyHoverBehavior.highlight) {
      return Offset.zero;
    }

    if (hoverBehavior == SquigglyHoverBehavior.liftLetters) {
      return Offset(0, -influence * grapheme.amplitude * (1 + fluidity));
    }

    if (hoverBehavior == SquigglyHoverBehavior.magnetic) {
      final delta = pointer - center;
      final distance = delta.distance;
      if (distance <= 0) {
        return Offset.zero;
      }
      final pull = delta / distance;
      return pull * influence * grapheme.amplitude * (0.8 + fluidity);
    }

    return Offset.zero;
  }

  double _influence(Offset center) {
    final pointer = pointerPosition.value;
    if (pointer == null) {
      return 0;
    }
    final normalized =
        ((pointer - center).distance / hoverRadius).clamp(0.0, 1.0).toDouble();
    return 1 - normalized * normalized * (3 - 2 * normalized);
  }

  List<_GraphemeLayout>? _buildGraphemeLayout() {
    // Independent painting can change bidi ordering, ligatures, and joining.
    // Keep the authoritative shaped run for those cases.
    if (textPainter.textDirection == TextDirection.rtl ||
        textPainter.textAlign == TextAlign.justify ||
        textPainter.ellipsis != null ||
        textPainter.maxLines != null) {
      return null;
    }

    if (_containsAmbiguousShaping(text)) {
      return null;
    }

    final lines = textPainter.computeLineMetrics();
    final result = <_GraphemeLayout>[];
    var start = 0;
    var index = 0;
    for (final grapheme in text.characters) {
      final end = start + grapheme.length;
      if (grapheme.trim().isEmpty) {
        start = end;
        continue;
      }

      final boxes = textPainter.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );
      final validBoxes = boxes
          .where((box) => box.right > box.left && (box.right - box.left) > 0)
          .toList(growable: false);
      if (validBoxes.isEmpty) {
        start = end;
        continue;
      }

      final box = _mergeBoxes(validBoxes);
      final line = _lineForBox(lines, box);
      if (line == null) {
        start = end;
        continue;
      }
      final painter = TextPainter(
        text: TextSpan(text: grapheme, style: style),
        textDirection: textPainter.textDirection,
        locale: textPainter.locale,
        strutStyle: textPainter.strutStyle,
      )..layout();
      final letterMetrics = painter.computeLineMetrics();
      if (letterMetrics.length != 1) {
        start = end;
        continue;
      }
      result.add(
        _GraphemeLayout(
          index: index,
          text: grapheme,
          painter: painter,
          offset: Offset(
            box.left,
            line.baseline - letterMetrics.single.baseline,
          ),
          amplitude: math.min(3, line.height * 0.08),
        ),
      );
      start = end;
      index++;
    }
    return result.isEmpty ? null : result;
  }

  TextBox _mergeBoxes(List<TextBox> boxes) {
    final left = boxes.map((box) => box.left).reduce(math.min);
    final top = boxes.map((box) => box.top).reduce(math.min);
    final right = boxes.map((box) => box.right).reduce(math.max);
    final bottom = boxes.map((box) => box.bottom).reduce(math.max);
    return TextBox.fromLTRBD(
      left,
      top,
      right,
      bottom,
      textPainter.textDirection ?? TextDirection.ltr,
    );
  }

  LineMetrics? _lineForBox(List<LineMetrics> lines, TextBox box) {
    for (final line in lines) {
      final lineTop = line.baseline - line.ascent;
      if ((lineTop - box.top).abs() < 0.5) {
        return line;
      }
    }
    return null;
  }

  bool _containsAmbiguousShaping(String text) {
    for (final codeUnit in text.codeUnits) {
      if ((codeUnit >= 0x0590 && codeUnit <= 0x08ff) ||
          (codeUnit >= 0x0900 && codeUnit <= 0x1fff) ||
          (codeUnit >= 0xa800 && codeUnit <= 0xabff) ||
          (codeUnit >= 0xfb00 && codeUnit <= 0xfdff) ||
          (codeUnit >= 0xfe70 && codeUnit <= 0xfeff)) {
        return true;
      }
    }
    return text.contains('\u200d') || _hasFlagPair(text);
  }

  bool _hasFlagPair(String text) {
    var regionalIndicators = 0;
    for (final codePoint in text.runes) {
      if (codePoint >= 0x1f1e6 && codePoint <= 0x1f1ff) {
        regionalIndicators++;
      }
    }
    return regionalIndicators >= 2;
  }

  double _lineStart(LineMetrics line, double width) {
    switch (textPainter.textAlign) {
      case TextAlign.center:
        return (width - line.width) / 2;
      case TextAlign.right:
      case TextAlign.end:
        return width - line.width;
      case TextAlign.left:
      case TextAlign.start:
      case TextAlign.justify:
        return 0;
    }
  }

  @override
  bool shouldRepaint(covariant _SquigglyTextPainter oldPainter) =>
      textPainter.text != oldPainter.textPainter.text ||
      textPainter.textAlign != oldPainter.textPainter.textAlign ||
      textPainter.textDirection != oldPainter.textPainter.textDirection ||
      textPainter.locale != oldPainter.textPainter.locale ||
      textPainter.maxLines != oldPainter.textPainter.maxLines ||
      textPainter.ellipsis != oldPainter.textPainter.ellipsis ||
      textPainter.strutStyle != oldPainter.textPainter.strutStyle ||
      color != oldPainter.color ||
      amplitude != oldPainter.amplitude ||
      wavelength != oldPainter.wavelength ||
      strokeWidth != oldPainter.strokeWidth ||
      gap != oldPainter.gap ||
      speed != oldPainter.speed ||
      animationStyle != oldPainter.animationStyle ||
      fluidity != oldPainter.fluidity ||
      stagger != oldPainter.stagger ||
      pointerPosition != oldPainter.pointerPosition ||
      hoverBehavior != oldPainter.hoverBehavior ||
      hoverRadius != oldPainter.hoverRadius ||
      animation != oldPainter.animation;
}

class _GraphemeLayout {
  const _GraphemeLayout({
    required this.index,
    required this.text,
    required this.painter,
    required this.offset,
    required this.amplitude,
  });

  final int index;
  final String text;
  final TextPainter painter;
  final Offset offset;
  final double amplitude;
}
