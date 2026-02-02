import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

import 'dart:async';
import 'package:flutter/services.dart'; // Clipboard
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../logic/file_manager.dart';
// Widgets
import '../widgets/breadcrumb_bar.dart'; // TopControlBar
import '../widgets/level_gauge.dart';
import '../widgets/quick_tags.dart'; // StatusTagSelector
import '../widgets/control_panel.dart'; // ControlPanel (Bottom Zone)
import '../widgets/ui/ios_page_route.dart';
// Screens
import 'smart_review_screen.dart';
import 'photo_preview_screen.dart';
import 'gallery_screen.dart';

/// Main camera screen with professional minimalist UI
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isAiMode = false;
  bool _isTorchOn = false;
  File? _lastPhoto;
  bool _isProcessing = false;
  ResolutionPreset _currentResolution = ResolutionPreset.high;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoomLevel = 1.0;

  // Feedback state
  String? _feedbackText;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _loadLastPhoto();
    _initializeFileSystem();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeFileSystem() async {
    await FileManager.getRootDirectory();
    if (mounted) setState(() {}); // Rebuild to update breadcrumbs
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showFeedback('No cameras available');
        return;
      }

      final controller = CameraController(
        _cameras![0],
        _currentResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller; // Assign locally first before init

      await controller.initialize();

      // Verify controller is still mounted after async init
      if (!mounted) {
        return;
      }

      _maxAvailableZoom = await controller.getMaxZoomLevel();
      _minAvailableZoom = await controller.getMinZoomLevel();

      // Start at 1.0x if safely possible
      _currentZoomLevel = 1.0.clamp(_minAvailableZoom, _maxAvailableZoom);
      await controller.setZoomLevel(_currentZoomLevel);

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (e is CameraException) {
        _showFeedback('Camera Init Error: ${e.code}');
      } else {
        _showFeedback('Camera Error: $e');
      }
    }
  }

  // ... (Methods _loadLastPhoto through _showResolutionSheet remain similar)
  // But we are editing the top/structure, so we return valid structure.
  // Wait, I cannot edit _takePicture here. It's too far down.
  // This chunk is for the top Lifecycle mixin part.

  Future<void> _loadLastPhoto() async {
    final File? photo = await FileManager.getLastPhoto();
    if (mounted) {
      setState(() {
        _lastPhoto = photo;
      });
    }
  }

  Future<void> _openPhotoPreview() async {
    if (_lastPhoto == null || !_lastPhoto!.existsSync()) return;

    await Navigator.of(context).push(
      IOSPageRoute(
        builder: (context) => PhotoPreviewScreen(photoFile: _lastPhoto!),
      ),
    );
  }

  Future<void> _openGallery() async {
    final Directory currentDir = FileManager.getCurrentDirectory();
    if (!await currentDir.exists()) return;

    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.pausePreview();
    }

    if (mounted) {
      await Navigator.of(context).push(
        IOSPageRoute(
          builder: (context) => GalleryScreen(currentDirectory: currentDir),
        ),
      );
    }

    if (mounted && _controller != null && _controller!.value.isInitialized) {
      await _controller!.resumePreview();
      _loadLastPhoto(); // Reload in case they deleted something? (Not implemented yet but good hygiene)
    }
  }

  Future<void> _setZoom(double zoomLevel) async {
    if (_controller == null || !_isInitialized) return;

    final double level = zoomLevel.clamp(_minAvailableZoom, _maxAvailableZoom);

    try {
      await _controller!.setZoomLevel(level);
      setState(() {
        _currentZoomLevel = level;
      });
    } catch (e) {
      debugPrint('Error setting zoom: $e');
    }
  }

  Future<void> _setResolution(ResolutionPreset preset) async {
    if (_controller == null || _currentResolution == preset) return;

    setState(() {
      _isInitialized = false;
      _currentResolution = preset;
    });

    await _controller?.dispose();
    _controller = null;

    await _initializeCamera();
    _showFeedback('Res: ${preset.name}');
  }

  void _showResolutionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'RESOLUTION',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            _buildResolutionOption('High (1080p)', ResolutionPreset.high),
            _buildResolutionOption('Very High (4K)', ResolutionPreset.veryHigh),
            _buildResolutionOption('Ultra High (Max)', ResolutionPreset.max),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionOption(String label, ResolutionPreset preset) {
    final bool isSelected = _currentResolution == preset;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop();
        _setResolution(preset);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_isAiMode) {
        final XFile imageFile = await _controller!.takePicture();
        final Uint8List imageBytes = await imageFile.readAsBytes();

        if (mounted) {
          Navigator.of(context).push(
            IOSPageRoute(
              builder: (context) => SmartReviewScreen(
                imageBytes: imageBytes,
                onSave: (selectedText, newBytes) async {
                  await _savePhotoWithText(
                      newBytes ?? imageBytes, selectedText);
                },
              ),
            ),
          );
        }
      } else {
        // Fast Mode
        final XFile imageFile = await _controller!.takePicture();
        final Uint8List imageBytes = await imageFile.readAsBytes();

        // Haptic or visual feedback
        _showFeedback('CAPTURED');

        _savePhotoInBackground(imageBytes);
      }
    } catch (e) {
      debugPrint('Camera Error: $e');
      if (e is CameraException) {
        // Try to recover
        _showFeedback('Recovering Camera...');
        _isInitialized = false;
        await _controller?.dispose();
        _controller = null;
        await _initializeCamera();
      } else {
        _showFeedback('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _savePhotoInBackground(Uint8List imageBytes) async {
    try {
      final File savedFile = await FileManager.savePhoto(imageBytes);
      if (mounted) {
        setState(() {
          _lastPhoto = savedFile;
        });
      }
    } catch (e) {
      _showFeedback('Save Error: $e');
    }
  }

  Future<void> _savePhotoWithText(
      Uint8List imageBytes, String? selectedText) async {
    try {
      final File savedFile = await FileManager.savePhoto(imageBytes);

      if (selectedText != null && selectedText.isNotEmpty) {
        await FileManager.appendToAssetData(selectedText);
      }

      if (mounted) {
        setState(() {
          _lastPhoto = savedFile;
        });
        _showFeedback('SAVED + TAGGED');
      }
    } catch (e) {
      _showFeedback('Error: $e');
    }
  }

  void _toggleAiMode() {
    setState(() {
      _isAiMode = !_isAiMode;
    });
    _showFeedback(_isAiMode ? 'AI MODE' : 'FAST MODE');
  }

  Future<void> _toggleTorch() async {
    if (_controller == null || !_isInitialized) return;

    try {
      _isTorchOn = !_isTorchOn;
      await _controller!.setFlashMode(
        _isTorchOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
      _showFeedback(_isTorchOn ? 'TORCH ON' : 'TORCH OFF');
    } catch (e) {
      _showFeedback('Torch Error');
    }
  }

  void _showFolderDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // For custom shape
      isScrollControlled: true,
      builder: (context) => const _FolderDetailsSheet(),
    );
  }

  void _showFolderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _FolderBottomSheet(
        onFolderCreated: () {
          setState(() {}); // Rebuild breadcrumbs
          _loadLastPhoto();
        },
      ),
    );
  }

  void _showFeedback(String message) {
    if (mounted) {
      // FeedbackLogic is now declarative in build via _FeedbackOverlay
      // We just update the text here.
      if (mounted) {
        setState(() {
          _feedbackText = message;
        });
        // Auto-clear logic can be handled by the widget or here.
        // The widget needs to see the CHANGE.
        // Simple way: clear it after duration here to allow re-trigger.
        _feedbackTimer?.cancel();
        _feedbackTimer = Timer(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _feedbackText = null;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _handleBreadcrumbTap(int index) {
    final List<String> paths = FileManager.getBreadcrumbPath();
    // If tapping the last item (current directory), show create folder sheet
    if (index == paths.length - 1) {
      _showFolderSheet();
      return;
    }

    // Otherwise, navigate to that directory
    final Directory? targetDir = FileManager.getDirectoryForBreadcrumb(index);
    if (targetDir != null && targetDir.existsSync()) {
      FileManager.setCurrentDirectory(targetDir);
      setState(() {}); // Rebuild breadcrumbs
      _loadLastPhoto();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Layer 1: Camera Preview
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_controller!),
                  // Vignette Overlay (Subtle Gradient)
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.9,
                        colors: [
                          Colors.transparent,
                          Colors.black
                              .withValues(alpha: 0.4), // Subtle darkened edges
                        ],
                        stops: const [0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.accentGreen),
            ),

          // Layer 2: Precision Overlay
          if (_isInitialized) const Positioned.fill(child: LevelGauge()),

          // UI LAYER - Delayed Entrance
          _DelayedEntrance(
            delay: const Duration(milliseconds: 80),
            child: Stack(
              children: [
                // Layer 3: Top Control Bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: TopControlBar(
                    onFolderTap: _showFolderDetails,
                    onSettingsTap: _showResolutionSheet,
                    onGridTap: _openGallery,
                    onBreadcrumbTap: _handleBreadcrumbTap,
                  ),
                ),

                // Layer 4: Right Edge Status Tags
                const Positioned(
                  right: 16,
                  top: 100, // Clear the top bar
                  bottom: 100, // Clear the bottom controls
                  child: StatusTagSelector(),
                ),

                // Layer 5: Bottom Control Zone
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ControlPanel(
                    onShutterTap: _takePicture,
                    isAiMode: _isAiMode,
                    onAiToggle: _toggleAiMode,
                    onTorchToggle: _toggleTorch,
                    isTorchOn: _isTorchOn,
                    lastPhoto: _lastPhoto,
                    onThumbnailTap: _openPhotoPreview,
                    currentZoom: _currentZoomLevel,
                    minZoom: _minAvailableZoom,
                    maxZoom: _maxAvailableZoom,
                    onZoomChanged: _setZoom,
                  ),
                ),
              ],
            ),
          ),

          // Layer 6: Feedback Overlay (Floating)
          Positioned(
            bottom: 160, // Above bottom controls
            left: 0,
            right: 0,
            child: _FeedbackOverlay(text: _feedbackText),
          ),
        ],
      ),
    );
  }
}

