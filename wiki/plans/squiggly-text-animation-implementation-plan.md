# SquigglyText Animation Implementation Plan

## Scope and release strategy

Implement the roadmap as additive, reviewable slices. The first release must preserve the current visual and semantic behavior when `animationStyle` is `SquigglyAnimationStyle.none`. No controller, pointer listener, per-grapheme cache, or animation repaint should exist in that default path.

The work should be delivered in six implementation phases. Each phase has a narrow code surface, focused tests, and an exit gate. Do not begin a later phase while an earlier phase changes the interpretation of the layout contract.

## Phase 0: Baseline contracts and API decision

### Objectives

- Freeze the current static behavior as the compatibility baseline.
- Decide and document the public parameter units and validation rules.
- Correct `softWrap` behavior before introducing animated layout data.
- Establish tests for semantics, dimensions, multiline layout, alignment, directionality, and long text.

### Files and responsibilities

- `lib/flutter_squiggly_text.dart`: add enums, additive constructor properties, assertions, and the corrected layout-width decision.
- `test/flutter_squiggly_text_test.dart`: add static contract tests.
- `CHANGELOG.md`: record the additive API only when the API is actually introduced.
- `wiki/decisions/`: record final choices for speed units, fluidity model, grapheme dependency, shaping fallback, and minimum SDK.

### API contract

Add:

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

Use defaults that produce no animation and no extra interaction. Validate every numeric value with finite checks and bounded ranges. Assertions are appropriate for programmer errors, but painter code should still clamp or guard values so a release build cannot enter an invalid arithmetic path.

Recommended initial defaults:

- `animationStyle: none`
- `speed: 1.0`
- `fluidity: 0.0`
- `stagger: pi / 4`
- `hoverBehavior: none`
- `hoverRadius: 48.0`
- `hoverOnly: false`
- `pauseWhenNotVisible: true`
- `respectReducedMotion: true`

The exact defaults for non-static parameters may change during implementation, but they must be explicit in API docs and tests.

### `softWrap` correction

In the `LayoutBuilder` path, use `constraints.maxWidth` only when `softWrap` is true and the width is bounded. Use `double.infinity` otherwise. Preserve the existing widget width policy, but test unbounded and bounded parents so the change is intentional rather than incidental.

### Tests and exit criteria

Add tests that verify:

- The default widget exposes the complete original text through semantics.
- Static rendering creates no active ticker.
- `softWrap: false` does not wrap at a bounded width.
- Multiline wrapping remains exception-free with `softWrap: true`.
- Start, center, end, justified, LTR, and RTL configurations retain expected size and line starts.
- Invalid speed, fluidity, stagger, and hover radius values fail fast.

Exit only when `dart format`, `flutter analyze`, and the focused widget tests pass.

## Phase 1: Animation foundation and wave mode

### Objectives

- Convert the widget to stateful lifecycle management.
- Add a repeating controller only for active automatic animation.
- Connect the controller to a painter repaint source.
- Implement `wave` without changing the static path.

### Implementation sequence

1. Convert `SquigglyText` to `StatefulWidget` without changing its public constructor.
2. Add `_SquigglyTextState` with `TickerProviderStateMixin`.
3. Define a single internal phase source. Prefer controller value plus elapsed-time normalization, or a controller duration derived from `speed`, but keep speed behavior mathematically predictable.
4. Start/stop the controller from `initState`, `didUpdateWidget`, reduced-motion changes, and interaction activation changes.
5. Move the painter construction into the layout builder so the painter receives the current immutable layout snapshot and the controller as `repaint`.
6. Add animated underline phase to each line while preserving the existing line-start and baseline calculations.

### Controller rules

- `none` never starts a ticker.
- `wave`, `letters`, and `waveAndLetters` start only when motion is allowed and not blocked by `hoverOnly`.
- A zero speed may render a stable phase and should not need continuous ticking.
- Disposing the widget must dispose the controller and any internally owned focus node.
- Configuration changes must not leak a previous controller or restart unnecessarily.

### Tests and exit criteria

Use deterministic fake time to verify that:

- Static mode does not tick.
- The underline phase changes after advancing time in `wave` mode.
- Doubling speed produces the documented phase progression.
- Multiple laid-out lines receive valid underline paths.
- Rebuilding the parent does not recreate layout work merely because time advanced.

