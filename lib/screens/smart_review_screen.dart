import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import '../core/app_colors.dart';

/// AI freeze-frame screen where user can select detected text
class SmartReviewScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(String?, Uint8List?) onSave;

  const SmartReviewScreen({
    super.key,
    required this.imageBytes,
    required this.onSave,
  });

  @override
  State<SmartReviewScreen> createState() => _SmartReviewScreenState();
}

class _SmartReviewScreenState extends State<SmartReviewScreen> {
  ui.Image? _image;
  List<TextBlock> _textBlocks = [];
  bool _isProcessing = false;
  final List<String> _selectedTexts = [];
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Drawing State
  bool _isDrawingMode = false;
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  @override
  void initState() {
    super.initState();
    _loadImage();
    _processImage();
  }

  Future<void> _loadImage() async {
    final ui.Codec codec = await ui.instantiateImageCodec(widget.imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    if (mounted) {
      setState(() {
        _image = frameInfo.image;
      });
    }
  }

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Save bytes to temporary file for ML Kit processing
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File(
          '${tempDir.path}/temp_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(widget.imageBytes);

      final InputImage inputImage = InputImage.fromFilePath(tempFile.path);

      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (mounted) {
        setState(() {
          _textBlocks = recognizedText.blocks;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: AppColors.background,
          ),
        );
      }
    }
  }

  void _toggleTextBlock(TextBlock block) {
    setState(() {
      if (_selectedTexts.contains(block.text)) {
        _selectedTexts.remove(block.text);
      } else {
        _selectedTexts.add(block.text);
      }
    });
  }

  Future<void> _saveAndExit() async {
    if (_strokes.isNotEmpty && _image != null) {
      // Merge drawing onto image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final double width = _image!.width.toDouble();
      final double height = _image!.height.toDouble();

      // Draw original image
      canvas.drawImage(_image!, Offset.zero, Paint());

      // Draw strokes (scaled to image size)
      // Since strokes are recorded in screen coordinates, we need to scale them to image coordinates.
      // Wait, _ImagePainter scaling logic:
      // scale = min(screenW / imgW, screenH / imgH)
      // ScreenCoord = ImgCoord * scale
      // ImgCoord = ScreenCoord / scale
      // But I need the current scale factor.

      final Size screenSize = MediaQuery.of(context).size;
      final double imageWidth = _image!.width.toDouble();
      final double imageHeight = _image!.height.toDouble();
      final double scaleX = screenSize.width / imageWidth;
      final double scaleY = screenSize.height / imageHeight;
      final double scale = scaleX < scaleY ? scaleX : scaleY;

      final Paint paint = Paint()
        ..color = AppColors.tagBad
        ..strokeCap = StrokeCap.round
        ..strokeWidth =
            5.0 / scale // Accessorize stroke width relative to image size
        ..style = PaintingStyle.stroke;

      for (final stroke in _strokes) {
        if (stroke.isEmpty) continue;
        final Path path = Path();
        path.moveTo(stroke.first.dx / scale, stroke.first.dy / scale);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx / scale, stroke[i].dy / scale);
        }
        canvas.drawPath(path, paint);
      }

      // Also draw current stroke
      if (_currentStroke.isNotEmpty) {
        final Path path = Path();
        path.moveTo(
            _currentStroke.first.dx / scale, _currentStroke.first.dy / scale);
        for (int i = 1; i < _currentStroke.length; i++) {
          path.lineTo(
              _currentStroke[i].dx / scale, _currentStroke[i].dy / scale);
        }
        canvas.drawPath(path, paint);
      }

      final ui.Image mergedImage = await recorder.endRecording().toImage(
            width.toInt(),
            height.toInt(),
          );

      final ByteData? byteData = await mergedImage.toByteData(
          format:
              ui.ImageByteFormat.png); // PNG required for high fidelity buffer

      // Convert to JPG or PNG? Camera saves as JPG usually.
      // toByteData only supports png (raw rgba) or raw.
      // We will return the png bytes.

