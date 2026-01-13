import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  Future<void> generateAndPrintEstimate(Map<String, dynamic> data, String? base64Image) async {
    final pdf = pw.Document();
    final date = DateFormat('MMM dd, yyyy').format(DateTime.now());

    Uint8List? imageBytes;
    if (base64Image != null) {
      imageBytes = base64Decode(base64Image.split(',').last);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('RAP ESTIMATE REPORT', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Text(date),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              if (imageBytes != null)
                pw.Center(
                  child: pw.Container(
                    height: 200,
                    child: pw.Image(pw.MemoryImage(imageBytes)),
                  ),
                ),
              pw.SizedBox(height: 20),
              _sectionHeader('Item Summary'),
              pw.Text(data['item_summary']),
              pw.SizedBox(height: 10),
              _sectionHeader('Location'),
              pw.Text(data['location']),
              pw.SizedBox(height: 20),
              _sectionHeader('Cost Breakdown'),
              _costRow('Standard Labor', '\$${data['labor_cost_original_usd']}'),
              _costRow('Labor Discount (20%)', '-\$${(double.parse(data['labor_cost_original_usd']) * 0.2).toStringAsFixed(2)}'),
              _costRow('Final Labor Cost', '\$${data['labor_cost_final_usd']}', isBold: true),
              pw.Divider(),
              _costRow('Material Cost', '\$${data['material_cost_total_usd']}'),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                color: PdfColors.blue50,
                child: pw.Column(
                  children: [
                    _costRow('Total Likely Estimate', '\$${data['total_estimate_range_usd']['likely']}', isBold: true),
                    pw.Text('Range: \$${data['total_estimate_range_usd']['low']} - \$${data['total_estimate_range_usd']['high']}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Center(child: pw.Text('RAP - Smart Repair & Build Cost Estimates', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 8))),
              pw.Center(child: pw.Text(data['disclaimer'], style: pw.TextStyle(color: PdfColors.grey600, fontSize: 6), textAlign: pw.TextAlign.center)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
    );
  }

  pw.Widget _costRow(String label, String value, {bool isBold = false}) {
    final style = pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label, style: style), pw.Text(value, style: style)],
      ),
    );
  }
}
