/// A customizable squiggly underline for Flutter text.
///
/// Use [SquigglyText] for static or animated underlines, optional grapheme
/// animation, and pointer interaction while retaining Flutter text layout and
/// accessibility semantics.
library flutter_squiggly_text;

import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

  /// Shrinks letters near the pointer.
  shrink,

  /// Enlarges letters near the pointer.
  enlarge,

  /// Trembles the letter nearest to the pointer.
  trembleLetter,

  /// Trembles a word-sized region around the pointer.
  trembleWord,

  /// Repels nearby letters away from the pointer.
  repel,

  /// Lifts letters near the pointer.
  liftLetters,

  /// Applies a magnetic response near the pointer.
  magnetic,
}

/// Selects how much text is animated while a pointer interaction is active.
enum SquigglyHoverScope {
  /// Animates the complete text.
  all,

  /// Animates a word-sized region around the pointer.
  word,

  /// Animates a letter-sized region around the pointer.
  letter,
}

/// Optional underline and animation values shared by [SquigglyText].
///
/// Every field is nullable. A null field leaves that setting to the widget
/// constructor or the library default. [SquigglyText] resolves each styled
/// field as the explicit constructor argument, then the non-null field here,
/// then the library default.
class SquigglyTextStyle {
  /// Creates a style whose set fields override [SquigglyText] defaults.
  const SquigglyTextStyle({
    this.squiggleColor,
    this.squiggleGradient,
    this.amplitude,
    this.wavelength,
    this.strokeWidth,
    this.gap,
    this.animationStyle,
    this.speed,
    this.phase,
  })  : assert(amplitude == null || amplitude >= 0),
        assert(
          amplitude == null ||
              (amplitude == amplitude && amplitude != double.infinity),
        ),
        assert(wavelength == null || wavelength > 0),
        assert(
          wavelength == null ||
              (wavelength == wavelength && wavelength != double.infinity),
        ),
        assert(strokeWidth == null || strokeWidth > 0),
        assert(
          strokeWidth == null ||
              (strokeWidth == strokeWidth && strokeWidth != double.infinity),
        ),
        assert(gap == null || gap >= 0),
        assert(gap == null || (gap == gap && gap != double.infinity)),
        assert(speed == null || speed >= 0),
        assert(speed == null || (speed == speed && speed != double.infinity)),
        assert(
          phase == null ||
              (phase == phase &&
                  phase != double.infinity &&
                  phase != double.negativeInfinity),
        );

  /// A red, static underline using the library geometry defaults.
  static const SquigglyTextStyle spellcheck = SquigglyTextStyle(
    squiggleColor: Colors.red,
    animationStyle: SquigglyAnimationStyle.none,
  );

  /// Letter displacement with no underline wave.
  static const SquigglyTextStyle handwriting = SquigglyTextStyle(
    animationStyle: SquigglyAnimationStyle.letters,
    amplitude: 0,
    speed: 1,
  );

  /// The squiggle color. Null leaves color to the widget or theme.
  final Color? squiggleColor;

  /// The squiggle stroke gradient. Null keeps a solid color.
  final Gradient? squiggleGradient;

  /// The underline wave height in logical pixels.
  final double? amplitude;

  /// The distance between matching points in consecutive waves.
  final double? wavelength;

  /// The width of the squiggle stroke.
  final double? strokeWidth;

  /// The distance between the text baseline and the squiggle.
  final double? gap;

  /// The animation style.
  final SquigglyAnimationStyle? animationStyle;

  /// The number of wave cycles per second.
  final double? speed;

  /// The animation phase offset in turns.
  final double? phase;
}

