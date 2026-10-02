# Touch pointer routing

Date: 2026-10-02

## What the code did

Configured pointer effects live in `_SquigglyTextState` in `lib/flutter_squiggly_text.dart`.

`_interactionConfigured` is true when `hoverBehavior` is not `none`, or when `hoverOnly` is set on an animation that is not `none`. Only then does `build` wrap the text. Before this change that wrapper was only a `MouseRegion`:

- `onHover` called `_setPointerPosition(event.localPosition)`.
- `onExit` called `_setPointerPosition(null)`.

`_setPointerPosition` writes `_pointerPosition` and calls `_updateAnimation`. It does nothing when interaction is not configured.

`_updateAnimation` treats a non-null `_pointerPosition`, keyboard focus, and `hoverPreview` as the same kind of activation. `hoverOnly` holds the ticker until one of those is active. Tremble modes also start the ticker from that activation even when `animationStyle` is `none`.

The painter reads `_pointerPosition` directly. When the value is null and `hoverPreview` is true, it substitutes the text center. Focus sets that preview flag (`hoverPreview: widget.hoverPreview || _isFocused`) without writing a pointer coordinate, so a focused widget stays on the center until a real pointer exists. A real pointer wins over the center.

Reduced motion does not remove the pointer wrapper. It stops the ticker and passes `SquigglyHoverBehavior.none` into the painter, so pointer motion has no visual effect.

Touch and pen never produced `MouseRegion.onHover`, so phones never set `_pointerPosition`.

## Routing choice

Keep `MouseRegion` for hover and exit. Add a `Listener` around it when interaction is configured.

`Listener` reports pointer down, move, up, and cancel without joining the gesture arena, so an ancestor scroll view can still accept the drag. A `GestureDetector` would compete for that drag and was not used.

Contact tracking accepts `PointerDeviceKind.touch`, `stylus`, and `invertedStylus`:

- The first contact pointer's down and move call `_setPointerPosition` with `localPosition`.
- Up and cancel clear the contact id and restore the last hover point, which is null when no mouse or pen is hovering. The effect does not stay after the finger lifts.
- Mouse and trackpad down or up are ignored. A click does not clear a hover that is still inside the widget. Leaving the widget still clears through `MouseRegion.onExit`.

While a contact pointer is down, hover updates are stored but not shown, so the finger keeps the point. Hover exit during that contact forgets the stored hover and does not clear the finger. When the finger lifts, the stored hover is restored if the mouse is still inside.

`Listener` is the parent of `MouseRegion`, and both are sized to the same child, so hover and contact `localPosition` values share one origin. The painter, shader, amplitude, and public constructor fields are unchanged. Focus still supplies the center only when `_pointerPosition` is null. Reduced motion still forces the painter behavior to `none`.

## Tests

`test/configuration_interactions_test.dart` checks that a `PointerDeviceKind.touch` down and move write the same local point a mouse hover writes for `trembleLetter`, that the ticker starts, and that pointer up clears the point and stops the ticker. A second test checks that a mouse button up leaves the hover point in place.
