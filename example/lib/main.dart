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
  final _textController = TextEditingController(
    text: 'Squiggly Text',
  );
  double _fontSize = 88;
  double _speed = 1;
  SquigglyHoverBehavior _hoverBehavior = SquigglyHoverBehavior.none;
  SquigglyHoverScope _hoverScope = SquigglyHoverScope.all;
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
    final previewStyle = const TextStyle(
      fontFamily: 'AmaticSC',
      fontWeight: FontWeight.w700,
      height: 1,
      color: Color(0xFF1A1A1A),
    ).copyWith(fontSize: _fontSize);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Squiggly Text'),
      ),
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
            'The handwriting face trembles in place. Adjust the text and its letter animation below.',
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
                        amplitude: 0,
                        textAlign: TextAlign.center,
                        animationStyle: SquigglyAnimationStyle.letters,
                        speed: _speed,
                        hoverBehavior: _hoverBehavior,
                        hoverPreview: !_hoverOnly,
                        hoverScope: _hoverScope,
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
                    label: 'Font size',
                    value: _fontSize,
                    min: 40,
                    max: 120,
                    divisions: 40,
                    onChanged: (value) => setState(() => _fontSize = value),
                  ),
                  _SliderSetting(
                    label: 'Animation speed',
                    value: _speed,
                    min: 0,
                    max: 3,
                    divisions: 30,
                    onChanged: (value) => setState(() => _speed = value),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _hoverOnly
                        ? 'Move the pointer over the text to activate it.'
                        : 'Pointer effects preview at the center of the text. '
                            'Move the pointer over it to interact.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SquigglyHoverScope>(
                    initialValue: _hoverScope,
                    decoration: const InputDecoration(
                      labelText: 'Animation range',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final scope in SquigglyHoverScope.values)
                        DropdownMenuItem(
                          value: scope,
                          child: Text(_hoverScopeLabel(scope)),
                        ),
                    ],
                    onChanged: (scope) {
                      if (scope != null) {
                        setState(() => _hoverScope = scope);
                      }
                    },
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
                          child: Text(_hoverBehaviorLabel(behavior)),
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
              'A longer sentence wraps naturally while every line keeps its animation.',
              style: TextStyle(fontSize: 22, height: 1.35),
              amplitude: 0,
            ),
          ),
          const _ExampleSection(
            title: 'Right-to-left text',
            child: SquigglyText(
              'Right-to-left layout sample',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 24),
              amplitude: 0,
            ),
          ),
          _ExampleSection(
            title: 'Custom semantics label',
            child: Semantics(
              label: 'Accessible animated greeting',
              child: const SquigglyText(
                'Hello Flutter',
                semanticsLabel: 'Accessible animated greeting',
                style: TextStyle(fontSize: 24),
                amplitude: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _hoverBehaviorLabel(SquigglyHoverBehavior behavior) {
    switch (behavior) {
      case SquigglyHoverBehavior.none:
        return 'none (static)';
      case SquigglyHoverBehavior.highlight:
        return 'highlight';
      case SquigglyHoverBehavior.shrink:
        return 'shrink nearby letters';
      case SquigglyHoverBehavior.enlarge:
        return 'enlarge nearby letters';
      case SquigglyHoverBehavior.trembleLetter:
        return 'tremble hovered letter';
      case SquigglyHoverBehavior.trembleWord:
        return 'tremble hovered word';
      case SquigglyHoverBehavior.repel:
        return 'repel like a magnet';
      case SquigglyHoverBehavior.liftLetters:
        return 'lift nearby letters';
      case SquigglyHoverBehavior.magnetic:
        return 'pull like a magnet';
    }
  }

  String _hoverScopeLabel(SquigglyHoverScope scope) {
    switch (scope) {
      case SquigglyHoverScope.all:
        return 'all text';
      case SquigglyHoverScope.word:
        return 'hovered word';
      case SquigglyHoverScope.letter:
        return 'hovered letter';
    }
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
