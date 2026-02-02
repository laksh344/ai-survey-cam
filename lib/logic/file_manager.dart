import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';

/// Manages file system operations: folders, photos, and asset data
/// Migrated to Public External Storage (Pictures)
class FileManager {
  static Directory? _rootDirectory;
  static Directory? _currentDirectory;
  static String? _nextPhotoTag;

  /// Initialize root directory
  static Future<Directory> getRootDirectory() async {
    if (_rootDirectory != null && await _rootDirectory!.exists()) {
      return _rootDirectory!;
    }

    // Migration to Public Pictures Directory
    final String picturesPath =
        await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_PICTURES);
    _rootDirectory = Directory('$picturesPath/${Constants.rootFolderName}');

    if (!await _rootDirectory!.exists()) {
      await _rootDirectory!.create(recursive: true);
    }

    _currentDirectory = _rootDirectory;
    return _rootDirectory!;
  }

  /// Get current working directory
  static Directory getCurrentDirectory() {
    return _currentDirectory ?? _rootDirectory ?? Directory('');
  }

  /// Set current directory
  static void setCurrentDirectory(Directory dir) {
    _currentDirectory = dir;
  }

  /// Create a new folder in the current directory
  static Future<Directory> createFolder(String folderName) async {
    final Directory current = getCurrentDirectory();
    final Directory newFolder = Directory('${current.path}/$folderName');

    if (!await newFolder.exists()) {
      await newFolder.create(recursive: true);
    }

    return newFolder;
  }

  /// Navigate to a parent directory
  static bool navigateToParent() {
    if (_currentDirectory == null || _rootDirectory == null) return false;

    final String currentPath = _currentDirectory!.path;
    final String rootPath = _rootDirectory!.path;

    if (currentPath == rootPath) return false; // Already at root

    final Directory parent = _currentDirectory!.parent;
    if (parent.path.length >= rootPath.length) {
      _currentDirectory = parent;
      return true;
    }

    return false;
  }

  /// Get breadcrumb path as list of folder names
  static List<String> getBreadcrumbPath() {
    if (_rootDirectory == null || _currentDirectory == null) {
      return ['Home'];
    }

    final String rootPath = _rootDirectory!.path;
    final String currentPath = _currentDirectory!.path;

    if (currentPath == rootPath) {
      return ['Home'];
    }

    // Safe substring in case paths don't match (e.g. initial load race)
    if (!currentPath.startsWith(rootPath)) return ['Home'];

    final String relativePath = currentPath.substring(rootPath.length + 1);
    final List<String> parts = relativePath.split(Platform.pathSeparator);
    return ['Home', ...parts];
  }

  /// Get directory for a breadcrumb index (for navigation)
  static Directory? getDirectoryForBreadcrumb(int index) {
    if (_rootDirectory == null) return null;

    final List<String> breadcrumbs = getBreadcrumbPath();
    if (index < 0 || index >= breadcrumbs.length) return null;

    if (index == 0) return _rootDirectory;

    final List<String> pathParts = breadcrumbs.sublist(1, index + 1);
    final String path =
        '${_rootDirectory!.path}/${pathParts.join(Platform.pathSeparator)}';
    return Directory(path);
  }

  /// Save photo to current directory
  static Future<File> savePhoto(List<int> imageBytes,
      {String? customName}) async {
    final Directory current = getCurrentDirectory();
    final String timestamp =
        DateFormat(Constants.dateFormat).format(DateTime.now());

    String fileName;
    if (customName != null) {
      fileName = customName;
    } else {
      final String tag = _nextPhotoTag ?? '';
      fileName = '$timestamp${tag.isNotEmpty ? "_$tag" : ""}.jpg';
    }

    final File photoFile = File('${current.path}/$fileName');
    await photoFile.writeAsBytes(imageBytes);

    // Clear tag after use
    _nextPhotoTag = null;

    // NOTE: In a real app, you would assume OS MediaStore picks this up,
    // or use a MediaScanner plugin to force a scan so it appears in Gallery immediately.
    // print('Saved to Public Storage: ${photoFile.path}');

    return photoFile;
  }

  /// Set tag for next photo
  static void setNextPhotoTag(String tag) {
    _nextPhotoTag = tag;
  }

  /// Get tag for next photo
  static String? getNextPhotoTag() {
    return _nextPhotoTag;
  }

  /// Append text to Asset_Data.txt in current directory
  static Future<void> appendToAssetData(String text) async {
    final Directory current = getCurrentDirectory();
    final File assetFile =
        File('${current.path}/${Constants.assetDataFileName}');

    final String timestamp =
        DateFormat(Constants.dateFormat).format(DateTime.now());
    final String entry = '$timestamp: $text\n';

    await assetFile.writeAsString(entry, mode: FileMode.append);
  }

  /// Get last photo in current directory
  static Future<File?> getLastPhoto() async {
    final Directory current = getCurrentDirectory();

    if (!await current.exists()) return null;

    final List<FileSystemEntity> entities = current.listSync();
    final List<File> photos = entities
        .whereType<File>()
        .where((file) =>
            file.path.toLowerCase().endsWith('.jpg') ||
            file.path.toLowerCase().endsWith('.jpeg'))
        .toList();

    if (photos.isEmpty) return null;

    // Sort by modification time, newest first
    photos
        .sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    return photos.first;
  }

  /// List all folders in current directory
  static Future<List<Directory>> listFolders() async {
    final Directory current = getCurrentDirectory();

    if (!await current.exists()) return [];

    final List<FileSystemEntity> entities = current.listSync();
    return entities.whereType<Directory>().toList();
  }
}
