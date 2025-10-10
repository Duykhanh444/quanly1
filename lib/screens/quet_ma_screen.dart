import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile_scanner;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as mlkit;

class QuetMaScreen extends StatefulWidget {
  const QuetMaScreen({super.key});

  @override
  State<QuetMaScreen> createState() => _QuetMaScreenState();
}

class _QuetMaScreenState extends State<QuetMaScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> scannedCodes = []; // Danh sách mã đã quét
  String? lastScanned; // Lưu mã vừa quét để highlight

  // Quét từ ảnh gallery
  Future<void> _pickImageAndScan() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final inputImage = mlkit.InputImage.fromFilePath(image.path);
      final barcodeScanner = mlkit.BarcodeScanner();

      final List<mlkit.Barcode> barcodes = await barcodeScanner.processImage(
        inputImage,
      );

      for (var barcode in barcodes) {
        final value = barcode.rawValue;
        if (value != null && value.isNotEmpty) {
          if (!scannedCodes.contains(value)) {
            setState(() {
              scannedCodes.add(value);
              _flashHighlight(value);
            });
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Mã $value đã tồn tại!")));
          }
        }
      }

      if (barcodes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Không tìm thấy mã QR/barcode trong ảnh."),
          ),
        );
      }

      barcodeScanner.close();
    }
  }

  // Quét từ camera
  void _onDetect(mobile_scanner.BarcodeCapture capture) {
    final barcode = capture.barcodes.first;
    final value = barcode.rawValue;
    if (value != null && value.isNotEmpty) {
      if (!scannedCodes.contains(value)) {
        setState(() {
          scannedCodes.add(value);
          _flashHighlight(value);
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Mã $value đã tồn tại!")));
      }
    }
  }

  // Highlight tạm thời mã vừa quét
  void _flashHighlight(String code) {
    setState(() {
      lastScanned = code;
    });
    Timer(const Duration(seconds: 2), () {
      setState(() {
        if (lastScanned == code) lastScanned = null;
      });
    });
  }

  // Xóa mã khỏi danh sách
  void _removeCode(String code) {
    setState(() {
      scannedCodes.remove(code);
      if (lastScanned == code) lastScanned = null;
    });
  }

  // Xác nhận và trả về danh sách
  void _confirmScan() {
    Navigator.pop(context, scannedCodes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quét nhiều hóa đơn"),
        backgroundColor: const Color(0xFF4A00E0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _pickImageAndScan,
            tooltip: "Tải ảnh lên để quét",
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmScan,
            tooltip: "Xác nhận",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                mobile_scanner.MobileScanner(onDetect: _onDetect),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment(0, 0.7),
                  child: Text(
                    "Đưa mã QR hoặc barcode vào khung",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: ListView.builder(
                itemCount: scannedCodes.length,
                itemBuilder: (context, index) {
                  final code = scannedCodes[index];
                  final isHighlighted = code == lastScanned;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    color: isHighlighted
                        ? Colors.greenAccent
                        : Colors.transparent,
                    child: ListTile(
                      title: Text(code),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeCode(code),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
