# Later-feature feasibility

Research date: 2026-09-25.

This note checks the "build later" list in [User-Facing Feature Opportunities](user-facing-feature-opportunities.md). Four investigations read `lib/flutter_squiggly_text.dart` and the existing wiki. None of them changed code.

## Revised order

| Feature | Verdict | Effort | Why |
| --- | --- | --- | --- |
| Stroke `Gradient` | Build now | Small | The squiggle is already its own `Paint` and `drawPath`. A shader on that paint does not touch the glyph atlas. |
| Phase offset in turns, default 0 | Build now | Small | Two running widgets with the same `speed` share a phase because each elapsed clock starts at 0. An offset does not add a second clock. |
| `spellcheck` and `handwriting` presets | Build now | Small | Const defaults plus a merge. No new motion. |
| Skip-ink as a Latin descender gap, default off | Later | Medium | Line boxes are font metrics, not outlines. A character heuristic is the only honest version. |
| External `Animation<double>` and one-shot draw | Later | Medium | Stopping the ticker today swaps the sine for the static Bezier instead of holding the frame. One clock only. |
| `marker` preset | Later | Blocked | Defined as a large one-shot wave. That animation does not exist, and no in-repo number is a "large" amplitude. |
| Static selection under an ancestor `SelectionArea` | Later | Medium | A transparent `Text` can register. Atlas and hover must stay out. Easy to get wrong on scaling, ellipsis, RTL, and double semantics. |
| `SquigglyTextTheme` | Later | Small | Additive, but only the example repeats these knobs, and several of them should stay per widget. |
| True outline skip-ink, or a from-scratch selectable | Drop | Large | Outlines are not returned by `TextPainter`. A custom selection protocol duplicates the framework. |

## Stroke and skip-ink

`paint` draws glyphs, then one stroke path per line. Static mode uses quadratic Beziers. Animated mode uses a sine polyline. The turbulence shader samples the text atlas only.

Attach `gradient.createShader(rect)` on the stroke `Paint` after the canvas translate, one rect per line from `line.left` through `line.width`. `SweepGradient` does not follow the stroke. `squiggleGradient == null` keeps `squiggleColor`.

`LineMetrics`, `getBoxesForSelection`, and `GlyphInfo.graphemeClusterLayoutBounds` do not expose glyph outlines. `BoxHeightStyle.tight` is per run, so `g` and `a` in one style share a box. A later skip-ink can split the path on a short descending-character set (`g`, `j`, `p`, `q`, `y`), cached with the layout. It will be wrong for Amatic SC and for non-Latin text, and it will miss glyphs that the atlas has already jittered. Do not parse font files.

Neither feature needs squiggle ranges or rich text.

`_lineStart` ignores `TextDirection` and treats `TextAlign.end` as the physical right. Gradient rects and any future gaps should use `LineMetrics.left`, not that helper.

## Phase and one-shot

Wave phase is `elapsedSeconds * 2π * speed`. The shader seed is `(elapsedSeconds / (0.068 / speed)).floor() % 5`. Same speed and same elapsed time means lockstep. Widgets diverge only when one ticker starts later or pauses.

Ship `phase` as turns on the sine, and add `phase / speed` seconds to the seed clock when `speed > 0`. Do not add a separate seed integer. Do not reuse `stagger`; that field was specified as a per-grapheme offset, and letter motion is one atlas field.

`speed == 0`, `hoverOnly` while idle, and reduced motion all set `animationActive` false. The next paint is the Bezier, not a frozen sine. A one-shot "draw then hold" has to keep painting the revealed path after the clock completes. An external `Animation<double>` must replace the internal ticker, be ignored when reduced motion is on, and be removed in `dispose`. `TickerMode` already mutes the internal ticker; a second controller that ignores it would keep moving. Leave `repeat` and `onEnd` on the caller's controller.

## Selection

`CustomPaint` plus one `Semantics` label is not a `RenderParagraph`, so `SelectionArea` sees nothing.

A transparent `Text` registered with an ancestor `SelectionArea` can match static text and a wave-only underline, because those modes do not move glyphs. Pass `textScaler: TextScaler.noScaling` until the painter itself applies scaling, keep the overlay in the glyph band (the widget is taller by `gap + amplitude + strokeWidth`), and remove the outer semantics node so the label is not spoken twice. Copy `text`, not `semanticsLabel`.

Do not select when letter animation or any hover behavior is configured, even if reduced motion happens to skip the atlas for that frame. Wave with hover `none` can stay selectable.

Do not mount an internal `SelectionArea`; that would steal drags the app did not ask for. Opt out with `selectable: false` later. A custom `Selectable` on this `TextPainter` is the large version of the same idea.

## Theme and presets

Highest priority if a theme is added later: explicit constructor argument, then a non-null preset field, then the theme, then today's defaults. Do not make every `double` nullable. Theme fields worth sharing: `squiggleColor`, `amplitude`, `wavelength`, `strokeWidth`, `gap`, `animationStyle`, `speed`. Leave text, semantics, layout, `style`, pointer knobs, `fluidity`, `stagger`, and lifecycle flags on the widget.

Color chain when `squiggleColor` is null: preset, theme, `DefaultTextStyle.merge(style).color`, `textTheme.bodyMedium`, `Colors.black`.

`spellcheck`: `Colors.red`, `animationStyle: none`, `hoverBehavior: none`, and the constructor geometry (amplitude 2, wavelength 8, strokeWidth 1.5, gap 2). That matches Material's red wavy underline. Flutter does not publish a wave size.

`handwriting`: `animationStyle: letters`, `amplitude: 0`, `speed: 1`. Same idea as the example hero. Do not bake in Amatic SC or a font size; the package does not ship that font.

## Sources

Investigations on 2026-09-25:

- Stroke gradient and skip-ink
- Phase offset and one-shot animation
- Static text selection
- Theme extension and presets
