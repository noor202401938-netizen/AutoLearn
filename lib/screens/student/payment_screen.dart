import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../backend/api_client.dart';
import '../../widgets/notebook/notebook.dart';

/// Hands the student to Stripe Checkout. The server sets the price and the
/// Stripe webhook enrols them once the payment clears.
class PaymentScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final int amountCents;
  final String currency;
  const PaymentScreen({super.key, required this.courseId, required this.courseTitle, required this.amountCents, this.currency = 'USD'});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _busy = false;
  bool _opened = false;
  String? _error;

  Future<void> _pay() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await ApiClient.instance.json('POST', '/payments/checkout', body: {'courseId': widget.courseId});
      final url = Uri.parse(data['url'] as String);
      // Same tab on the web (Stripe sends them back to the app); browser on mobile.
      await launchUrl(url, webOnlyWindowName: kIsWeb ? '_self' : null, mode: LaunchMode.externalApplication);
      if (mounted) {
        setState(() {
          _busy = false;
          _opened = true;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NotebookPage(
      title: 'Enrol',
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: NoteCard(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(widget.courseTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 12),
                Row(children: [
                  Text('Total', style: theme.textTheme.bodyLarge),
                  const Spacer(),
                  Text('${widget.currency} ${(widget.amountCents / 100).toStringAsFixed(2)}',
                      style: NotebookColors.figures(size: 22, weight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                ]),
                const SizedBox(height: 6),
                const MarginNote('one payment, yours to keep', tilt: 0, size: 18),
                const SizedBox(height: 24),
                if (_opened) ...[
                  Text('Finish paying in the Stripe window. Your enrolment appears as soon as the payment clears.',
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: () => Navigator.pop(context, true), child: const Text("I've paid — back to the course")),
                ] else
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _pay,
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: const Text('Pay securely with Stripe'),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
