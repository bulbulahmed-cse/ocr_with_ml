import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_to_pdf/features/ocr/domain/entities/image_entity.dart';
import '../../data/datasources/mlkit_datasource.dart';
import '../../domain/entities/text_block_entity.dart';
import '../../../clipboard/presentation/providers/clipboard_provider.dart';
import '../../../pdf/presentation/providers/pdf_provider.dart';
import '../../../../shared/widgets/text_box_painter.dart';
import '../providers/dependency_providers.dart';
import '../providers/ocr_state_provider.dart';

/// Camera state provider
final cameraProvider = FutureProvider<List<CameraDescription>>((ref) async {
  return await availableCameras();
});

/// Main OCR screen with live camera view
class OcrScreen extends ConsumerStatefulWidget {
  const OcrScreen({super.key});

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends ConsumerState<OcrScreen> {
  final TextEditingController _invoiceController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _invoiceController.dispose();
    _totalController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final ocrNotifier = ref.read(ocrNotifierProvider.notifier);

      // Process the captured image
      await ocrNotifier.loadUiImageAndProcess(
        ImageEntity(file: File(image.path))
      );
    } catch (e) {
      if (mounted) {
        _showError(context, 'Failed to capture image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Invoice Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (ocrState.hasTextBlocks)
            IconButton(
              icon: const Icon(Icons.list_alt),
              onPressed: () => _navigateToTextList(context, ocrState, clipboardNotifier),
              tooltip: 'View Detected Text',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Camera/Image view - upper side
            Expanded(
              flex: 4,
              child: ocrState.isProcessing || pdfState.isGenerating
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCameraView(context, ocrState, ocrNotifier),
            ),
        
            // Three text fields - down side
            Expanded(
              flex: 2,
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  children: [
                    const Text(
                      'Invoice Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _invoiceController,
                      decoration: InputDecoration(
                        labelText: 'Invoice No.',
                        prefixIcon: const Icon(Icons.receipt_long),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _totalController,
                      decoration: InputDecoration(
                        labelText: 'Total',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          _dateController.text =
                          '${date.day}/${date.month}/${date.year}';
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: (){}, child: const Text("Submit"))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView(
      BuildContext context,
      OcrState state,
      OcrNotifier notifier,
      ) {
    // If image is captured, show it with overlay
    if (state.hasImage) {
      return Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Captured image with detection overlay
            Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Stack(
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
                          color: Colors.grey[800],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 80, color: Colors.grey),
                                SizedBox(height: 10),
                                Text('Image failed to load', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (state.image!.uiImage != null && state.hasTextBlocks)
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
                ),
              ),
            ),
            // Recapture button
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'recapture',
                    onPressed: () {
                      // Clear current image to show camera again
                      notifier.clearImage();
                    },
                    backgroundColor: Colors.blue,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Recapture'),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    heroTag: 'gallery',
                    onPressed: () => notifier.pickImage(ImageSource.gallery),
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.photo_library, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show live camera preview
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Live camera preview
          Center(
            child: AspectRatio(
              aspectRatio: .8,
              child: CameraPreview(_cameraController!),
            ),
          ),

          // Camera controls overlay
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gallery button
                FloatingActionButton(
                  heroTag: 'gallery',
                  onPressed: () => notifier.pickImage(ImageSource.gallery),
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: const Icon(Icons.photo_library, color: Colors.black87),
                ),
                const SizedBox(width: 24),
                // Capture button
                GestureDetector(
                  onTap: _captureImage,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.9),
                      border: Border.all(color: Colors.blue, width: 4),
                    ),
                    child: const Icon(
                      Icons.camera,
                      size: 36,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Switch camera button (if multiple cameras available)
                FloatingActionButton(
                  heroTag: 'switch',
                  onPressed: () async {
                    final cameras = await availableCameras();
                    if (cameras.length > 1) {
                      final currentIndex = cameras.indexOf(_cameraController!.description);
                      final newIndex = (currentIndex + 1) % cameras.length;

                      await _cameraController?.dispose();
                      _cameraController = CameraController(
                        cameras[newIndex],
                        ResolutionPreset.high,
                        enableAudio: false,
                      );
                      await _cameraController!.initialize();
                      setState(() {});
                    }
                  },
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: const Icon(Icons.flip_camera_ios, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTextList(
      BuildContext context,
      OcrState state,
      ClipboardNotifier clipboardNotifier,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetectedTextListScreen(
          textBlocks: state.textBlocks,
          clipboardNotifier: clipboardNotifier,
        ),
      ),
    );
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

/// Separate screen to show detected text list
class DetectedTextListScreen extends StatelessWidget {
  final List<TextBlockEntity> textBlocks;
  final ClipboardNotifier clipboardNotifier;

  const DetectedTextListScreen({
    super.key,
    required this.textBlocks,
    required this.clipboardNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detected Text'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            onPressed: () => _copyAllText(context),
            tooltip: 'Copy All Text',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Found ${textBlocks.length} text blocks',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: textBlocks.length,
              itemBuilder: (context, index) {
                final block = textBlocks[index];
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
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 18,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                block.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.analytics,
                                    size: 16,
                                    color: confidenceColor,
                                  ),
                                  const SizedBox(width: 6),
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
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 22),
                          color: Colors.blue,
                          onPressed: () => _copyText(context, block.text),
                          tooltip: 'Copy',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _copyAllText(BuildContext context) async {
    try {
      final allText = textBlocks.map((block) => block.text).join('\n\n');
      await clipboardNotifier.copyText(allText);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All text copied to clipboard!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy text: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyText(BuildContext context, String text) async {
    try {
      await clipboardNotifier.copyText(text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Copied: ${text.substring(0, text.length > 30 ? 30 : text.length)}...',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy text: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}