      if (byteData != null) {
        widget.onSave(_selectedTexts.join('\n'), byteData.buffer.asUint8List());
        if (mounted) Navigator.of(context).pop();
        return;
      }
    }

    widget.onSave(_selectedTexts.join('\n'), null);
    if (mounted) Navigator.of(context).pop();
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double imageWidth = _image?.width.toDouble() ?? screenSize.width;
    final double imageHeight = _image?.height.toDouble() ?? screenSize.height;
    final double scaleX = screenSize.width / imageWidth;
    final double scaleY = screenSize.height / imageHeight;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Image display
          Center(
            child: _image != null
                ? GestureDetector(
                    onTapDown: (details) {
                      if (_isDrawingMode) return;
                      final Offset localPosition = details.localPosition;
                      // Find which text block was tapped
                      for (final TextBlock block in _textBlocks) {
                        final Rect boundingBox = Rect.fromLTRB(
                          block.boundingBox.left * scale,
                          block.boundingBox.top * scale,
                          block.boundingBox.right * scale,
                          block.boundingBox.bottom * scale,
                        );
                        if (boundingBox.contains(localPosition)) {
                          HapticFeedback.selectionClick();
                          _toggleTextBlock(block);
                          break;
                        }
                      }
                    },
                    onPanStart: (details) {
                      if (!_isDrawingMode) return;
                      setState(() {
                        _currentStroke = [details.localPosition];
                      });
                    },
                    onPanUpdate: (details) {
                      if (!_isDrawingMode) return;
                      setState(() {
                        _currentStroke.add(details.localPosition);
                      });
                    },
                    onPanEnd: (_) {
                      if (!_isDrawingMode) return;
                      setState(() {
                        _strokes.add(List.from(_currentStroke));
                        _currentStroke = [];
                      });
                    },
                    child: CustomPaint(
                      size: Size(imageWidth * scale, imageHeight * scale),
                      painter: _ImagePainter(
                        image: _image!,
                        textBlocks: _textBlocks,
                        selectedTexts: _selectedTexts,
                        scale: scale,
                        strokes: _strokes,
                        currentStroke: _currentStroke,
                      ),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentGreen,
                    ),
                  ),
          ),

          // Processing indicator
          if (_isProcessing)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.accentGreen,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Detecting text...',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.overlayBlack,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    const Text(
                      'Select Text',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _isDrawingMode ? Icons.edit : Icons.edit_outlined,
                        color: _isDrawingMode
                            ? AppColors.tagBad
                            : AppColors.textPrimary,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isDrawingMode = !_isDrawingMode;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _cancel();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom control bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.overlayBlack,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedTexts.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.accentGreen,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Selected: ${_selectedTexts.length} blocks',
                                style: const TextStyle(
                                  color: AppColors.accentGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Cancel button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _cancel();
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.textSecondary),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Save button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              _saveAndExit();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Save Photo',
                              style: TextStyle(
                                color: AppColors.background,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw image with text block overlays
class _ImagePainter extends CustomPainter {
  final ui.Image image;
  final List<TextBlock> textBlocks;
  final List<String> selectedTexts;
  final double scale;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _ImagePainter({
    required this.image,
    required this.textBlocks,
    this.selectedTexts = const [],
    required this.scale,
    this.strokes = const [],
    this.currentStroke = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw image
    final Rect imageRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint(),
    );

    // Draw text block overlays (only if not drawing or just show them underneath?)
    // Let's keep them visible.
    for (final TextBlock block in textBlocks) {
      final bool isSelected = selectedTexts.contains(block.text);

      final Paint paint = Paint()
        ..color = isSelected
            ? AppColors.accentGreen
            : AppColors.tagFix.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 1.0;

      final Rect boundingBox = Rect.fromLTRB(
        block.boundingBox.left * scale,
        block.boundingBox.top * scale,
        block.boundingBox.right * scale,
        block.boundingBox.bottom * scale,
      );

      canvas.drawRect(boundingBox, paint);

      if (isSelected) {
        final Paint fillPaint = Paint()
          ..color = AppColors.accentGreen.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        canvas.drawRect(boundingBox, fillPaint);
      }
    }

    // Draw Strokes
    final Paint strokePaint = Paint()
      ..color = AppColors.tagBad
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final Path path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, strokePaint);
    }

    if (currentStroke.isNotEmpty) {
      final Path path = Path();
      path.moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.textBlocks != textBlocks ||
        oldDelegate.selectedTexts != selectedTexts ||
        oldDelegate.scale != scale ||
        oldDelegate.strokes.length != strokes.length ||
        oldDelegate.currentStroke.length != currentStroke.length;
  }
}
