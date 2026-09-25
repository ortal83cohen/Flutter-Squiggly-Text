# SquigglyText Animation Technical Research

## Status

This note describes the widget before animation was added: a `StatelessWidget` whose painter always repainted. That is no longer the code. The shipped behavior is in [SquigglyText Implementation Summary](../summaries/squiggly-text-implementation-summary.md).

## Purpose

This document turns the animation roadmap into implementation constraints. It is based on the current package implementation, the package minimums (`Dart >=3.0.0`, `Flutter >=3.10.0`), and the behavior that must remain stable for existing users.

## Current implementation findings

The widget currently has three important properties:

1. `SquigglyText` is a `StatelessWidget` that constructs a new painter during build.
2. `_SquigglyTextPainter` owns one `TextPainter`, lays it out in `LayoutBuilder`, paints the complete text, and then paints one quadratic-Bezier underline per line.
3. `shouldRepaint` always returns `true`, so the current implementation does not provide a useful configuration or layout identity for animation caching.

The existing public surface already includes wrapping, alignment, directionality, locale, maximum lines, overflow, strut style, and a semantic label. These are layout contracts, not optional details. Animation must be layered on top of them.

There is one baseline defect to resolve before animation work: `softWrap` is accepted by `SquigglyText`, but it is not passed into the layout decision. `TextPainter` has no `softWrap` property; the widget must pass an infinite layout width when `softWrap` is `false`, while still respecting the incoming width when it is `true`.

## Recommended architecture

Use a stateful widget with an internal animation owner, but keep layout data in a separate immutable model.

### Widget and state

`SquigglyText` should remain the public widget and retain its existing constructor parameters. Add the new enum and numeric properties as additive parameters with static-safe defaults. `_SquigglyTextState` should own:

- An `AnimationController` only when automatic animation is needed.
- A `FocusNode` only when focus interaction is enabled, or a carefully managed supplied focus path if one is added later.
- Pointer position and hover-enter state.
- The current effective reduced-motion decision.

The widget should not expose its controller in the first release. Internal lifecycle management avoids requiring every caller to provide `TickerProvider`, dispose a controller, or coordinate a ticker with widget updates.

### Layout and paint models

Split the current painter responsibilities into:

- An immutable layout snapshot containing the `TextPainter`, line metrics, widget size, line starts, and optional grapheme records.
- A `CustomPainter` that receives the snapshot and a `Listenable` repaint source.

The state should rebuild the snapshot only when a layout-affecting input changes. The controller should trigger painter repaint without calling `setState` and without rebuilding the widget tree each frame.

The snapshot key must include at least:

- Text and effective `TextStyle`.
- Locale and text direction.
- Text alignment, soft-wrap mode, maximum lines, overflow, and strut style.
- The bounded width supplied by `LayoutBuilder`.
- Animation mode when it changes whether grapheme records are required.

Paint-only values such as wave phase, hover position, and current transform values must not invalidate text layout.

## Text layout, graphemes, and shaping

### Grapheme segmentation

Do not use `split('')` or iterate through UTF-16 code units. Add the `characters` package if the minimum SDK-compatible release can be selected, and use its grapheme-cluster iteration. Store each cluster's UTF-16 start and end offsets so it can be related back to `TextPainter` selections and line metrics.

The segmentation model must preserve:

- Combining marks attached to a base character.
- Emoji modifiers and variation selectors.
- Zero-width-joiner emoji sequences.
- Regional-indicator flag sequences.
- Indic and other scripts where a visible unit may span multiple code points.

### Position records

For each eligible cluster, store:

- The original cluster string and UTF-16 range.
- Its line index.
- A paint rectangle or baseline-relative origin.
- Its visual center.
- The shaped/independent-paint eligibility decision.

`TextPainter.getBoxesForSelection` can provide boxes for UTF-16 ranges and is useful for locating clusters without manually measuring every character. The implementation must verify its behavior for newline ranges, trailing spaces, bidi text, and clusters that produce multiple boxes. A cluster with multiple boxes or no stable box should be marked ineligible for independent animation.

### Shaping fallback

Painting every cluster with a separate `TextPainter` can change kerning, ligatures, joining behavior, and script shaping. The implementation should therefore use a conservative eligibility policy:

- Start with independently painted clusters only for simple, single-box runs where the cluster boundaries and visual order are unambiguous.
- Treat complex scripts, clusters with multiple boxes, and uncertain bidi mappings as grouped runs or as full-text fallback.
- Preserve the original full-text painting path when the fallback is selected.

Fallback is a correctness feature. It is preferable to omit letter motion for a run than to produce broken glyph shaping.

### Overflow and ellipsis

Ellipsis changes what is visibly painted and cannot be inferred safely from the original string alone. The first implementation should build grapheme records from the visible text boxes and mark records beyond the painted range as unavailable. If exact visible-range mapping is not reliable for a given case, use full-text fallback for that layout rather than animating hidden or duplicated text.

## Animation APIs and models

### Public enums and parameters

Use the proposed enums:

```dart
enum SquigglyAnimationStyle { none, wave, letters, waveAndLetters }

enum SquigglyHoverBehavior { none, highlight, liftLetters, magnetic }
```

Recommended first-release semantics:

- `speed`: cycles per second, default `1.0`; require a finite value greater than or equal to zero.
- `fluidity`: normalized smoothing amount from `0.0` to `1.0`; `0.0` follows targets directly and larger values increase smoothing. Require a finite value in range.
- `stagger`: phase offset in radians between adjacent visual grapheme records; require a finite value.
- `hoverRadius`: logical pixels, finite and greater than zero when hover behavior is enabled.
- `hoverOnly`: automatic animation is disabled until hover or focus activates the effect.
- `pauseWhenNotVisible`: a best-effort lifecycle optimization, not a promise of viewport visibility detection in the first release.
- `respectReducedMotion`: default `true`; reduced motion disables continuous motion and leaves only static rendering or a restrained, non-looping interaction.