Add a focused painter test for the static path so the old underline geometry remains covered. Exit when wave mode is stable in widget tests and the static regression suite remains green.

## Phase 2: Cached per-grapheme layout

### Objectives

- Add grapheme-safe segmentation.
- Build stable records only when a letter animation style is requested.
- Preserve layout features and establish shaping fallback.

### Implementation sequence

1. Add the selected `characters` dependency after confirming Dart 3.0 compatibility.
2. Build grapheme records from UTF-16 ranges, retaining original text offsets.
3. Layout the complete text with the authoritative `TextPainter` first.
4. Resolve each record's boxes with `getBoxesForSelection` and map it to line metrics.
5. Reject records with ambiguous/multiple boxes, newline-only ranges, unavailable visible geometry, or unsupported shaping conditions.
6. Mark the entire affected run, or the whole text where necessary, for full-text fallback.
7. Store the snapshot in a cache owned by the state or layout builder. Rebuild it only when the layout key changes.

### Layout invalidation matrix

Rebuild for text, style, locale, direction, alignment, soft wrap, max lines, overflow, strut style, bounded width, and any change between no-letter and letter animation mode. Do not rebuild for phase, pointer position, focus state, or current interpolation values.

### Painting strategy

Use one of two explicit paths:

- Full-text path: paint the authoritative `TextPainter` exactly once, then paint the underline.
- Independent-record path: paint only eligible records at transformed offsets, and paint in visual order. Never paint the full text first and then paint transformed records over it.

If independent painting cannot preserve shaping or overflow, use the full-text path and suppress letter transforms for that snapshot.

### Tests and exit criteria

Add records/layout tests for:

- ASCII clusters.
- Combining marks.
- Emoji ZWJ sequences and flags.
- Multiline text.
- LTR and RTL visual order.
- Center, start, end, and justified alignment.
- Ellipsis and max-lines fallback.
- Complex/ambiguous records falling back without exceptions.

Exit when snapshots are stable across repaint-only frames and all existing layout tests pass.

## Phase 3: Letter motion and fluidity

### Objectives

- Implement `letters` and `waveAndLetters`.
- Apply restrained per-record transforms.
- Make speed, stagger, and fluidity consistent and deterministic.

### Implementation sequence

1. Add vertical translation based on phase plus record index stagger.
2. Define conservative internal amplitude bounds relative to text size or line height.
3. Add optional small rotation only after the vertical transform is tested.
4. Apply hover/focus target values through the same transform pipeline rather than introducing a second painter path.
5. Interpolate displayed transform values toward target values using the normalized `fluidity` setting.
6. Keep underline phase and letter phase derived from one time source so `waveAndLetters` cannot drift unexpectedly.

### Tests and exit criteria

Verify with fake time that:

- `letters` leaves the underline static unless the mode includes wave behavior.
- `waveAndLetters` drives both effects from the same phase.
- Adjacent records differ by the configured stagger.
- Fluidity changes convergence without changing the target phase.
- Transform bounds remain conservative for extreme but valid settings.
- Letter animation does not call text layout during a frame.

Exit when animation remains readable at default settings and fallback text remains exactly legible.

## Phase 4: Hover and focus interaction

### Objectives

- Add conditional pointer handling.
- Implement highlight and lift behavior first.
- Add keyboard focus parity.
- Defer magnetic behavior until performance and smoothing are demonstrated.

### Pointer implementation

Wrap the painted content in `MouseRegion` only when `hoverBehavior != none`. Keep the pointer position in local coordinates. Compute influence from each record center using the configured radius and smooth it through the existing target/display transform pipeline.

Behavior definitions:

- `none`: no pointer listener and no interaction state.
- `highlight`: alter color/opacity or a bounded emphasis value; do not change geometry.
- `liftLetters`: apply a small influence-weighted vertical lift to nearby eligible records.
- `magnetic`: reserved for a follow-up implementation after pointer movement and painting costs are measured.

On exit, clear the target and animate back to idle. When no records are independently paintable, highlight may still work through the full-text path; lift and magnetic should gracefully do nothing.

### Focus implementation

Make focus behavior explicit and accessible. Avoid adding every `SquigglyText` to the default tab order. A future public focus option or supplied focus node should be chosen before implementation; if no public option is added, focus can remain available through an interaction wrapper documented for consumers.

