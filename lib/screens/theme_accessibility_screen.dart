import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/preference_notifier.dart';
import '../widgets/notebook/notebook.dart';

/// Paper or blackboard, text size, motion. Saved on this device.
class ThemeAccessibilityScreen extends StatelessWidget {
  const ThemeAccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = PreferenceNotifier.instance;
    return NotebookPage(
      title: 'Theme & accessibility',
      body: ListenableBuilder(
        listenable: prefs,
        builder: (context, _) {
          final theme = Theme.of(context);
          final mode = switch (prefs.themeMode) { ThemeMode.light => 'light', ThemeMode.dark => 'dark', _ => 'system' };
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(padding: const EdgeInsets.all(24), children: [
                const NoteHeading('Page'),
                const SizedBox(height: 14),
                Wrap(spacing: 16, runSpacing: 16, children: [
                  for (final (value, label, light) in const [
                    ('light', 'Paper', true),
                    ('dark', 'Blackboard', false),
                    ('system', 'Match my device', null),
                  ])
                    _Swatch(label: label, light: light, selected: mode == value, onTap: () => prefs.updateTheme(value)),
                ]),
                const SizedBox(height: 32),
                const NoteHeading('Text size'),
                const SizedBox(height: 14),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'small', label: Text('Small')),
                    ButtonSegment(value: 'normal', label: Text('Normal')),
                    ButtonSegment(value: 'large', label: Text('Large')),
                    ButtonSegment(value: 'extraLarge', label: Text('Largest')),
                  ],
                  selected: {prefs.fontSize},
                  onSelectionChanged: (s) => prefs.updateFontSize(s.first),
                ),
                const SizedBox(height: 10),
                Text('The quick brown fox priced its eggs at equilibrium.', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 32),
                const NoteHeading('Motion'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reduce motion'),
                  subtitle: const Text('Turn off animations and transitions'),
                  value: prefs.reduceMotion,
                  onChanged: prefs.updateReduceMotion,
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

/// A little preview of the page in each theme.
class _Swatch extends StatelessWidget {
  final String label;
  final bool? light; // null = split (system)
  final bool selected;
  final VoidCallback onTap;
  const _Swatch({required this.label, required this.light, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const paper = AppTheme.paper, board = AppTheme.board;
    final fill = light == null
        ? BoxDecoration(gradient: LinearGradient(colors: [paper, paper, board, board], stops: const [0, 0.5, 0.5, 1]))
        : BoxDecoration(color: light! ? paper : board);
    return InkWell(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 120,
          height: 80,
          decoration: fill.copyWith(
            border: Border.all(color: selected ? NotebookColors.of(context).annotation : theme.colorScheme.outline, width: selected ? 3 : 1),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const SupplyDemandSketch(size: 54, labels: false),
        ),
        const SizedBox(height: 6),
        selected ? Highlight(label, style: theme.textTheme.labelLarge) : Text(label, style: theme.textTheme.labelLarge),
      ]),
    );
  }
}

