# Text scaling and text height behavior

Research date: 2026-10-02.

`SquigglyText` builds a `TextPainter` in `_SquigglyTextPainter` and never passed a text scaler or `textHeightBehavior`. `MediaQuery` text scaling therefore left the widget at the authored font size. This note records which Flutter API can fix that against the package constraint, and the approach that was implemented.

## What the declared minimum could compile

`pubspec.yaml` required `flutter: ">=3.10.0"` and `sdk: ">=3.0.0 <4.0.0"`. The check below uses the Flutter git tags `3.10.0` and `3.16.0`, not only the 3.47.3 SDK installed on this machine.

| API | Flutter 3.10.0 | Flutter 3.16.0 |
| --- | --- | --- |
| `TextPainter.textScaleFactor` (`double`, default `1.0`) | Present | Present, deprecated |
| `TextPainter.textHeightBehavior` | Present | Present |
| `TextPainter.textScaler` | Absent | Present, default `TextScaler.noScaling` |
| `MediaQuery.textScaleFactorOf` | Present, returns `double` | Present, deprecated |
| `MediaQuery.textScalerOf` | Absent | Present, returns `TextScaler` |
| `TextScaler` | Absent | Present |

`Text` on 3.16 resolves the scaler as the widget's own `textScaler` or deprecated `textScaleFactor` when set, otherwise `MediaQuery.textScalerOf(context)`. `SquigglyText` does not grow a public scaler argument. `Text` has one; this package stays on the ambient query only, which is the case `Text` uses when the caller passes neither override.

`Text` on 3.16 resolves height behavior as the explicit argument, then `DefaultTextStyle.of(context).textHeightBehavior`, then `DefaultTextHeightBehavior.maybeOf(context)`.

## Why `textScaleFactor` is not enough

A `double` scale factor compiles on Flutter 3.10 and still exists later as a deprecated parameter. It only multiplies font size. `TextScaler` exists so platforms can scale nonlinearly: `TextScaler.scale` depends on the input font size, and `textScaleFactor` on that type is documented as an estimate kept for compatibility. Passing `MediaQuery.textScaleFactorOf` would make a linear 2.0 setting larger, and it would not match `Text` when the ambient scaler is not `TextScaler.linear`.

The deprecation on `TextPainter.textScaleFactor` says the double was deprecated after `v3.12.0-2.0.pre`, which shipped as Flutter 3.16. Using it on a current SDK also trips `deprecated_member_use` under `flutter_lints`.

## Decision

Raise the Flutter constraint from `>=3.10.0` to `>=3.16.0` and pass `TextPainter.textScaler`. The Dart SDK constraint stays `>=3.0.0 <4.0.0`. Flutter 3.16 ships with Dart 3.2, and this change does not need newer Dart language features. The root `# Changelog` title stays in place. The `## Unreleased` notes record the constraint bump.

Implementation:

- Read the scaler with `MediaQuery.textScalerOf(context)`. There is no public `textScaler` parameter.
- Resolve `textHeightBehavior` as the new optional constructor argument, or `DefaultTextStyle.of(context).textHeightBehavior` when that argument is null.
- Forward both into `TextPainter`.
- Include both in `_AtlasLayoutKey` and in `shouldRepaint`, so a scaler or height-behavior change cannot reuse an atlas or skip a repaint.

`TextScaler.noScaling` is `TextScaler.linear(1.0)`, which is the `TextPainter` default when no scaler is passed. A null `textHeightBehavior` is also that painter's default. Callers who leave scaling at 1.0 and do not set height behavior keep the previous layout, including when `DefaultTextStyle.textHeightBehavior` is null.

This widget does not consult `DefaultTextHeightBehavior.maybeOf`. An ancestor that sets only that inherited widget, with a null `DefaultTextStyle.textHeightBehavior`, still does not affect `SquigglyText`. `Text` would use it as a third fallback.

Letter travel and the atlas shader still read `style.fontSize` (default 14) rather than the scaled font size. Scaling changes glyph size through `TextPainter`. It does not change hover, amplitude, or letter-motion distances.
