import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/app_colors.dart';
import 'logic/permission_manager.dart';
import 'logic/file_manager.dart';
import 'screens/camera_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize file system
  await FileManager.getRootDirectory();

  runApp(const SurveyorCamApp());
}

class SurveyorCamApp extends StatelessWidget {
  const SurveyorCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Surveyor Cam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.accentGreen,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.accentGreen,
          selectionColor: AppColors.activeGreenBG,
          selectionHandleColor: AppColors.accentGreen,
        ),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentGreen,
          surface: AppColors.background, // Match background for matte look
          onSurface: AppColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          toolbarHeight: 48,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        fontFamily: 'Roboto', // Or system font
      ),
      home: const PermissionCheckScreen(),
    );
  }
}

/// Screen that checks permissions before showing camera
class PermissionCheckScreen extends StatefulWidget {
  const PermissionCheckScreen({super.key});

  @override
  State<PermissionCheckScreen> createState() => _PermissionCheckScreenState();
}

class _PermissionCheckScreenState extends State<PermissionCheckScreen> {
  bool _isChecking = true;
  bool _hasPermissions = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    // Ensure splash is seen for at least 2 seconds
    await Future.delayed(const Duration(milliseconds: 2000));

    // Check if permissions are already granted
    final bool cameraGranted = await PermissionManager.isCameraGranted();
    final bool storageGranted = await PermissionManager.isStorageGranted();

    if (cameraGranted && storageGranted) {
      if (mounted) {
        setState(() {
          _hasPermissions = true;
          _isChecking = false;
        });
      }
      return;
    }

    // Request permissions
    final bool allGranted = await PermissionManager.requestAllPermissions();

    if (mounted) {
      setState(() {
        _hasPermissions = allGranted;
        _isChecking = false;

        if (!allGranted) {
          _errorMessage =
              'Camera and storage permissions are required to use this app.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const SplashScreen();
    }

    if (!_hasPermissions) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage ?? 'Permissions Required',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please grant camera and storage permissions to continue.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _checkPermissions();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Grant Permissions',
                    style: TextStyle(
                      color: AppColors.background,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    openAppSettings();
                  },
                  child: const Text(
                    'Open Settings',
                    style: TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const CameraScreen();
  }
}