class _FeedbackOverlay extends StatefulWidget {
  final String? text;

  const _FeedbackOverlay({this.text});

  @override
  State<_FeedbackOverlay> createState() => _FeedbackOverlayState();
}

class _FeedbackOverlayState extends State<_FeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityIn;
  late Animation<double> _opacityOut;

  @override
  void initState() {
    super.initState();
    // Total duration: 120ms (In) + 600ms (Hold) + 180ms (Out) = 900ms
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    // Fade In: 0ms -> 120ms (0.0 -> 0.133)
    _opacityIn = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.133, curve: Cubic(0.2, 0.0, 0.0, 1.0)),
    ));

    // Slide Up: 6px up. Use Transform.translate with Offset in pixels?
    // SlideTransition uses relative offset.
    // We will use AnimatedBuilder with explicit Transform in build for pixels.
    // But for simplicity with SlideTransition, we can use a small relative value
    // or just implement a custom AnimatedBuilder. Let's use Transform.translate.
    // Curve: Cubic(0.2, 0.0, 0.0, 1.0)
    // Duration: Matches Fade In (120ms)? Usually slide happens with fade.
    // The spec says "Translate Y: +6px -> 0".
    // Let's assume the slide duration matches entrance 120ms.

    // Fade Out: 720ms -> 900ms (0.8 -> 1.0)
    _opacityOut = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.8, 1.0, curve: Cubic(0.2, 0.0, 0.0, 1.0)),
    ));
  }

  @override
  void didUpdateWidget(_FeedbackOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != null && widget.text != oldWidget.text) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text == null && _controller.isDismissed) return const SizedBox();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Opacity logic:
        // 0.0 -> 0.133: Fade In (uses _opacityIn)
        // 0.133 -> 0.8: Hold (Opacity 1.0)
        // 0.8 -> 1.0: Fade Out (uses _opacityOut)
        double currentOpacity = 1.0;
        if (_controller.value <= 0.133) {
          currentOpacity = _opacityIn.value;
        } else if (_controller.value >= 0.8) {
          currentOpacity = _opacityOut.value;
        }

        // Slide logic: 6px -> 0px during entrance (0.0 -> 0.133)
        // Easing: cubic-bezier(0.2, 0.0, 0.0, 1.0)
        double currentTranslation = 0.0;
        if (_controller.value <= 0.133) {
          // Map 0.0->0.133 to 0.0->1.0
          double t = _controller.value / 0.133;
          // Apply cubic curve
          const curve = Cubic(0.2, 0.0, 0.0, 1.0);
          double curvedT = curve.transform(t);
          // Interpolate 6.0 -> 0.0
          currentTranslation = 6.0 * (1.0 - curvedT);
        }

        return Opacity(
          opacity: currentOpacity,
          child: Transform.translate(
            offset: Offset(0, currentTranslation),
            child: child,
          ),
        );
      },
      child: Center(
        child: Text(
          widget.text?.toUpperCase() ?? '',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              shadows: [
                Shadow(
                    color: Colors.black45, blurRadius: 4, offset: Offset(0, 1))
              ]),
        ),
      ),
    );
  }
}

