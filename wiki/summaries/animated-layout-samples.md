# Animated Layout Samples

The layout and accessibility examples now use letter animation and share the
main preview speed, pointer behavior and range, activation, and reduced-motion
settings. Their text remains fixed and their font size is half the selected size.

The multiline example is constrained to 420 logical pixels (or available width).
The English RTL layout example fills the available width and aligns right;
it demonstrates layout, not native RTL script shaping. Project content remains
in English. The semantics example explains its stable screen-reader label.

Validation: all five example widget tests passed, including shared controls,
multiline height, and full-width RTL layout. No live browser verification was
performed. Existing unrelated working-tree edits were preserved.