The focus response must preserve `semanticsLabel`, be visible without a pointer, and remain restrained. Add keyboard traversal tests and verify that parent gesture detectors are not broken.

### Tests and exit criteria

Test pointer enter, movement, radius falloff, exit restoration, focus activation, and no pointer effect when hover is disabled. Verify hover is inert under reduced motion according to the chosen policy. Exit when desktop/web behavior is deterministic and mobile does not pay for unused pointer handling.

## Phase 5: Accessibility and lifecycle polish

### Objectives

- Integrate reduced-motion preferences.
- Pause work when it is not useful.
- Validate semantics, lifecycle, selection, and gesture coexistence.

### Reduced-motion decision

Read `MediaQuery.disableAnimations` at build time and update controller state when it changes. Confirm the API against Flutter 3.10 before implementation. With reduced motion enabled, render static text and underline by default and stop continuous ticking. Document any one-shot focus or hover emphasis explicitly.

### Lifecycle decision

Implement app lifecycle pausing if it can be done without changing public behavior. Treat true viewport visibility as optional until profiling justifies a dependency. `pauseWhenNotVisible` must not imply that the widget knows its scroll viewport position unless a visibility mechanism is actually installed.

### Tests and exit criteria

Add tests for reduced motion, app inactive/resume behavior, widget disposal, semantics, selection compatibility, and parent gesture detectors. Confirm no ticker remains active after unmounting. Exit when accessibility-sensitive applications can opt into the feature without losing readable text or the complete semantic label.

## Phase 6: Documentation, example, benchmarking, and release

### Documentation edits

- `README.md`: add a minimal animated example, parameter units, static-default statement, reduced-motion behavior, and a note about complex-script fallback.
- `CHANGELOG.md`: describe additive enums/properties, corrected `softWrap` behavior if released, and any minimum SDK change.
- `wiki/README.md`: link the roadmap, this implementation plan, the research document, and final decision records.
- `example/`: add a runnable demonstration covering all styles, hover, focus, reduced motion, RTL, multiline, and long text.

### Benchmark matrix

Measure build/layout/paint behavior for:

- One short static label.
- One short wave label.
- One multiline paragraph with letter motion.
- Many animated labels in a scrolling list.
- One long string with hover enabled.

The key assertion is qualitative and measurable: animated frames do not relayout text. Record frame timing and memory observations before deciding whether to add `RepaintBoundary` or visibility detection.

### Release gate

Before release, run:

```text
dart format .
flutter analyze
flutter test
```

Also run the example on web and at least one non-web target, manually check RTL/emoji/reduced-motion behavior, and confirm that the default static widget has no active animation controller. Use a minor version for additive API changes; use a major version only if a compatibility break is unavoidable.

## Risk register and mitigations

| Risk | Detection | Mitigation |
| --- | --- | --- |
| Per-cluster painting breaks shaping | Script/ligature tests and visual review | Full-text fallback for ambiguous runs |
| `softWrap` behavior changes unexpectedly | Bounded-width regression tests | Document and release-note the corrected contract |
| Animation causes per-frame layout | Instrument layout snapshot construction | Drive only painter repaint from the controller |
| Hover causes excessive repaints | Profile many instances and long text | One painter, conditional `MouseRegion`, bounded records |
| Reduced-motion API differs at minimum SDK | Analyze with minimum-compatible SDK | Verify API before coding; isolate compatibility logic |
| Ellipsis animates invisible text | Max-lines/ellipsis tests | Use visible boxes or full-text fallback |
| Focus makes every widget tabbable | Keyboard traversal test | Keep focus opt-in and document the integration |
| Visibility dependency adds complexity | Dependency review and benchmarks | Start with lifecycle pausing only |

## Definition of done mapped to evidence

- Static compatibility: default widget tests and static golden pass.
- Wave and letter modes: deterministic phase and transform tests pass.
- Interaction: pointer/focus tests pass on supported platforms.
- Accessibility: reduced-motion and semantics tests pass.
- Layout: multiline, RTL, alignment, emoji, combining marks, overflow, and shaping fallback tests pass.
- Performance: no per-frame text layout in instrumentation and benchmark results are recorded.
- Documentation: README, changelog, wiki index, decisions, and example are updated.
- Tooling: format, analyze, and test commands pass.