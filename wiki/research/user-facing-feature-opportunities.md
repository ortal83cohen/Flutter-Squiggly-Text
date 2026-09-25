# User-facing feature opportunities

Research date: 2026-09-25.

This note answers which additions would help people who depend on `flutter_squiggly_text`, given the widget that already ships. It is a product backlog, not an implementation plan.

## 1. What the package is today

`SquigglyText` paints one `String` with a squiggle under every laid-out line, plus an optional ink-jitter shader and pointer responses.

Already available:

- Static Bezier squiggle or a looping sine wave (`amplitude`, `wavelength`, `strokeWidth`, `gap`, `speed`).
- Full-run glyph displacement (`letters`, `waveAndLetters`) that keeps shaping, combining marks, ligatures, RTL, and emoji together.
- Pointer behaviors: highlight, shrink, enlarge, tremble letter, tremble word, repel, lift, magnetic, with a full-text / word / letter scope.
- Keyboard focus as a centered stand-in for the pointer when interaction is configured.
- Ordinary layout knobs: align, direction, locale, soft wrap, overflow, max lines, strut, semantics label.
- Reduced motion on by default. `pauseWhenNotVisible` follows app lifecycle, not whether the widget is inside the viewport.
- No plugins. Android, iOS, web, Windows, macOS, and Linux.

The public repository has no open issues (checked 2026-09-25). Demand below comes from gaps in the widget versus `Text`, from Flutter engine limits, and from neighboring packages.

## 2. Who the users are

Two jobs show up in the API and in the packages people reach for instead:

1. **Decorative type.** Headlines, handwriting, hero text, playful hover on web and desktop. This is the CodePen path the shader already follows (Lucas Bebber, "Squiggly Text").
2. **A controllable squiggle mark.** Spelling, grammar, or emphasis under part of a sentence. Flutter's own docs use `TextDecorationStyle.wavy` for this, and the wave shape is not configurable.

The package is strong at job 1 for a single plain string. It is weak at job 2, and it is not a drop-in `Text`.

## 3. What not to add

These already exist elsewhere and would blur the package:

| Request | Better home |
| --- | --- |
| Typewriter, fade, rotate, scramble, liquid fill | `animated_text_kit` |
| Generic fades, shimmers, and arbitrary shaders on any widget | `flutter_animate` |
| Boxes, circles, brackets, speech bubbles | `rough_notation`, `flutter_text_decorator` |
| A dictionary or suggestion popup | `simple_spell_checker`, Flutter `SpellCheckConfiguration` |
| A replacement `TextField` | `EditableText` owns caret, IME, and composing ranges |

Straight, dotted, dashed, and rainbow "draw the line once" underlines exist in `basic_underline`, including a URL launcher. Matching that catalog is less useful than making the squiggle work on real text.

## 4. Gaps that block adoption

These are the reasons a developer tries the package and goes back to `Text` or `TextDecorationStyle.wavy`.

### 4.1 Plain `String` only

The constructor takes `String`. There is no `SquigglyText.rich`, no `InlineSpan`, and no per-span style. A headline with one emphasized word, a link, or a different color has to be split into several widgets, which breaks line wrapping and the shared turbulence field.

Gradient **fills on the glyphs** can already be done with `TextStyle.foreground`, because the atlas is a normal `TextPainter` snapshot. Gradient on the **squiggle stroke** cannot. The stroke is one solid `Color`.

### 4.2 Squiggle is all or nothing

Every line with width greater than zero gets the same stroke. Callers cannot underline one word, one `TextRange`, or two kinds of mark (spelling versus grammar). That is the main thing `TextDecorationStyle.wavy` still does better: it rides on `TextSpan`s.

Flutter's built-in wavy decoration does not expose amplitude, wavelength, phase, animation, or skip-ink. `decorationThickness` is the only stroke control. Issue [flutter/flutter#174968](https://github.com/flutter/flutter/issues/174968) asks for CSS-style `text-decoration-skip-ink` because underlines cut through `g`, `j`, `p`, `q`, and `y`. A custom painter can do that; the engine still cannot.

A range API is the feature that makes this package the wavy underline people cannot get from `TextStyle`:

```dart
SquigglyText(
  'Check teh spelling',
  ranges: [
    SquiggleRange(start: 6, end: 9, color: Colors.red),
  ],
)
```

Ranges should be UTF-16 offsets into the same string `TextPainter` uses, clipped to laid-out boxes, and wrapped per line. Empty `ranges` keeps today's full-line squiggle so this stays additive.

### 4.3 It ignores system text scaling

`TextPainter` is constructed without `textScaler` (or the older `textScaleFactor`). `Text` applies `MediaQuery` text scaling. This widget does not, so large-text accessibility settings leave it at the authored font size. `textHeightBehavior` is also absent. Both are expected on anything that claims to be a text widget.

### 4.4 Hover is a mouse

Interaction is a `MouseRegion`. Touch drags and mobile pointers never update `_pointerPosition`. Keyboard focus jumps to the text center, which is the right fallback when there is no pointer, but a finger on a phone does nothing. A `Listener` (or `MouseRegion` plus pointer down/move) would feed the same local offset the shader already uses.

### 4.5 The text cannot be selected

Painting goes through `CustomPaint`. `SelectionArea` and `SelectableText` do not see glyphs. Marketing pages and docs often need copy. Static mode can stack a transparent `SelectableText` (or participate in the selection registrar) and keep the squiggle in the painter. Animated atlas mode should stay non-selectable; displacing glyphs and a selection highlight will not agree.

### 4.6 `stagger` and letter strength are not really controls

`stagger` is public, validated, stored, and documented as having no visual effect. The shader steps one turbulence seed for the whole atlas. Callers who set `stagger` see no change.

