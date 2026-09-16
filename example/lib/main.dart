import 'package:flutter_squiggly_text_example/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_squiggly_text/flutter_squiggly_text.dart';

void main() {
  runApp(const SquigglyTextExampleApp());
}

/// Demonstrates the flutter_squiggly_text package.
class SquigglyTextExampleApp extends StatelessWidget {
  /// Creates the example application.
  const SquigglyTextExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Squiggly Text Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const ExamplePage(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales);
  }
}

/// Displays the interactive package example.
class ExamplePage extends StatefulWidget {
  /// Creates the example page.
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  static const _colors = <Color>[
    Colors.teal,
    Colors.deepOrange,
    Colors.indigo,
    Colors.pink,
  ];

  final _textController = TextEditingController(
    text: 'Squiggly Text',
  );
  double _amplitude = 6;
  double _wavelength = 14;
  double _gap = 4;
  Color _squiggleColor = Colors.deepOrange;
  SquigglyAnimationStyle _animationStyle =
      SquigglyAnimationStyle.waveAndLetters;
  SquigglyHoverBehavior _hoverBehavior = SquigglyHoverBehavior.none;
  bool _hoverOnly = false;
  bool _respectReducedMotion = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const previewStyle = TextStyle(
      fontFamily: 'AmaticSC',
      fontSize: 88,
      fontWeight: FontWeight.w700,
      height: 1,
      color: Color(0xFF1A1A1A),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Squiggly Text'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Interactive preview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The handwriting face trembles in place. Use Wave + letters to keep both the glyphs and the underline moving.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Animated glyph preview',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 28,
                      ),
                      child: SquigglyText(
                        _textController.text,
                        style: previewStyle.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        squiggleColor: _squiggleColor,
                        amplitude: _amplitude,
                        wavelength: _wavelength,
                        gap: _gap,
                        strokeWidth: 2,
                        textAlign: TextAlign.center,
                        animationStyle: _animationStyle,
                        speed: 1,
                        hoverBehavior: _hoverBehavior,
                        hoverOnly: _hoverOnly,
                        respectReducedMotion: _respectReducedMotion,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'Preview text',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _SliderSetting(
                    label: 'Amplitude',
                    value: _amplitude,
                    min: 0,
                    max: 20,
                    divisions: 40,
                    onChanged: (value) => setState(() => _amplitude = value),
                  ),
                  _SliderSetting(
                    label: 'Wavelength',
                    value: _wavelength,
                    min: 4,
                    max: 24,
                    divisions: 20,
                    onChanged: (value) => setState(() => _wavelength = value),
                  ),
                  _SliderSetting(
                    label: 'Gap',
                    value: _gap,
                    min: 0,
                    max: 8,
                    divisions: 16,
                    onChanged: (value) => setState(() => _gap = value),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SquigglyAnimationStyle>(
                    initialValue: _animationStyle,
                    decoration: const InputDecoration(
                      labelText: 'Animation style',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: SquigglyAnimationStyle.none,
                        child: Text('none (static)'),
                      ),
                      DropdownMenuItem(
                        value: SquigglyAnimationStyle.wave,
                        child: Text('wave (underline only)'),
                      ),
                      DropdownMenuItem(
                        value: SquigglyAnimationStyle.letters,
                        child: Text('letters (glyphs only)'),
                      ),
                      DropdownMenuItem(
                        value: SquigglyAnimationStyle.waveAndLetters,
                        child: Text('wave + letters'),
                      ),
                    ],
                    onChanged: (style) {
                      if (style != null) {
                        setState(() => _animationStyle = style);
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _animationStyle == SquigglyAnimationStyle.wave
                        ? 'Wave moves the underline only. Choose wave + letters to animate the glyphs.'
                        : _animationStyle == SquigglyAnimationStyle.letters
                            ? 'Letters tremble in place. The underline stays static.'
                            : _animationStyle ==
                                    SquigglyAnimationStyle.waveAndLetters
                                ? 'Glyphs and underline both animate.'
                                : 'Static text and underline.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SquigglyHoverBehavior>(
                    initialValue: _hoverBehavior,
                    decoration: const InputDecoration(
                      labelText: 'Pointer interaction',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final behavior in SquigglyHoverBehavior.values)
                        DropdownMenuItem(
                          value: behavior,
                          child: Text(behavior.name),
                        ),
                    ],
                    onChanged: (behavior) {
                      if (behavior != null) {
                        setState(() => _hoverBehavior = behavior);
                      }
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Animate only on hover or focus'),
                    value: _hoverOnly,
                    onChanged: (value) => setState(() => _hoverOnly = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Respect reduced-motion settings'),
                    value: _respectReducedMotion,
                    onChanged: (value) =>
                        setState(() => _respectReducedMotion = value),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      for (final color in _colors)
                        ChoiceChip(
                          label: const SizedBox.shrink(),
                          avatar: CircleAvatar(backgroundColor: color),
                          selected: color == _squiggleColor,
                          onSelected: (_) =>
                              setState(() => _squiggleColor = color),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Layout and accessibility',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const _ExampleSection(
            title: 'Multiline text',
            child: SquigglyText(
              'A longer sentence wraps naturally while every line keeps its underline.',
              style: TextStyle(fontSize: 22, height: 1.35),
              squiggleColor: Colors.deepOrange,
              amplitude: 2.5,
              wavelength: 9,
            ),
          ),
          const _ExampleSection(
            title: 'Right-to-left text',
            child: SquigglyText(
              'Right-to-left layout sample',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 24),
              squiggleColor: Colors.indigo,
            ),
          ),
          _ExampleSection(
            title: 'Custom semantics label',
            child: Semantics(
              label: 'Accessible underlined greeting',
              child: const SquigglyText(
                'Hello Flutter',
                semanticsLabel: 'Accessible underlined greeting',
                style: TextStyle(fontSize: 24),
                squiggleColor: Colors.pink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 92, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(value.toStringAsFixed(1)),
        ),
      ],
    );
  }
}

class _ExampleSection extends StatelessWidget {
  const _ExampleSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
