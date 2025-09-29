import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // ✅ Lắng nghe khi host thay đổi
  static ValueNotifier<String> hostNotifier = ValueNotifier<String>(
    'http://192.168.0.113:5000', // Đặt IP LAN máy bạn ở đây
  );

  static const _hostKey = 'api_host';

  // ✅ Khởi tạo, load host từ SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString(_hostKey);
    if (host != null) {
      hostNotifier.value = host;
    }
  }

  // ✅ Lưu host mới
  static Future<void> setHost(String host) async {
    hostNotifier.value = host;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, host);
  }

  // ✅ Lấy host hiện tại
  static String get host => hostNotifier.value;

  // ✅ Base URL API
  static String get apiBase => '$host/api';
}
