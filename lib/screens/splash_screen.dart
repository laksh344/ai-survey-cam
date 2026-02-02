import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'v${packageInfo.version}+${packageInfo.buildNumber}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Match native launch background
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Centered Logo
            Center(
              child: Container(
                width: 120, // Approximate size
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24), // iOS-style rounded
                  // Use the icon from assets
                  image: const DecorationImage(
                    image: AssetImage('assets/icon_foreground.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Bottom Branding
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SurveyCam ${_version.isEmpty ? "v1.0.0+1" : _version}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500, // Slightly bold
                    fontFamily: 'Roboto', // Clean font
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Made In India',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 32), // Bottom padding
              ],
            ),
          ],
        ),
      ),
    );
  }
}
