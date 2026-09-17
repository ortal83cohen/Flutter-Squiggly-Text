# Changelog

## 0.1.6 - 2026-09-17

- Automated patch release from main.

## 0.1.5 - 2026-09-16

- Automated patch release from main.

## 0.1.4 - 2026-09-16

- Automated patch release from main.

## Unreleased

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

## 0.1.0

- Initial release.

- Verified support for Android, iOS, Web, Windows, macOS, and Linux.
