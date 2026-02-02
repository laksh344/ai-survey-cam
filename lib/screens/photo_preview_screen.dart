import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../widgets/ui/ios_scale_button.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class PhotoPreviewScreen extends StatefulWidget {
  final File photoFile;
  final String? heroTag;

  const PhotoPreviewScreen({
    super.key,
    required this.photoFile,
    this.heroTag,
  });

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  late File _currentFile;
  Key _imageKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _currentFile = widget.photoFile;
  }

  Future<void> _openEditor(BuildContext context) async {
    if (mounted) {
      await Navigator.push(
        context,
        _FadeRoute(
          builder: (context) => ProImageEditor.file(
            _currentFile,
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (Uint8List bytes) async {
                await _currentFile.writeAsBytes(bytes);
                PaintingBinding.instance.imageCache.clear();
                PaintingBinding.instance.imageCache.clearLiveImages();
                if (context.mounted) {
                  setState(() {
                    _imageKey = UniqueKey();
                  });
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                }
              },
            ),
            configs: const ProImageEditorConfigs(
              designMode: ImageEditorDesignMode.material,
              // Theme configuration removed to avoid API mismatch, defaulting to Material.
              // Ideally update to use 'theme' parameter if available in v11.
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: IOSScaleButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
        ),
        actions: [
          Center(
            child: IOSScaleButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _openEditor(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: widget.heroTag ?? _currentFile.path,
            child: Image.file(
              _currentFile,
              key: _imageKey,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _FadeRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  _FadeRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
}
