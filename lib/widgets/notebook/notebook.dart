// Lecture-notebook building blocks shared by every screen.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
export '../../theme/app_theme.dart' show NotebookColors;

/// Graph-paper page: faint grid, a heavier line every 5 squares, and an
/// optional red margin rule on the left. Fills its parent.
class GraphPaper extends StatelessWidget {
  final double cell;
  final double? marginAt;
  const GraphPaper({super.key, this.cell = 24, this.marginAt});

  @override
  Widget build(BuildContext context) {
    final nb = NotebookColors.of(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: CustomPaint(painter: _GridPainter(nb.gridLine, nb.marginLine, cell, marginAt)),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color line, margin;
  final double cell;
  final double? marginAt;
  _GridPainter(this.line, this.margin, this.cell, this.marginAt);

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()..color = line..strokeWidth = 0.6;
    final thick = Paint()..color = line..strokeWidth = 1.2;
    var i = 0;
    for (double x = 0; x <= size.width; x += cell, i++) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), i % 5 == 0 ? thick : thin);
    }
    i = 0;
    for (double y = 0; y <= size.height; y += cell, i++) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), i % 5 == 0 ? thick : thin);
    }
    if (marginAt != null) {
      final m = Paint()..color = margin.withValues(alpha: 0.55)..strokeWidth = 1.5;
      canvas.drawLine(Offset(marginAt!, 0), Offset(marginAt!, size.height), m);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.line != line || old.margin != margin || old.cell != cell || old.marginAt != marginAt;
}

/// A sheet of paper sitting on the page: flat fill, ink hairline, and a hard
/// offset shadow like a stack of index cards. Lifts slightly on hover.
class NoteCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  const NoteCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(20), this.color});

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final nb = NotebookColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lifted = _hover && widget.onTap != null;
    final offset = lifted ? 6.0 : 3.0;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(lifted ? -2 : 0, lifted ? -2 : 0, 0),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color ?? nb.sheet,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.8), width: 1.25),
        boxShadow: [BoxShadow(color: nb.stackShadow, offset: Offset(offset, offset))],
      ),
      child: widget.child,
    );
    if (widget.onTap == null) return card;
    // Exposed as a focusable button so screen readers and keyboards can use it
    // (Enter/Space activate it; focus lifts it like hover).
    return Semantics(
      button: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _hover = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap!())},
        child: GestureDetector(onTap: widget.onTap, behavior: HitTestBehavior.opaque, child: card),
      ),
    );
  }
}

/// Text with a highlighter stroke behind it.
class Highlight extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const Highlight(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final nb = NotebookColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _MarkerPainter(nb.highlighter.withValues(alpha: dark ? 0.28 : 0.75)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(text, style: style),
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  final Color color;
  _MarkerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Slightly uneven band covering the lower ~60% of the line, like a real marker swipe.
    final top = size.height * 0.38;
    final path = Path()
      ..moveTo(0, top + 2)
      ..lineTo(size.width, top)
      ..lineTo(size.width - 2, size.height - 1)
      ..lineTo(2, size.height + 1)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => old.color != color;
}

/// Handwritten note in the margin, tilted a touch.
class MarginNote extends StatelessWidget {
  final String text;
  final double size;
  final double tilt;
  final Color? color;
  const MarginNote(this.text, {super.key, this.size = 20, this.tilt = -0.03, this.color});

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: tilt,
        alignment: Alignment.centerLeft,
        child: Text(text, style: NotebookColors.of(context).hand(size: size, color: color)),
      );
}

/// Section heading with a pen-drawn underline, like a notebook header.
class NoteHeading extends StatelessWidget {
  final String text;
  final String? note;
  final Widget? trailing;
  const NoteHeading(this.text, {super.key, this.note, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 2),
            CustomPaint(size: const Size(72, 6), painter: _ScribblePainter(nb.annotation)),
          ],
        ),
        if (note != null) ...[
          const SizedBox(width: 12),
          Padding(padding: const EdgeInsets.only(bottom: 6), child: MarginNote(note!, size: 18)),
        ],
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ScribblePainter extends CustomPainter {
  final Color color;
  _ScribblePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.1, size.width * 0.55, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.9, size.width, size.height * 0.3);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ScribblePainter old) => old.color != color;
}