/// Displays [text] with a customizable squiggly underline.
class SquigglyText extends StatefulWidget {
  /// Creates a squiggly text widget.
  ///
  /// Styled fields resolve in this order: the explicit constructor argument,
  /// then the matching non-null [squiggleStyle] field, then the library
  /// default. A null argument is not explicit.
  const SquigglyText(
    this.text, {
    super.key,
    this.style,
    Color? squiggleColor,
    Gradient? squiggleGradient,
    double? amplitude,
    double? wavelength,
    double? strokeWidth,
    double? gap,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.locale,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.strutStyle,
    this.semanticsLabel,
    SquigglyAnimationStyle? animationStyle,
    double? speed,
    double? phase,
    this.fluidity = 0.5,
    this.stagger = 0.2,
    this.hoverBehavior = SquigglyHoverBehavior.none,
    this.hoverRadius = 48,
    this.hoverPreview = false,
    this.hoverScope = SquigglyHoverScope.all,
    this.hoverOnly = false,
    this.pauseWhenNotVisible = true,
    this.respectReducedMotion = true,
    this.squiggleStyle,
  })  : _squiggleColor = squiggleColor,
        _squiggleGradient = squiggleGradient,
        _amplitude = amplitude,
        _wavelength = wavelength,
        _strokeWidth = strokeWidth,
        _gap = gap,
        _animationStyle = animationStyle,
        _speed = speed,
        _phase = phase,
        assert(amplitude == null || amplitude >= 0),
        assert(
          amplitude == null ||
              (amplitude == amplitude && amplitude != double.infinity),
        ),
        assert(wavelength == null || wavelength > 0),
        assert(
          wavelength == null ||
              (wavelength == wavelength && wavelength != double.infinity),
        ),
        assert(strokeWidth == null || strokeWidth > 0),
        assert(
          strokeWidth == null ||
              (strokeWidth == strokeWidth && strokeWidth != double.infinity),
        ),
        assert(gap == null || gap >= 0),
        assert(gap == null || (gap == gap && gap != double.infinity)),
        assert(maxLines == null || maxLines > 0),
        assert(speed == null || speed >= 0),
        assert(speed == null || (speed == speed && speed != double.infinity)),
        assert(
          phase == null ||
              (phase == phase &&
                  phase != double.infinity &&
                  phase != double.negativeInfinity),
        ),
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

  /// The explicit squiggle color, before [squiggleStyle] is applied.
  final Color? _squiggleColor;

  /// The explicit squiggle gradient, before [squiggleStyle] is applied.
  final Gradient? _squiggleGradient;

  /// The explicit underline height, before [squiggleStyle] is applied.
  final double? _amplitude;

  /// The explicit wavelength, before [squiggleStyle] is applied.
  final double? _wavelength;

  /// The explicit stroke width, before [squiggleStyle] is applied.
  final double? _strokeWidth;

  /// The explicit gap, before [squiggleStyle] is applied.
  final double? _gap;

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

  /// The explicit animation style, before [squiggleStyle] is applied.
  final SquigglyAnimationStyle? _animationStyle;

  /// The explicit speed, before [squiggleStyle] is applied.
  final double? _speed;

  /// The explicit phase offset in turns, before [squiggleStyle] is applied.
  final double? _phase;

  /// Shared underline and animation values.
  ///
  /// Used only for fields the constructor left unset.
  final SquigglyTextStyle? squiggleStyle;

  /// The squiggle color.
  ///
  /// An explicit constructor color wins. Otherwise this is
  /// [SquigglyTextStyle.squiggleColor] when set. Null means the underline uses
  /// [style], then [DefaultTextStyle], then the theme body color, then black.
  Color? get squiggleColor => _squiggleColor ?? squiggleStyle?.squiggleColor;

  /// The squiggle stroke gradient.
  ///
  /// An explicit constructor gradient wins over [squiggleColor]. Null keeps a
  /// solid [squiggleColor]. Glyph color stays on [style].
  Gradient? get squiggleGradient =>
      _squiggleGradient ?? squiggleStyle?.squiggleGradient;

  /// The height of the underline wave in logical pixels.
  ///
  /// Controls the underline height. It does not change letter displacement.
  /// Defaults to 2.
  double get amplitude => _amplitude ?? squiggleStyle?.amplitude ?? 2;

