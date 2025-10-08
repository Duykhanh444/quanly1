import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRBulkGenerateScreen extends StatefulWidget {
  final List<Map<String, dynamic>> danhSachHang;

  const QRBulkGenerateScreen({super.key, required this.danhSachHang});

  @override
  State<QRBulkGenerateScreen> createState() => _QRBulkGenerateScreenState();
}

class _QRBulkGenerateScreenState extends State<QRBulkGenerateScreen> {
  bool _isGenerating = false;

  Future<void> _generatePdf() async {
    setState(() => _isGenerating = true);

    final pdf = pw.Document();

    for (var hang in widget.danhSachHang) {
      final qrData =
          "tenHang=${Uri.encodeComponent(hang['tenHang'])}&giaTri=${hang['giaTri']}&soLuong=${hang['soLuong']}&ghiChu=${Uri.encodeComponent(hang['ghiChu'] ?? '')}";

      final qrImage = await QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
      ).toImageData(300);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    hang['tenHang'],
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Image(
                    pw.MemoryImage(qrImage!.buffer.asUint8List()),
                    width: 150,
                    height: 150,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text("Giá trị: ${hang['giaTri']} đ"),
                  pw.Text("Số lượng: ${hang['soLuong']}"),
                  if (hang['ghiChu'] != null &&
                      hang['ghiChu'].toString().isNotEmpty)
                    pw.Text("Ghi chú: ${hang['ghiChu']}"),
                ],
              ),
            );
          },
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/ma_qr_hang_hoa.pdf");
    await file.writeAsBytes(await pdf.save());

    setState(() => _isGenerating = false);

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'ma_qr_hang_hoa.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🧾 In mã QR hàng hóa")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Danh sách hàng hóa sẽ được in mã QR:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: widget.danhSachHang.length,
                itemBuilder: (context, index) {
                  final hang = widget.danhSachHang[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.inventory),
                      title: Text(hang['tenHang']),
                      subtitle: Text(
                        "Giá: ${hang['giaTri']} đ | SL: ${hang['soLuong']}\nGhi chú: ${hang['ghiChu']}",
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(
                _isGenerating ? "Đang tạo PDF..." : "Tạo file PDF mã QR",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
