# Configuration and interaction review

This review maps the public animation and pointer settings to the current implementation. It is intended to guide a small, additive cleanup rather than a public API rewrite.

## Current model

`SquigglyText` exposes three separate axes:

| Axis | API | Current meaning |
| --- | --- | --- |
| Autonomous motion | `animationStyle` | Underline wave, atlas turbulence, or both. |
| Pointer response | `hoverBehavior` | Shader response such as scale, tremble, repel, lift, or magnetic motion. |
| Pointer range | `hoverScope` | Shader mask covering all text, one word, or one grapheme. |

`speed` gates the ticker and controls wave phase and atlas seed cadence. `hoverOnly` gates the ticker until pointer, focus, or preview is active. `hoverPreview` supplies a synthetic center pointer when no real pointer exists. `respectReducedMotion` disables the ticker and passes `hoverBehavior.none` to the painter.

This is a workable additive API. `hoverScope` does not change the geometric underline. While a pointer, focus, or preview target is active and the scope is a word or a letter, the shader multiplies the letter-displacement offset by that region's influence, so autonomous letter tremor outside the region stops. The example separates automatic animation from pointer and focus activation.

## Combination findings

### `trembleLetter` and `trembleWord` need fixed scopes

The public enum documents `trembleLetter` as the nearest letter and `trembleWord` as a word-sized region. The shader uses the same tremble formula for both modes, so the distinction is the selected region. The state layer now derives an effective scope:

* `trembleLetter` always uses a letter-sized region.
* `trembleWord` always uses a word-sized region.
* Other pointer behaviors continue to use the caller’s `hoverScope`.

This preserves both public fields and removes the contradictory combinations without a public API break.

For scale, repel, lift, and magnetic behaviors, `hoverScope` is a useful independent range setting. The behavior names describe the effect, while the scope describes its extent.

### `hoverOnly`, focus, and preview

`hoverOnly` is evaluated against `_pointerPosition`, focus, and `hoverPreview`. `hoverPreview` is now documented and presented as an explicit activation target: when enabled, it intentionally activates a hover-only animation around the text center. The example exposes automatic animation separately from pointer/focus activation, so this combination is visible rather than implicit.

Focus now supplies the same centered target used by preview, so focused tremble and other pointer effects have visible keyboard feedback. The ticker and painter use the same activation decision:

Focus also acts as a centered pointer target for pointer behaviors. This gives keyboard users visible feedback while preserving real pointer coordinates when a pointer is present.

### `speed == 0`

Zero speed stops the ticker. This is a “freeze” control for autonomous motion; static pointer transforms such as highlight, scale, and repel can still respond to pointer repaint. Time-dependent effects remain frozen at their stable seed. The example permits zero and presents it as the low end of animation speed.

### Reduced motion

Reduced motion suppresses the ticker and maps the painter’s pointer behavior to `none`. The surrounding `MouseRegion` can remain because interaction configuration is still present, but pointer updates have no visual effect. This is safe, though focus remains potentially requested even while all motion is suppressed. Keeping the current behavior avoids an accessibility regression; documentation should say that pointer motion is disabled, not pointer hit testing.

### `fluidity` and `stagger`

`fluidity` is the strength adjustment for lift and magnetic pointer effects. It is not a general smoothing or spring parameter. `stagger` is validated and carried through the painter, and rendering does not read it. Letter motion is one shared displacement field, so per-grapheme phase stagger is not part of the current model.

Retain both fields for compatibility. Do not describe `stagger` as an active phase offset.

## Recommended minimal model

Keep the existing public constructor and enums for compatibility. Clarify the conceptual model in docs and the example:

* `animationStyle` controls automatic motion.
* `hoverBehavior` controls the pointer/focus effect.
* `hoverScope` controls the extent of that effect, except `trembleLetter` and `trembleWord`, which use their documented fixed scopes.
* `hoverOnly` gates automatic motion and pointer animation; `hoverPreview` is an explicit center target and intentionally activates the effect.
* `speed: 0` freezes time-based motion.

Internally, add small derived getters or a private configuration object rather than adding more public booleans:

```text
effectiveHoverScope = trembleLetter -> letter
                     trembleWord   -> word
                     otherwise     -> hoverScope
interactionTarget = real pointer, focused center, or preview center
animationActive = automatic motion or time-based hover effect
                 AND speed > 0 AND visibility/motion policy allows it
```

The painter now includes the scope and preview state in repaint decisions, so changing either setting while a pointer/preview is present updates the visual immediately.

## Focused tests

`test/configuration_interactions_test.dart` and `test/flutter_squiggly_text_test.dart` cover the cases below:

* `trembleLetter` and `trembleWord` selecting their documented effective scopes, regardless of the dropdown scope.
* Focused pointer behavior producing the same centered target as preview.
* `hoverOnly: true` with and without `hoverPreview`.
* `speed: 0` stopping time-based animation while retaining static pointer transforms where applicable.
* Changing `hoverScope` and `hoverPreview` at runtime causing repaint.
* `respectReducedMotion` disabling visual pointer motion while preserving semantics.
