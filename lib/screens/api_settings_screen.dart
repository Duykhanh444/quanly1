import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quan_ly_xuong/api_config.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = ApiConfig.host; // gán sẵn host hiện tại
  }

  Future<void> _saveHost(String newHost) async {
    final trimmed = newHost.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập host hợp lệ")),
      );
      return;
    }

    await ApiConfig.setHost(trimmed);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Đã lưu API host thành công")),
      );
      Navigator.pop(context);
    }
  }

  void _openQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _QrScannerScreen()),
    ).then((scanned) {
      if (scanned != null && scanned is String && scanned.isNotEmpty) {
        _controller.text = scanned;
        _saveHost(scanned);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt API"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: "Quét QR",
            onPressed: _openQrScanner,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nhập địa chỉ API server (ví dụ: http://192.168.0.113:5242)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "http://192.168.x.x:5242",
                prefixIcon: Icon(Icons.cloud),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _saveHost(_controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.save),
              label: const Text("Lưu API Host", style: TextStyle(fontSize: 18)),
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
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- màn hình quét QR code ---
class _QrScannerScreen extends StatelessWidget {
  const _QrScannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quét QR API"),
        backgroundColor: Colors.teal,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final raw = barcodes.first.rawValue;
            if (raw != null && raw.isNotEmpty) {
              Navigator.pop(context, raw); // trả về link quét được
            }
          }
        },
      ),
    );
  }
}
