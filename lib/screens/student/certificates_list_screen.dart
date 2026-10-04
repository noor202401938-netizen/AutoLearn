import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/api_client.dart';
import '../../model/certificate_model.dart';
import '../../repository/certificate_repository.dart';
import '../../widgets/notebook/notebook.dart';
import 'certificate_screen.dart';

/// Certificates you've earned, pinned up like awards on a corkboard.
class CertificatesListScreen extends StatefulWidget {
  final bool embedded;
  const CertificatesListScreen({super.key, this.embedded = false});

  @override
  State<CertificatesListScreen> createState() => _CertificatesListScreenState();
}

class _CertificatesListScreenState extends State<CertificatesListScreen> {
  final _repo = CertificateRepository();
  List<CertificateModel>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await _repo.list();
      if (mounted) setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_error != null) {
      content = NotebookError(message: _error!, onRetry: _load);
    } else if (_items == null) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      final theme = Theme.of(context);
      final nb = NotebookColors.of(context);
      content = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), children: [
          Text('Certificates', style: theme.textTheme.displaySmall),
          const MarginNote('finish a course to earn one'),
          const SizedBox(height: 24),
          if (_items!.isEmpty)
            const NotebookEmpty(
              title: 'No certificates yet',
              note: 'complete every lesson or pass a final test',
            ),
          Wrap(spacing: 20, runSpacing: 20, children: [
            for (final c in _items!)
              SizedBox(
                width: 320,
                child: NoteCard(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CertificateScreen(certificate: c))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.workspace_premium_outlined, color: nb.annotation, size: 28),
                      const Spacer(),
                      Text(DateFormat('d MMM yyyy').format(c.completionDate), style: NotebookColors.figures(size: 12)),
                    ]),
                    const SizedBox(height: 12),
                    Text(c.courseName, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    MarginNote('awarded to ${c.userName}', size: 18, tilt: 0),
                  ]),
                ),
              ),
          ]),
        ]),
      );
    }
    return widget.embedded ? content : NotebookPage(title: 'Certificates', body: content);
  }
}
