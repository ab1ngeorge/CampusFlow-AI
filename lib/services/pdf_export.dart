import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class PdfExport {
  static Future<void> exportAndShare(String studentName, List<ChatMessage> messages) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, h:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(studentName, context),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 10),
          ...messages.map((m) => _buildMessageRow(m, dateFormat)),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'CampusFlow_Chat_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildHeader(String studentName, pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 2, color: PdfColors.indigo)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CampusFlow AI',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
              pw.Text('Chat Transcript',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(studentName,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      ),
    );
  }

  static pw.Widget _buildMessageRow(ChatMessage message, DateFormat dateFormat) {
    final isUser = message.sender == MessageSender.user;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: isUser ? PdfColors.indigo50 : PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: isUser ? PdfColors.indigo200 : PdfColors.grey300,
          width: 0.5,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                isUser ? 'You' : 'CampusFlow AI',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: isUser ? PdfColors.indigo : PdfColors.teal,
                ),
              ),
              pw.Text(
                dateFormat.format(message.timestamp),
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            message.text.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1'),
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