class _DelayedEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _DelayedEntrance({required this.child, required this.delay});
  @override
  State<_DelayedEntrance> createState() => _DelayedEntranceState();
}

class _DelayedEntranceState extends State<_DelayedEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}

class _FolderBottomSheet extends StatefulWidget {
  final VoidCallback onFolderCreated;

  const _FolderBottomSheet({required this.onFolderCreated});

  @override
  State<_FolderBottomSheet> createState() => _FolderBottomSheetState();
}

class _FolderBottomSheetState extends State<_FolderBottomSheet> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _createFolder() async {
    final String folderName = _controller.text.trim();
    if (folderName.isEmpty) return;

    try {
      final Directory newFolder = await FileManager.createFolder(folderName);
      FileManager.setCurrentDirectory(newFolder);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onFolderCreated();
      }
    } catch (e) {
      // Error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'NEW FOLDER',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Enter folder name',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.textSecondary),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.accentGreen),
              ),
            ),
            autofocus: true,
            onSubmitted: (_) => _createFolder(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _createFolder();
                },
                child: const Text('CREATE',
                    style: TextStyle(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FolderDetailsSheet extends StatefulWidget {
  const _FolderDetailsSheet();

  @override
  State<_FolderDetailsSheet> createState() => _FolderDetailsSheetState();
}

class _FolderDetailsSheetState extends State<_FolderDetailsSheet> {
  int _fileCount = 0;
  double _totalSizeMb = 0;
  bool _isLoading = true;
  String _cleanPath = '';
  String _rawPath = '';

  @override
  void initState() {
    super.initState();
    _loadFolderStats();
  }

  Future<void> _loadFolderStats() async {
    final Directory current = FileManager.getCurrentDirectory();
    _rawPath = current.path;
    _cleanPath = _getCleanPath(_rawPath);

    int count = 0;
    int totalBytes = 0;

    if (await current.exists()) {
      try {
        await for (final FileSystemEntity entity
            in current.list(recursive: false, followLinks: false)) {
          if (entity is File) {
            count++;
            try {
              totalBytes += await entity.length();
            } catch (e) {
              // Ignore file access errors
            }
          }
        }
      } catch (e) {
        // Ignore directory access errors
      }
    }

    if (mounted) {
      setState(() {
        _fileCount = count;
        _totalSizeMb = totalBytes / (1024 * 1024);
        _isLoading = false;
      });
    }
  }

  String _getCleanPath(String rawPath) {
    // Convert /storage/emulated/0/.../FolderName to readable format
    String path = rawPath;

    // Handle standard Android public storage path
    if (path.startsWith('/storage/emulated/0/')) {
      path = path.replaceFirst('/storage/emulated/0/', 'Internal Storage > ');
    } else if (path.startsWith('/data/user/0/')) {
      // Legacy/Fallback for private storage
      path = path.replaceFirst('/data/user/0/', 'App Data > ');
    }

    // Clean up specific known folders for better readability
    path = path.replaceAll(
        'Internal Storage > Pictures > ${Constants.rootFolderName}',
        'SurveyorCam');

    // Replace slashes with arrows
    path = path.replaceAll('/', ' > ');

    return path;
  }

  Future<void> _copyPath() async {
    await Clipboard.setData(ClipboardData(text: _rawPath));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Matte Dark Grey
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.folder_open, color: AppColors.accentGreen, size: 24),
              SizedBox(width: 12),
              Text(
                'Folder Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Path Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: SelectableText(
              _cleanPath,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'RobotoMono', // Monospace
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              if (_isLoading)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.textSecondary))
              else
                Text(
                  '$_fileCount Files • ${_totalSizeMb.toStringAsFixed(1)} MB',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Action
          OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _copyPath();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('COPY FULL PATH'),
          ),
          const SizedBox(height: 16), // Bottom padding
        ],
      ),
    );
  }
}
