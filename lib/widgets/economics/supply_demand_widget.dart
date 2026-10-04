// lib/widgets/economics/supply_demand_widget.dart
import 'package:flutter/material.dart';
import '../notebook/notebook.dart';

/// Linear market used by the lab (price and quantity on a 0–100 scale):
///   demand  P = 100 + d − 0.8·Q        (d > 0: demand increases)
///   supply  P =  20 − s + 0.8·Q        (s > 0: supply increases)
/// Returns the equilibrium (quantity, price).
(double, double) equilibrium(double d, double s) {
  final q = (80 + d + s) / 1.6;
  return (q, 100 + d - 0.8 * q);
}

/// Plain-English reading of a shock, e.g. "demand rose → price ↑, quantity ↑".
String explainShift(double d, double s) {
  if (d == 0 && s == 0) return 'move a slider to shock the market';
  final (q0, p0) = equilibrium(0, 0);
  final (q1, p1) = equilibrium(d, s);
  String arrow(double a, double b) => (b - a).abs() < 0.05 ? '–' : (b > a ? '↑' : '↓');
  final causes = [
    if (d != 0) 'demand ${d > 0 ? 'rose' : 'fell'}',
    if (s != 0) 'supply ${s > 0 ? 'rose' : 'fell'}',
  ].join(' & ');
  return '$causes → price ${arrow(p0, p1)}, quantity ${arrow(q0, q1)}';
}

class _Scenario {
  final String label;
  final double demand, supply;
  const _Scenario(this.label, this.demand, this.supply);
}

const _scenarios = [
  _Scenario('A drought hits the harvest', 0, -20),
  _Scenario('Incomes rise', 20, 0),
  _Scenario('New tech cuts costs', 0, 20),
  _Scenario('A cheaper substitute appears', -20, 0),
  _Scenario('Boom: incomes up, costs up', 20, -20),
];

class SupplyDemandInteractiveWidget extends StatefulWidget {
  const SupplyDemandInteractiveWidget({super.key});

  @override
  State<SupplyDemandInteractiveWidget> createState() => _SupplyDemandInteractiveWidgetState();
}

class _SupplyDemandInteractiveWidgetState extends State<SupplyDemandInteractiveWidget> {
  double _d = 0;
  double _s = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final (q0, p0) = equilibrium(0, 0);
    final (q, p) = equilibrium(_d, _s);
    final supplyInk = theme.colorScheme.primary;
    final demandInk = nb.annotation;

    Widget readout(String label, double v, double base) {
      final delta = v - base;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: theme.textTheme.labelSmall),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(v.toStringAsFixed(1), style: NotebookColors.figures(size: 24, weight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(width: 6),
          if (delta.abs() >= 0.05)
            Text('${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}', style: NotebookColors.figures(size: 13, color: delta > 0 ? nb.correct : nb.annotation)),
        ]),
      ]);
    }

    Widget slider(String label, Color color, double value, ValueChanged<double> onChanged) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.titleSmall?.copyWith(color: color)),
            Row(children: [
              Text('decrease', style: theme.textTheme.bodySmall),
              Expanded(
                child: Slider(
                  value: value,
                  min: -30,
                  max: 30,
                  divisions: 12,
                  activeColor: color,
                  label: value == 0 ? 'no change' : '${value > 0 ? '+' : ''}${value.toInt()}',
                  onChanged: onChanged,
                ),
              ),
              Text('increase', style: theme.textTheme.bodySmall),
            ]),
          ],
        );

    return NoteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Market equilibrium lab', style: theme.textTheme.titleLarge),
        Text('Shift supply and demand and watch where the market settles.', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final sc in _scenarios)
            ActionChip(
              label: Text(sc.label),
              onPressed: () => setState(() {
                _d = sc.demand;
                _s = sc.supply;
              }),
            ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: readout('Equilibrium price (P*)', p, p0)),
          Expanded(child: readout('Equilibrium quantity (Q*)', q, q0)),
        ]),
        const SizedBox(height: 4),
        MarginNote(explainShift(_d, _s), size: 21, tilt: 0),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          width: double.infinity,
          child: Semantics(
            label: 'Supply and demand diagram. Equilibrium price ${p.toStringAsFixed(1)}, quantity ${q.toStringAsFixed(1)}.',
            child: CustomPaint(
              painter: _MarketPainter(
                d: _d,
                s: _s,
                axis: theme.colorScheme.onSurface,
                grid: nb.gridLine,
                supply: supplyInk,
                demand: demandInk,
                dot: nb.highlighter,
                hand: nb.hand(size: 18, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        slider('Demand', demandInk, _d, (v) => setState(() => _d = v)),
        slider('Supply', supplyInk, _s, (v) => setState(() => _s = v)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() {
              _d = 0;
              _s = 0;
            }),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reset market'),
          ),
        ),
      ]),
    );
  }
}

