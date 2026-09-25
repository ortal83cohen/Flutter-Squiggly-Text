# Changelog

## 0.1.5 - 2026-09-16

- Automated patch release from main.

## 0.1.4 - 2026-09-16

- Automated patch release from main.

## Unreleased

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

## 0.1.0

- Initial release.

- Verified support for Android, iOS, Web, Windows, macOS, and Linux.
