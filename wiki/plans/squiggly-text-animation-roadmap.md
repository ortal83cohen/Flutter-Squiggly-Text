# SquigglyText Animation Roadmap

## Status

Sections 3 onward are the original proposal. They are not a description of the shipped widget. For the code as it is now, use [SquigglyText Implementation Summary](../summaries/squiggly-text-implementation-summary.md).

## 1. Goal

Evolve `SquigglyText` from a static squiggly underline into an optional, web-inspired text animation widget while preserving the current static behavior, Flutter text layout features, and accessibility contract.

The feature should support:

- Animated underline waves.
- Per-grapheme letter motion when appropriate.
- Configurable speed, phase staggering, and motion fluidity.
- Pointer hover interactions on desktop and web.
- Keyboard focus parity where hover is unavailable.
- Reduced-motion behavior.
- Multiline, alignment, RTL, emoji, and accessibility support.

Static rendering remains the default so existing users do not receive an unexpected animation or performance cost.

## 2. Shipped status

The widget now does the following. This replaces the 2026-09-16 status note, which described grapheme splitting and only three hover modes.

- Static rendering stays the default.
- The underline wave uses monotonic elapsed time.
- Letter modes displace one full-text atlas with a fragment shader. They do not split graphemes or fall back by script.
- Hover behaviors also include shrink, enlarge, tremble-letter, tremble-word, and repel, with `hoverScope` and `hoverPreview`.
- `trembleLetter` and `trembleWord` ignore the caller's scope and use a letter or word region.
- Keyboard focus and `hoverPreview` share a centered pointer target.
- Reduced motion stops the ticker and clears pointer motion.
- `pauseWhenNotVisible` follows app lifecycle only, not viewport visibility.
- `stagger` has no visual effect. `fluidity` is lift and magnetic strength, not a spring.

## 3. Original baseline

This section describes the package before animation work. It is not the current widget.

The implementation at that time was in `lib/flutter_squiggly_text.dart`:

- `SquigglyText` is a `StatelessWidget`.
- Text is laid out by one `TextPainter`.
- Text and underline paths are painted by one `CustomPainter`.
- The underline is generated per line from quadratic Bezier segments.
- Wrapping, alignment, directionality, locale, maximum lines, strut style, and semantics are already part of the public surface.
- There is no animation clock, hover state, per-letter layout cache, or external animation control.

At that time the tests covered semantics and multiline rendering in `test/flutter_squiggly_text_test.dart`.

## 4. Product Principles

1. **Static by default**: `animationStyle` defaults to `none`.
2. **Progressive enhancement**: animation must not remove existing text-layout capabilities.
3. **Accessibility first**: motion is optional, semantics expose the original text, and reduced-motion settings are respected.
4. **Cache layout, animate paint**: frame updates should repaint existing geometry rather than relayout text.
5. **Grapheme-safe behavior**: split visible units by grapheme clusters, not UTF-16 code units.
6. **Graceful degradation**: complex scripts and unsupported text shaping must remain readable even if per-letter effects are disabled.
7. **Small public API**: expose useful controls without forcing callers to manage Flutter animation lifecycle details.

## 5. Proposed Public API

The exact names can be finalized during implementation, but the initial API should be close to:

```dart
enum SquigglyAnimationStyle {
  none,
  wave,
  letters,
  waveAndLetters,
}

enum SquigglyHoverBehavior {
  none,
  highlight,
  liftLetters,
  magnetic,
}
```

Candidate `SquigglyText` properties:

```dart
final SquigglyAnimationStyle animationStyle;
final double speed;
final double fluidity;
final double stagger;
final SquigglyHoverBehavior hoverBehavior;
final double hoverRadius;
final bool hoverOnly;
final bool pauseWhenNotVisible;
final bool respectReducedMotion;
```

Recommended semantics:

- `speed`: animation cycles per second or a documented speed multiplier. Choose one unit and keep it stable.
- `fluidity`: how strongly position changes are smoothed. Low values feel direct; high values feel spring-like.
- `stagger`: phase offset between neighboring graphemes.
- `hoverBehavior`: selects the pointer response without requiring custom callbacks.
- `hoverRadius`: pointer influence radius in logical pixels.
- `hoverOnly`: prevents automatic motion until the pointer enters the widget.
- `pauseWhenNotVisible`: allows the implementation to stop its ticker when animation is not useful.
- `respectReducedMotion`: disables or substantially reduces motion when accessibility settings request it.

The first implementation should avoid exposing an `AnimationController` directly. An internal controller keeps lifecycle management simple. External progress control can be added later through an optional `Animation<double>` if real use cases require synchronization.

## 6. Rendering Architecture

### 5.1 Layout model

