# Build-now features

Shipped three additive `SquigglyText` options from the verdict table in [Later-Feature Feasibility](../research/later-feature-feasibility.md).

## What shipped

- `squiggleGradient` paints the underline stroke. Null keeps the solid `squiggleColor`. Glyph color stays on `TextStyle`. The turbulence shader is unchanged.
- `phase` is an offset in turns, default `0`. It is added to the wave sine. When `speed` is positive it also shifts the letter shader clock by `phase / speed` seconds. `speed == 0` does not invent motion.
- `SquigglyTextStyle.spellcheck` is a red static underline with the library geometry defaults. `SquigglyTextStyle.handwriting` uses letter animation, amplitude `0`, and speed `1`. Explicit constructor arguments win over preset fields.

The underline and its gradient both start at `LineMetrics.left`, so centered and right-to-left lines follow the glyphs. A negative phase still picks a shader seed in `0..4`. Preset numbers use the same finite-value checks as the widget.

## Left out

Skip-ink, an external `Animation`, one-shot draw, a marker preset, `SelectionArea`, `ThemeExtension`, `textScaler`, squiggle ranges, rich text, and touch input were not implemented.
