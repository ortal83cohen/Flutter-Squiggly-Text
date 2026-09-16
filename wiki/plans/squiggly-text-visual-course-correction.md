# SquigglyText Visual Course Correction

## Superseded

This document is kept as history. The rigid-body sine bounce it prescribed does not match the CodePen. Letter animation should follow [CodePen Glyph Displacement Plan](codepen-glyph-displacement-plan.md) instead: monotonic time plus turbulence displacement of a glyph snapshot.

## Decision

A full rewrite is not required. The widget lifecycle, layout snapshot, grapheme fallback, underline, hover, and reduced-motion paths can stay. The original visual target was wrong: the CodePen reference animates the glyphs, while the first plan treated a tiny vertical bounce plus an underline as the product.

The course correction is to keep the architecture and replace the letter-motion model so the example can show a handwriting-style face with obvious, organic text animation.

## What was wrong

- The CodePen look is jittery glyph motion, not a spellcheck underline.
- Letter amplitude was capped at `min(3, lineHeight * 0.08)`, about 2px.
- `stagger` defaulted to `0.2` radians, so letters moved almost in lockstep.
- `fluidity` shrank automatic motion instead of smoothing it.
- The example used a rigid UI font and did not pass letter-motion settings.
- Tests only asserted that a ticker ran, not that glyph motion was visible.

## What to keep

- `StatefulWidget` plus one `AnimationController` as the repaint source.
- Conservative grapheme records with full-text fallback.
- Static default (`animationStyle: none`).
- Optional underline wave.
- Hover, focus, and reduced-motion gates.

## New visual model

Approximate the CodePen, do not port SVG `feTurbulence`.

For each eligible grapheme `i`:

- Vertical offset: `A * sin(phi + seed_i)`
- Horizontal offset: `0.45A * cos(1.17 * phi + seed_i')`
- Small rotation around the glyph center, bounded to a few degrees

`A` is `max(amplitude, fontSize * 0.16)`, capped at `fontSize * 0.35`. Automatic letter motion ignores the old fluidity damper. Extra paint padding equals `A` so glyphs are not clipped.

The example hero preview uses Amatic SC, large type, `waveAndLetters`, and explicit `speed`/`stagger` so the font and the motion are both visible without extra configuration.

Shader displacement remains a later option if this transform model is not close enough. It is not needed to correct the current "no animation on the text" failure.
