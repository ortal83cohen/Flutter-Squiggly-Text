import 'package:flutter/material.dart';
import 'package:flutter_squiggly_text/flutter_squiggly_text.dart';
import 'package:flutter_squiggly_text_example/l10n/app_localizations.dart';

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
      supportedLocales: AppLocalizations.supportedLocales,
    );
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

  final _textController = TextEditingController(text: 'Make every word ripple');
  double _fontSize = 36;
  double _letterSpacing = 0;
  double _lineHeight = 1.2;
  FontWeight _fontWeight = FontWeight.w700;
  TextAlign _textAlign = TextAlign.center;
  TextDirection _textDirection = TextDirection.ltr;
  TextOverflow _overflow = TextOverflow.clip;
  int _maxLines = 2;
  Color _textColor = Colors.teal;
  SquigglyAnimationStyle _animationStyle = SquigglyAnimationStyle.letters;
  double _speed = 1;
  double _fluidity = 0.5;
  double _stagger = 0.2;
  SquigglyHoverBehavior _hoverBehavior = SquigglyHoverBehavior.none;
  double _hoverRadius = 48;
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
    final previewStyle = theme.textTheme.headlineMedium?.copyWith(
      fontSize: _fontSize,
      fontWeight: _fontWeight,
      letterSpacing: _letterSpacing,
      height: _lineHeight,
      color: _textColor,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Squiggly Text')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Interactive text preview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Adjust typography and text behavior to see the widget respond.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 180,
                    child: Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: SquigglyText(
                          _textController.text,
                          style: previewStyle,
                          // The example focuses on text; no underline is drawn.
                          amplitude: 0,
                          gap: 0,
                          textAlign: _textAlign,
                          textDirection: _textDirection,
                          maxLines: _maxLines,
                          overflow: _overflow,
                          animationStyle: _animationStyle,
                          speed: _speed,
                          fluidity: _fluidity,
                          stagger: _stagger,
                          hoverBehavior: _hoverBehavior,
                          hoverRadius: _hoverRadius,
                          hoverOnly: _hoverOnly,
                          respectReducedMotion: _respectReducedMotion,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    label: 'Font size',
                    value: _fontSize,
                    min: 16,
                    max: 64,
                    divisions: 24,
                    onChanged: (value) => setState(() => _fontSize = value),
                  ),
                  _SliderSetting(
                    label: 'Letter spacing',
                    value: _letterSpacing,
                    min: -2,
                    max: 8,
                    divisions: 20,
                    onChanged: (value) =>
                        setState(() => _letterSpacing = value),
                  ),
                  _SliderSetting(
                    label: 'Line height',
                    value: _lineHeight,
                    min: 0.8,
                    max: 2,
                    divisions: 12,
                    onChanged: (value) => setState(() => _lineHeight = value),
                  ),
                  DropdownButtonFormField<FontWeight>(
                    initialValue: _fontWeight,
                    decoration: const InputDecoration(
                      labelText: 'Font weight',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final weight in <FontWeight>[
                        FontWeight.w300,
                        FontWeight.w400,
                        FontWeight.w500,
                        FontWeight.w700,
                        FontWeight.w900,
                      ])
                        DropdownMenuItem(
                          value: weight,
                          child: Text('Weight ${weight.value}'),
                        ),
                    ],
                    onChanged: (weight) {
                      if (weight != null) {
                        setState(() => _fontWeight = weight);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _EnumDropdown<TextAlign>(
                    label: 'Text alignment',
                    value: _textAlign,
                    values: TextAlign.values,
                    onChanged: (value) => setState(() => _textAlign = value),
                  ),
                  const SizedBox(height: 12),
                  _EnumDropdown<TextDirection>(
                    label: 'Text direction',
                    value: _textDirection,
                    values: TextDirection.values,
                    onChanged: (value) =>
                        setState(() => _textDirection = value),
                  ),
                  const SizedBox(height: 12),
                  _EnumDropdown<TextOverflow>(
                    label: 'Overflow',
                    value: _overflow,
                    values: TextOverflow.values,
                    onChanged: (value) => setState(() => _overflow = value),
                  ),
                  _SliderSetting(
                    label: 'Max lines',
                    value: _maxLines.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    valueText: '$_maxLines',
                    onChanged: (value) =>
                        setState(() => _maxLines = value.round()),
                  ),
                  const SizedBox(height: 8),
                  _EnumDropdown<SquigglyAnimationStyle>(
                    label: 'Text animation',
                    value: _animationStyle,
                    values: const [
                      SquigglyAnimationStyle.none,
                      SquigglyAnimationStyle.letters,
                    ],
                    onChanged: (value) =>
                        setState(() => _animationStyle = value),
                  ),
                  _SliderSetting(
                    label: 'Animation speed',
                    value: _speed,
                    min: 0,
                    max: 3,
                    divisions: 12,
                    onChanged: (value) => setState(() => _speed = value),
                  ),
                  _SliderSetting(
                    label: 'Fluidity',
                    value: _fluidity,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    onChanged: (value) => setState(() => _fluidity = value),
                  ),
                  _SliderSetting(
                    label: 'Letter stagger',
                    value: _stagger,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    onChanged: (value) => setState(() => _stagger = value),
                  ),
                  const SizedBox(height: 8),
                  _EnumDropdown<SquigglyHoverBehavior>(
                    label: 'Pointer interaction',
                    value: _hoverBehavior,
                    values: SquigglyHoverBehavior.values,
                    onChanged: (value) =>
                        setState(() => _hoverBehavior = value),
                  ),
                  _SliderSetting(
                    label: 'Pointer radius',
                    value: _hoverRadius,
                    min: 16,
                    max: 120,
                    divisions: 13,
                    onChanged: (value) => setState(() => _hoverRadius = value),
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
                  Text('Text color', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      for (final color in _colors)
                        ChoiceChip(
                          label: const SizedBox.shrink(),
                          avatar: CircleAvatar(backgroundColor: color),
                          selected: color == _textColor,
                          onSelected: (_) => setState(() => _textColor = color),
                        ),
                    ],
                  ),
                ],
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
    this.valueText,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 112, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueText ?? value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 38, child: Text(valueText ?? value.toStringAsFixed(1))),
      ],
    );
  }
}

class _EnumDropdown<T extends Enum> extends StatelessWidget {
  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final option in values)
          DropdownMenuItem(value: option, child: Text(option.name)),
      ],
      onChanged: (option) {
        if (option != null) {
          onChanged(option);
        }
      },
    );
  }
}