Document units explicitly. Do not make `speed` or `fluidity` overloaded multipliers whose meaning changes by animation style.

### Wave phase

Represent underline motion with a phase supplied by the controller:

$$
y(x,t) = A \sin\left(2\pi\frac{x}{\lambda} + \phi(t)\right)
$$

The phase should advance as `2 * pi * speed * elapsedSeconds`. Keep the existing static path as the `none` path so static output remains stable. For animated lines, the same phase can be used for each line, or a documented line offset can be added later; do not make line offsets implicit.

### Letter transforms

For eligible record index `i`, derive a target transform from the same phase and the configured stagger:

$$
\Delta y_i(t) = A_l \sin\left(\phi(t) + i \cdot s\right)
$$

Start with a small vertical translation. Rotation and scale should be separate bounded options internally and should not be combined at large amplitudes. The initial public API does not need to expose every transform component.

### Fluidity

Implement fluidity first as a deterministic interpolation toward the target transform. This is easier to test and does not require a simulation tick whose behavior varies with frame duration. A spring can be introduced later only if interaction testing demonstrates a real benefit. Clamp all displayed transforms to conservative bounds so a large input cannot make text unreadable.

## Pointer, focus, and accessibility behavior

### Pointer input

Build a `MouseRegion` only when a hover behavior is configured and reduced motion has not disabled the behavior. Convert `PointerHoverEvent.localPosition` to the widget's local coordinates and calculate influence from each record center:

$$
I = \exp\left(-\frac{d^2}{2r^2}\right)
$$

Use a small epsilon or a positive-value assertion for `r`. Pointer exit should clear the target and interpolate back to idle. `highlight` should modify visual emphasis without changing layout. `liftLetters` should apply a bounded vertical offset. `magnetic` should be deferred until the preceding behaviors have verified pointer smoothing and performance.

Do not add a pointer listener on mobile when no pointer behavior is requested. Do not use a widget per letter; one `MouseRegion` and one painter are sufficient.

### Focus parity

Focus must be opt-in or tied to an explicit interaction configuration so the default widget does not unexpectedly enter the focus order. When focus is enabled, use `Focus`/`FocusableActionDetector` behavior compatible with the package minimum, preserve the semantic label, and trigger a restrained focus state. Focus should provide a discoverable non-pointer response, not emulate the exact magnetic cursor field.

### Reduced motion

Use the platform/media accessibility signal available in the minimum supported Flutter API, and verify the exact API name against Flutter 3.10 during implementation. The current SDK exposes `MediaQuery.disableAnimations`; the implementation must compile against the package minimum rather than only the installed SDK.

When reduced motion is requested:

- Do not run an infinite controller for continuous wave or letter motion.
- Render the static underline and text by default.
- Either suppress hover/focus motion or allow only a single restrained state change, and document the choice.
- Preserve semantics and all text layout behavior.

## Lifecycle, visibility, and repaint

Use `TickerProviderStateMixin` only while the internal controller is needed. Create, start, stop, and dispose it in response to widget updates and lifecycle changes. The controller should be inactive for `animationStyle == none`, for reduced motion, and for `hoverOnly == true` until activation.

`CustomPainter(repaint: controller)` is the preferred frame path. `shouldRepaint` should compare configuration and layout snapshot identity; phase changes arrive through `repaint` and must not require `shouldRepaint` to return `true` for every widget build.

`pauseWhenNotVisible` should initially mean pausing when the widget is detached or the app is inactive if those signals can be handled without extra dependencies. True viewport visibility requires `visibility_detector` or an equivalent mechanism and should be a separate decision because it adds dependency and scheduling complexity. A `RepaintBoundary` can be considered for repeated animated labels, but it should be measured rather than applied indiscriminately.

## Testing and measurement findings

The current tests only verify semantics and that a wrapped widget does not throw. The implementation needs deterministic tests at three layers:

- Constructor and validation tests for finite numeric ranges and static defaults.
- Widget tests using `FakeAsync`/`WidgetTester` time control to verify controller activation, phase progression, reduced motion, hover, focus, and semantics.
- Painter/layout tests for line starts, dimensions, snapshot invalidation, grapheme records, and fallback decisions.

Use stable structural assertions instead of asserting exact raster pixels for every frame. Keep a small number of golden tests for static output and representative animation phases. Add RTL, combining-mark, emoji, multiline, alignment, overflow, and long-text cases.

Performance measurements should compare static mode, wave mode, letter mode, and hover mode for a short label, multiline paragraph, long text, and many instances in a scrolling list. Confirm that animation frames do not call text layout. If performance is poor, reduce optional transform work before degrading glyph quality.

## Dependency and compatibility decisions

1. The `characters` package is the recommended dependency for grapheme clusters, subject to selecting a release compatible with Dart 3.0. Verify with `flutter pub get` and the package's published SDK constraints before editing `pubspec.yaml`.
2. Do not add a visibility dependency in the first implementation unless lifecycle pausing is insufficient and profiling demonstrates a need.
3. Do not require an external animation package; Flutter's controller, painter, focus, and pointer APIs are sufficient.
4. Keep the minimum SDK unchanged unless a required API cannot be implemented compatibly. If the minimum must rise, make that a deliberate release decision with changelog and migration notes.

## Research conclusions

The safest implementation order is: repair and test the static layout contract, add phase-driven underline animation, introduce a cache with conservative shaping fallback, add restrained letter motion, then add hover/focus and reduced-motion polish. The controlling invariant throughout is that layout-affecting inputs rebuild the snapshot, while time and interaction only repaint it.