import 'package:flutter/material.dart';
import '../../utils/preference_notifier.dart';
import 'notebook.dart';

class ShellSection {
  final String label;
  final IconData icon;
  const ShellSection(this.label, this.icon);
}

/// App frame shared by students and admins. Wide screens get ring-binder
/// section tabs down the left; phones get a bottom bar with the first few
/// sections plus "More".
class NotebookShell extends StatelessWidget {
  final List<ShellSection> sections;
  final int index;
  final ValueChanged<int> onSelect;
  final Widget page;
  final String tagline;

  /// Sections shown directly in the phone's bottom bar.
  final List<int> mobileTabs;

  const NotebookShell({
    super.key,
    required this.sections,
    required this.index,
    required this.onSelect,
    required this.page,
    required this.tagline,
    required this.mobileTabs,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 840;
    final content = Stack(children: [
      const GraphPaper(),
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SafeArea(child: KeyedSubtree(key: ValueKey(index), child: page)),
        ),
      ),
    ]);

    if (wide) {
      return Scaffold(
        body: Row(children: [
          _SectionTabs(sections: sections, selected: index, onSelect: onSelect, tagline: tagline),
          Expanded(child: content),
        ]),
      );
    }

    final nb = NotebookColors.of(context);
    final tab = mobileTabs.indexOf(index);
    return Scaffold(
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab == -1 ? mobileTabs.length : tab,
        backgroundColor: nb.sheet,
        indicatorColor: nb.highlighter.withValues(alpha: 0.6),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => i < mobileTabs.length ? onSelect(mobileTabs[i]) : _showMore(context),
        destinations: [
          for (final i in mobileTabs) NavigationDestination(icon: Icon(sections[i].icon), label: sections[i].label),
          const NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NotebookColors.of(context).sheet,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < sections.length; i++)
              if (!mobileTabs.contains(i))
                ListTile(
                  leading: Icon(sections[i].icon),
                  title: Text(sections[i].label),
                  selected: index == i,
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelect(i);
                  },
                ),
            const ThemeToggle(asListTile: true),
          ]),
        ),
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  final List<ShellSection> sections;
  final int selected;
  final ValueChanged<int> onSelect;
  final String tagline;
  const _SectionTabs({required this.sections, required this.selected, required this.onSelect, required this.tagline});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: nb.sheet,
        border: Border(right: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.8), width: 1.25)),
      ),
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(children: [
              const SupplyDemandSketch(size: 36, labels: false),
              const SizedBox(width: 10),
              Text('AutoLearn', style: theme.textTheme.headlineSmall),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(66, 0, 20, 20), child: MarginNote(tagline, size: 16)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [for (var i = 0; i < sections.length; i++) _tab(context, i)],
            ),
          ),
          const Divider(),
          const ThemeToggle(),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _tab(BuildContext context, int i) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final active = i == selected;
    final s = sections[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () => onSelect(i),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(children: [
            SizedBox(width: 14, child: active ? Text('✓', style: nb.hand(size: 20)) : null),
            Icon(s.icon, size: 20, color: active ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            active
                ? Highlight(s.label, style: theme.textTheme.titleSmall)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(s.label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface)),
                  ),
          ]),
        ),
      ),
    );
  }
}

/// Paper <-> blackboard switch.
class ThemeToggle extends StatelessWidget {
  final bool asListTile;
  const ThemeToggle({super.key, this.asListTile = false});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final label = dark ? 'Switch to paper' : 'Switch to blackboard';
    void toggle() => PreferenceNotifier.instance.updateTheme(dark ? 'light' : 'dark');
    final icon = Icon(dark ? Icons.description_outlined : Icons.co_present_outlined);
    if (asListTile) return ListTile(leading: icon, title: Text(label), onTap: toggle);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton.icon(onPressed: toggle, icon: icon, label: Text(label)),
    );
  }
}
