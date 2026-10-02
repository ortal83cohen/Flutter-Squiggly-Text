# Motion formula, seed crossfade, and letter amplitude

Date: 2026-10-02

## Question

How should letter travel match SVG `feDisplacementMap`, keep trembling while a pointer hovers one letter or word, and expose a peak offset without a new noise function?

## What was verified before editing

`shaders/squiggly_turbulence.frag` computed:

```glsl
offset = uScale * (noiseRG - 0.5) * 2.0
```

Noise is in `0..1`, so `(noise - 0.5) * 2` is `-1..1` and the peak was `±uScale`. SVG `feDisplacementMap` is `scale * (channel - 0.5)`, peak `±scale/2`. The extra `* 2` sent ink about twice as far as the CodePen scales of 6 and 8.

Float uniforms are tightly packed in declaration order. `setFloat` indices in `_paintAtlas` already matched that order. Samplers are separate (`setImageSampler(0)` for `uText`). Verified indices before the new floats:

| Index | Uniform | Notes |
| --- | --- | --- |
| 0–1 | `uSize` | `vec2` |
| 2 | `uSeed` | integer 0..4, held for `0.068 / speed` seconds |
| 3 | `uScale` | was `logicalScale.clamp(1.5, max(1.5, fontSize * 0.12))` |
| 4 | `uBaseFrequency` | `0.02` |
| 5 | `uOctaves` | uploaded as 3, loop bound stays the constant 3 |
| 6–7 | `uPointer` | `vec2` |
| 8 | `uPointerRadius` | |
| 9 | `uPointerLift` | lift and magnetic, already scaled by `fluidity` |
| 10 | `uHoverMode` | |
| 11 | `uHoverScope` | 0 all, 1 word, 2 letter |
| 12 | `uPointerActive` | |
| 13–16 | scope rect | left, top, right, bottom |
| 17 | `uInteractionScale` | pointer strength, still clamped with the 1.5 floor |

When `uHoverScope != 0` and `uPointerActive > 0`, the shader multiplied `offset` by `scopeInfluence`. That froze autonomous tremor outside the hovered letter or word. Lift, magnetic, repel, and tremble already add a local term through `influence`.

`stagger` is validated and stored. It has no rendering consumer. Per-grapheme stagger stays out of scope.

Gradient noise replacement is out of scope. The value-noise primitive is unchanged.

## Decisions

### Displacement

The shader offset for one seed is now:

```glsl
scale * (noiseRG - 0.5)
```

Peak magnitude is `scale / 2`.

Default scale, when `letterAmplitude` is null:

```text
(seedIndex is odd ? 8 : 6) * (fontSize / 100)
```

There is no 1.5px floor. The uploaded scale is capped at `fontSize * 0.12`, so the peak stays at or below `0.06 * fontSize`. The CodePen table already sits under that cap (`0.03` and `0.04` times the font size), so the cap does not change the 6/8 seeds. Using `0.06 * fontSize` as a minimum would lift the 100px peaks from ±3 and ±4 to ±6, which misses the SVG reference.

Peaks with the default (null) amplitude:

| Font size | Even seed (scale 6) | Odd seed (scale 8) |
| --- | --- | --- |
| 100 | ±3 px | ±4 px |
| 14 | ±0.42 px | ±0.56 px |

`0.06 * 14` is 0.84px and `0.06 * 100` is 6px. The defaults are the lower CodePen peaks, not that ceiling.

An explicit `letterAmplitude` is the peak in logical pixels for every seed. The uploaded scale is `2 * letterAmplitude`, so the shader peak is the requested value. It is not clamped to the font-size ceiling and does not change underline `amplitude`.

### Atlas padding

Letter travel reserves `ceil(peak) + 2` logical pixels, using the stronger seed (or the explicit peak). Pointer room is unchanged: `0` when hover is `none`, otherwise `max(7, (1 + fluidity) * max(1.5, fontSize * 0.12))`. Interaction scale at float index 17 still uses that 1.5 floor. Only autonomous letter travel dropped it.

### Seed crossfade

The CPU computes one smoothstep weight from the fractional position inside the `0.068 / speed` hold. The first three quarters upload `0`. The last quarter maps `(fraction - 0.75) / 0.25` through `t * t * (3 - 2 * t)`. `fluidity` is not reused.

The shader evaluates both seeds and mixes their offsets with that weight. It does not smoothstep again. The second sample runs only when the weight is above 0.

Two trailing floats were required. One blend weight cannot also carry the next scale, because adjacent seeds use 6 and 8 unless `letterAmplitude` fixes both peaks.

| Index | Uniform | Role |
| --- | --- | --- |
| 18 | `uSeedBlend` | smoothstep weight, 0..1 |
| 19 | `uNextScale` | scale for `mod(floor(uSeed + 0.5) + 1, 5)` |

Earlier `setFloat` indices did not shift.

### Pointer scope

The `offset *= scopeInfluence` multiply is gone. Autonomous displacement uses `uScale` for the whole atlas. Pointer lift, magnetic pull, repel, hover scale, and tremble still multiply by local `influence`.

### `letterAmplitude`

Optional `double?` on `SquigglyText` only. It is not a `SquigglyTextStyle` field. Null is the font-derived path. A set value must be finite and `>= 0`, same checks as underline `amplitude`. `0` is a real peak of zero, distinct from null.

`stagger` stays public and unused. Its doc comment now says it is reserved for compatibility and does not stagger graphemes.

## Validation limits

Widget tests cannot read `FragmentShader` floats. `squigglyLetterMapScale` is the value uploaded as `uScale` / `uNextScale`, including when `hoverScope` is `letter` and the pointer is active. The shader multiply removal was checked by reading `shaders/squiggly_turbulence.frag`. `animationStyle: none` and reduced motion still skip the letter shader: `none` paints with `TextPainter`, and reduced motion stops the ticker and clears hover behavior.

## Risks

- Padding is `ceil(peak) + 2` plus the existing pointer room. A glyph whose ink already sits on the atlas edge can still clip if the noise hits the mathematical peak on that edge.
- The 6↔8 scale change is continuous only because `uNextScale` is mixed. Dropping that uniform and blending noise under a single scale would pop the amplitude when the seed index flips.
- `uSeedBlend` is already smoothstepped. A second `smoothstep` in the shader would flatten the crossfade.
- Pointer interaction scale still has the 1.5px floor. Letter travel does not.
