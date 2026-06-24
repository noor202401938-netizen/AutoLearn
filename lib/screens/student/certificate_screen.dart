// lib/screens/student/certificate_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../model/certificate_model.dart';
import '../../utils/certificate_pdf_generator.dart';

class CertificateScreen extends StatefulWidget {
  final CertificateModel certificate;

  const CertificateScreen({
    super.key,
    required this.certificate,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final CertificatePdfGenerator _pdfGenerator = CertificatePdfGenerator();
  bool _isGeneratingPdf = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Certificate of Completion', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _isGeneratingPdf ? null : () => _downloadCertificate(context),
            tooltip: 'Download Certificate',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _isGeneratingPdf ? null : () => _shareCertificate(context),
            tooltip: 'Share Certificate',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4231C0), Color(0xFF6B38D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildCertificate(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCertificate(BuildContext context) {
    // Format date
    String formattedDate;
    try {
      final dateFormat = DateFormat('dd MMMM yyyy');
      formattedDate = dateFormat.format(widget.certificate.completionDate);
    } catch (e) {
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final date = widget.certificate.completionDate;
      formattedDate = '${date.day} ${months[date.month - 1]} ${date.year}';
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 900),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFF), // Slight off-white for premium feel
        borderRadius: BorderRadius.circular(16), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFC8C4D7).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Decorative corner elements
          Positioned(
            top: 0,
            right: 0,
            child: _buildCornerDecoration(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Transform.rotate(
              angle: 3.14159, // 180 degrees
              child: _buildCornerDecoration(),
            ),
          ),
          
          // Main content
          Padding(
            padding: const EdgeInsets.all(60.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // CERTIFICATE title
                const Text(
                  'CERTIFICATE',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                
                // OF COMPLETION
                const Text(
                  'OF COMPLETION',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // IS PRESENTED TO
                const Text(
                  'IS PRESENTED TO :',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Name with lines
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 400,
                      height: 1,
                      color: Colors.black,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.white,
                      child: Text(
                        widget.certificate.userName,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary, // Primary color
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 400,
                  height: 1,
                  color: Colors.black,
                  margin: const EdgeInsets.only(top: 5),
                ),
                const SizedBox(height: 30),
                
                // Description text
                Text(
                  'For successfully completing the lesson "${widget.certificate.lessonName}" '
                  'in the course "${widget.certificate.courseName}". '
                  'Completed on $formattedDate.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                
                // Signatures section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Left signature
                    Column(
                      children: [
                        const Text(
                          'Instructor',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'GENERAL INSTRUCTOR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    
                    // Center seal
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD700), // Gold
                        border: Border.all(
                          color: const Color(0xFFFFA500),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '✓',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    // Right signature
                    Column(
                      children: [
                        const Text(
                          'Director',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'CREATIVE DIRECTOR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerDecoration() {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
          children: [
          // Large blue curve
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary, // Primary
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Small gray curve
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadCertificate(BuildContext context) async {
    setState(() => _isGeneratingPdf = true);
    
    try {
      final file = await _pdfGenerator.generatePdf(widget.certificate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificate downloaded to: ${file.path}'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading certificate: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Future<void> _shareCertificate(BuildContext context) async {
    setState(() => _isGeneratingPdf = true);
    
    try {
      await _pdfGenerator.sharePdf(widget.certificate);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing certificate: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }
}
