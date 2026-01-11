import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Data source for PDF generation operations
class PdfDataSource {
  /// Generate PDF bytes from image and text blocks
  Future<Uint8List> generatePdf({
    required File imageFile,
    required ui.Image uiImage,
    required List<dynamic> textBlocks, // Using dynamic for flexibility with TextBlock
  }) async {
    try {
      final pdf = pw.Document();
      final imageSize = Size(uiImage.width.toDouble(), uiImage.height.toDouble());

      // Calculate scale to fit A4 with margins
      final pageWidth = PdfPageFormat.a4.width - 40; // 20px margin each side
      final pageHeight = PdfPageFormat.a4.height - 40;
      final scaleX = pageWidth / imageSize.width;
      final scaleY = pageHeight / imageSize.height;
      final scale = scaleX < scaleY ? scaleX : scaleY;

      final scaledWidth = imageSize.width * scale;
      final scaledHeight = imageSize.height * scale;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Container(
                width: scaledWidth,
                height: scaledHeight,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Stack(
                  children: textBlocks.map((block) {
                    return _buildPdfTextBlock(block, scale);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  pw.Widget _buildPdfTextBlock(dynamic block, double scale) {
    final rect = block.boundingBox;

    // Scale all positions
    final left = rect.left * scale;
    final top = rect.top * scale;
    final right = rect.right * scale;
    final bottom = rect.bottom * scale;

    // Calculate dimensions for font size
    final width = right - left;
    final height = bottom - top;
    final fontSize = (height * 0.6).clamp(6.0, 20.0);

    return pw.Positioned(
      left: left,
      top: top,
      child: pw.Container(
        width: width,
        height: height,
        alignment: pw.Alignment.centerLeft,
        child: pw.FittedBox(
          fit: pw.BoxFit.contain,
          child: pw.Text(
            block.text,
            style: pw.TextStyle(
              fontSize: fontSize,
              color: PdfColors.black,
            ),
          ),
        ),
      ),
    );
  }
}
