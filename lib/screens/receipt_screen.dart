import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../services/firestore_service.dart';

class ReceiptScreen extends StatelessWidget {
  final Invoice invoice;

  const ReceiptScreen({super.key, required this.invoice});

  // PDF তৈরি করার ফাংশন
  Future<Uint8List> _generatePdf(Map<String, dynamic> shopProfile) async {
    final pdf = pw.Document();

    final shopName = (shopProfile['shopName'] ?? 'My Shop') as String;
    final address = (shopProfile['address'] ?? '') as String;
    final phone = (shopProfile['phone'] ?? '') as String;

    final dateStr = DateFormat('dd MMM yyyy').format(invoice.date.toDate());
    final timeStr = DateFormat('hh:mm a').format(invoice.date.toDate());

    // 80mm Roll Paper Format (Thermal Printer standard)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                shopName.toUpperCase(),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (address.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  address,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
              if (phone.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  'Tel: $phone',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Text(
                '$dateStr • $timeStr',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),
              pw.Text(
                'CASH RECEIPT',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              // Items Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'DESCRIPTION',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      'PRICE',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              ...invoice.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.name, style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(
                              '${item.quantity} x Tk ${item.price.toStringAsFixed(2)}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          'Tk ${item.subtotal.toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 6),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),
              _pdfAmountRow('Subtotal', invoice.subtotal),
              if (invoice.discount > 0) _pdfAmountRow('Discount', -invoice.discount),
              pw.SizedBox(height: 4),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),
              _pdfAmountRow('Total', invoice.total, isBold: true, fontSize: 12),
              pw.SizedBox(height: 2),
              _pdfAmountRow(invoice.paymentMethod, invoice.total),
              pw.SizedBox(height: 12),
              pw.Text(
                'THANK YOU!',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              // Barcode Section in PDF
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: 'INV${invoice.invoiceNumber}',
                  width: 140,
                  height: 40,
                  drawText: false,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'INVOICE #${invoice.invoiceNumber}',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfAmountRow(String label, double amount, {bool isBold = false, double fontSize = 10}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          'Tk ${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _printOrSavePdf(BuildContext context, Map<String, dynamic> shopProfile) async {
    final pdfBytes = await _generatePdf(shopProfile);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(invoice.date.toDate());
    final timeStr = DateFormat('hh:mm a').format(invoice.date.toDate());

    return FutureBuilder<Map<String, dynamic>>(
      future: FirestoreService().getShopProfile(),
      builder: (context, snapshot) {
        final shopProfile = snapshot.data ?? {};
        final shopName = (shopProfile['shopName'] ?? '...') as String;
        final address = (shopProfile['address'] ?? '') as String;
        final phone = (shopProfile['phone'] ?? '') as String;

        return Scaffold(
          backgroundColor: const Color(0xFFEDEDED),
          appBar: AppBar(
            title: Text('Invoice #${invoice.invoiceNumber}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.print),
                tooltip: 'Print / Save PDF',
                onPressed: snapshot.hasData ? () => _printOrSavePdf(context, shopProfile) : null,
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ClipPath(
                    clipper: _ReceiptClipper(),
                    child: Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            shopName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (address.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              address,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Tel: $phone',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            '$dateStr  •  $timeStr',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          const _DashedDivider(),
                          const SizedBox(height: 12),
                          Text(
                            'CASH RECEIPT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'DESCRIPTION',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'PRICE',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...invoice.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontSize: 14)),
                                        Text(
                                          '${item.quantity} × ৳${item.price.toStringAsFixed(2)}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '৳${item.subtotal.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          const _DashedDivider(),
                          const SizedBox(height: 14),
                          _amountRow('Subtotal', invoice.subtotal),
                          if (invoice.discount > 0) _amountRow('Discount', -invoice.discount),
                          const SizedBox(height: 8),
                          const _DashedDivider(),
                          const SizedBox(height: 10),
                          _amountRow('Total', invoice.total, isBold: true, fontSize: 18),
                          const SizedBox(height: 6),
                          _amountRow(
                            invoice.paymentMethod,
                            invoice.total,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'THANK YOU!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 50,
                            child: BarcodeWidget(
                              barcode: Barcode.code128(),
                              data: 'INV${invoice.invoiceNumber}',
                              drawText: false,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'INVOICE #${invoice.invoiceNumber}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: snapshot.hasData ? () => _printOrSavePdf(context, shopProfile) : null,
                          icon: const Icon(Icons.print),
                          label: const Text('Print / Save PDF'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _amountRow(String label, double amount, {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '৳${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double zigWidth = 14
    final path = Path();
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 12);-ui

    double x = size.width;
    bool toggle = true;
    while (x > 0) {
      final nextX = (x - zigWidth).clamp(0, size.width).toDouble();
      path.lineTo(nextX, toggle ? size.height : size.height - 12);
      toggle = !toggle;
      x = nextX;
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        size: Size.infinite,
        painter: _DashedLinePainter(),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}