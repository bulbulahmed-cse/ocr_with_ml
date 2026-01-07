import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Text Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TextDetectionScreen(),
    );
  }
}

class TextDetectionScreen extends StatefulWidget {
  const TextDetectionScreen({super.key});

  @override
  State<TextDetectionScreen> createState() => _TextDetectionScreenState();
}

class _TextDetectionScreenState extends State<TextDetectionScreen> {
  File? _imageFile;
  List<TextBlock> _textBlocks = [];
  bool _isProcessing = false;
  ui.Image? _uiImage;
  double _scale = 1.0;
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _textBlocks = [];
          _uiImage = null;
          _scale = 1.0;
        });
        await _loadImage();
        await _processImage();
      }
    } catch (e) {
      _showError('Image pick error: $e');
    }
  }

  Future<void> _loadImage() async {
    if (_imageFile == null) return;

    try {
      final bytes = await _imageFile!.readAsBytes();

      // Simple decode without aggressive compression
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      if (mounted) {
        setState(() {
          _uiImage = frame.image;
        });
      }
    } catch (e) {
      print('Load image error: $e');
      if (mounted) {
        _showError('Image load error: $e');
      }
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;

    setState(() => _isProcessing = true);

    try {
      final inputImage = InputImage.fromFile(_imageFile!);
      final RecognizedText recognizedText =
      await _textRecognizer.processImage(inputImage);

      setState(() {
        _textBlocks = recognizedText.blocks;
        _isProcessing = false;
      });

      if (_textBlocks.isEmpty) {
        _showError('No text detected in image');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Text recognition error: $e');
    }
  }

  void _copyAllText() {
    final allText = _textBlocks.map((block) => block.text).join('\n\n');
    Clipboard.setData(ClipboardData(text: allText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All text copied!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: ${text.substring(0, text.length > 30 ? 30 : text.length)}...'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _generatePdf() async {
    if (_imageFile == null || _textBlocks.isEmpty || _uiImage == null) return;

    setState(() => _isProcessing = true);

    try {
      final pdf = pw.Document();
      final imageSize = Size(_uiImage!.width.toDouble(), _uiImage!.height.toDouble());

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
                  children: _textBlocks.map((block) {
                    return _buildPdfTextBlock(block, scale);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      );

      setState(() => _isProcessing = false);

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('PDF generation error: $e');
    }
  }

  pw.Widget _buildPdfTextBlock(TextBlock block, double scale) {
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _uiImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Detection'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_textBlocks.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _generatePdf,
              tooltip: 'Make PDF',
            ),
            IconButton(
              icon: const Icon(Icons.copy_all),
              onPressed: _copyAllText,
              tooltip: 'Copy All Text',
            ),
          ],
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : _imageFile == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Select an image to detect text',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Zoom controls
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  onPressed: () {
                    setState(() {
                      _scale = (_scale - 0.2).clamp(0.5, 3.0);
                    });
                  },
                ),
                Text('${(_scale * 100).toInt()}%'),
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  onPressed: () {
                    setState(() {
                      _scale = (_scale + 0.2).clamp(0.5, 3.0);
                    });
                  },
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('New Image'),
                ),
              ],
            ),
          ),
          // Image with detection
          Expanded(
            flex: 3,
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (_imageFile == null) {
                      return const CircularProgressIndicator();
                    }

                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Image.file(
                          _imageFile!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) {
                            print('Image error: $error');
                            return Container(
                              width: 300,
                              height: 300,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Image failed to load',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (_uiImage != null && _textBlocks.isNotEmpty)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: TextBoxPainter(
                                textBlocks: _textBlocks,
                                imageSize: Size(
                                  _uiImage!.width.toDouble(),
                                  _uiImage!.height.toDouble(),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          // Detected text list
          if (_textBlocks.isNotEmpty)
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300, width: 2),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.blue.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Detected ${_textBlocks.length} text blocks',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _textBlocks.length,
                        itemBuilder: (context, index) {
                          final block = _textBlocks[index];
                          final confidence = (block.lines.isNotEmpty
                              ? block.lines.first.confidence ?? 0.0
                              : 0.0) * 100;

                          final confidenceColor = confidence >= 80
                              ? Colors.green
                              : confidence >= 60
                              ? Colors.orange
                              : Colors.red;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                block.text,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.analytics,
                                      size: 14,
                                      color: confidenceColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Accuracy: ${confidence.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: confidenceColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                color: Colors.blue,
                                onPressed: () => _copyText(block.text),
                                tooltip: 'Copy',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom Painter for drawing bounding boxes over image
class TextBoxPainter extends CustomPainter {
  final List<TextBlock> textBlocks;
  final Size imageSize;

  TextBoxPainter({
    required this.textBlocks,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    canvas.scale(scale);

    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final fillPaint = Paint()
      ..color = Colors.green.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < textBlocks.length; i++) {
      final block = textBlocks[i];
      final rect = block.boundingBox;

      // Draw filled rectangle
      canvas.drawRect(rect, fillPaint);

      // Draw border
      canvas.drawRect(rect, paint);

      // Draw block number
      final textSpan = TextSpan(
        text: '${i + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.green,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(rect.left + 5, rect.top + 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}