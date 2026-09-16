# Changelog

## 0.1.2 - 2026-09-16

- Automated patch release from main.

## 0.1.1 - 2026-09-16

- Automated patch release from main.

## Unreleased

- Made `letters` and `waveAndLetters` use CodePen-style shared turbulence
	displacement of the complete shaped text run instead of bouncing letter
	sprites. Displacement is scaled from font size and `amplitude` remains
	underline-only.
- Updated the example preview to use Amatic SC and show glyph animation by
	default.
- Implemented hover and keyboard focus interaction for configured widgets,
	including bounded highlight, letter-lift, and magnetic pointer responses.
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