  /// The distance between matching points in consecutive waves.
  ///
  /// Defaults to 8.
  double get wavelength => _wavelength ?? squiggleStyle?.wavelength ?? 8;

  /// The width of the squiggle stroke.
  ///
  /// Defaults to 1.5.
  double get strokeWidth => _strokeWidth ?? squiggleStyle?.strokeWidth ?? 1.5;

  /// The distance between the text baseline and the squiggle.
  ///
  /// Defaults to 2.
  double get gap => _gap ?? squiggleStyle?.gap ?? 2;

  /// The animation style. Defaults to static rendering.
  SquigglyAnimationStyle get animationStyle =>
      _animationStyle ??
      squiggleStyle?.animationStyle ??
      SquigglyAnimationStyle.none;

  /// The number of wave cycles per second.
  ///
  /// Defaults to 1.
  double get speed => _speed ?? squiggleStyle?.speed ?? 1;

  /// The animation phase offset in turns.
  ///
  /// Added to the wave sine and, when [speed] is positive, to the letter
  /// shader clock. Defaults to 0, which keeps widgets with the same [speed]
  /// in lockstep. Negative turns are allowed and still select a shader seed
  /// from 0 through 4. [speed] of 0 does not start motion.
  double get phase => _phase ?? squiggleStyle?.phase ?? 0;

  /// The normalized strength adjustment for lift and magnetic interaction.
  final double fluidity;

  /// Reserved for per-grapheme staggering; currently has no visual effect.
  final double stagger;

  /// The pointer interaction style.
  final SquigglyHoverBehavior hoverBehavior;

  /// The pointer influence radius in logical pixels.
  final double hoverRadius;

  /// Whether to show the pointer effect around the text center by default.
  ///
  /// This is an explicit preview target. When enabled, it activates a
  /// hover-only animation even when the pointer has not entered the widget.
  final bool hoverPreview;

  /// The text region affected while pointer animation is active.
  ///
  /// [SquigglyHoverBehavior.trembleLetter] always uses a letter-sized region
  /// and [SquigglyHoverBehavior.trembleWord] always uses a word-sized region.
  /// Other pointer behaviors use this value directly.
  final SquigglyHoverScope hoverScope;

  /// Whether automatic animation waits for pointer input or keyboard focus.
  /// An explicit [hoverPreview] target also activates the animation.
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
  late final Ticker _ticker;
  late final ValueNotifier<double> _elapsedSeconds = ValueNotifier<double>(0);
  late final ValueNotifier<bool> _animationActive = ValueNotifier<bool>(false);
  Duration? _lastTickerElapsed;
  ui.FragmentShader? _shader;
  _SquigglyTextPainter? _painter;

  bool _isAnimating = false;
  bool _isFocused = false;
  bool _isAppVisible = true;
  late final ValueNotifier<Offset?> _pointerPosition =
      ValueNotifier<Offset?>(null);

  bool get _interactionConfigured =>
      widget.hoverBehavior != SquigglyHoverBehavior.none ||
      (widget.hoverOnly &&
          widget.animationStyle != SquigglyAnimationStyle.none);

  bool get _hoverNeedsAnimation =>
      widget.hoverBehavior == SquigglyHoverBehavior.trembleLetter ||
      widget.hoverBehavior == SquigglyHoverBehavior.trembleWord;

