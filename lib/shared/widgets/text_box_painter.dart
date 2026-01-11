import 'package:flutter/material.dart';
import '../../features/ocr/domain/entities/text_block_entity.dart';

/// Custom Painter for drawing bounding boxes over image
class TextBoxPainter extends CustomPainter {
  final List<TextBlockEntity> textBlocks;
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
      ..color = Colors.green.withValues(alpha: 0.2)
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
