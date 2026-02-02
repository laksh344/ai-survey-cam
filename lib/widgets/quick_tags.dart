import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../logic/file_manager.dart';
import 'ui/ios_glass_container.dart';
import 'ui/ios_scale_button.dart';

/// Right-edge vertical status tag selector (Etched Glass Capsules)
class StatusTagSelector extends StatefulWidget {
  const StatusTagSelector({super.key});

  @override
  State<StatusTagSelector> createState() => _StatusTagSelectorState();
}

class _StatusTagSelectorState extends State<StatusTagSelector> {
  String? _selectedTag;

  void _selectTag(String tag) {
    setState(() {
      if (_selectedTag == tag) {
        _selectedTag = null;
        FileManager.setNextPhotoTag(''); // Clear tag
      } else {
        _selectedTag = tag;
        FileManager.setNextPhotoTag(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildGlassPill(Constants.tagBad, AppColors.tagBad),
          const SizedBox(height: 16),
          _buildGlassPill(Constants.tagGood, AppColors.tagGood),
          const SizedBox(height: 16),
          _buildGlassPill(Constants.tagFix, AppColors.tagFix),
        ],
      ),
    );
  }

  Widget _buildGlassPill(String tag, Color color) {
    final bool isSelected = _selectedTag == tag;

    // "Inner green glow (≤12%)" - We simulate this by changing the glass opacity
    final double glassOpacity = isSelected ? 0.12 : 0.06;

    return IOSScaleButton(
      onPressed: () {
        // Haptic handled by IOSScaleButton, but logic here
        // Wait, IOSScaleButton triggers haptic on press.
        // We might want state change haptic confirm?
        // Plan says: "Toggle / Zoom: Selection click". IOSScaleButton does selectionClick.
        _selectTag(tag);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        // We wrap IOSGlassContainer logic here or use it directly?
        // IOSGlassContainer has fixed white/blur logic.
        // We need custom color tint for the "Glow".
        // Let's modify IOSGlassContainer usage or just build custom for this specific glow needs?
        // Actually IOSGlassContainer takes a child. The glow is the background.
        // Let's us IOSGlassContainer but maybe we need a colored version?
        // For now, let's stick to the plan: "Etched glass capsules".
        // Use IOSGlassContainer as base, maybe wrap in container for the border color change?
        child: IOSGlassContainer(
          borderRadius: 20,
          opacity: glassOpacity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          // We can't easily change the IOSGlassContainer color to green dynamically without modifying it.
          // Let's assume white frosted is fine, and we use the border/text for color.
          // OR, strict interpretation: "Capsule fills with soft glass highlight".
          // Let's just use the IOSGlassContainer and rely on the content/border.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 120),
                style: TextStyle(
                  color: isSelected
                      ? color
                      : AppColors.textPrimary.withValues(alpha: 0.4),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontFamily: 'Roboto',
                ),
                child: Text(tag.toUpperCase()),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check,
                  color: color,
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