Keep one authoritative text layout for normal painting and add a cached animated layout only when a per-letter style is requested.

The cache should contain:

- Grapheme cluster text.
- Cluster bounds and baseline position.
- Line index.
- Visual center for hover calculations.
- Text painter or shaped run data needed for painting.
- Whether the cluster is eligible for independent transformation.

Invalidate the cache when text, style, locale, direction, constraints, wrapping, maximum lines, overflow, or strut configuration changes.

### 5.2 Grapheme and shaping rules

Do not split the string with `split('')`. Use grapheme clusters so emoji, combining marks, and joined sequences remain intact.

Per-cluster painting can alter kerning or ligatures. The implementation should therefore:

- Prefer per-cluster animation for simple Latin and Hebrew text.
- Detect or document cases where shaping must remain grouped.
- Fall back to painting the full shaped text without independent transforms when necessary.
- Never sacrifice legibility for an animation effect.

An explicit `characters` dependency is acceptable if the Dart SDK does not provide the required grapheme API directly.

### 5.3 Painter lifecycle

Refactor the painter so that:

- Static mode uses normal `CustomPainter` repaint comparisons.
- Animated mode receives a `Listenable` or animation object through `repaint`.
- Layout is not recomputed on every frame.
- `shouldRepaint` compares configuration and cached layout identity instead of always returning `true`.
- A `RepaintBoundary` is considered for frequently animated instances.

## 7. Animation Model

### Phase 1: Animated underline

Add a time phase to the existing underline path. The wave can be represented as:

`y(x, t) = amplitude * sin(2 * pi * x / wavelength + phase(t))`

Acceptance criteria:

- Existing static output is unchanged when animation is disabled.
- `speed` changes the phase progression predictably.
- The animation can repeat indefinitely without rebuilding the widget tree.
- The wave remains correct for every laid-out line.

### Phase 2: Per-letter motion

For grapheme index `i`, use a phase offset derived from `stagger`:

`offset(i, t) = letterAmplitude * sin(phase(t) + i * staggerPhase)`

Initial transforms should be deliberately restrained:

- Vertical translation.
- Small rotation.
- Optional scale near the hover target.

Do not combine large translation, rotation, scale, and opacity changes by default. The text must remain easy to read.

### Phase 3: Fluidity

Use a smoothing layer between the target transform and the displayed transform. The first version can use a documented curve or interpolation. A spring model can follow after measurements show that it improves the interaction.

`fluidity` must be bounded and validated. Avoid making it an ambiguous multiplier that changes different animation properties unpredictably.

## 8. Hover and Focus Interaction

### Pointer behavior

Wrap the widget in `MouseRegion` only when a hover behavior is enabled. Track the pointer in local coordinates and calculate influence per grapheme from its visual center.

A Gaussian or smoothstep falloff is suitable:

`influence = exp(-distanceSquared / (2 * hoverRadiusSquared))`

The pointer should affect nearby letters more than distant letters. The response must be smoothed so rapid pointer movement does not cause visible jumps.

### Keyboard and accessibility parity

Hover-only behavior should not be the only way to discover the effect. Add a focus path:

- Support focusable usage without changing the default semantics label.
- Trigger a restrained focus animation when the widget receives keyboard focus.
- Keep the pointer-specific magnetic effect optional.
- Respect `MediaQuery.disableAnimations` and the platform accessibility setting.

## 9. Roadmap Phases

### Status snapshot

These phases are the original plan. Later work replaced per-grapheme motion with shader displacement. Do not read a "completed" phase as the current rendering model.

- Phase 0: The static baseline and `softWrap: false` fix are in the widget.
- Phase 1: The underline wave is in the widget, driven by a `Ticker` and elapsed seconds.
- Phase 2: Per-grapheme caches and shaping fallback were not shipped. Letter modes snapshot the full shaped run.
- Phase 3: Letter motion is shader displacement. `stagger` is unused, and `fluidity` is not a smoothing spring.
- Phase 4: Hover includes the original three modes plus shrink, enlarge, tremble, and repel.
- Phase 5: Reduced motion and app-lifecycle pausing are in the widget. Viewport visibility is still open.
- Phase 6: The example app and changelog exist. Benchmarks called for below are not in the test suite.


### Phase 0: Baseline and contracts

- Preserve all current constructor behavior.
- Add validation for new numeric parameters.
- Fix or explicitly define `softWrap` behavior before introducing per-letter layout.
- Add tests for default static behavior, semantics, multiline layout, RTL, and long text.
- Record the public API decision in the changelog when implementation begins.

**Exit criteria:** existing tests pass and the package has a documented static baseline.

### Phase 1: Animation foundation

