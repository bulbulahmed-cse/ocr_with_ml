import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/datasources/mlkit_datasource.dart';
import '../../domain/entities/text_block_entity.dart';
import '../../../clipboard/presentation/providers/clipboard_provider.dart';
import '../../../pdf/presentation/providers/pdf_provider.dart';
import '../../../../shared/widgets/text_box_painter.dart';
import '../providers/dependency_providers.dart';
import '../providers/ocr_state_provider.dart';

/// Main OCR screen with Riverpod state management
class OcrScreen extends ConsumerWidget {
  const OcrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrState = ref.watch(ocrNotifierProvider);
    final ocrNotifier = ref.read(ocrNotifierProvider.notifier);
    final pdfState = ref.watch(pdfNotifierProvider);
    final pdfNotifier = ref.read(pdfNotifierProvider.notifier);
    final clipboardNotifier = ref.read(clipboardNotifierProvider);

    // Show error messages
    if (ocrState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showError(context, ocrState.errorMessage!);
        ocrNotifier.clearError();
      });
    }

    if (pdfState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showError(context, pdfState.errorMessage!);
        pdfNotifier.clearError();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Detection'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Script selection dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<RecognitionScript>(
              value: ocrState.recognitionScript,
              underline: const SizedBox(),
              icon: const Icon(Icons.language, color: Colors.white),
              items: const [
                DropdownMenuItem(
                  value: RecognitionScript.latin,
                  child: Text('Latin', style: TextStyle(color: Colors.black)),
                ),
                DropdownMenuItem(
                  value: RecognitionScript.devanagari,
                  child: Text('বাংলা (Bengali)', style: TextStyle(color: Colors.black)),
                ),
              ],
              onChanged: (script) {
                if (script != null) {
                  // Update script provider
                  ref.read(recognitionScriptProvider.notifier).state = script;
                  // Update OCR state and re-process
                  ocrNotifier.changeScript(script);
                }
              },
            ),
          ),
          if (ocrState.hasTextBlocks) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: pdfState.isGenerating
                  ? null
                  : () => pdfNotifier.generatePdf(),
              tooltip: 'Make PDF',
            ),
            IconButton(
              icon: const Icon(Icons.copy_all),
              onPressed: () => _copyAllText(
                context,
                ocrState.textBlocks,
                clipboardNotifier,
              ),
              tooltip: 'Copy All Text',
            ),
          ],
        ],
      ),
      body: ocrState.isProcessing || pdfState.isGenerating
          ? const Center(child: CircularProgressIndicator())
          : !ocrState.hasImage
              ? _buildEmptyState(context, ocrNotifier)
              : _buildImageWithDetection(
                  context,
                  ocrState,
                  ocrNotifier,
                  clipboardNotifier,
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context, OcrNotifier notifier) {
    return Center(
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
                onPressed: () => notifier.pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => notifier.pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageWithDetection(
    BuildContext context,
    OcrState state,
    OcrNotifier notifier,
    ClipboardNotifier clipboardNotifier,
  ) {
    return Column(
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
                  notifier.updateScale(state.scale - 0.2);
                },
              ),
              Text('${(state.scale * 100).toInt()}%'),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  notifier.updateScale(state.scale + 0.2);
                },
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: () => notifier.pickImage(ImageSource.gallery),
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
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Image.file(
                        state.image!.file,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stackTrace) {
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
                      if (state.image!.uiImage != null &&
                          state.hasTextBlocks)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: TextBoxPainter(
                              textBlocks: state.textBlocks,
                              imageSize: Size(
                                state.image!.uiImage!.width.toDouble(),
                                state.image!.uiImage!.height.toDouble(),
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
        if (state.hasTextBlocks)
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
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Detected ${state.textBlocks.length} text blocks',
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
                      itemCount: state.textBlocks.length,
                      itemBuilder: (context, index) {
                        final block = state.textBlocks[index];
                        final confidence = (block.lines.isNotEmpty
                                ? block.lines.first.confidence ?? 0.0
                                : 0.0) *
                            100;

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
                              onPressed: () => _copyText(
                                context,
                                block.text,
                                clipboardNotifier,
                              ),
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
    );
  }

  void _copyAllText(
    BuildContext context,
    List<TextBlockEntity> textBlocks,
    ClipboardNotifier clipboardNotifier,
  ) async {
    try {
      final allText = textBlocks.map((block) => block.text).join('\n\n');
      await clipboardNotifier.copyText(allText);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All text copied!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to copy text: $e');
      }
    }
  }

  void _copyText(
    BuildContext context,
    String text,
    ClipboardNotifier clipboardNotifier,
  ) async {
    try {
      await clipboardNotifier.copyText(text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Copied: ${text.substring(0, text.length > 30 ? 30 : text.length)}...'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to copy text: $e');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
