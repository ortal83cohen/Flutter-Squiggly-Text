# Animation Quality Improvement Research

Date: 2026-09-25

## Question

How can the current squiggly animation look closer to ink tremor, stay readable, and stop fighting the pointer effects, without a new rendering architecture?

## Scope

This review covers the live implementation:

- `lib/flutter_squiggly_text.dart`
- `shaders/squiggly_turbulence.frag`
- the example preview in `example/lib/main.dart`

The earlier roadmap and the CodePen displacement plan describe an architecture that is already in place: a monotonic ticker, a glyph atlas, and a turbulence displacement shader. This document does not reopen that architecture. It records what still makes the motion look wrong.

Reference: [Lucas Bebber, Squiggly Text](https://codepen.io/lbebber/pen/KwGEQv). SVG `feDisplacementMap` uses `scale * (channel - 0.5)`, so a scale of 6 or 8 moves samples by at most ±3 or ±4 user pixels.

## What already works

- Time is monotonic elapsed seconds. The old one-second controller wrap is gone.
- Letters are one shaped atlas, so RTL, ligatures, emoji, and joining scripts stay intact.
- Neighbors share one noise field. They are not independent bouncing sprites.
- Seed changes about every `0.068 / speed` seconds, with scales alternating 6 and 8 before the font-size multiplier.
- Static mode still paints with `TextPainter` and does not run the ticker.
- Reduced motion disables the ticker and pointer motion.

## Findings, in the order they change the picture

### 1. Displacement is about 1.8× the CodePen, and the atlas is padded for the smaller number

The shader maps noise with:

```glsl
offset = uScale * (noiseRG - 0.5) * 2.0
```

That is a range of `[-uScale, +uScale]`. The SVG filter the CodePen uses is `scale * (channel - 0.5)`, a range of `[-scale/2, +scale/2]`.

`uScale` is already `(6 or 8) * (fontSize / 100)`. At the example size of 88 px the uploaded scales are about 5.3 and 7.0, and the extra `* 2` turns those into peak offsets of about ±5.3 px and ±7.0 px. The CodePen at 100 px peaks at ±3 px and ±4 px.

Padding is `_maximumDisplacement`, which is `fontSize * 0.12` (10.6 px at 88 px type), plus 2 px. The shader can ask for about 14 px on the stronger seed. The outer strokes of `g`, `y`, and wide handwriting glyphs get clamped into the atlas edge on every other seed. The tremor then reads as a pop and a smear, not as a bend.

Small body text has the opposite problem. The scale is clamped up to 1.5 px before the `* 2`, so a 14 px glyph can move by ±3 px, about a fifth of the em. The floor that was meant to keep motion visible dissolves small text.

### 2. The noise is boiling clouds, not ink ridges

SVG `feTurbulence` with the default type is summed absolute Perlin gradient noise. The shader uses smoothed value noise and a `sin` hash:

```glsl
fract(sin(dot(point + seed, vec2(127.1, 311.7))) * 43758.5453)
```

Value noise interpolates scalar cell corners. The field is blobby, and the `sin` hash leaves diagonal lattice structure. Absolute gradient noise has ridges and directional bends, which is why a stroke in the CodePen warps instead of sliding as a soft blob.

`uOctaves` is uploaded as 3 and then ignored. The loop bound is the constant `3`, which matches the reference, so this is not a visual bug. It is a dead uniform. Flutter shader loops need a constant bound, so the uniform cannot drive the loop anyway.

The two channels are offset by about 20 noise cells, so red and green are decorrelated. Channel independence is fine. The noise primitive is the gap.

### 3. Each seed is held, then the picture jumps

At `speed == 1` the field is constant for 68 ms, then it is replaced. At 60 fps that is about four identical frames. At 120 fps it is about eight. The CodePen steps for the same reason CSS cannot interpolate `filter: url(...)`. On a high-refresh display the hold reads as stutter, not vibration.

A short blend at the end of each hold keeps the tremor and removes the pop. Evaluate both seeds and mix their offsets across the last quarter of the step, with a smoothstep. `fluidity` should not be reused for this: it already scales lift and magnetic strength.

### 4. Pointer scope turns off the letter tremor

The configuration review says `hoverScope` limits pointer effects and does not limit autonomous letter motion. The shader does the opposite whenever a pointer or preview target is active and the scope is not the whole text:

```glsl
if (uHoverScope != 0.0 && uPointerActive > 0.0) {
  offset *= scopeInfluence;
}
```

Hovering one letter freezes the rest of the sentence. `trembleLetter` and `trembleWord` then add a second motion, a nearly rigid sine of 2.4 px, on top of the masked turbulence. The hovered region jitters twice, in two different languages, and the rest of the line goes still.

Pointer effects should add a local term. They should not multiply the autonomous field down to zero.

### 5. The underline and the glyphs are different animations

The static underline is a chain of quadratic beziers that zigzag by `amplitude`. The animated underline is a sine polyline sampled every `max(1.5, wavelength / 8)` pixels. Starting or stopping the ticker changes the shape, not only the phase. The sample step is coarse enough to facet a long wavelength.

The example sets `amplitude: 0`, so the package's squiggle is invisible in the main preview. `waveAndLetters` is never what the example is judging.

The geometric stroke should stay out of the glyph atlas. It can still share the motion: drive the existing bezier control offsets with `sin(phase + x / wavelength)` so static and animated frames are the same curve family. A later pass can offset those control points by the same noise field, sampled along the baseline, if the wave and the letters need to feel like one piece of ink.

### 6. One `speed` runs two clocks

`speed` is wave cycles per second and also the divisor of the 68 ms letter step. `speed: 1` is a calm underline and a fast tremor. Raising it to make the letters busier makes the underline busy too. Splitting them is an API decision. Until then, do not retune one by changing the shared knob.

`stagger` is validated and stored, and it has no visual effect. Do not revive it as a per-letter phase. Independent oscillators are the look the displacement plan rejected. If it is ever wired, the only coherent use is a spatial shift of the shared noise field.

### 7. Letter mode is a filtered bitmap

`none` paints vectors through `TextPainter`. `letters` rasterizes that painting with `toImageSync` and samples it with the shader's linear `texture()`. Every displaced sample filters the coverage again, so stems get gray fringes. Enlarge, shrink, and highlight are bitmap scales around a center (`highlight` zooms by up to 12%), which softens the ink further. Highlight is a zoom, not a color emphasis.

Clamped UVs (`clamp` to `0.001…0.999`) repeat the border texel when a sample would leave the atlas. Transparent padding hides some of this. Where padding is short, the border smears.

Signed-distance atlases would stay sharp, and they are a large project. The useful near-term step is to rasterize at least at 2× when device pixel ratio is lower, sample with decal (transparent outside the atlas), and stop using scale as the highlight.

### 8. The painter throws away the atlas on ordinary rebuilds

`build` constructs a new `_SquigglyTextPainter` and disposes the previous image. Focus calls `setState`. Parent sliders in the example rebuild the text. Each of those hitches is a fresh `toImageSync`, which can show up as a one-frame stall in the tremor. The ticker path itself does not rebuild the widget, and that part is correct.

## What not to do

- Do not go back to per-glyph `translate` / `rotate`. That cannot bend a stroke.
- Do not add a widget per letter.
- Do not parse font files for outlines. Flutter still does not return shaped glyph paths, and a TTF parser will disagree with `TextPainter`.
- Do not put the underline into the displacement atlas.
- Do not add more public multipliers until the formula, the noise, and the scope mask are fixed. Tuning on top of the `* 2` offset will not converge.

## Recommended order

1. **Match the SVG offset and pad for it.** Use `uScale * (noise - 0.5)` with no extra `* 2`. Pad by the real peak, `ceil(uScale / 2) + 2`, after the font-size multiplier. Lower the 1.5 px floor for small type so the peak stays near `0.06 * fontSize`.
2. **Replace value noise with compact gradient noise**, still three octaves of `abs(noise)`, still one shared field. Keep the five seeds.
3. **Stop masking autonomous turbulence with `hoverScope`.** Add pointer motion on top. Rebuild `trembleLetter` / `trembleWord` as a local gain on that same field, not a second sine.
4. **Crossfade the last quarter of each seed step** inside the shader. One extra noise evaluation. No new public parameter.
5. **Make the animated underline the same quadratic family as the static one**, with a traveling phase. Raise the example amplitude above zero in at least one sample so this can be seen.
6. **Decal sampling and a 2× atlas when device pixel ratio is below 2.** Change highlight from a zoom to a local tint.
7. **Keep the atlas across focus and other non-layout rebuilds.**

After 1–4, compare the example hero to the CodePen at similar type size. The test is: strokes bend, neighbors stay glued, the step is a tremor rather than a pop, and descenders are not clipped. Steps 5–7 are the underline, sharpness, and hitch work.

## Validation

- Unit-check peak offset: at 100 px and seed scales 6 and 8, displacement is within ±3 and ±4 logical pixels.
- Widget test: with `letters` plus `hoverScope: letter`, glyphs outside the hovered box still receive a non-zero autonomous scale uniform. Today the shader forces that offset to 0.
- Golden or manual: descenders at 88 px and 120 px stay inside the atlas on both seeds.
- Manual on a 120 Hz display: seed changes do not present as a held frame followed by a teleport.
- `none` and reduced motion stay on the vector path.

## Remaining product choices

These can wait until the formula is fixed:

- Whether letter cadence gets its own parameter, or keeps sharing `speed`.
- Whether `stagger` shifts the noise field or stays reserved.
- Whether `waveAndLetters` should pull the underline control points with the same noise.
