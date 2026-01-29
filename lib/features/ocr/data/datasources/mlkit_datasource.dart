import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/entities/text_block_entity.dart';
import '../models/text_block_model.dart';

/// Supported text recognition scripts
enum RecognitionScript {
  latin,
  devanagari, // Supports Bengali, Hindi, and other Indic scripts
}

/// Data source for ML Kit text recognition operations
class MlKitDataSource {
  TextRecognizer? _textRecognizer;
  RecognitionScript _currentScript = RecognitionScript.devanagari;

  MlKitDataSource({RecognitionScript? script}) {
    _currentScript = script ?? RecognitionScript.devanagari;
    _initializeRecognizer();
  }

  void _initializeRecognizer() {
    _textRecognizer?.close();
    // For Bengali/Bangla, use default recognizer (without script specification)
    // which can detect multiple languages including Bengali
    // For Latin, explicitly use latin script for better performance
    // if (_currentScript == RecognitionScript.devanagari) {
      // Use default recognizer for Bengali - it can auto-detect Bengali text
      _textRecognizer = TextRecognizer(
        script: TextRecognitionScript.devanagiri
      );
    // } else {
    //   _textRecognizer = TextRecognizer(
    //     script: TextRecognitionScript.latin,
    //   );
    // }
  }

  /// Change recognition script
  void setScript(RecognitionScript script) {
    if (_currentScript != script) {
      _currentScript = script;
      _initializeRecognizer();
    }
  }

  /// Get current script
  RecognitionScript get currentScript => _currentScript;

  /// Process image and extract text blocks
  Future<Map> recognizeText(File imageFile) async {
    try {
      if (_textRecognizer == null) {
        _initializeRecognizer();
      }

      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer!.processImage(inputImage);
     final List<TextBlockEntity> textList = (recognizedText.blocks).map((block) => TextBlockModel.fromTextBlock(block))
          .toList();
      final invoiceNo = extractInvoiceNumber(recognizedText.text);
      final invoiceDate = extractInvoiceDate(recognizedText.text);
      final result = {
        "text_block":textList,
        "date":invoiceDate,
        "invoice_no":invoiceNo
      };
      return result;
    } catch (e) {
      throw Exception('Failed to recognize text: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }

  ///Get Invoice
  String? extractInvoiceNumber(String fullText) {
    final regex = RegExp(
      r'(Invoice\s*No\.?\s*[:\-]?\s*)(\d+)',
      caseSensitive: false,
    );

    final match = regex.firstMatch(fullText);

    print("Invoi ce");
    if (match != null) {
      print("Invoice No: ${match.group(2)}");
      return match.group(2); // Only number
    }
    return null;
  }

  /// Get Invoice Date
  String? extractInvoiceDate(String fullText) {
    final regex = RegExp(
      r'(Invoice\s*Date|Date)\s*[:\-]?\s*'
      r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}|\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}|\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4})',
      caseSensitive: false,
    );

    final match = regex.firstMatch(fullText);

    if (match != null) {
      print("Invoice Date: ${match.group(2)}");
      return match.group(2); // Only date
    }
    return null;
  }


}
