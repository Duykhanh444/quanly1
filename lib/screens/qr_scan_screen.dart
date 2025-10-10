import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as scanner;
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:image_picker/image_picker.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final scanner.MobileScannerController _controller =
      scanner.MobileScannerController(
        detectionSpeed: scanner.DetectionSpeed.noDuplicates,
        facing: scanner.CameraFacing.back,
        formats: [scanner.BarcodeFormat.all],
      );

  final Set<String> _daQuet = {}; // tránh quét trùng
  final List<Map<String, dynamic>> _khoTam = []; // danh sách kho quét được
  bool _dangGui = false;

  /// 🧩 Phân tích dữ liệu từ mã QR
  Map<String, dynamic> _phanTichQR(String value) {
    try {
      if (value.trim().startsWith('{') && value.trim().endsWith('}')) {
        return jsonDecode(value);
      } else if (value.contains('=')) {
        return Uri.splitQueryString(value);
      } else {
        return {'tenKho': value};
      }
    } catch (_) {
      return {'tenKho': value};
    }
  }

  /// 📦 Xử lý khi phát hiện mã
  Future<void> _xuLyMa(String value) async {
    if (_daQuet.contains(value)) return; // tránh quét trùng
    _daQuet.add(value);

    final decoded = _phanTichQR(value);
    final String tenKho = decoded['tenKho'] ?? decoded['tenHang'] ?? 'Không rõ';
    final double giaTri =
        double.tryParse(
          decoded['giaTri']?.toString() ?? decoded['gia']?.toString() ?? '0',
        ) ??
        0;
    final String ghiChu = decoded['ghiChu'] ?? 'Nhập từ QR';
    final String? maDonHang = decoded['maDonHang'] ?? decoded['id']?.toString();

    final kho = {
      "tenKho": tenKho,
      "giaTri": giaTri,
      "ghiChu": ghiChu,
      "ngayNhap": DateTime.now().toIso8601String(),
      "trangThai": "Hoạt động",
      if (maDonHang != null) "maDonHang": maDonHang,
    };

    setState(() => _khoTam.add(kho));

    // 🧠 Gọi API ngay sau khi quét xong (tự tạo kho)
    try {
      final ok = await ApiService.themHoacSuaKhoHangJson(kho);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Tạo kho mới: $tenKho (${giaTri.toStringAsFixed(0)}đ)",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception("Lỗi API");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Không thể tạo kho: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// 🚀 Gửi tất cả kho đã quét lên API
  Future<void> _guiTatCa() async {
    if (_dangGui || _khoTam.isEmpty) return;
    setState(() => _dangGui = true);

    int thanhCong = 0;
    for (var kho in _khoTam) {
      final ok = await ApiService.themHoacSuaKhoHangJson(kho);
      if (ok) thanhCong++;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "✅ Đã gửi $thanhCong / ${_khoTam.length} kho hàng thành công!",
        ),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _khoTam.clear();
      _daQuet.clear();
      _dangGui = false;
    });
  }

  /// 🖼️ Quét mã QR từ ảnh tải lên
  Future<void> _quetTuAnh() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    try {
      // ✅ Giải mã QR từ ảnh
      final value = await QrCodeToolsPlugin.decodeFrom(image.path);

      if (value != null && value.isNotEmpty) {
        await _xuLyMa(value);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("📸 Quét được từ ảnh: $value")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Không phát hiện mã QR trong ảnh")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ Lỗi khi quét ảnh: $e")));
    }
  }

  // =================== GIAO DIỆN ===================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📦 Quét mã để thêm nhiều kho hàng"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: "Quét từ ảnh",
            onPressed: _quetTuAnh,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Làm mới",
            onPressed: () {
              setState(() {
                _daQuet.clear();
                _khoTam.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🔄 Đã làm mới danh sách.")),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          scanner.MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final value = barcode.rawValue;
                if (value != null) _xuLyMa(value);
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '➡️ Di chuyển camera qua mã hoặc chọn ảnh QR để quét',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.cloud_upload),
        label: Text(_dangGui ? "Đang gửi..." : "Gửi tất cả"),
        onPressed: _dangGui ? null : _guiTatCa,
      ),
      bottomNavigationBar: _khoTam.isNotEmpty
          ? Container(
              color: Colors.teal.shade50,
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "📋 ${_khoTam.length} mã đã quét",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      itemCount: _khoTam.length,
                      itemBuilder: (context, index) {
                        final kho = _khoTam[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            "• ${kho["tenKho"]} - ${kho["giaTri"]}đ",
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
