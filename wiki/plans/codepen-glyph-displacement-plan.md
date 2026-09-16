# CodePen Glyph Displacement Plan

## Status

This plan supersedes [SquigglyText Visual Course Correction](squiggly-text-visual-course-correction.md) for letter animation. That document correctly identified that the CodePen target is glyph motion, not a spellcheck underline. It then prescribed a larger rigid-body sine bounce. That model cannot produce the reference look.

Do not implement more per-grapheme translation, rotation, or stagger tuning until the displacement model below is in place.

## Goal

Make `SquigglyAnimationStyle.letters` and `waveAndLetters` read as **ink jitter**: the painted text warps in place, at handwriting scale, with a high-frequency tremble. The reference is [Lucas Bebber's Squiggly Text](https://codepen.io/lbebber/pen/KwGEQv).

The underline remains a separate product feature. This plan does not replace it. It changes how the **glyphs** are animated.

## 1. What the CodePen actually does

The reference is not letter bouncing. It is an SVG filter on the whole text block.

### 1.1 HTML and CSS

The text lives in one element. CSS applies one looping animation:

```css
@keyframes squiggly-anim {
  0%   { filter: url('#squiggly-0'); }
  25%  { filter: url('#squiggly-1'); }
  50%  { filter: url('#squiggly-2'); }
  75%  { filter: url('#squiggly-3'); }
  100% { filter: url('#squiggly-4'); }
}

animation: squiggly-anim 0.34s linear infinite;
```

There is no per-letter DOM, no `translateY`, no rotation, and no underline.

CSS cannot interpolate between two `url(#filter)` values, so the animation **steps** through five discrete displacement fields. At 60 fps that is about four frames per seed. The period is `0.34s`, which is about `14.7 Hz`. That frequency is why the result reads as vibration rather than a bounce.

The typeface is Amatic SC at `100px`. That scale matters: a 6–8 px displacement is visible but still attached to the letter.

### 1.2 SVG filter graph

Each filter is the same graph with a different `seed` and a slightly different `scale`:

| Filter id     | `feTurbulence` seed | `feDisplacementMap` scale |
| ------------- | ------------------- | ------------------------- |
| `squiggly-0`  | 0                   | 6                         |
| `squiggly-1`  | 1                   | 8                         |
| `squiggly-2`  | 2                   | 6                         |
| `squiggly-3`  | 3                   | 8                         |
| `squiggly-4`  | 4                   | 6                         |

Shared turbulence parameters:

- `baseFrequency = 0.02` (spatial period ≈ 50 px in user space)
- `numOctaves = 3`
- `type` omitted, so SVG default `turbulence` (sum of absolute-value noise, not `fractalNoise`)
- `stitchTiles` omitted, so `noStitch`

`feDisplacementMap` defaults:

- `in = SourceGraphic` (the already-painted text)
- `in2 =` turbulence result
- `xChannelSelector = R`
- `yChannelSelector = G`
- `scale` in user-space pixels

Pixel math, using unpremultiplied 0–1 channels:

```
dx = scale * (R - 0.5)
dy = scale * (G - 0.5)
color(x, y) = source(x + dx, y + dy)
```

At `100px` type, `scale = 6` is `0.06 * fontSize`. Neighboring pixels share the same low-frequency field, so a stroke bends instead of the whole glyph sliding as a sprite.

### 1.3 Visual consequences

The reference look has four properties the current widget lacks:

1. **Intra-glyph deformation.** The left side of an `S` can move differently from the right side.
2. **Spatially coherent noise.** Adjacent letters share one field. They do not dance on independent oscillators.
3. **High-frequency discrete updates.** The field jumps to a new seed ~15 times per second. The amplitude of each jump is a few pixels.
4. **Small displacement relative to font size.** 6–8 px on 100 px type, not 16–35% of `fontSize`.

## 2. Why the current implementation fails

The current letter path is in `_paintLetters` / `_glyphMotion` in `lib/flutter_squiggly_text.dart`.

### 2.1 Loop discontinuity (the visible snap)

The ticker is:

```dart
AnimationController(duration: const Duration(seconds: 1))..repeat();
```

Phase is:

```dart
_phase => (animation?.value ?? 0) * 2 * math.pi * speed
```

`repeat()` drives `value` from `0` to `1`, then snaps it to `0`. Continuity of `sin(k * phase)` after that snap requires `k * speed` to be an integer. The example uses `speed: 2.4`. The letter model uses extra incommensurate harmonics:

```
dx = cos(phase * 1.17 + seed) * A * 0.45
dy = sin(phase + seed) * A
rotation = sin(phase * 0.85 + seed) * 0.14
```

When `value` wraps:

- `sin(2π * 2.4)` is not `sin(0)`
- `cos(2π * 2.4 * 1.17)` is not `cos(0)`
- `sin(2π * 2.4 * 0.85)` is not `sin(0)`

Every letter teleports. The underline uses the same `_phase`, so `wave` and `waveAndLetters` snap as well. This is a clock bug, independent of the visual model.

The CodePen also jumps, but those jumps are 6–8 px noise-field changes, not whole-glyph translations of `0.16–0.35 * fontSize`.

### 2.2 Rigid-body motion (the wrong look)

Each grapheme is painted with its own `TextPainter`, then the canvas is translated and rotated around the glyph center. The glyph bitmap/outline is unchanged. That is a bouncing sprite, not warped ink.

The previous course correction made this worse on purpose:

- Amplitude became `max(amplitude, fontSize * 0.16)`, capped at `fontSize * 0.35`
- Horizontal travel and rotation were added
- Example `speed` was raised to `2.4` and `stagger` to `0.9`

The result is large, slow, per-letter oscillation: "bouncy, not vibrating."

### 2.3 Independent oscillators (the wrong coupling)

`stagger` and per-index seeds make neighbors move out of phase. The CodePen uses one noise field over the whole block, so neighbors stay visually glued.

### 2.4 Per-letter canvas is already what we do

Painting each letter on `Canvas` is not a new option. It is the current architecture. It cannot warp interiors unless we also displace samples or path points inside the glyph.

### 2.5 Layout and hover can stay

The following remain useful and should not be rewritten:

- `StatefulWidget` plus one ticker
- Authoritative `TextPainter` layout
- Conservative grapheme records for hover / fallback
- Static default, reduced motion, focus, pointer gates
- Geometric underline path

## 3. Option analysis

### Option A — Keep rigid transforms, fix the clock and retune

**Idea:** Use elapsed seconds instead of a wrapping `0..1` controller. Lower amplitude. Raise frequency. Keep per-letter `sin`/`cos`.

**Pros:** Smallest diff. No shaders. Tests stay simple.

**Cons:** Still sprite motion. Still independent letters. No intra-glyph warp. Tuning will never converge on the CodePen.

**Verdict:** Required clock fix for the underline. Insufficient for letters.

### Option B — Per-letter canvas paint with a different motion function

**Idea:** Keep one `TextPainter` per grapheme. Drive offsets from Perlin noise sampled at each glyph center, optionally with discrete seed steps.

**Pros:** No GPU shader packaging. Hover lift stays easy. Works everywhere `Canvas` works.

**Cons:** Each letter remains a rigid sprite. Independent center samples still decouple neighbors unless the same field is sampled, and even then the letter does not bend.

**Verdict:** Acceptable **fallback** when shaders or raster snapshot are unavailable. Not the target look.

### Option C — Per-glyph outline manipulation

**Idea:** Extract glyph `Path`s, displace control points with noise, fill the warped paths.

**Pros:** True interior deformation. Resolution independent.

**Cons:** Flutter has no public post-shaping outline API (`TextPainter` / `Paragraph` cannot return glyph paths). Issues [150126](https://github.com/flutter/flutter/issues/150126) and [188791](https://github.com/flutter/flutter/issues/188791) are still proposals. Third-party TTF parsers (`glyph_path`) ignore HarfBuzz, bidi, fallback fonts, and ligatures, so they will disagree with the layout we already trust. `Path` also does not expose verbs/points for in-place edits.

**Verdict:** Rejected until the engine exposes shaped outlines.

### Option D — Widget tree of `Transform` / `ImageFiltered` per letter

**Idea:** One widget per grapheme.

**Cons:** Breaks the "cache layout, animate paint" rule. Expensive. Still rigid unless each child is also filtered. Hover and semantics become harder.

**Verdict:** Rejected.

### Option E — Rasterize laid-out text, displace with a fragment shader

**Idea:** Paint the authoritative text (or each line) into a `Picture` / `ui.Image` on layout. Each frame, draw that image with a fragment shader that implements turbulence + displacement.

This is the Flutter equivalent of `feTurbulence` + `feDisplacementMap` on `SourceGraphic`.

**Pros:**

- Intra-glyph warp
- Shared field across letters
- Discrete seeds or continuous noise scroll
- One draw call per frame after snapshot
- `FragmentProgram` exists on Flutter `>= 3.7`, so the package minimum `>= 3.10` can stay
- Works on Skia and Impeller through `Paint.shader` + `setImageSampler` (does **not** require `ImageFilter.shader`, which is Impeller-only and newer)

**Cons:**

- Shader asset packaging for a pub.dev widget
- First frame must wait for `FragmentProgram.fromAsset`
- Snapshot must include padding so displaced samples are not clipped
- Color emoji / bitmap glyphs warp as bitmaps (acceptable; SVG does the same)
- Flutter web HTML renderer has no fragment shaders; CanvasKit / Impeller web do
- Hover lift is no longer a per-glyph canvas rotate; it must be a shader uniform or a pre-snapshot transform

**Verdict:** **Primary implementation.**

### Option F — `ImageFilter.shader` / `ImageFiltered`

**Idea:** Paint text as a child, let the engine feed it to a filter shader.

**Cons:** `ImageFilter.shader` is Impeller-only. Web and older Skia Android builds throw. Harder to feature-detect cleanly in a package that still supports Flutter 3.10.

**Verdict:** Later optimization, not the first path.

### Option G — Platform-view SVG filter on web only

**Idea:** `HtmlElementView` with the original SVG filters.

**Cons:** Not Flutter text layout. No Android/iOS/desktop. Accessibility and hit-testing diverge.

**Verdict:** Rejected for the package widget.

### Option H — Bake five noise textures and cycle them

**Idea:** Check in five small RG noise PNGs matching seeds 0–4. Shader only samples text + noise.

**Pros:** Closer bit-for-bit to the CodePen's five filters. Simpler GLSL.

**Cons:** Binary assets, fixed resolution, weaker parameterization (`baseFrequency` becomes UV scale only).

**Verdict:** Optional fidelity pass after procedural turbulence works. Not required to start.

## 4. Recommended design

Use **elapsed-time clock + snapshot of laid-out glyphs + turbulence displacement shader**, with a **CPU rigid jitter fallback**.

```
layout TextPainter (cached)
        │
        ├─ letters / waveAndLetters
        │     paint glyphs at rest → Picture → ui.Image (layout only)
        │     each frame: draw image with turbulence displacement shader
        │
        └─ wave / static underline
              draw geometric path from the same elapsed phase
```

Do not paint transformed per-grapheme sprites in the primary letter path.

### 4.1 Time source (fixes the snap)

Replace `AnimationController(duration: 1s).repeat()` as the source of truth for phase.

Use a `Ticker` (or an `AnimationController` whose value is ignored) and store:

```
t = elapsedSeconds   // monotonic, never wrapped
```

Derived quantities:

```
wavePhase = 2 * π * speed * t          // continuous forever
seedIndex = floor(t / 0.068) % 5     // 0.34s / 5, CodePen cadence
seed = seedIndex                       // 0..4
mapScale = (seedIndex.isOdd) ? 8 : 6 // matches the reference table
```

`speed` for letters should scale the **seed cadence**, not a sine amplitude. Proposed mapping:

```
frameDuration = 0.068 / max(speed, ε)   // speed 1 ≈ CodePen 0.34s loop
```

Keep underline `speed` as cycles per second of the geometric wave. If one public `speed` must drive both, document that letters use it as a cadence multiplier and the wave uses it as cycles per second. Do not invent a second public parameter in the first displacement slice unless the example cannot be tuned.

Never feed `controller.value` in `[0, 1]` into `sin(k * value)` for incommensurate `k`.

When the ticker stops, freeze `t`. Do not reset it to `0` (resetting is another snap).

### 4.2 Snapshot

Build the snapshot only when the layout key changes: text, style, locale, direction, align, wrap, max lines, overflow, strut, width, device pixel ratio.

Algorithm:

1. Layout the authoritative `TextPainter`.
2. Pad the picture by `ceil(maxDisplacement) + 1` on every side. `maxDisplacement` is `max(mapScale)` in logical pixels, converted to device pixels. For the CodePen scales that is 8 px plus shader-safety padding (12–16 px logical is enough at default settings).
3. Paint glyphs at rest, translated by the pad. Do **not** include the underline in this snapshot.
4. `picture.toImageSync(pixelWidth, pixelHeight)` at the current device pixel ratio.
5. Retain the `ui.Image` until the next layout invalidation. Dispose the previous image.

Paint snapshot contents with the same path used today for static text (`textPainter.paint`). Independent per-grapheme painters are unnecessary for the displacement path and should be skipped unless hover still needs centers.

Do not snapshot every frame.

### 4.3 Shader

Add `shaders/squiggly_turbulence.frag` to the package.

Declare it in the package `pubspec.yaml`:

```yaml
flutter:
  shaders:
    - shaders/squiggly_turbulence.frag
```

Load with:

```dart
FragmentProgram.fromAsset(
  'packages/flutter_squiggly_text/shaders/squiggly_turbulence.frag',
);
```

Confirm during implementation that the example app receives the shader without a second `shaders:` entry. If the tool does not bundle package shaders automatically, document the consumer entry and also add it to `example/pubspec.yaml`. Treat extra consumer configuration as a defect to minimize.

GLSL contract (uniform order is the ABI; keep it stable and tested):

```glsl
#include <flutter/runtime_effect.glsl>

uniform vec2  uSize;          // 0,1  snapshot size in pixels
uniform float uSeed;          // 2    0..4, or a continuous seed
uniform float uScale;         // 3    displacement in pixels (6 or 8)
uniform float uBaseFrequency; // 4    0.02 at 1.0 CSS px scale
uniform float uOctaves;       // 5    3
uniform vec2  uPointer;       // 6,7  local px; (-1,-1) if none
uniform float uPointerRadius; // 8
uniform float uPointerLift;   // 9    extra dy under the pointer
uniform sampler2D uText;      // image sampler 0

out vec4 fragColor;
```

Core sampling:

```
vec2 uv = FlutterFragCoord().xy / uSize;
vec2 noise = turbulence(uv / uBaseFrequencyPeriod, uSeed, uOctaves);
// turbulence: 3 octaves of abs(valueNoise or gradientNoise)
vec2 offset = (noise - 0.5) * 2.0 * uScale; // map 0..1 → -scale..+scale
vec2 sampleUv = uv + offset / uSize;
sampleUv += pointerLift(uv);
fragColor = texture(uText, sampleUv);
```

Implementation notes:

- Use 2D value noise or simplex, then `abs(n)` per octave to approximate SVG `type="turbulence"`.
- Hash the integer seed into the noise domain (`p + vec2(seed * 19.19, seed * 47.7)`).
- Empty texels must stay transparent. Sample with a transparent border; do not smear edge letters. Emulate `TileMode.decal` in-shader: if `sampleUv` is outside `[0,1]`, return `vec4(0)`.
- Premultiplied alpha output, as Flutter shaders require.
- Do not use `ImageFilter.shader` in v1 (`uSize` would be engine-provided and Impeller-only).
- Reuse one `FragmentShader` instance across frames. Set floats each paint.

Pointer uniforms let `liftLetters` / `magnetic` survive without per-glyph canvas transforms: extra displacement near `uPointer`, zero when hover is off.

### 4.4 Cadence

Default letter timing should copy the CodePen, not a 1 Hz sine:

- Loop length `0.34s` at `speed == 1`
- Five seeds
- Alternating scales `6, 8, 6, 8, 6`
- Spatial frequency `0.02` in snapshot pixel space, adjusted by `devicePixelRatio` so logical 50 px period stays stable across densities

Scale should track font size so 88 px example type is close to the 100 px reference:

```
mapScale = (seedOdd ? 8 : 6) * (fontSize / 100)
```

Cap map scale so small body text does not dissolve (`clamp(mapScale, 1.5, fontSize * 0.12)`).

This replaces `_glyphAmplitude = max(amplitude, fontSize * 0.16)`.

Public `amplitude` continues to mean **underline** amplitude. Do not reuse it as letter bounce. If letter intensity must be user-facing later, add a separate parameter. Do not overload `amplitude` in this slice.

### 4.5 Fallback

If the shader program fails to load, the platform has no fragment shaders, or reduced-quality mode is forced:

1. Paint static glyphs (current full-text path).
2. Optional: add **shared-field** rigid jitter — sample the same CPU hash noise at each glyph center, amplitude `mapScale`, updating on the same seed cadence. No per-letter phase stagger.
3. Never enable the old `sin(phase * 1.17)` rotator.

Tests can use the CPU path by injecting a fake displacement function, but add at least one shader golden on a platform that compiles shaders (example app / integration).

### 4.6 Underline

Keep the geometric wave. Drive it from `2 * π * speed * t` with monotonic `t` so it no longer snaps.

Do not run the underline through the displacement shader in v1. Mixing a clean sine and a turbulence field in one bitmap makes the underline unreadable and harder to test.

`waveAndLetters` = displaced glyph snapshot + geometric wave on top, both using the same `t`.

### 4.7 Hover, focus, reduced motion

- `highlight`: still possible as a second snapshot or a shader tint near the pointer. Defer visual polish if it blocks displacement.
- `liftLetters` / `magnetic`: shader pointer uniforms, using existing grapheme centers only if CPU fallback needs them. Primary path does not require per-letter painters.
- Reduced motion: no ticker, snapshot drawn with `uScale = 0` (identity), static underline.
- `hoverOnly`: ticker runs only while pointer/focus is active; freeze `t` rather than zeroing it.

### 4.8 What to delete from the letter path

Once displacement paints letters:

- `_glyphMotion` sine/cosine/rotation
- Per-frame `canvas.rotate` around glyph centers
- `_glyphAmplitude` padding based on 16–35% of font size
- Independent `TextPainter` per grapheme **for painting** (keep box lookup only if hover/tests need centers)

Keep `_containsAmbiguousShaping` only if we still split letters. The snapshot path paints the full shaped run, so RTL, ligatures, emoji ZWJ, and Arabic joining work without fallback. That is a correctness upgrade: **letter animation no longer needs to split graphemes.**

Grapheme splitting remains optional for hover influence. Build it lazily when `hoverBehavior != none`.

## 5. Architecture changes

### 5.1 State

`_SquigglyTextState` owns:

- `Ticker` + `double _elapsedSeconds`
- `FragmentProgram?` loaded once
- `FragmentShader?` reused
- `ui.Image? _glyphAtlas` and a layout signature
- Existing pointer / focus / reduced-motion flags

Load the shader in `initState` (`unawaited` + `setState` when ready, or a `FutureBuilder`-free flag). Until it is ready, paint undisplaced text. Do not block first layout.

### 5.2 Painter

Split paint into two passes:

1. Glyphs: `drawRect` / `drawImageRect` with `Paint.shader = displacementShader`, or `canvas.drawImage` into a rect whose `Paint.shader` samples the atlas. The robust pattern is:

   ```
   shader.setImageSampler(0, atlas);
   canvas.drawRect(paddedRect, Paint()..shader = shader);
   ```

2. Underline: existing path code, phase from `_elapsedSeconds`.

`shouldRepaint` compares config and atlas identity. Time arrives through the ticker `Listenable`.

### 5.3 Files

| File | Role |
| --- | --- |
| `shaders/squiggly_turbulence.frag` | Turbulence + displacement |
| `lib/src/squiggly_time.dart` | Monotonic elapsed phase helpers |
| `lib/src/squiggly_displacement.dart` | Shader load, uniform binding, seed/scale table |
| `lib/src/glyph_atlas.dart` | Picture → `ui.Image` snapshot |
| `lib/flutter_squiggly_text.dart` | Widget wiring; remove rigid `_glyphMotion` |
| `example/pubspec.yaml` | Shader consume path if required |
| `test/displacement_loop_test.dart` | Clock continuity |
| `test/glyph_atlas_test.dart` | Snapshot invalidation |

Keep the public widget in the existing library export. Internal types stay private or in `src/`.

## 6. Implementation slices

Do not retune the current bounce in parallel. Each slice should leave `main` compilable.

### Slice 0 — Clock continuity

- Switch the ticker to monotonic elapsed seconds.
- Keep current visual model **temporarily** so the slice is reviewable, but compute `_phase = 2 * π * speed * elapsedSeconds` with no wrap.
- Add a test: after `pump(1s)` vs mid-loop, glyph-center proxy / wave y at `x=0` does not jump by more than one sample step when crossing the old 1 s boundary.
- Example `speed: 2.4` must not snap the underline.

Exit: no end-of-loop teleport on wave or letters, even if letters still look wrong.

### Slice 1 — Glyph atlas

- Snapshot static glyphs at layout time.
- Paint the atlas without displacement (identity blit).
- Tests: atlas rebuilds when text/style/width/DPR change; does not rebuild on ticker ticks.
- Confirm RTL and emoji paint identically to today's static path.

Exit: letters mode can render from an image without visual change vs static text.

### Slice 2 — Displacement shader

- Add the fragment shader and uniform binder.
- Drive `uSeed` / `uScale` from the CodePen table and elapsed cadence.
- Pad the atlas.
- Example hero stays Amatic SC, large, `waveAndLetters`.
- Manual check against the CodePen: tremble in place, shared field, no bouncing sprites.

Exit: default letters look like warped ink. Old `_glyphMotion` is deleted.

### Slice 3 — Interaction and fallback

- Pointer uniforms.
- Shader-missing fallback (static or shared-field CPU jitter).
- Reduced motion identity draw.
- Hover-only freezes `t`.

### Slice 4 — Docs and API cleanup

- README: describe displacement, not bounce. Mention shader requirement and reduced motion.
- Changelog: letter animation visual change. This is a **behavior change** for anyone already using `letters` / `waveAndLetters` (currently unreleased or 0.1.x; still document it).
- Update the roadmap status and mark the old visual course correction as superseded.
- Do not advertise per-letter rotation.

## 7. Tests

Deterministic tests, no dependence on exact Perlin bit patterns except goldens.

Clock:

- Elapsed `t=0.99` and `t=1.01` produce nearby wave samples for integer and non-integer `speed`.
- Seed index is `floor(t / frameDuration) % 5`.
- Stopping the ticker freezes seed; restarting does not reset `t` unless the widget is new.

Atlas:

- Signature change rebuilds and disposes the previous `ui.Image`.
- Ticker-only frames do not call `TextPainter.layout` (spy or counter on a test subclass).

Shader:

- Identity (`uScale = 0`) matches the static golden for a short ASCII string.
- `uScale > 0` golden differs from identity and remains inside the padded bounds (no clip of descenders).
- Transparent outside the atlas.

Fallback:

- If program load is stubbed to fail, text still paints and semantics stay intact.

Keep existing tests for static default, reduced motion, hover gating, and grapheme-safe semantics. Remove or rewrite tests that assert extra height from `_glyphAmplitude` bounce padding; displacement padding is smaller and on the paint rect, not necessarily widget height. Widget height should still include underline gap plus a small displacement inset so the wave and warped ink are not clipped.

## 8. Performance

Budget:

- `TextPainter.layout`: layout key only
- `toImageSync`: layout key only, size of the text block plus pad
- Per frame: uniform uploads + one rect draw + underline path

`toImageSync` is the cost to watch. Short labels are cheap. A full-screen paragraph snapshot every resize is acceptable; a snapshot every frame is not.

Device pixel ratio: snapshot at `dpr` so the shader does not upsample a blurry atlas, then displace in pixel space.

Multiple instances: each widget has its own atlas. A later optimization can cache by `(text, style, width, dpr)` if profiling shows duplication. Not in v1.

## 9. Risks

| Risk | Mitigation |
| --- | --- |
| Package shaders not auto-bundled for consumers | Verify with a clean example build; if needed, document one `shaders:` line and file a follow-up to embed via `lib/` assets |
| Shader compile fail on HTML renderer / ancient Skia | CPU/static fallback, no exception in `paint` |
| Displacement clips glyphs | Pad atlas by `ceil(uScale) + 2` px; test descenders (`g`, `y`) |
| Premultiplied alpha fringes | Sample atlas created with transparent background; keep premultiplied output |
| `toImageSync` on web is expensive | Keep layout-only; consider line-by-line atlases only if a long paragraph profiles badly |
| Hover highlight needs a second atlas | Defer highlight quality; keep lift as shader offset |
| Visual mismatch from using simplex instead of SVG Perlin | Tune `uBaseFrequency` and `uScale` against a side-by-side recording; optional later bake of five SVG noise maps |
| Public `speed` meaning splits between wave and letters | Document cadence vs cycles; add `letterCadence` only if tuning fights the underline |
| Raising min SDK for `ImageFilter.shader` | Do not; stay on `FragmentProgram` + image sampler |

## 10. Explicit non-goals for this plan

- Porting `feTurbulence` bit-exactly
- Vertex shaders (Flutter does not ship custom vertex shaders for this)
- Per-letter widget trees
- Outline morphing via TTF parsing
- Putting the underline through the displacement map
- Further increases to rigid bounce amplitude

## 11. Definition of done

Letter animation is done when:

1. Crossing any controller period produces no whole-glyph teleport.
2. Glyphs warp internally rather than sliding as sprites.
3. Neighbors share one displacement field.
4. Update cadence is in the ~10–20 Hz discrete range at `speed == 1`, not a 1 Hz bounce.
5. Displacement stays on the order of 6–8 px at 100 px type.
6. RTL, emoji, and ligatures remain shaped (full-run snapshot).
7. Static `animationStyle: none` is unchanged.
8. Reduced motion paints identity.
9. `dart format`, `flutter analyze`, and `flutter test` pass.
10. The example hero is compared against the CodePen by eye: tremble, not bounce.

## 12. Open product choices

These do not block writing the slices, but should be decided before Slice 2 lands:

1. **One `speed` or two.** Keep one parameter (wave cycles / letter cadence multiplier) unless the example cannot match both looks.
2. **Letter intensity API.** Leave unexposed in v1; derive from font size and the CodePen table.
3. **Fallback quality.** Static text vs shared-field CPU jitter when shaders are missing.
4. **Hover highlight.** Allow it to stay as today's per-grapheme recolor until a second atlas exists.

Recommended defaults: (1) one `speed`, (2) no new public intensity, (3) static fallback plus optional tiny shared jitter, (4) defer highlight polish.
