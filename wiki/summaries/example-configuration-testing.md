# Example configuration testing and fixes

## Scope

Manually exercised the local Flutter web example: editable and empty text,
font-size limits, speed limits, all pointer modes, all/word/letter ranges,
activation and reduced-motion controls. Used three lower-cost agents for
rendering fixes, example controls, and configuration review, followed by
integration review and additional regression coverage.

## Changes

- Reserve horizontal and vertical shader margins separately and include them
  in the available text width, preventing clipped scaled text in narrow previews.
- Keep atlas painting, pointer coordinates, and scope coordinates consistent.
- Correct inverse shader sampling for lift, repel, and magnetic pull.
- Separate static pointer displacement strength from automatic text turbulence.
- Honor the named scopes of tremble-letter and tremble-word modes.
- Give keyboard focus a centered interaction target and repaint when scope or
  preview configuration changes.
- Clarify activation, pointer range, paused animation, and no-pointer-effect
  labels in the example; preserve layout and accessibility demonstrations.
- Document preview precedence and the existing limitation that `stagger` has no
  visual effect. No public constructor parameters were removed.

## Validation

- 24 package tests passed at the time of this pass.
- Example widget tests now also cover shared layout samples and fixed tremble ranges. See [Animated Layout Samples](animated-layout-samples.md).
- Static analysis passed with no issues.
- Release web build succeeded.
- Final controls and single accessibility label checked in Chrome.

Package regression tests cover bounded multiline scaling, effective tremble
scope, keyboard focus targets, explicit preview activation, and runtime repaint
invalidation, in addition to the existing layout and animation tests.

The system has multiple Flutter installations. Validation uses Flutter 3.47.0
at `/Users/ortalcohen/fvm/versions/3.47.0/bin/flutter`; the older SDK cannot resolve
the package's current `characters` dependency constraint.

The browser check does not simulate an operating-system reduced-motion setting;
that behavior is covered by the package's MediaQuery-based regression test.