Letter travel is `max(1.5, fontSize * 0.12)` inside the painter. Underline `amplitude` is intentionally separate, so there is no public knob for how wild the ink is except font size. The example sliders expose font size and speed, not this.

## 5. Features that make the squiggle worth choosing

These do not exist in a stronger form on `TextDecorationStyle.wavy` or in `basic_underline`.

### 5.1 Stroke appearance

- **Gradient or sweep along the path.** Brand underlines and the rainbow effect people already look for in underline packages. A `Gradient` shader on the stroke `Paint` is enough; it does not need a new fragment shader.
- **Skip ink.** Break the squiggle where glyph bounds descend through the stroke. This is the readability fix Flutter's issue above is asking the engine for. Use line glyph boxes, not a second text layout.
- **Phase or seed per instance.** A list of badges that share `speed` currently waves in lockstep. An optional `phase` (turns or radians) makes them feel independent. Zero stays the default.
- **One-shot draw.** Looping motion is the only animation. Headlines often need the squiggle to draw itself once, then hold. An `Animation<double>` progress, or `repeat: false` plus `onEnd`, covers hero entrances and scroll-linked reveals. The roadmap already deferred external progress until a real use case appeared; reveal and synchronized sections are that use case.
- **Presets, not new enums for every mood.** Small constructors or a `SquiggleStyle` such as `spellcheck` (tight red wave, no letter motion), `marker` (large amplitude, one-shot), and `handwriting` (current letter shader). Presets should only fill defaults the caller did not set.

### 5.2 Motion that the API already implies

- **Implement `stagger` or stop advertising it.** If per-grapheme phase is still out of scope because displacement is one atlas, say so in the constructor docs and keep the field only for compatibility. Leaving a silent knob is worse than a missing feature.
- **Public letter scale.** Something like `letterAmplitude` in logical pixels, defaulting to today's font-size fraction, so underline height and ink travel can be tuned apart.
- **Shared clock.** An optional `Animation<double>` or `Listenable` elapsed time lets several `SquigglyText` widgets and a surrounding `flutter_animate` scene share one clock. The internal ticker remains the default, matching the "small public API" principle in the animation roadmap.

### 5.3 Fit into an app

- **`SquigglyTextTheme` via `ThemeExtension`.** Amplitude, wavelength, color, and animation style are repeated at every call site. A theme extension matches `ThemeData` without a new inherited widget.
- **`onTap` only at widget level if needed.** Per-word links belong on spans once rich text exists. A single URL field would copy `basic_underline` without helping paragraphs.
- **Interactive semantics.** A configured hover target is focusable but still exposes only a text label. When interaction is on, semantics should expose a button or a custom action so screen-reader users know focus does something. Reduced motion should also drop focusability if the focused state has no visible effect. Today focus can still be requested while pointer motion is forced off.
- **Shader fallback that apps can see.** Asset load failure is swallowed and the painter draws static text. Web HTML renderer and a missing asset look the same. A `onEffectUnavailable` callback, or a debug `FlutterError`, lets apps avoid promising jitter they cannot show. Do not add a second rendering stack.

### 5.4 Lifecycle

`TickerMode` already mutes tickers from `SingleTickerProviderStateMixin` when an ancestor disables it. `pauseWhenNotVisible` does not know about the viewport; a widget inside a long scroll view keeps the turbulence ticker until the app pauses. Prefer documenting `TickerMode` for offstage routes. A viewport check is worth adding only if a profile shows many mounted, off-screen instances. Avoid a `visibility_detector` dependency for that.

## 6. Suggested order

Value here means "a caller can do something they cannot do with `Text` plus this package today."

| Order | Feature | Why this order |
| --- | --- | --- |
| 1 | `textScaler` and `textHeightBehavior` | Correctness for a text widget. Small, and it unblocks accessibility review. |
| 2 | Squiggle `ranges` | The wavy-underline job Flutter cannot customize. Additive if omitted. |
| 3 | `SquigglyText.rich` / `InlineSpan` | Unlocks mixed style once ranges exist. `WidgetSpan` can wait; embedded widgets fight the atlas. |
| 4 | Touch pointer path | The hover API is the headline feature and does nothing on touch. |
| 5 | Public letter amplitude, and an honest `stagger` | Callers already look for these knobs. |
| 6 | Gradient stroke, skip-ink, phase | Visual reasons to prefer this painter over `TextDecorationStyle.wavy`. |
| 7 | One-shot progress / external `Animation` | Hero and scroll use, without forcing every caller to own a controller. |
| 8 | Static-mode selection | Copy on pages that do not use the shader. |
| 9 | Theme extension and presets | Convenience after the real knobs exist. |
| 10 | Viewport pause, shader callback, richer semantics | Polish after the adoption gaps. |

Explicitly later, and only if a caller asks: overline and strike squiggles, multiple hover behaviors at once, embedding the painter inside `EditableText`.

## 7. Sources

- This repo: `lib/flutter_squiggly_text.dart`, `README.md`, `wiki/plans/squiggly-text-animation-roadmap.md`, `wiki/research/configuration-interactions-review.md`, `wiki/plans/codepen-glyph-displacement-plan.md`.
- Flutter `TextDecorationStyle.wavy` and the wavy spell-check sample in `TextStyle` docs.
- Flutter issue [#174968](https://github.com/flutter/flutter/issues/174968), decoration skip-ink.
- Neighboring packages: `basic_underline`, `rough_notation`, `flutter_text_decorator`, `animated_text_kit`, `flutter_animate`, `simple_spell_checker`.
- GitHub `ortal83cohen/Flutter-Squiggly-Text` issues: none open on 2026-09-25.
