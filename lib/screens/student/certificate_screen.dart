import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/certificate_model.dart';
import '../../utils/certificate_pdf_generator.dart';
import '../../widgets/notebook/notebook.dart';

/// The certificate as it will print: double-ruled border, serif type, a red
/// seal. Download / print produce the same design as a PDF.
class CertificateScreen extends StatefulWidget {
  final CertificateModel certificate;
  const CertificateScreen({super.key, required this.certificate});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final _pdf = CertificatePdfGenerator();
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Exception catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't create the PDF: $e")));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.certificate;
    return NotebookPage(
      title: 'Certificate',
      actions: [
        IconButton(tooltip: 'Print', onPressed: _busy ? null : () => _run(() => _pdf.print(c)), icon: const Icon(Icons.print_outlined)),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            onPressed: _busy ? null : () => _run(() => _pdf.share(c)),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download PDF'),
          ),
        ),
      ],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: AspectRatio(aspectRatio: 1.414, child: _Certificate(c)),
          ),
        ),
      ),
    );
  }
}

class _Certificate extends StatelessWidget {
  final CertificateModel c;
  const _Certificate(this.c);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final ink = theme.colorScheme.onSurface;
    return LayoutBuilder(builder: (context, box) {
      final s = box.maxWidth / 900; // scale type with the page
      TextStyle serif(double size, {FontWeight w = FontWeight.w600, bool italic = false}) =>
          theme.textTheme.displayLarge!.copyWith(fontSize: size * s, fontWeight: w, fontStyle: italic ? FontStyle.italic : null, color: ink, height: 1.15);
      return NoteCard(
        padding: EdgeInsets.all(10 * s),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: ink, width: 2)),
          padding: EdgeInsets.all(6 * s),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: ink, width: 0.6)),
            padding: EdgeInsets.symmetric(horizontal: 60 * s, vertical: 36 * s),
            child: Column(children: [
              Text('AUTOLEARN', style: theme.textTheme.labelLarge?.copyWith(fontSize: 14 * s, letterSpacing: 4 * s, color: ink)),
              SizedBox(height: 20 * s),
              Text('Certificate of Completion', style: serif(44), textAlign: TextAlign.center),
              SizedBox(height: 24 * s),
              Text('This certifies that', style: serif(18, w: FontWeight.w400, italic: true)),
              SizedBox(height: 8 * s),
              Text(c.userName, style: serif(38), textAlign: TextAlign.center),
              Container(width: 340 * s, height: 1.5, color: nb.annotation, margin: EdgeInsets.only(top: 6 * s, bottom: 16 * s)),
              Text('has completed the course', style: serif(18, w: FontWeight.w400, italic: true)),
              SizedBox(height: 8 * s),
              Text(c.courseName, style: serif(26, w: FontWeight.w500), textAlign: TextAlign.center),
              const Spacer(),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(DateFormat('d MMMM yyyy').format(c.completionDate), style: serif(15, w: FontWeight.w500)),
                    Text('Date awarded', style: serif(12, w: FontWeight.w400, italic: true)),
                  ]),
                ),
                Container(
                  width: 80 * s,
                  height: 80 * s,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: nb.annotation, width: 2)),
                  child: NotebookMark(size: 52 * s),
                ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(c.certificateId, style: NotebookColors.figures(size: 11 * s, color: ink)),
                    Text('Certificate ID', style: serif(12, w: FontWeight.w400, italic: true)),
                  ]),
                ),
              ]),
            ]),
          ),
        ),
      );
    });
  }
}
