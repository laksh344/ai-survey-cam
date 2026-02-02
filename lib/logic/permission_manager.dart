import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Manages app permissions (Camera, Storage, Microphone)
class PermissionManager {
  /// Request all required permissions
  static Future<bool> requestAllPermissions() async {
    final List<Permission> permissions = [
      Permission.camera,
      Permission.microphone,
    ];

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        permissions.add(Permission.manageExternalStorage);
      } else {
        permissions.add(Permission.storage);
      }
    }

    final Map<Permission, PermissionStatus> statuses =
        await permissions.request();

    // Check if all permissions are granted
    bool allGranted = true;
    for (final PermissionStatus status in statuses.values) {
      if (!status.isGranted) {
        allGranted = false;
        break;
      }
    }

    return allGranted;
  }

  /// Check if camera permission is granted
  static Future<bool> isCameraGranted() async {
    return await Permission.camera.isGranted;
  }

  /// Check if storage permission is granted
  static Future<bool> isStorageGranted() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        return await Permission.manageExternalStorage.isGranted;
      }
    }
    return await Permission.storage.isGranted;
  }

  /// Check if microphone permission is granted
  static Future<bool> isMicrophoneGranted() async {
    return await Permission.microphone.isGranted;
  }
}
