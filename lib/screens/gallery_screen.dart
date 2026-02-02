import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../core/app_colors.dart';
import 'photo_preview_screen.dart';
import '../widgets/ui/ios_page_route.dart';
import '../widgets/ui/ios_scale_button.dart';

class GalleryScreen extends StatelessWidget {
  final Directory currentDirectory;

  const GalleryScreen({required this.currentDirectory, super.key});

  Future<List<FileSystemEntity>> _loadPhotos() async {
    if (!currentDirectory.existsSync()) return [];

    final List<FileSystemEntity> files = currentDirectory.listSync();

    // Filter for images
    final List<FileSystemEntity> images = files.where((file) {
      if (file is File) {
        final String path = file.path.toLowerCase();
        return path.endsWith('.jpg') ||
            path.endsWith('.jpeg') ||
            path.endsWith('.png');
      }
      return false;
    }).toList();

    // Sort by Last Modified DESC (Newest first)
    images.sort((a, b) {
      return b.statSync().modified.compareTo(a.statSync().modified);
    });

    return images;
  }

  @override
  Widget build(BuildContext context) {
    // Extract folder name for title
    final String folderName =
        currentDirectory.path.split(Platform.pathSeparator).last;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          folderName,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: Center(
          child: IOSScaleButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
        ),
      ),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: _loadPhotos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accentGreen));
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white)));
          }

          final List<FileSystemEntity>? files = snapshot.data;

          if (files == null || files.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No photos in this folder",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final File file = files[index] as File;
              return RepaintBoundary(
                child: IOSScaleButton(
                  pressedScale: 0.97,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      IOSPageRoute(
                        builder: (context) => PhotoPreviewScreen(
                          photoFile: file,
                          heroTag: file.path,
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: file.path,
                    child: Image.file(
                      file,
                      cacheWidth: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
