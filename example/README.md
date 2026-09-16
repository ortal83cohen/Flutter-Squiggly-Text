# flutter_squiggly_text example

This Flutter app demonstrates the `flutter_squiggly_text` package with an
interactive preview. The hero sample uses Amatic SC so glyph jitter is easy
to see. Use the controls to edit the preview text, change its font size and
animation speed, choose a pointer range and interaction mode, choose whether
the preview runs automatically or on hover and keyboard focus, and toggle
reduced-motion behavior. The letter and word tremble modes use a fixed pointer
target, so the pointer range is disabled for those modes.

The lower sections show multiline text, right-to-left layout, and custom
accessibility labels. They animate with the same speed, pointer, activation,
and reduced-motion settings as the main preview. Their fixed text uses half
the selected font size. The multiline sample has a constrained width; the
English RTL layout sample spans the available width and aligns to the right.
The accessibility sample explains the stable label announced by screen readers.

Run it from this directory:

```shell
flutter pub get
flutter run
```

The example uses the package from the parent directory through a local path
dependency. It can be run on Android, iOS, Web, Windows, macOS, and Linux when
the corresponding Flutter toolchain is installed.