/// The app's mark: a hand-drawn open notebook with ruled lines, one line
/// highlighted and a red-pen tick. Also the empty-state illustration.
class NotebookMark extends StatelessWidget {
  final double size;
  const NotebookMark({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nb = NotebookColors.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MarkPainter(ink: scheme.onSurface, page: nb.sheet, pen: nb.annotation, marker: nb.highlighter),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  final Color ink, page, pen, marker;
  _MarkPainter({required this.ink, required this.page, required this.pen, required this.marker});

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(1.5, w / 55)
      ..color = ink;

    // Two pages curving away from the spine.
    Path pageShape(double side) => Path()
      ..moveTo(0.5 * w, 0.26 * h)
      ..quadraticBezierTo((0.5 + side * 0.2) * w, 0.16 * h, (0.5 + side * 0.42) * w, 0.22 * h)
      ..lineTo((0.5 + side * 0.42) * w, 0.78 * h)
      ..quadraticBezierTo((0.5 + side * 0.2) * w, 0.72 * h, 0.5 * w, 0.84 * h)
      ..close();
    for (final side in [-1.0, 1.0]) {
      final shape = pageShape(side);
      canvas.drawPath(shape, Paint()..color = page);
      canvas.drawPath(shape, stroke);
    }

    // Highlighter swipe, then ruled lines on the left page.
    canvas.drawRect(Rect.fromPoints(p(0.17, 0.44), p(0.42, 0.52)), Paint()..color = marker.withValues(alpha: 0.8));
    final rule = Paint()
      ..color = ink.withValues(alpha: 0.55)
      ..strokeWidth = math.max(1, w / 90)
      ..strokeCap = StrokeCap.round;
    for (final y in [0.36, 0.49, 0.62]) {
      canvas.drawLine(p(0.18, y), p(0.42, y + 0.01), rule);
    }
    // Right page: two lines and a tick in red pen.
    for (final y in [0.36, 0.49]) {
      canvas.drawLine(p(0.58, y + 0.01), p(0.82, y), rule);
    }
    final tick = Path()
      ..moveTo(0.6 * w, 0.62 * h)
      ..lineTo(0.66 * w, 0.68 * h)
      ..lineTo(0.8 * w, 0.54 * h);
    canvas.drawPath(tick, stroke..color = pen);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.ink != ink || old.page != page || old.pen != pen || old.marker != marker;
}

/// Empty state: the mark, a handwritten line, and an optional action.
class NotebookEmpty extends StatelessWidget {
  final String title;
  final String note;
  final String? actionLabel;
  final VoidCallback? onAction;
  const NotebookEmpty({super.key, required this.title, required this.note, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NotebookMark(size: 110),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            MarginNote(note, tilt: 0, size: 19),
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with a retry — never fall back to fake data.
class NotebookError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const NotebookError({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => NotebookEmpty(
        title: message,
        note: 'check your connection and try again',
        actionLabel: 'Retry',
        onAction: onRetry,
      );
}

/// Page scaffold for full-screen (pushed) notebook pages: graph paper behind
/// an ink app bar. Embedded tabs should just use their content directly.
class NotebookPage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  const NotebookPage({super.key, required this.title, required this.body, this.actions, this.floatingActionButton});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), actions: actions, backgroundColor: Colors.transparent),
        extendBodyBehindAppBar: false,
        floatingActionButton: floatingActionButton,
        body: Stack(children: [const GraphPaper(), body]),
      );
}

/// Renders the small slice of markdown that lessons and tutor replies use:
/// paragraphs, `#` headings, `-`/`1.` lists, **bold** and *italic*.
// ponytail: hand-rolled subset; swap for a markdown package if lessons need tables/links.
class NoteText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const NoteText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = style ?? theme.textTheme.bodyLarge!;
    final blocks = <Widget>[];
    for (final raw in text.trim().split(RegExp(r'\n\s*\n'))) {
      final lines = raw.split('\n');
      final heading = RegExp(r'^(#{1,3})\s+(.*)').firstMatch(lines.first.trim());
      if (lines.length == 1 && heading != null) {
        blocks.add(Text(heading.group(2)!, style: heading.group(1)!.length == 1 ? theme.textTheme.headlineSmall : theme.textTheme.titleLarge));
        continue;
      }
      final listItem = RegExp(r'^\s*(?:[-*•]|(\d+)[.)])\s+(.*)');
      if (lines.every((l) => listItem.hasMatch(l) || l.trim().isEmpty)) {
        blocks.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final l in lines.where((l) => l.trim().isNotEmpty))
            Builder(builder: (_) {
              final m = listItem.firstMatch(l)!;
              return Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 24, child: Text(m.group(1) != null ? '${m.group(1)}.' : '•', style: base)),
                  Expanded(child: Text.rich(_inline(m.group(2)!, base))),
                ]),
              );
            }),
        ]));
        continue;
      }
      blocks.add(Text.rich(_inline(lines.map((l) => l.trim()).join(' '), base)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final b in blocks) Padding(padding: const EdgeInsets.only(bottom: 12), child: b)],
    );
  }

  static TextSpan _inline(String s, TextStyle base) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`');
    var i = 0;
    for (final m in re.allMatches(s)) {
      if (m.start > i) spans.add(TextSpan(text: s.substring(i, m.start)));
      if (m.group(1) != null) {
        spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else if (m.group(2) != null) {
        spans.add(TextSpan(text: m.group(2), style: const TextStyle(fontStyle: FontStyle.italic)));
      } else {
        spans.add(TextSpan(text: m.group(3), style: NotebookColors.figures(size: (base.fontSize ?? 14) - 1)));
      }
      i = m.end;
    }
    if (i < s.length) spans.add(TextSpan(text: s.substring(i)));
    return TextSpan(style: base, children: spans);
  }
}

/// "3d ago" style relative time for notes, posts, bookmarks.
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1) return '${d.inHours}h ago';
  if (d.inDays < 30) return '${d.inDays}d ago';
  return '${t.day}/${t.month}/${t.year}';
}
