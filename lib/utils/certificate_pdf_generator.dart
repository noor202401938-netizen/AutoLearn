import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../model/certificate_model.dart';

// Print colours mirror the app's paper & ink palette.
final _ink = PdfColor.fromHex('#1D3557');
final _paper = PdfColor.fromHex('#FFFCF4');
final _red = PdfColor.fromHex('#C8553D');

class CertificatePdfGenerator {
  /// A landscape A4 certificate as PDF bytes.
  Future<Uint8List> build(CertificateModel c) async {
    final doc = pw.Document(title: 'Certificate — ${c.courseName}', author: 'AutoLearn');
    final serif = pw.Font.times();
    final serifBold = pw.Font.timesBold();
    final serifItalic = pw.Font.timesItalic();

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => pw.Container(
        color: _paper,
        padding: const pw.EdgeInsets.all(10),
        child: pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(color: _ink, width: 2)),
          padding: const pw.EdgeInsets.all(6),
          child: pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(color: _ink, width: 0.6)),
            padding: const pw.EdgeInsets.symmetric(horizontal: 60, vertical: 40),
            child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
              pw.Text('AUTOLEARN', style: pw.TextStyle(font: serifBold, fontSize: 12, letterSpacing: 4, color: _ink)),
              pw.SizedBox(height: 24),
              pw.Text('Certificate of Completion', style: pw.TextStyle(font: serifBold, fontSize: 40, color: _ink)),
              pw.SizedBox(height: 28),
              pw.Text('This certifies that', style: pw.TextStyle(font: serifItalic, fontSize: 16, color: _ink)),
              pw.SizedBox(height: 10),
              pw.Text(c.userName, style: pw.TextStyle(font: serifBold, fontSize: 34, color: _ink)),
              pw.Container(width: 320, height: 1, color: _red, margin: const pw.EdgeInsets.only(top: 6, bottom: 18)),
              pw.Text('has completed the course', style: pw.TextStyle(font: serifItalic, fontSize: 16, color: _ink)),
              pw.SizedBox(height: 10),
              pw.Text(c.courseName, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: serif, fontSize: 24, color: _ink)),
              pw.Spacer(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(DateFormat('d MMMM yyyy').format(c.completionDate), style: pw.TextStyle(font: serif, fontSize: 13, color: _ink)),
                  pw.Text('Date awarded', style: pw.TextStyle(font: serifItalic, fontSize: 10, color: _ink)),
                ]),
                // A small red seal.
                pw.Container(
                  width: 70,
                  height: 70,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: _red, width: 2)),
                  child: pw.Text('A', style: pw.TextStyle(font: serifBold, fontSize: 30, color: _red)),
                ),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text(c.certificateId, style: pw.TextStyle(font: pw.Font.courier(), fontSize: 9, color: _ink)),
                  pw.Text('Certificate ID', style: pw.TextStyle(font: serifItalic, fontSize: 10, color: _ink)),
                ]),
              ]),
            ]),
          ),
        ),
      ),
    ));
    return doc.save();
  }

  /// Downloads on the web; opens the share sheet on mobile/desktop.
  Future<void> share(CertificateModel c) async {
    final name = 'AutoLearn-certificate-${c.courseName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}.pdf';
    await Printing.sharePdf(bytes: await build(c), filename: name);
  }

  Future<void> print(CertificateModel c) => Printing.layoutPdf(onLayout: (_) => build(c));
}
