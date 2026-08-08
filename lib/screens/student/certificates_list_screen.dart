import 'package:flutter/material.dart';
import '../../repository/auth_repository.dart';
import '../../repository/certificate_repository.dart';
import '../../model/certificate_model.dart';
import 'certificate_screen.dart';

class CertificatesListScreen extends StatefulWidget {
  const CertificatesListScreen({super.key});

  @override
  State<CertificatesListScreen> createState() => _CertificatesListScreenState();
}

class _CertificatesListScreenState extends State<CertificatesListScreen> {
  final CertificateRepository _certificateRepository = CertificateRepository();
  List<CertificateModel> _certificates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    final theme = Theme.of(context);
    setState(() => _isLoading = true);
    try {
      final user = await AuthRepository().getCurrentUser();
      final uid = user?['uid'] as String?;
      if (uid != null) {
        final certificates = await _certificateRepository.getUserCertificates(uid);
        setState(() {
          _certificates = certificates;
          _isLoading = false;
        });
      } else {
        setState(() {
          _certificates = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading certificates: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: theme.colorScheme.onSurfaceVariant),
            onPressed: () {},
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: RefreshIndicator(
                    onRefresh: _loadCertificates,
                    child: CustomScrollView(
                  slivers: [
                    _buildHeader(),
                    if (_certificates.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.workspace_premium_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text('No Certificates Yet', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('Complete lessons to earn certificates', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildCertificateCard(_certificates[index]),
                            childCount: _certificates.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 40,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.workspace_premium, color: theme.colorScheme.tertiary, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'My Achievements',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'View and share your earned certificates',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.onPrimary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: theme.colorScheme.tertiary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_certificates.length} Certificates Earned',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateCard(CertificateModel certificate) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.verified, color: theme.colorScheme.onSecondary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certificate.courseName,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completed: ${_formatDate(certificate.completionDate)}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Credential ID: ${certificate.certificateId.length >= 8 ? certificate.certificateId.substring(0, 8) : certificate.certificateId}...',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CertificateScreen(certificate: certificate),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }
}
