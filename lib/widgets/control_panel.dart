import 'package:flutter/material.dart';
import 'dart:io';
import '../core/app_colors.dart';
import 'ui/ios_glass_container.dart';
import 'ui/ios_scale_button.dart';

class ControlPanel extends StatefulWidget {
  final VoidCallback onShutterTap;
  final bool isAiMode;
  final VoidCallback onAiToggle; // Toggles between FAST / AI
  final File? lastPhoto;
  final VoidCallback? onThumbnailTap;
  final bool isTorchOn;
  final VoidCallback onTorchToggle;

  // Zoom props
  final double currentZoom;
  final Function(double) onZoomChanged;
  final double minZoom;
  final double maxZoom;

  const ControlPanel({
    super.key,
    required this.onShutterTap,
    required this.isAiMode,
    required this.onAiToggle,
    this.lastPhoto,
    this.onThumbnailTap,
    required this.isTorchOn,
    required this.onTorchToggle,
    this.currentZoom = 1.0,
    required this.onZoomChanged,
    this.minZoom = 1.0,
    this.maxZoom = 4.0,
  });

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _enterController;
  late Animation<double> _enterAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _enterAnim = CurvedAnimation(
        parent: _enterController, curve: const Cubic(0.2, 0.0, 0.0, 1.0));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _enterController, curve: const Cubic(0.2, 0.0, 0.0, 1.0)),
    );
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Floating shelf logic: We wrap in a glass container with padding around.
    return FadeTransition(
      opacity: _enterAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: IOSGlassContainer(
            opacity: AppColors.opGlassMin,
            borderRadius: 32,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Torch Toggle (Small, centered above zoom)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IOSScaleButton(
                    onPressed: widget.onTorchToggle,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: widget.isTorchOn
                            ? AppColors.textPrimary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isTorchOn
                              ? AppColors.accentGreen
                              : Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        widget.isTorchOn
                            ? Icons.flashlight_on
                            : Icons.flashlight_off,
                        color: widget.isTorchOn
                            ? AppColors.accentGreen
                            : Colors.white.withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ),
                  ),
                ),

                // Zoom Controls
                _ZoomSelector(
                  currentZoom: widget.currentZoom,
                  onZoomChanged: widget.onZoomChanged,
                  minZoom: widget.minZoom,
                  maxZoom: widget.maxZoom,
                ),

                const SizedBox(height: 24),

                // Main Controls Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Thumbnail (Left)
                    _Thumbnail(
                      photo: widget.lastPhoto,
                      onTap: widget.onThumbnailTap,
                    ),

                    // Shutter (Center)
                    _ShutterButton(onTap: widget.onShutterTap),

                    // Mode Toggle (Right)
                    _ModeToggle(
                      isAiMode: widget.isAiMode,
                      onToggle: widget.onAiToggle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomSelector extends StatelessWidget {
  final double currentZoom;
  final Function(double) onZoomChanged;
  final double minZoom;
  final double maxZoom;

  const _ZoomSelector({
    required this.currentZoom,
    required this.onZoomChanged,
    required this.minZoom,
    required this.maxZoom,
  });

  @override
  Widget build(BuildContext context) {
    final List<double> levels = [0.5, 1.0, 2.0, 4.0];
    final validLevels =
        levels.where((z) => z >= minZoom && z <= maxZoom || z == 1.0).toList();
    if (validLevels.isEmpty) validLevels.add(1.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: validLevels.map((zoom) {
        final bool isSelected = (currentZoom - zoom).abs() < 0.1;
        return IOSScaleButton(
          pressedScale: 0.97,
          onPressed: () => onZoomChanged(zoom),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${zoom.toStringAsFixed(zoom == zoom.toInt() ? 0 : 1)}x",
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textPrimary.withValues(alpha: 0.4),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                    fontFamily: 'Roboto', // Or system default
                  ),
                ),
                // Green underline for active state
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.only(top: 4),
                  width: isSelected ? 16 : 0,
                  height: 2,
                  decoration: const BoxDecoration(
                    color: AppColors.accentGreen,
                    borderRadius: BorderRadius.all(Radius.circular(1)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ShutterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Ceramic White Ring
    return IOSScaleButton(
      onPressed: onTap,
      pressedScale: 0.97, // Specific for shutter
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            // Inner shadow simulation via gradient or minimal box shadow?
            // Apple style is clean. Recessed feel.
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 2,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            )
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white, // Ceramic White center for "Take Photo"
            // For SmartReview/AI mode usually shutter is white.
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final File? photo;
  final VoidCallback? onTap;

  const _Thumbnail({this.photo, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IOSScaleButton(
      onPressed: onTap ?? () {},
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6), // Slightly more rounded
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
          color: const Color(0xFF1C1C1E),
        ),
        child: photo != null && photo!.existsSync()
            ? ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.file(photo!, fit: BoxFit.cover),
              )
            : Icon(
                Icons.image_outlined,
                color: Colors.white.withValues(alpha: 0.3),
                size: 20,
              ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isAiMode;
  final VoidCallback onToggle;

  const _ModeToggle({required this.isAiMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return IOSScaleButton(
      onPressed: onToggle,
      child: IOSGlassContainer(
        opacity: 0.1,
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _modeLabel("FAST", !isAiMode),
            _modeLabel("AI", isAiMode),
          ],
        ),
      ),
    );
  }

  Widget _modeLabel(String text, bool active) {
    // Opacity shift only, no slide
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: active ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: active
            ? BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