  SquigglyHoverScope get _effectiveHoverScope {
    switch (widget.hoverBehavior) {
      case SquigglyHoverBehavior.trembleLetter:
        return SquigglyHoverScope.letter;
      case SquigglyHoverBehavior.trembleWord:
        return SquigglyHoverScope.word;
      case SquigglyHoverBehavior.none:
      case SquigglyHoverBehavior.highlight:
      case SquigglyHoverBehavior.shrink:
      case SquigglyHoverBehavior.enlarge:
      case SquigglyHoverBehavior.repel:
      case SquigglyHoverBehavior.liftLetters:
      case SquigglyHoverBehavior.magnetic:
        return widget.hoverScope;
    }
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
    WidgetsBinding.instance.addObserver(this);
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'packages/flutter_squiggly_text/shaders/squiggly_turbulence.frag',
      );
      if (!mounted) {
        return;
      }
      setState(() => _shader = program.fragmentShader());
    } catch (_) {
      // Unsupported renderers and missing assets use static text.
    }
  }

  void _handleTick(Duration tickerElapsed) {
    final previous = _lastTickerElapsed;
    if (previous != null) {
      _elapsedSeconds.value += (tickerElapsed - previous).inMicroseconds /
          Duration.microsecondsPerSecond;
    }
    _lastTickerElapsed = tickerElapsed;
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
        oldWidget.phase != widget.phase ||
        oldWidget.squiggleGradient != widget.squiggleGradient ||
        oldWidget.hoverOnly != widget.hoverOnly ||
        oldWidget.hoverBehavior != widget.hoverBehavior ||
        oldWidget.hoverPreview != widget.hoverPreview ||
        oldWidget.hoverScope != widget.hoverScope ||
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
    if (_isFocused == focused) {
      return;
    }
    _isFocused = focused;
    setState(() {});
    _updateAnimation();
  }

  void _updateAnimation() {
    if (!mounted) {
      return;
    }
    final reducedMotion =
        widget.respectReducedMotion && MediaQuery.of(context).disableAnimations;
    final interactionActive =
        _pointerPosition.value != null || _isFocused || widget.hoverPreview;
    final shouldAnimate =
        (widget.animationStyle != SquigglyAnimationStyle.none ||
                (_hoverNeedsAnimation && interactionActive)) &&
            widget.speed > 0 &&
            (!widget.hoverOnly || interactionActive) &&
            (!widget.pauseWhenNotVisible || _isAppVisible) &&
            !reducedMotion;
    if (shouldAnimate != _isAnimating) {
      _isAnimating = shouldAnimate;
      _animationActive.value = shouldAnimate;
      if (shouldAnimate) {
        _lastTickerElapsed = null;
        _ticker.start();
      } else {
        _ticker.stop();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _painter?._releaseOwnedResources();
    _painter = null;
    _pointerPosition.dispose();
    _ticker.dispose();
    _elapsedSeconds.dispose();
    _animationActive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        widget.respectReducedMotion && MediaQuery.of(context).disableAnimations;
    final effectiveStyle =
        DefaultTextStyle.of(context).style.merge(widget.style);
    final effectiveColor = widget.squiggleColor ??
        effectiveStyle.color ??
        Theme.of(context).textTheme.bodyMedium?.color ??
        Colors.black;
    final direction = widget.textDirection ?? Directionality.of(context);
    final previousPainter = _painter;
    final painter = _SquigglyTextPainter(
      text: widget.text,
      style: effectiveStyle,
      color: effectiveColor,
      gradient: widget.squiggleGradient,
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
      elapsedSeconds: _elapsedSeconds,
      animationActive: _animationActive,
      shader: _shader,
      devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
      speed: widget.speed,
      phase: widget.phase,
      animationStyle: widget.animationStyle,
      fluidity: widget.fluidity,
      stagger: widget.stagger,
      pointerPosition: _pointerPosition,
      hoverBehavior:
          reducedMotion ? SquigglyHoverBehavior.none : widget.hoverBehavior,
      hoverRadius: widget.hoverRadius,
      hoverPreview: widget.hoverPreview || _isFocused,
      hoverScope: _effectiveHoverScope,
    );
    _painter = painter;
    previousPainter?._releaseOwnedResources();

    Widget child = Semantics(
      label: widget.semanticsLabel ?? widget.text,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.hasBoundedWidth
              ? (widget.softWrap ? constraints.maxWidth : double.infinity)
              : double.infinity;
          painter.layout(maxWidth: maxWidth);
          return SizedBox(
            width: (constraints.hasBoundedWidth
                    ? constraints.maxWidth
                    : painter.textPainter.width) +
                painter.horizontalPadding * 2,
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
    required this.gradient,
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
    required this.elapsedSeconds,
    required this.animationActive,
    required this.shader,
    required this.devicePixelRatio,
    required this.speed,
    required this.phase,
    required this.animationStyle,
    required this.fluidity,
    required this.stagger,
    required this.pointerPosition,
    required this.hoverBehavior,
    required this.hoverRadius,
    required this.hoverPreview,
    required this.hoverScope,
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
            elapsedSeconds,
            animationActive,
            pointerPosition,
          ]),
        );

  final TextPainter textPainter;
  final String text;
  final TextStyle style;
  final Color color;
  final Gradient? gradient;
  final double amplitude;
  final double wavelength;
  final double strokeWidth;
  final double gap;
  final ValueListenable<double> elapsedSeconds;
  final ValueListenable<bool> animationActive;
  final ui.FragmentShader? shader;
  final double devicePixelRatio;
  final double speed;
  final double phase;
  final SquigglyAnimationStyle animationStyle;
  final double fluidity;
  final double stagger;
  final ValueListenable<Offset?> pointerPosition;
  final SquigglyHoverBehavior hoverBehavior;
  final double hoverRadius;
  final bool hoverPreview;
  final SquigglyHoverScope hoverScope;

  ui.Image? _textAtlas;
  Size _atlasLogicalSize = Size.zero;
  Object? _atlasLayoutKey;

  void _rebuildAtlasIfNeeded(double maxWidth) {
    final wantsAtlas = animationStyle == SquigglyAnimationStyle.letters ||
        animationStyle == SquigglyAnimationStyle.waveAndLetters ||
        hoverBehavior != SquigglyHoverBehavior.none;
    if (!wantsAtlas) {
      _textAtlas?.dispose();
      _textAtlas = null;
      _atlasLayoutKey = null;
      return;
    }

    final key = _AtlasLayoutKey(
      text: text,
      style: style,
      locale: textPainter.locale,
      direction: textPainter.textDirection ?? TextDirection.ltr,
      align: textPainter.textAlign,
      maxWidth: maxWidth,
      maxLines: textPainter.maxLines,
      overflow: textPainter.ellipsis,
      strutStyle: textPainter.strutStyle,
      devicePixelRatio: devicePixelRatio,
      padding: _atlasOrigin,
      width: textPainter.width,
      height: textPainter.height,
    );
    if (key == _atlasLayoutKey && _textAtlas != null) {
      return;
    }

    _textAtlas?.dispose();
    _textAtlas = null;
    _atlasLayoutKey = key;
    final logicalWidth = textPainter.width + horizontalPadding * 2;
    final logicalHeight = textPainter.height + _verticalPadding * 2;
    _atlasLogicalSize = Size(logicalWidth, logicalHeight);
    final recorder = ui.PictureRecorder();
    final atlasCanvas = Canvas(recorder);
    atlasCanvas.scale(devicePixelRatio);
    textPainter.paint(atlasCanvas, _atlasOrigin);
    final picture = recorder.endRecording();
    try {
      _textAtlas = picture.toImageSync(
        (logicalWidth * devicePixelRatio).ceil(),
        (logicalHeight * devicePixelRatio).ceil(),
      );
    } catch (_) {
      _textAtlas = null;
    } finally {
      picture.dispose();
    }
  }

  double get _maximumDisplacement {
    final fontSize = style.fontSize ?? 14;
    return math.max(1.5, fontSize * 0.12);
  }

  bool get _animatesLetters =>
      animationActive.value &&
      (animationStyle == SquigglyAnimationStyle.letters ||
          animationStyle == SquigglyAnimationStyle.waveAndLetters);

  bool get _animatesWave =>
      animationActive.value &&
      (animationStyle == SquigglyAnimationStyle.wave ||
          animationStyle == SquigglyAnimationStyle.waveAndLetters);

  double get _baseAtlasPadding {
    if (!_usesAtlas) return 0;
    final pointerRoom = hoverBehavior == SquigglyHoverBehavior.none
        ? 0.0
        : math.max(7.0, (1 + fluidity) * _maximumDisplacement);
    return (_maximumDisplacement + pointerRoom).ceilToDouble() + 2;
  }

  double get _hoverScale => switch (hoverBehavior) {
        SquigglyHoverBehavior.highlight => 0.12,
        SquigglyHoverBehavior.enlarge => 0.5,
        _ => 0.0,
      };

  // The shader scales around the text center. Reserve each axis separately
  // so wrapped text can grow vertically without consuming its width budget.
  double get horizontalPadding =>
      _baseAtlasPadding + textPainter.width * _hoverScale / 2;
  double get _verticalPadding =>
      _baseAtlasPadding + textPainter.height * _hoverScale / 2;
  Offset get _atlasOrigin => Offset(horizontalPadding, _verticalPadding);

  double get height =>
      textPainter.height + gap + amplitude + strokeWidth + _verticalPadding * 2;

  void layout({required double maxWidth}) {
    final textWidth = maxWidth.isFinite && _usesAtlas
        ? math.max(0.0, (maxWidth - _baseAtlasPadding * 2) / (1 + _hoverScale))
        : maxWidth;
    textPainter.layout(
      minWidth: textWidth.isFinite ? textWidth : 0,
      maxWidth: textWidth,
    );
    _rebuildAtlasIfNeeded(maxWidth);
  }

  bool get _usesAtlas =>
      animationStyle == SquigglyAnimationStyle.letters ||
      animationStyle == SquigglyAnimationStyle.waveAndLetters ||
      hoverBehavior != SquigglyHoverBehavior.none;

  @override
  void paint(Canvas canvas, Size size) {
    if (_usesAtlas) {
      _paintAtlas(canvas);
    } else {
      textPainter.paint(canvas, _atlasOrigin);
    }

    canvas.save();
    canvas.translate(horizontalPadding, _verticalPadding);
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
      final lineGradient = gradient;
      if (lineGradient != null) {
        final baseline = line.baseline + gap + strokeWidth / 2;
        paint.shader = lineGradient.createShader(
          Rect.fromLTWH(
            line.left,
            baseline - amplitude,
            width,
            amplitude * 2,
          ),
          textDirection: textPainter.textDirection,
        );
      } else {
        paint.shader = null;
      }
      canvas.drawPath(_underlinePath(line), paint);
    }
    canvas.restore();
  }

  void _releaseOwnedResources() {
    _textAtlas?.dispose();
    _textAtlas = null;
  }

  Path _underlinePath(LineMetrics line) {
    final path = Path();
    final startX = line.left;
    final baseline = line.baseline + gap + strokeWidth / 2;
    final lineWidth = line.width;
    if (_animatesWave) {
      final sample = math.max(1.5, wavelength / 8);
      double waveY(double x) =>
          baseline +
          amplitude * math.sin(2 * math.pi * x / wavelength + _wavePhase);
      path.moveTo(startX, waveY(0));
      for (var x = sample; x < lineWidth; x += sample) {
        path.lineTo(startX + x, waveY(x));
      }
      path.lineTo(startX + lineWidth, waveY(lineWidth));
      return path;
    }

    final step = wavelength / 2;
    path.moveTo(startX, baseline);
    for (var x = 0.0; x < lineWidth; x += step) {
      final endX = math.min(x + step, lineWidth);
      final controlX = x + (endX - x) / 2;
      final direction = ((x / step).round().isEven ? 1 : -1).toDouble();
      path.quadraticBezierTo(
        startX + controlX,
        baseline + amplitude * direction,
        startX + endX,
        baseline,
      );
    }
    return path;
  }

  double get _wavePhase =>
      elapsedSeconds.value * 2 * math.pi * speed + phase * 2 * math.pi;

  /// Maps [value] into `0 .. modulo - 1`, including when [value] is negative.
  static int _positiveModulo(int value, int modulo) {
    final remainder = value % modulo;
    return remainder < 0 ? remainder + modulo : remainder;
  }

  void _paintAtlas(Canvas canvas) {
    final atlas = _textAtlas;
    if (atlas == null) {
      textPainter.paint(canvas, _atlasOrigin);
      return;
    }
    final paint = Paint();
    final fragmentShader = shader;
    if (fragmentShader == null) {
      canvas.drawImageRect(
        atlas,
        Offset.zero & Size(atlas.width.toDouble(), atlas.height.toDouble()),
        Offset.zero & _atlasLogicalSize,
        paint,
      );
      return;
    }

    final fontSize = style.fontSize ?? 14;
    final frameDuration = 0.068 / math.max(speed, double.minPositive);
    final seededElapsed =
        speed > 0 ? elapsedSeconds.value + phase / speed : elapsedSeconds.value;
    final seedIndex = _positiveModulo(
      (seededElapsed / frameDuration).floor(),
      5,
    );
    final logicalScale = (seedIndex.isOdd ? 8.0 : 6.0) * (fontSize / 100.0);
    final mapScale = logicalScale.clamp(1.5, _maximumDisplacement);
    Offset? pointer = pointerPosition.value;
    if (pointer == null && hoverPreview) {
      pointer = Offset(
        _atlasLogicalSize.width / 2,
        _atlasLogicalSize.height / 2,
      );
    }
    final textPointer = pointer == null ? null : pointer - _atlasOrigin;
    final scopeRect = pointer == null ? null : _scopeRect(textPointer!);
    final scopedRect = scopeRect?.shift(_atlasOrigin);
    fragmentShader
      ..setFloat(0, _atlasLogicalSize.width)
      ..setFloat(1, _atlasLogicalSize.height)
      ..setFloat(2, seedIndex.toDouble())
      ..setFloat(3, _animatesLetters ? mapScale : 0)
      ..setFloat(4, 0.02)
      ..setFloat(5, 3)
      ..setFloat(6, pointer?.dx ?? -10000)
      ..setFloat(7, pointer?.dy ?? -10000)
      ..setFloat(8, hoverRadius)
      ..setFloat(
        9,
        hoverBehavior == SquigglyHoverBehavior.liftLetters
            ? 1 + fluidity
            : hoverBehavior == SquigglyHoverBehavior.magnetic
                ? -(0.8 + fluidity)
                : 0,
      )
      ..setFloat(10, _hoverShaderMode)
      ..setFloat(11, _hoverScopeShaderValue)
      ..setFloat(12, pointer == null ? 0 : 1)
      ..setFloat(13, scopedRect?.left ?? -1)
      ..setFloat(14, scopedRect?.top ?? -1)
      ..setFloat(15, scopedRect?.right ?? -1)
      ..setFloat(16, scopedRect?.bottom ?? -1)
      ..setFloat(17, (6.0 * fontSize / 100).clamp(1.5, _maximumDisplacement))
      ..setImageSampler(0, atlas);
    paint.shader = fragmentShader;
    canvas.drawRect(
      Offset.zero & _atlasLogicalSize,
      paint,
    );
  }

  Rect? _scopeRect(Offset pointer) {
    if (hoverScope == SquigglyHoverScope.all) {
      return null;
    }
    final textPosition = textPainter.getPositionForOffset(pointer);
    TextRange range;
    if (hoverScope == SquigglyHoverScope.word) {
      range = textPainter.getWordBoundary(textPosition);
    } else {
      var start = 0;
      for (final grapheme in text.characters) {
        final end = start + grapheme.length;
        if (textPosition.offset >= start && textPosition.offset < end) {
          range = TextRange(start: start, end: end);
          final boxes = textPainter.getBoxesForSelection(
            TextSelection(baseOffset: range.start, extentOffset: range.end),
          );
          return _unionBoxes(boxes);
        }
        start = end;
      }
      return null;
    }
    return _unionBoxes(
      textPainter.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
      ),
    );
  }

  Rect? _unionBoxes(List<TextBox> boxes) {
    if (boxes.isEmpty) {
      return null;
    }
    var bounds = boxes.first.toRect();
    for (final box in boxes.skip(1)) {
      bounds = bounds.expandToInclude(box.toRect());
    }
    return bounds;
  }

  double get _hoverScopeShaderValue {
    switch (hoverScope) {
      case SquigglyHoverScope.all:
        return 0;
      case SquigglyHoverScope.word:
        return 1;
      case SquigglyHoverScope.letter:
        return 2;
    }
  }

  double get _hoverShaderMode {
    switch (hoverBehavior) {
      case SquigglyHoverBehavior.highlight:
        return 1;
      case SquigglyHoverBehavior.shrink:
        return 2;
      case SquigglyHoverBehavior.enlarge:
        return 3;
      case SquigglyHoverBehavior.trembleLetter:
        return 4;
      case SquigglyHoverBehavior.trembleWord:
        return 5;
      case SquigglyHoverBehavior.repel:
        return 6;
      case SquigglyHoverBehavior.none:
      case SquigglyHoverBehavior.liftLetters:
      case SquigglyHoverBehavior.magnetic:
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
      style != oldPainter.style ||
      color != oldPainter.color ||
      amplitude != oldPainter.amplitude ||
      wavelength != oldPainter.wavelength ||
      strokeWidth != oldPainter.strokeWidth ||
      gap != oldPainter.gap ||
      speed != oldPainter.speed ||
      phase != oldPainter.phase ||
      gradient != oldPainter.gradient ||
      animationStyle != oldPainter.animationStyle ||
      fluidity != oldPainter.fluidity ||
      stagger != oldPainter.stagger ||
      pointerPosition != oldPainter.pointerPosition ||
      hoverBehavior != oldPainter.hoverBehavior ||
      hoverRadius != oldPainter.hoverRadius ||
      hoverPreview != oldPainter.hoverPreview ||
      hoverScope != oldPainter.hoverScope ||
      shader != oldPainter.shader ||
      devicePixelRatio != oldPainter.devicePixelRatio ||
      elapsedSeconds != oldPainter.elapsedSeconds ||
      animationActive != oldPainter.animationActive;
}

class _AtlasLayoutKey {
  const _AtlasLayoutKey({
    required this.text,
    required this.style,
    required this.locale,
    required this.direction,
    required this.align,
    required this.maxWidth,
    required this.maxLines,
    required this.overflow,
    required this.strutStyle,
    required this.devicePixelRatio,
    required this.padding,
    required this.width,
    required this.height,
  });

  final String text;
  final TextStyle style;
  final Locale? locale;
  final TextDirection direction;
  final TextAlign align;
  final double maxWidth;
  final int? maxLines;
  final String? overflow;
  final StrutStyle? strutStyle;
  final double devicePixelRatio;
  final Offset padding;
  final double width;
  final double height;

  @override
  bool operator ==(Object other) {
    return other is _AtlasLayoutKey &&
        text == other.text &&
        style == other.style &&
        locale == other.locale &&
        direction == other.direction &&
        align == other.align &&
        maxWidth == other.maxWidth &&
        maxLines == other.maxLines &&
        overflow == other.overflow &&
        strutStyle == other.strutStyle &&
        devicePixelRatio == other.devicePixelRatio &&
        padding == other.padding &&
        width == other.width &&
        height == other.height;
  }

  @override
  int get hashCode => Object.hash(
        text,
        style,
        locale,
        direction,
        align,
        maxWidth,
        maxLines,
        overflow,
        strutStyle,
        devicePixelRatio,
        padding,
        width,
        height,
      );
}
