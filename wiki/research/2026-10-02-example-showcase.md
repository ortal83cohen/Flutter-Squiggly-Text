# Example showcase gap

Research date: 2026-10-02.

This note records why the example app hides the package's underline, and which public API the example should use to show it. It does not change `lib/`.

## What the example does today

`example/lib/main.dart` builds four `SquigglyText` widgets:

1. The interactive preview.
2. A multiline layout sample.
3. A right-to-left layout sample.
4. A semantics-label sample.

Every one of them sets `amplitude: 0`, `animationStyle: SquigglyAnimationStyle.letters`, and `showSquiggle: true`. There is no control for animation style. The intro says the handwriting face trembles in place.

`amplitude` is the underline wave height. The painter skips a line when `amplitude` is 0, so `showSquiggle: true` still draws nothing. Letter motion does not use `amplitude`. Someone who runs the example sees glyph tremor and pointer effects only.

The widget test locks that shape: it expects exactly four `SquigglyText` widgets, and every widget after the preview is hard-coded to `SquigglyAnimationStyle.letters`.

## Public API the example never reaches

All of the following already exist on `SquigglyText` / `SquigglyTextStyle` in `lib/flutter_squiggly_text.dart`.

| API | What it does | Example today |
| --- | --- | --- |
| `SquigglyAnimationStyle.none` | Static text and a static Bezier squiggle. | Unused. |
| `SquigglyAnimationStyle.wave` | Animates the underline sine wave. | Unused. |
| `SquigglyAnimationStyle.letters` | Animates glyphs. Underline stays a static squiggle unless amplitude is 0, in which case it is skipped. | Forced on every sample. |
| `SquigglyAnimationStyle.waveAndLetters` | Wave plus glyph motion. | Unused. |
| `showSquiggle` | Opt-in underline. Default is false. | True, but amplitude 0 hides it. |
| `amplitude` | Underline height in logical pixels. Default 2. Does not move letters. | Forced to 0. |
| `SquigglyTextStyle.spellcheck` | Red static underline (`squiggleColor: Colors.red`, `animationStyle: none`). Amplitude stays at the library default. | Unused. |
| `SquigglyTextStyle.handwriting` | Letter motion, amplitude 0, speed 1. | Not used by name. The preview copies its look with explicit arguments. |
| `squiggleGradient` | Stroke gradient along each laid-out line. Null keeps a solid color. Glyph color stays on `style`. | Unused. |
| `phase` | Offset in turns for the wave and, when speed is positive, the letter shader. Default 0. | Unused. |

Styled fields resolve as explicit constructor argument, then a non-null `squiggleStyle` field, then the library default. A spellcheck sample must not pass `amplitude: 0` or `animationStyle`, or those arguments would replace the preset. `showSquiggle: true` is still required, because the preset does not turn the underline on.

A static `none` squiggle needs a positive amplitude. A letters-only sample can keep amplitude 0 so the handwriting tremor has a clean baseline. `wave` and `waveAndLetters` need a positive amplitude (about 4 in the example, above the library default of 2) or the wave has nothing to travel.

## README claim

The README example section says the app contains an interactive preview with Amatic SC, glyph displacement, underline geometry, color, wrapping, right-to-left text, and accessibility semantics. Wrapping, direction, semantics, and glyph displacement are on screen. Underline geometry and squiggle color are not, because every sample zeroes the wave.

The same README already shows the calls the example is missing: `animationStyle: wave` with `squiggleGradient` and `phase: 0.25`, and `squiggleStyle: SquigglyTextStyle.spellcheck` on a misspelling with `showSquiggle: true`.

## What the example should show

Keep the current preview controls: font size, speed, hover scope, hover behavior, activation, and reduced motion.

Add one animation-style control with the four enum values. Drive the preview and the layout samples from it:

- `wave` and `waveAndLetters`: `showSquiggle: true` and amplitude about 4.
- `none`: `showSquiggle: true` and the same visible amplitude, so the squiggle is static rather than absent.
- `letters`: amplitude 0, so only the tremor remains.

Add a short second group that does not follow that amplitude. It should stay readable in a phone-width list (no fixed width in the hundreds of pixels):

- `SquigglyTextStyle.spellcheck` on a misspelling, with `showSquiggle: true`.
- A `wave` sample with `squiggleGradient` and a non-zero `phase`.

The intro should describe the underline and letter motion, not only a handwriting tremble.

No new package API is required. `letterAmplitude` does not exist on this branch and the example must not depend on it.
