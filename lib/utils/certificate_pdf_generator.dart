// lib/utils/certificate_pdf_generator.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../model/certificate_model.dart';

class CertificatePdfGenerator {
  Future<File> generatePdf(CertificateModel certificate) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMMM yyyy');
    final formattedDate = dateFormat.format(certificate.completionDate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Stack(
              children: [
                // Decorative corner elements
                pw.Positioned(
                  top: 0,
                  right: 0,
                  child: _buildCornerDecoration(),
                ),
                pw.Positioned(
                  bottom: 0,
                  left: 0,
                  child: pw.Transform.rotate(
                    angle: 3.14159, // 180 degrees
                    child: _buildCornerDecoration(),
                  ),
                ),
                
                // Main content
                pw.Padding(
                  padding: const pw.EdgeInsets.all(60),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // CERTIFICATE title
                      pw.Text(
                        'CERTIFICATE',
                        style: pw.TextStyle(
                          fontSize: 48,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 10),
                      
                      // OF COMPLETION
                      pw.Text(
                        'OF COMPLETION',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.normal,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 40),
                      
                      // IS PRESENTED TO
                      pw.Text(
                        'IS PRESENTED TO :',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.normal,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 20),
                      
                      // Name with lines
                      pw.Stack(
                        alignment: pw.Alignment.center,
                        children: [
                          pw.Container(
                            width: 400,
                            height: 1,
                            color: PdfColors.black,
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                            ),
                            child: pw.Text(
                              certificate.userName,
                              style: pw.TextStyle(
                                fontSize: 32,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#1E3A8A'), // Dark blue
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        width: 400,
                        height: 1,
                        color: PdfColors.black,
                        margin: const pw.EdgeInsets.only(top: 5),
                      ),
                      pw.SizedBox(height: 30),
                      
                      // Description text
                      pw.Text(
                        'For successfully completing the lesson "${certificate.lessonName}" '
                        'in the course "${certificate.courseName}". '
                        'Completed on $formattedDate.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 60),
                      
                      // Signatures section
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: [
                          // Left signature
                          pw.Column(
                            children: [
                              pw.Text(
                                'Instructor',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                              pw.SizedBox(height: 40),
                              pw.Text(
                                'GENERAL INSTRUCTOR',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.normal,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                          
                          // Center seal
                          pw.Container(
                            width: 80,
                            height: 80,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              color: PdfColor.fromHex('#FFD700'), // Gold
                              border: pw.Border.all(
                                color: PdfColor.fromHex('#FFA500'),
                                width: 2,
                              ),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                '✓',
                                style: pw.TextStyle(
                                  fontSize: 40,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                          ),
                          
                          // Right signature
                          pw.Column(
                            children: [
                              pw.Text(
                                'Director',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                              pw.SizedBox(height: 40),
                              pw.Text(
                                'CREATIVE DIRECTOR',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.normal,
                                  color: PdfColors.grey700,
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
        },
      ),
    );

    // Save PDF to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'certificate_${certificate.certificateId.substring(0, 8)}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  pw.Widget _buildCornerDecoration() {
    return pw.Container(
      width: 150,
      height: 150,
      child: pw.Stack(
        children: [
          // Large blue curve
          pw.Positioned(
            top: 0,
            right: 0,
            child: pw.Container(
              width: 120,
              height: 120,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#4169E1'), // Blue
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          // Small gray curve
          pw.Positioned(
            top: 20,
            right: 20,
            child: pw.Container(
              width: 100,
              height: 100,
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> printPdf(CertificateModel certificate) async {
    final pdf = await generatePdf(certificate);
    final bytes = await pdf.readAsBytes();
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
    );
  }

  Future<void> sharePdf(CertificateModel certificate) async {
    final pdf = await generatePdf(certificate);
    final bytes = await pdf.readAsBytes();
    
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'certificate_${certificate.certificateId.substring(0, 8)}.pdf',
    );
  }
}

