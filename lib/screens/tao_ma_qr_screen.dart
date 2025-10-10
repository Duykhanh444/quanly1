import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import '../models/khohang.dart';
import '../services/api_service.dart';

class TaoMaQRScreen extends StatefulWidget {
  const TaoMaQRScreen({Key? key}) : super(key: key);

  @override
  State<TaoMaQRScreen> createState() => _TaoMaQRScreenState();
}

class _TaoMaQRScreenState extends State<TaoMaQRScreen> {
  // 📷 Quét QR từ ảnh
  Future<void> _quetQRAnh() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
      final inputImage = InputImage.fromFilePath(picked.path);
      final barcodes = await barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final value = barcodes.first.rawValue ?? "";

        try {
          final data = jsonDecode(value);
          final kho = KhoHang.fromJson({
            "id": 0,
            "tenKho": data["tenKho"],
            "giaTri": data["giaTri"],
            "ghiChu": data["ghiChu"],
            "trangThai": "Hoạt động",
            "ngayNhap": DateTime.now().toIso8601String(),
          });

          final result = await ApiService.themHoacSuaKhoHang(kho);
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Đã tạo kho hàng mới từ mã QR trong ảnh"),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("❌ Tạo kho hàng thất bại")),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("⚠️ Lỗi khi đọc dữ liệu QR: $e")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Không tìm thấy mã QR trong ảnh")),
        );
      }

      await barcodeScanner.close();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Lỗi khi đọc QR: $e")));
    }
  }

  // 🎥 Quét QR bằng camera
  void _quetQRCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _QRScanCameraScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tạo / Quét mã QR"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_2, size: 100, color: Colors.teal),
              const SizedBox(height: 20),
              const Text(
                "Chọn cách nhập kho bằng mã QR",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _quetQRCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Quét QR bằng Camera"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: _quetQRAnh,
                icon: const Icon(Icons.image_outlined),
                label: const Text("Quét QR từ ảnh trong máy"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  side: const BorderSide(color: Colors.teal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================
// 📸 Màn hình quét QR Camera
// ==========================
class _QRScanCameraScreen extends StatelessWidget {
  const _QRScanCameraScreen();

  Future<void> _handleQR(BuildContext context, String value) async {
    try {
      final data = jsonDecode(value);
      final kho = KhoHang.fromJson({
        "id": 0,
        "tenKho": data["tenKho"],
        "giaTri": data["giaTri"],
        "ghiChu": data["ghiChu"],
        "trangThai": "Hoạt động",
        "ngayNhap": DateTime.now().toIso8601String(),
      });

      final result = await ApiService.themHoacSuaKhoHang(kho);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã tạo kho hàng mới từ mã QR")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Tạo kho hàng thất bại")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ Lỗi khi xử lý QR: $e")));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ms.MobileScannerController();
    return Scaffold(
      appBar: AppBar(
        title: const Text("📷 Quét mã QR"),
        backgroundColor: Colors.teal,
      ),
      body: ms.MobileScanner(
        controller: controller,
        onDetect: (capture) async {
          final barcode = capture.barcodes.first;
          final value = barcode.rawValue;
          if (value != null && value.isNotEmpty) {
            await _handleQR(context, value);
          }
        },
      ),
    );
  }
}
