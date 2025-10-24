// lib/screens/chi_tiet_kho_hang_screen.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/notification_service.dart';
import '../utils/string_utils.dart';
import '../models/khohang.dart';
import '../models/hoadon.dart';
import '../models/hoadon_item.dart';
import '../services/api_service.dart';
import 'kho_hang_bill_screen.dart';

class ChiTietKhoHangScreen extends StatefulWidget {
  final KhoHang kho;
  const ChiTietKhoHangScreen({super.key, required this.kho});

  @override
  State<ChiTietKhoHangScreen> createState() => _ChiTietKhoHangScreenState();
}

class _ChiTietKhoHangScreenState extends State<ChiTietKhoHangScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) =>
      date == null ? "—" : DateFormat("dd-MM-yyyy").format(date);

  String _formatCurrency(double? value) {
    final formatter = NumberFormat.currency(
      locale: "vi_VN",
      symbol: "VND",
      decimalDigits: 0,
    );
    return formatter.format(value ?? 0);
  }

  int _tinhSoNgay(DateTime? start, DateTime? end) {
    if (start == null) return 0;
    final ngayKetThuc = end ?? DateTime.now();
    return ngayKetThuc.difference(start).inDays;
  }

  String _taoDuLieuQR() {
    final kho = widget.kho;
    final dataQR = Uri(
      queryParameters: {
        'tenHang': (kho.tenKho ?? '').toUnsignedVietnamese(),
        'giaTri': (kho.giaTri ?? 0).toString(),
        'ghiChu': (kho.ghiChu ?? '').toUnsignedVietnamese(),
        'soLuong': '1',
      },
    ).query;
    return dataQR;
  }

  Future<Uint8List> _taoFilePdf() async {
    final kho = widget.kho;
    final qrData = _taoDuLieuQR();
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final roboto = pw.Font.ttf(fontData);

    final qrPainter = QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: true,
    );
    final ui.Image qrImage = await qrPainter.toImage(300);
    final qrBytes = await qrImage.toByteData(format: ui.ImageByteFormat.png);
    final qrPng = qrBytes!.buffer.asUint8List();

    final barcode = Barcode.code128();
    final barcodeData = (kho.tenKho ?? '').toUnsignedVietnamese();
    final barcodeSvg = barcode.toSvg(
      barcodeData,
      width: 300,
      height: 80,
      drawText: true,
    );

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                "PHIẾU KHO HÀNG",
                style: pw.TextStyle(
                  font: roboto,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Tên hàng: ${kho.tenKho ?? ''}",
                style: pw.TextStyle(font: roboto),
              ),
              pw.Text(
                "Giá trị: ${_formatCurrency(kho.giaTri)}",
                style: pw.TextStyle(font: roboto),
              ),
              pw.Text(
                "Ghi chú: ${kho.ghiChu ?? ''}",
                style: pw.TextStyle(font: roboto),
              ),
              pw.Text(
                "Trạng thái: ${kho.trangThai ?? ''}",
                style: pw.TextStyle(font: roboto),
              ),
              pw.SizedBox(height: 20),
              pw.Image(pw.MemoryImage(qrPng), width: 180, height: 180),
              pw.SizedBox(height: 10),
              pw.SvgImage(svg: barcodeSvg),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> _inPDF(BuildContext context) async {
    try {
      final pdfBytes = await _taoFilePdf();
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Không thể in PDF: $e")));
    }
  }

  Future<void> _sharePDF(BuildContext context) async {
    try {
      final pdfBytes = await _taoFilePdf();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'phieu_kho_${widget.kho.id}.pdf',
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Không thể chia sẻ PDF: $e")));
    }
  }

  Future<void> _chonPhuongThucThanhToan(BuildContext context) async {
    final phuongThuc = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Chọn phương thức thanh toán"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.money, color: Colors.green),
              title: const Text("Tiền mặt"),
              onTap: () => Navigator.pop(ctx, "Tiền mặt"),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.blue),
              title: const Text("Chuyển khoản"),
              onTap: () => Navigator.pop(ctx, "Chuyển khoản"),
            ),
          ],
        ),
      ),
    );

    if (phuongThuc == null || !mounted) return;

    final hoaDon = HoaDon(
      maHoaDon: "PXK${DateTime.now().millisecondsSinceEpoch}",
      ngayLap: DateTime.now(),
      tongTien: (widget.kho.giaTri ?? 0).toInt(),
      loaiHoaDon: "Xuất kho",
      items: [
        HoaDonItem(
          tenHang: widget.kho.tenKho ?? '',
          soLuong: 1,
          giaTien: (widget.kho.giaTri ?? 0).toInt(),
        ),
      ],
    );

    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            KhoHangBillScreen(
              hoaDon: hoaDon,
              phuongThuc: phuongThuc,
              onConfirmPayment: () async {
                try {
                  final updated = {
                    "id": widget.kho.id,
                    "tenKho": widget.kho.tenKho,
                    "giaTri": widget.kho.giaTri,
                    "ghiChu": widget.kho.ghiChu,
                    "ngayNhap": widget.kho.ngayNhap?.toIso8601String(),
                    "ngayXuat": DateTime.now().toIso8601String(),
                    "trangThai": "Đã xuất",
                  };
                  final ok = await ApiService.themHoacSuaKhoHangJson(updated);
                  if (mounted) {
                    if (ok) {
                      // ✨ KÍCH HOẠT THÔNG BÁO TẠI ĐÂY
                      Provider.of<NotificationService>(
                        context,
                        listen: false,
                      ).addNotification(
                        title: 'Xuất Kho Thành Công',
                        body:
                            'Sản phẩm "${widget.kho.tenKho}" đã được xuất kho.',
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "✅ Đã xuất kho và cập nhật trạng thái.",
                          ),
                        ),
                      );
                      setState(() {
                        widget.kho.trangThai = "Đã xuất";
                        widget.kho.ngayXuat = DateTime.now();
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("⚠️ Cập nhật trạng thái thất bại."),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Lỗi khi cập nhật kho: $e")),
                    );
                }
              },
            ),
        transitionsBuilder: (context, anim, secondary, child) {
          final offsetAnim = Tween<Offset>(
            begin: const Offset(0.2, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut));
          final fadeAnim = CurvedAnimation(
            parent: anim,
            curve: Curves.easeInOut,
          );
          return FadeTransition(
            opacity: fadeAnim,
            child: SlideTransition(position: offsetAnim, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kho = widget.kho;
    final soNgay = _tinhSoNgay(kho.ngayNhap, kho.ngayXuat);

    final infoCards = [
      ("Tên hàng", kho.tenKho ?? "", Icons.inventory, Colors.deepPurple),
      (
        "Giá trị",
        _formatCurrency(kho.giaTri),
        Icons.monetization_on,
        Colors.green,
      ),
      (
        "Ngày nhập",
        _formatDate(kho.ngayNhap),
        Icons.calendar_today,
        Colors.indigo,
      ),
      (
        "Ngày xuất",
        _formatDate(kho.ngayXuat),
        Icons.exit_to_app,
        Colors.orange,
      ),
      ("Trạng thái", kho.trangThai ?? "", Icons.info_outline, Colors.teal),
      ("Số ngày trong kho", "$soNgay ngày", Icons.access_time, Colors.blue),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text("Chi tiết kho hàng"),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _inPDF(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePDF(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            for (int i = 0; i < infoCards.length; i++)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final animation = CurvedAnimation(
                    parent: _controller,
                    curve: Interval(i * 0.1, 1.0, curve: Curves.easeOutBack),
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildInfoCard(
                  infoCards[i].$1,
                  infoCards[i].$2,
                  infoCards[i].$3,
                  infoCards[i].$4,
                ),
              ),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  const Text(
                    "Mã QR & Mã vạch",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: _taoDuLieuQR(),
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: (kho.tenKho ?? '').toUnsignedVietnamese(),
                    width: 250,
                    height: 80,
                    drawText: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: kho.trangThai != "Đã xuất"
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _chonPhuongThucThanhToan(context),
                icon: const Icon(Icons.local_shipping),
                label: const Text("Xuất kho & Thanh toán"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