class _MarketPainter extends CustomPainter {
  final double d, s;
  final Color axis, grid, supply, demand, dot;
  final TextStyle hand;
  _MarketPainter({
    required this.d,
    required this.s,
    required this.axis,
    required this.grid,
    required this.supply,
    required this.demand,
    required this.dot,
    required this.hand,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 30.0;
    final w = size.width - pad * 2, h = size.height - pad * 2;
    Offset at(double q, double p) => Offset(pad + q / 100 * w, size.height - pad - p / 100 * h);

    // Graph-paper plot area.
    final gridPaint = Paint()..color = grid..strokeWidth = 0.6;
    for (var i = 0; i <= 10; i++) {
      canvas.drawLine(at(i * 10, 0), at(i * 10, 100), gridPaint);
      canvas.drawLine(at(0, i * 10), at(100, i * 10), gridPaint);
    }
    final axisPaint = Paint()..color = axis..strokeWidth = 1.6;
    canvas.drawLine(at(0, 0), at(0, 100), axisPaint);
    canvas.drawLine(at(0, 0), at(100, 0), axisPaint);

    void label(String t, Offset o, [Color? c]) {
      final tp = TextPainter(text: TextSpan(text: t, style: hand.copyWith(color: c)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, o);
    }

    label('P', at(0, 100) + const Offset(-22, -6), axis);
    label('Q', at(100, 0) + const Offset(-4, 4), axis);

    double demandP(double dd, double q) => 100 + dd - 0.8 * q;
    double supplyP(double ss, double q) => 20 - ss + 0.8 * q;

    void line(double Function(double q) price, Paint paint, {bool dashed = false}) {
      // Clip the line to the visible 0..100 price range.
      final pts = [for (var q = 5.0; q <= 95; q += 1) at(q, price(q).clamp(0, 100).toDouble())];
      if (!dashed) {
        canvas.drawPath(Path()..addPolygon(pts, false), paint..style = PaintingStyle.stroke);
        return;
      }
      for (var i = 0; i + 2 < pts.length; i += 4) {
        canvas.drawLine(pts[i], pts[i + 2], paint);
      }
    }

    final shifted = d != 0 || s != 0;
    final faint = Paint()..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    if (shifted) {
      if (d != 0) line((q) => demandP(0, q), faint..color = demand.withValues(alpha: 0.45), dashed: true);
      if (s != 0) line((q) => supplyP(0, q), Paint()..color = supply.withValues(alpha: 0.45)..strokeWidth = 1.5, dashed: true);
    }
    final bold = Paint()..strokeWidth = 3..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    line((q) => demandP(d, q), bold..color = demand);
    line((q) => supplyP(s, q), Paint()..color = supply..strokeWidth = 3..strokeCap = StrokeCap.round);
    label(d == 0 ? 'D' : 'D₁', at(92, demandP(d, 92).clamp(0, 100).toDouble()) + const Offset(4, -6), demand);
    label(s == 0 ? 'S' : 'S₁', at(92, supplyP(s, 92).clamp(0, 100).toDouble()) + const Offset(4, -18), supply);

    // Old equilibrium (hollow) and new equilibrium (highlighted) with guides.
    final (q0, p0) = equilibrium(0, 0);
    final (q1, p1) = equilibrium(d, s);
    final guide = Paint()..color = axis.withValues(alpha: 0.5)..strokeWidth = 1;
    void dashTo(Offset a, Offset b) {
      final n = ((b - a).distance / 6).floor();
      for (var i = 0; i < n; i += 2) {
        canvas.drawLine(Offset.lerp(a, b, i / n)!, Offset.lerp(a, b, (i + 1) / n)!, guide);
      }
    }

    final e1 = at(q1, p1);
    dashTo(e1, at(q1, 0));
    dashTo(e1, at(0, p1));
    if (shifted) {
      canvas.drawCircle(at(q0, p0), 5, Paint()..color = axis.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      label('E₀', at(q0, p0) + const Offset(6, 2), axis.withValues(alpha: 0.7));
    }
    canvas.drawCircle(e1, 7, Paint()..color = dot);
    canvas.drawCircle(e1, 7, Paint()..color = axis..style = PaintingStyle.stroke..strokeWidth = 1.5);
    label(shifted ? 'E₁' : 'E', e1 + const Offset(8, -22), axis);
  }

  @override
  bool shouldRepaint(_MarketPainter old) =>
      old.d != d || old.s != s || old.axis != axis || old.supply != supply || old.demand != demand;
}
