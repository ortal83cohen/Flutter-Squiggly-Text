# flutter_squiggly_text

Add a customizable squiggly underline to Flutter text, with optional animation
and pointer interaction.

## Features

- Static or animated underlines with configurable amplitude, wavelength, gap,
	stroke width, color, and speed.
- Letter animation that preserves grapheme clusters, including combining marks
	and emoji sequences.
- Pointer interactions for highlighting, lifting, and magnetically pulling nearby letters.
- Keyboard-focus activation through `hoverOnly` when interaction is configured.
- Standard Flutter text layout options, including wrapping, alignment,
	overflow, maximum lines, strut styles, locales, and text direction.
- Accessibility semantics with an optional custom label.
- Reduced-motion support enabled by default.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_squiggly_text: ^0.1.0
```

## Usage

```dart
import 'package:flutter_squiggly_text/flutter_squiggly_text.dart';

const SquigglyText(
  'Hello Flutter',
  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  squiggleColor: Colors.deepOrange,
  amplitude: 3,
  wavelength: 10,
)
```

`SquigglyText` supports regular Flutter text styling, wrapping, alignment,
maximum lines, and custom accessibility labels.

Animation is static by default. To enable the initial animated underline wave:

```dart
const SquigglyText(
  'Hello Flutter',
  animationStyle: SquigglyAnimationStyle.wave,
  speed: 1,
)
```

Use `SquigglyAnimationStyle.letters` to wriggle graphemes in place, or
`SquigglyAnimationStyle.waveAndLetters` to combine that motion with the
underline. Letter motion scales with font size and `amplitude` so the glyphs
stay readable and visibly alive. Animation parameters are validated, and
`respectReducedMotion` defaults to `true` so platform reduced-motion
preferences disable the internal ticker and pointer response.

Pointer interaction can be enabled with `hoverBehavior` and `hoverRadius`:

```dart
const SquigglyText(
  'Hover me',
  animationStyle: SquigglyAnimationStyle.waveAndLetters,
  hoverBehavior: SquigglyHoverBehavior.liftLetters,
  hoverRadius: 56,
)
```

`highlight` brightens nearby graphemes, while `liftLetters` and `magnetic` lift
nearby graphemes with a bounded falloff. When animation is enabled, `hoverOnly`
waits for pointer input or keyboard focus. Configured interaction participates
in keyboard focus traversal; the default static widget does not request focus.

Set `pauseWhenNotVisible` to pause automatic animation while the app is
inactive or paused. This is an app-lifecycle signal, not viewport visibility
detection.

## API overview

The main public API is the `SquigglyText` widget:

| Option | Purpose |
| --- | --- |
| `style` and `squiggleColor` | Configure text and underline appearance. |
| `amplitude`, `wavelength`, `strokeWidth`, and `gap` | Configure underline geometry. |
| `animationStyle`, `speed`, `fluidity`, and `stagger` | Configure animation. |
| `hoverBehavior`, `hoverRadius`, and `hoverOnly` | Configure pointer and focus interaction. |
| `respectReducedMotion` and `pauseWhenNotVisible` | Control when animation runs. |
| `semanticsLabel` | Provide an alternative accessibility label. |

See the generated API documentation for the complete constructor and property
reference.

## Example application

The [`example/`](example/) directory contains an interactive preview with
Amatic SC, glyph animation, underline geometry, color, wrapping,
right-to-left text, and accessibility semantics.

```shell
cd example
flutter pub get
flutter run
```

## Supported platforms

This package is implemented entirely with Flutter's cross-platform rendering
APIs and has no platform-specific plugins or native dependencies. It supports
all Flutter application targets:

- Android
- iOS
- Web
- Windows
- macOS
- Linux

The example application can be used on every supported Flutter target.

## License

This package is available under the MIT License.
