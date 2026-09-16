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
  bool _previewOnIdle = true;
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
                        hoverPreview: _previewOnIdle,
                        hoverScope: _effectiveScope,
                        hoverOnly: !_previewOnIdle,
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
                    _speed == 0
                        ? 'Animation paused; pointer effects remain available.'
                        : _previewOnIdle
                            ? 'Pointer effects preview at the center of the text. '
                                'Move the pointer over it to interact.'
                            : 'Move the pointer over the text or focus it with '
                                'the keyboard to activate it.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SquigglyHoverScope>(
                    key: ValueKey(_effectiveScope),
                    initialValue: _effectiveScope,
                    decoration: const InputDecoration(
                      labelText: 'Pointer range',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final scope in SquigglyHoverScope.values)
                        DropdownMenuItem(
                          value: scope,
                          child: Text(_hoverScopeLabel(scope)),
                        ),
                    ],
                    onChanged: _rangeIsFixed
                        ? null
                        : (scope) {
                            if (scope != null) {
                              setState(() => _hoverScope = scope);
                            }
                          },
                  ),
                  if (_rangeIsFixed)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _hoverBehavior == SquigglyHoverBehavior.trembleLetter
                            ? 'This effect always targets one letter.'
                            : 'This effect always targets one word.',
                      ),
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<bool>(
                    initialValue: _previewOnIdle,
                    decoration: const InputDecoration(
                      labelText: 'Activation',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: true,
                        child: Text('Automatic preview'),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text('Hover or keyboard focus'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _previewOnIdle = value);
                      }
                    },
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
          Text('Layout and accessibility',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text(
            'These samples share the animation and pointer controls above. '
            'Font size is scaled to half the main preview; sample text stays fixed.',
          ),
          const SizedBox(height: 16),
          _ExampleSection(
            title: 'Multiline text',
            child: SizedBox(
              width: 420,
              child: _layoutSample(
                'A longer sentence wraps naturally while every line keeps its animation.',
              ),
            ),
          ),
          _ExampleSection(
            title: 'Right-to-left layout (English text, aligned right)',
            child: SizedBox(
              width: double.infinity,
              child: _layoutSample(
                'Right-aligned animated sample',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
          ),
          _ExampleSection(
            title: 'Custom semantics label',
            child: _layoutSample(
              'Hello Flutter',
              semanticsLabel: 'Accessible animated greeting',
            ),
          ),
          const Text(
            'Screen readers announce “Accessible animated greeting” '
            'as one stable label while the text animates.',
          ),
        ],
      ),
    );
  }

  Widget _layoutSample(
    String text, {
    TextDirection? textDirection,
    TextAlign textAlign = TextAlign.start,
    String? semanticsLabel,
  }) =>
      SquigglyText(
        text,
        style: TextStyle(
          fontFamily: 'AmaticSC',
          fontWeight: FontWeight.w700,
          fontSize: _fontSize / 2,
          height: 1.35,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        amplitude: 0,
        animationStyle: SquigglyAnimationStyle.letters,
        speed: _speed,
        hoverBehavior: _hoverBehavior,
        hoverPreview: _previewOnIdle,
        hoverScope: _effectiveScope,
        hoverOnly: !_previewOnIdle,
        respectReducedMotion: _respectReducedMotion,
        textDirection: textDirection,
        textAlign: textAlign,
        semanticsLabel: semanticsLabel,
      );

  String _hoverBehaviorLabel(SquigglyHoverBehavior behavior) {
    switch (behavior) {
      case SquigglyHoverBehavior.none:
        return 'none';
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

  SquigglyHoverScope get _effectiveScope => switch (_hoverBehavior) {
        SquigglyHoverBehavior.trembleLetter => SquigglyHoverScope.letter,
        SquigglyHoverBehavior.trembleWord => SquigglyHoverScope.word,
        _ => _hoverScope,
      };

  bool get _rangeIsFixed =>
      _hoverBehavior == SquigglyHoverBehavior.trembleLetter ||
      _hoverBehavior == SquigglyHoverBehavior.trembleWord;

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
          width: 48,
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
  Widget build(BuildContext context) => Padding(
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
