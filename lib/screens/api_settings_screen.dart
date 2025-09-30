import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quan_ly_xuong/api_config.dart';
import 'package:http/http.dart' as http;

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _controller.text = ApiConfig.host;
  }

  /// 🔹 Kiểm tra kết nối server
  Future<void> _checkConnection(String host) async {
    String trimmed = host.trim();

    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập host hợp lệ")),
      );
      return;
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }

    setState(() => _checking = true);

    try {
      final uri = Uri.parse('$trimmed/api/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ Kết nối thành công")));
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Không tìm thấy endpoint /api/health (404)"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ Server phản hồi lỗi: ${response.statusCode}"),
          ),
        );
      }
    } on TimeoutException {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ Hết thời gian kết nối")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Không thể kết nối tới server: $e")),
      );
    } finally {
      setState(() => _checking = false);
    }
  }

  /// 🔹 Lưu host
  Future<void> _saveHost(String host) async {
    String trimmed = host.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    await ApiConfig.setHost(trimmed);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Đã lưu host thành công")));
    }
  }

  /// 🔹 Mở QR scanner
  void _openQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _QrScannerScreen()),
    ).then((scanned) {
      if (scanned != null && scanned is String && scanned.isNotEmpty) {
        _controller.text = scanned;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color mainColor1 = Color(0xFF4A00E0);
    const Color mainColor2 = Color(0xFF8E2DE2);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt API"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [mainColor1, mainColor2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: "Quét QR",
            onPressed: _openQrScanner,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nhập địa chỉ API server (ví dụ: 10.0.2.2:5000 hoặc 192.168.x.x:5000)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "http://192.168.x.x:5000",
                prefixIcon: Icon(Icons.cloud),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checking
                        ? null
                        : () => _checkConnection(_controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor1,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: _checking
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.wifi),
                    label: Text(
                      _checking ? "Đang kiểm tra..." : "Kiểm tra kết nối",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _saveHost(_controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor2,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text(
                      "Lưu host",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              "Host hiện tại:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ValueListenableBuilder<String>(
              valueListenable: ApiConfig.hostNotifier,
              builder: (context, value, _) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: mainColor1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrScannerScreen extends StatelessWidget {
  const _QrScannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color mainColor1 = Color(0xFF4A00E0);
    const Color mainColor2 = Color(0xFF8E2DE2);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quét QR API"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [mainColor1, mainColor2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final raw = barcodes.first.rawValue;
            if (raw != null && raw.isNotEmpty) {
              Navigator.pop(context, raw);
            }
          }
        },
      ),
    );
  }
}
