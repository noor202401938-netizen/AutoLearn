// lib/screens/student/certificates_list_screen.dart
import 'package:flutter/material.dart';
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
    setState(() => _isLoading = true);
    try {
      final user = null /* was FirebaseAuth.instance.currentUser */;
      if (user != null) {
        final certificates = await _certificateRepository.getUserCertificates(user.uid);
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _certificates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.workspace_premium_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Certificates Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete lessons to earn certificates',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCertificates,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _certificates.length,
                    itemBuilder: (context, index) {
                      final certificate = _certificates[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4169E1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.workspace_premium,
                              color: Color(0xFF4169E1),
                              size: 28,
                            ),
                          ),
                          title: Text(
                            certificate.courseName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                certificate.lessonName,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Completed: ${_formatDate(certificate.completionDate)}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CertificateScreen(
                                  certificate: certificate,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}


