import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/main_services.dart';
import 'package:danet/screens/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final MainServices _services = MainServices();

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentVersion =
          int.tryParse(packageInfo.version.replaceAll('.', '')) ?? 0;

      final latestData = await _services.getLatestRelease();
      if (latestData == null) throw Exception("Không thể kết nối API");

      int latestVersion = latestData['version'];
      int isRequired = latestData['is_required'] ?? 0;
      bool versionExists = await _services.checkVersion(currentVersion);

      if (currentVersion == latestVersion ||
          (currentVersion > latestVersion && versionExists)) {
        _fetchMenuAndGoHome();
      } else if (currentVersion < latestVersion) {
        if (!versionExists) {
          _showPopup("Phiên bản không hợp lệ", exitOnly: true);
        } else {
          _showPopup(
            "Đã có phiên bản mới, bạn vui lòng nâng cấp ứng dụng nhé!",
            exitOnly: (isRequired == 1),
          );
        }
      } else {
        _showPopup("Phiên bản không hợp lệ", exitOnly: true);
      }
    } catch (e) {
      _showPopup("Lỗi hệ thống: $e", exitOnly: true);
    }
  }

  Future<void> _fetchMenuAndGoHome() async {
    try {
      final items = await _services.getMenu();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(menuItems: items)),
      );
    } catch (e) {
      debugPrint("Lỗi lấy menu: $e");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage(menuItems: [])),
      );
    }
  }

  void _showPopup(String message, {required bool exitOnly}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Thông báo"),
        content: Text(message),
        actions: [
          if (!exitOnly)
            TextButton(
              onPressed: () => _fetchMenuAndGoHome(),
              child: const Text("Bỏ qua"),
            ),
          TextButton(
            onPressed: () => exit(0),
            child: const Text("OK", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
