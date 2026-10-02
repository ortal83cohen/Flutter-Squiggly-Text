# Changelog

## Unreleased

## 0.1.9 - 2026-10-02

- Pointed the README report link at this repository.
- `SquigglyText` now applies the ambient `MediaQuery` text scaler during
  layout, matching `Text`. This requires Flutter 3.16 or newer because
  `TextPainter.textScaler` did not exist in Flutter 3.10.
- Added optional `textHeightBehavior`. Null uses
  `DefaultTextStyle.of(context).textHeightBehavior`.
- Pointer effects follow a finger or stylus as well as the mouse. Contact uses
  the same local point as hover, clears when the touch ends or is canceled, and
  a mouse click keeps the effect while the pointer stays inside.
- Calmed letter motion. Displacement now follows SVG
  `scale * (channel - 0.5)`, so the peak is half of the previous distance,
  and small text is no longer lifted to a 1.5px floor.
- Added optional `letterAmplitude`, the peak letter offset in logical pixels.
  Null keeps the font-derived distance and does not change underline
  `amplitude`.
- Crossfaded turbulence seeds across the last quarter of each step so the
  picture no longer jumps between seeds.
- Kept autonomous letter tremor while a pointer hovers one letter or word.
  Pointer effects add local motion instead of freezing the rest of the line.
- The example demonstrates the underline wave, spellcheck preset, and gradient.

## 0.1.8 - 2026-09-25

- Pointed the README example GIF at an absolute GitHub URL so pub.dev can show
  it before package analysis resolves relative image paths.

## 0.1.7 - 2026-09-25

- Added an optional `squiggleGradient` for the underline stroke. A null gradient
  keeps the solid `squiggleColor`. The gradient follows each laid-out line and
  does not recolor the glyphs.
- Added a `phase` offset in turns. The default `0` keeps matching animations in
  lockstep. Negative turns are allowed, and a negative phase still selects a
  letter-shader seed from 0 through 4. `speed: 0` does not start motion.
- Added `SquigglyTextStyle` with `spellcheck` (red, static underline, library
  geometry) and `handwriting` (letter motion, amplitude 0, speed 1). Explicit
  constructor arguments override preset fields. Preset numbers use the same
  finite-value checks as the widget.
- Fixed underline placement so each squiggle starts at the laid-out line,
  including centered, end-aligned, and right-to-left text.
- Promoted notes under `## Unreleased` into the version section created by the
  patch release workflow.
- Changed the squiggly underline to be opt-in with `showSquiggle: true`;
  text is now rendered without an underline by default.
- Restored the example animation GIF and related captured media after they were
  accidentally emptied in a previous commit.
- Documented that agents must keep `CHANGELOG.md` updated for behavior,
  compatibility, workflow, and documentation-policy changes.
- Implemented hover and keyboard focus interaction for configured widgets,
	including bounded highlight, letter-lift, and magnetic pointer responses.
- Added hover modes for shrinking, enlarging, trembling a hovered letter or
	word, and repelling nearby letters.
- Added hover-only animation scopes for the full text, hovered word, or hovered
	letter, with a centered preview mode for interactive examples.
- Implemented `hoverOnly`, reduced-motion suppression, and best-effort app
	lifecycle pausing without adding visibility dependencies.
- Added validated animation style and interaction configuration.
- Added the optional `wave` underline animation; static rendering remains the
	default.
- Fixed `softWrap: false` to lay out text with unlimited width.
- Added focused regression coverage for animated hover pointer activation.

## 0.1.6 - 2026-09-17

- Automated patch release from main.

## 0.1.5 - 2026-09-16

- Automated patch release from main.

## 0.1.4 - 2026-09-16

- Automated patch release from main.

## 0.1.0

- Initial release.

- Verified support for Android, iOS, Web, Windows, macOS, and Linux.
