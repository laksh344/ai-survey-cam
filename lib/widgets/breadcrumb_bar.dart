import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../logic/file_manager.dart';
import 'ui/ios_glass_container.dart';
import 'ui/ios_scale_button.dart';

/// Transparent top control bar with breadcrumbs and actions
class TopControlBar extends StatelessWidget {
  final VoidCallback onFolderTap;
  final VoidCallback onSettingsTap;
  final VoidCallback? onGridTap;
  final Function(int index)? onBreadcrumbTap;

  const TopControlBar({
    super.key,
    required this.onFolderTap,
    required this.onSettingsTap,
    this.onGridTap,
    this.onBreadcrumbTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> paths = FileManager.getBreadcrumbPath();

    // No solid container. Chips float.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Left: Folder Icon (Glass Chip)
            IOSScaleButton(
              onPressed: onFolderTap,
              child: IOSGlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(8),
                opacity: 0.1,
                child: const Icon(Icons.folder_open_rounded,
                    color: Colors.white, size: 20),
              ),
            ),

            const SizedBox(width: 8),

            // Grid View Icon (Glass Chip)
            IOSScaleButton(
              onPressed: onGridTap ?? () {},
              child: IOSGlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(8),
                opacity: 0.1,
                child: const Icon(Icons.grid_view_rounded,
                    color: Colors.white, size: 20),
              ),
            ),

            const SizedBox(width: 8),

            // Center: Interactive Breadcrumb Path
            Expanded(
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: paths.length,
                  separatorBuilder: (context, index) => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.chevron_right,
                          size: 14, color: Colors.white38),
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final bool isLast = index == paths.length - 1;
                    return IOSScaleButton(
                      onPressed: () => onBreadcrumbTap?.call(index),
                      pressedScale: 0.97,
                      child: _BreadcrumbSegment(
                        text: paths[index],
                        isLast: isLast,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Right: Settings Icon (Glass Chip)
            IOSScaleButton(
              onPressed: onSettingsTap,
              child: IOSGlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(8),
                opacity: 0.1,
                child: const Icon(Icons.settings_outlined,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreadcrumbSegment extends StatelessWidget {
  final String text;
  final bool isLast;

  const _BreadcrumbSegment({required this.text, required this.isLast});

  @override
  Widget build(BuildContext context) {
    // Each segment is a small glass chip or just text on glass?
    // Plan: "Each breadcrumb segment wrapped in small IOSGlassContainer"
    return IOSGlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      opacity: isLast ? 0.12 : 0.05, // Active is brighter
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) {
            // Slide transition logic could go here if we tracked direction
            // For now, simpler fade is cleaner for simple implementation
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            text,
            key: ValueKey(text),
            style: TextStyle(
              color: isLast
                  ? AppColors.textPrimary
                  : AppColors.textPrimary.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ),
    );
  }
}
