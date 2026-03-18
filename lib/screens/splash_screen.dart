import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/main_services.dart';
import 'package:danet/screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4().toUpperCase();
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }

  Future<void> _checkVersion() async {
    try {
      String deviceId = await _getDeviceId();
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentVersion =
          int.tryParse(packageInfo.version.replaceAll('.', '')) ?? 0;

      final latestData = await _services.getLatestRelease(deviceId);
      if (latestData == null) throw Exception("Không thể kết nối API");

      int latestVersion = latestData['version'];
      // int latestVersion = 6406;
      int isRequired = latestData['is_required'] ?? 0;
      // int isRequired = 1;
      bool versionExists = await _services.checkVersionExists(
        currentVersion,
        deviceId,
      );

      if (currentVersion == latestVersion ||
          (currentVersion > latestVersion && versionExists)) {
        _fetchMenuAndGoHome(deviceId);
      } else if (currentVersion < latestVersion) {
        if (!versionExists) {
          _showPopup(
            "Phiên bản không hợp lệ",
            exitOnly: true,
            deviceId: deviceId,
          );
        } else {
          _showPopup(
            "Đã có phiên bản mới, bạn vui lòng nâng cấp ứng dụng nhé!",
            exitOnly: (isRequired == 1),
            deviceId: deviceId,
          );
        }
      } else {
        _showPopup(
          "Phiên bản không hợp lệ",
          exitOnly: true,
          deviceId: deviceId,
        );
      }
    } catch (e) {
      _showPopup("Lỗi hệ thống: $e", exitOnly: true, deviceId: "");
    }
  }

  Future<void> _fetchMenuAndGoHome(String deviceId) async {
    try {
      final items = await _services.getMenu(deviceId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(menuItems: items, deviceId: deviceId),
        ),
      );
    } catch (e) {
      debugPrint("Lỗi lấy menu: $e");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(menuItems: [], deviceId: ""),
        ),
      );
    }
  }

  void _showPopup(
    String message, {
    required bool exitOnly,
    required String deviceId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Thông báo"),
        content: Text(message),
        actions: [
          if (!exitOnly)
            TextButton(
              onPressed: () => _fetchMenuAndGoHome(deviceId),
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