- Convert the widget to stateful lifecycle management or introduce an equivalent internal animation owner.
- Add an internal repeating controller.
- Connect the controller to `CustomPainter.repaint`.
- Implement `animationStyle: wave`.
- Stop the controller when no animation is enabled.

**Exit criteria:** animated underline works at a stable frame rate and static mode does not tick.

### Phase 2: Cached per-grapheme layout

- Add grapheme-safe segmentation.
- Build and invalidate the layout cache.
- Preserve wrapping, alignment, directionality, overflow, and line metrics.
- Add a fallback for text that should remain shaped as a single run.

**Exit criteria:** every supported grapheme has a stable visual position across frames and multiline tests remain reliable.

### Phase 3: Letter animation

- Implement `letters` and `waveAndLetters`.
- Add vertical motion first, then optional rotation and scale.
- Apply `speed`, `fluidity`, and `stagger` consistently.
- Keep amplitudes conservative by default.

**Exit criteria:** per-letter motion is readable, configurable, and does not relayout on every tick.

### Phase 4: Hover interaction

- Add `MouseRegion` conditionally.
- Implement `highlight` and `liftLetters` first.
- Add `magnetic` only after pointer smoothing and performance are verified.
- Add focus behavior for keyboard users.

**Exit criteria:** hover works on web and desktop, has no effect on mobile without pointer input, and remains accessible by focus.

### Phase 5: Accessibility and lifecycle polish

- Respect reduced-motion preferences.
- Pause when the widget is disabled, detached, or not visible where practical.
- Verify semantics and screen-reader output.
- Test text selection and interaction with parent gesture detectors.
- Document animation costs and recommended usage.

**Exit criteria:** animation is optional, controllable, and safe for accessibility-sensitive applications.

### Phase 6: Release and feedback

- Update README usage examples.
- Add changelog entries and migration notes.
- Add screenshots or a small example app showing the animation styles.
- Benchmark static and animated modes.
- Release as a minor version if the API is additive; use a major version only for breaking changes.

## 10. Testing Strategy

Add focused widget and painter tests for:

- Animation disabled by default.
- Underline phase changes after advancing fake time.
- Speed changes produce different phase progression.
- Invalid speed, fluidity, stagger, and hover radius values fail validation.
- Multiline text animates each visible line correctly.
- Center, start, end, and justified alignment remain correct.
- LTR and RTL layouts use the correct visual order.
- Emoji and combining marks remain a single animated unit.
- Hover affects only clusters inside the configured radius.
- Pointer exit returns transforms smoothly to their idle state.
- Focus can trigger a non-pointer interaction.
- Reduced motion disables or limits animation.
- Semantics still expose the complete original string.
- Static mode does not keep an active ticker.

Use deterministic fake time for animation assertions. Avoid pixel-perfect tests for every frame; reserve golden tests for a small number of stable static and representative animated states.

## 11. Performance Targets

The implementation should aim for:

- No per-frame text layout in the normal animation path.
- No widget-per-letter tree for the default implementation.
- A single painter repaint for the whole text instance.
- Cached geometry invalidated only by layout-affecting changes.
- Static instances with no animation ticker.
- Reasonable behavior for long strings and multiple animated instances.

Benchmark at least:

- One short animated label.
- One multiline paragraph.
- Several animated labels in a scrolling list.
- A long string with hover enabled.

If per-letter painting becomes expensive, reduce optional transforms before reducing text quality or disabling the underline.

## 12. Documentation Deliverables

Update the following when implementation begins:

- `README.md`: basic animated usage and accessibility note.
- `CHANGELOG.md`: public API additions and behavior changes.
- `wiki/README.md`: link to this roadmap and later decision records.
- A future example or demo: all animation styles, hover behavior, reduced motion, RTL, and long text.

## 13. Open Decisions

Resolve these during Phase 0 or Phase 1:

1. Whether to add the `characters` package or use an available SDK API.
2. Whether `speed` is expressed as cycles per second or a unitless multiplier.
3. Whether `fluidity` should begin as interpolation or a true spring simulation.
4. Which complex-script cases require grouped shaping fallback.
5. Whether external animation progress is needed in the first public release.
6. Whether visibility detection is worth the dependency or can use lifecycle and ticker pausing only.
7. The minimum Flutter SDK version required for the final implementation.

## 14. Definition of Done

The feature is ready for release when:

- Static behavior remains compatible by default.
- Wave and per-letter modes work with documented parameters.
- Hover and focus interactions are optional and predictable.
- Multiline, RTL, emoji, and semantics tests pass.
- Reduced-motion behavior is implemented and documented.
- Animated instances avoid repeated text layout.
- README and changelog examples are complete.
- `dart format`, `flutter analyze`, and `flutter test` pass.
- A representative demo has been manually checked on web and at least one non-web Flutter target.
