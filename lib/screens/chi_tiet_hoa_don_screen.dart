// lib/screens/chi_tiet_hoa_don_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/hoadon.dart';
import '../models/hoadon_item.dart';
import '../services/api_service.dart';
import 'bill_screen.dart';

class ChiTietHoaDonScreen extends StatefulWidget {
  final HoaDon hd;
  final VoidCallback? onDaThanhToan;

  const ChiTietHoaDonScreen({Key? key, required this.hd, this.onDaThanhToan})
    : super(key: key);

  @override
  State<ChiTietHoaDonScreen> createState() => _ChiTietHoaDonScreenState();
}

class _ChiTietHoaDonScreenState extends State<ChiTietHoaDonScreen> {
  late HoaDon hd;

  @override
  void initState() {
    super.initState();
    hd = widget.hd;
    hd.ngayLap ??= DateTime.now();
    hd.trangThai ??= "Chưa thanh toán";
    hd.tinhTongTien();
  }

  String formatNumber(int number) =>
      NumberFormat("#,###", "vi_VN").format(number);

  int parseNumber(String text) {
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 0;
  }

  bool get _daThanhToan => hd.trangThai == "Đã thanh toán";

  // ===================== In và chia sẻ PDF =====================
  Future<Uint8List> _generateHoaDonPdf() async {
    final pdf = pw.Document();
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
    );

    // ✅ Tạo link QR VietQR
    final qrUrl =
        "https://img.vietqr.io/image/MB-9704229999-compact2.png?amount=${hd.tongTien}&addInfo=Thanh%20toan%20HD%20${hd.maHoaDon}";

    final qrImage = (await networkImage(qrUrl));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  "HÓA ĐƠN BÁN HÀNG",
                  style: pw.TextStyle(font: fontBold, fontSize: 20),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Mã hóa đơn: ${hd.maHoaDon}",
                  style: pw.TextStyle(font: font),
                ),
                pw.Text(
                  "Ngày lập: ${DateFormat('dd/MM/yyyy HH:mm').format(hd.ngayLap!)}",
                  style: pw.TextStyle(font: font),
                ),
                pw.Text(
                  "Phương thức: ${hd.phuongThuc}",
                  style: pw.TextStyle(font: font),
                ),
                pw.SizedBox(height: 10),

                pw.Table.fromTextArray(
                  headers: ["Tên hàng", "SL", "Giá", "Thành tiền"],
                  headerStyle: pw.TextStyle(font: fontBold),
                  cellStyle: pw.TextStyle(font: font),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  data: hd.items.map((e) {
                    return [
                      e.tenHang,
                      "${e.soLuong}",
                      formatNumber(e.giaTien),
                      formatNumber(e.thanhTien()),
                    ];
                  }).toList(),
                ),

                pw.SizedBox(height: 10),
                pw.Text(
                  "Tổng tiền: ${formatNumber(hd.tongTien)} VND",
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
                pw.SizedBox(height: 15),

                // ✅ QR VietQR
                pw.Image(qrImage, width: 140, height: 140),
                pw.SizedBox(height: 5),
                pw.Text(
                  "Quét mã VietQR để thanh toán",
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),

                pw.SizedBox(height: 10),
                pw.Text(
                  "Xin cảm ơn quý khách!",
                  style: pw.TextStyle(font: fontBold, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _inHoaDonPdf() async {
    final bytes = await _generateHoaDonPdf();
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  Future<void> _shareHoaDonPdf() async {
    final bytes = await _generateHoaDonPdf();
    final file = XFile.fromData(
      bytes,
      name: "HoaDon_${hd.maHoaDon}.pdf",
      mimeType: "application/pdf",
    );
    await Share.shareXFiles([file], text: "Hóa đơn ${hd.maHoaDon}");
  }

  // ===================== Lưu hóa đơn =====================
  Future<void> _luuHoaDonVaThoat() async {
    if (hd.loaiHoaDon == null || hd.loaiHoaDon!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn loại hóa đơn")),
      );
      return;
    }
    if (hd.phuongThuc == null || hd.phuongThuc!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn phương thức thanh toán")),
      );
      return;
    }

    hd.tinhTongTien();
    final result = await ApiService.themHoacSuaHoaDon(hd);
    if (result != null) {
      Navigator.pop(context, result);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã lưu hóa đơn")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lưu hóa đơn thất bại, vui lòng thử lại")),
      );
    }
  }

  // ===================== Thanh toán =====================
  Future<void> _thanhToan() async {
    if (hd.phuongThuc == null || hd.phuongThuc!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn phương thức thanh toán")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillScreen(
          hoaDon: hd,
          phuongThuc: hd.phuongThuc!,
          onConfirmPayment: () async {
            setState(() => hd.trangThai = "Đã thanh toán");
            final saved = await ApiService.themHoacSuaHoaDon(hd);
            if (saved != null) {
              Navigator.pop(context, saved);
              widget.onDaThanhToan?.call();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Đã thanh toán")));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Thanh toán thất bại, vui lòng thử lại"),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // ===================== Xóa hóa đơn =====================
  Future<void> _xoaHoaDon() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa hóa đơn"),
        content: const Text("Bạn có chắc chắn muốn xóa hóa đơn này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final deleted = await ApiService.xoaHoaDon(hd.id);
      if (deleted) {
        Navigator.pop(context, null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đã xóa hóa đơn")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Xóa hóa đơn thất bại")));
      }
    }
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết hóa đơn"),
        actions: [
          if (_daThanhToan) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
              onPressed: _inHoaDonPdf,
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              onPressed: _shareHoaDonPdf,
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _xoaHoaDon,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard("Mã hóa đơn", hd.maHoaDon),
            _buildDateCard("Ngày lập", hd.ngayLap!, _chonNgayLap),
            _buildDropdownCard(
              "Loại hóa đơn",
              hd.loaiHoaDon,
              ["Xuất", "Nhập"],
              (val) => setState(() => hd.loaiHoaDon = val),
              !_daThanhToan,
            ),
            _buildDropdownCard(
              "Phương thức thanh toán",
              hd.phuongThuc,
              ["Tiền mặt", "Chuyển khoản"],
              (val) => setState(() => hd.phuongThuc = val),
              !_daThanhToan,
            ),
            const SizedBox(height: 12),
            ...hd.items.asMap().entries.map((entry) {
              final i = entry.key;
              final mh = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(mh.tenHang),
                  subtitle: Text(
                    "SL: ${mh.soLuong} x ${formatNumber(mh.giaTien)} = ${formatNumber(mh.thanhTien())} VND",
                  ),
                  trailing: _daThanhToan
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                              ),
                              onPressed: () => _capNhatMatHang(i),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _xoaMatHang(i),
                            ),
                          ],
                        ),
                ),
              );
            }),
            const SizedBox(height: 12),
            _buildStatusCard(
              "Trạng thái",
              hd.trangThai!,
              _daThanhToan ? Colors.green : Colors.orange,
            ),
            _buildStatusCard(
              "Tổng tiền",
              "${formatNumber(hd.tongTien)} VND",
              Colors.teal,
            ),
            if (!_daThanhToan) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _themMatHang,
                style: _buttonStyle(Colors.purple.shade100, Colors.black87),
                child: const Text("Thêm mặt hàng"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _luuHoaDonVaThoat,
                style: _buttonStyle(Colors.blue.shade400, Colors.white),
                child: const Text("Lưu"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _thanhToan,
                style: _buttonStyle(Colors.green.shade400, Colors.white),
                child: const Text("Thanh toán (QR)"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===================== Helper UI =====================
  Future<void> _chonNgayLap() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: hd.ngayLap ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => hd.ngayLap = picked);
  }

  ButtonStyle _buttonStyle(Color bg, Color fg) => ElevatedButton.styleFrom(
    backgroundColor: bg,
    foregroundColor: fg,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  Widget _buildInfoCard(String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _buildDateCard(String label, DateTime date, VoidCallback onTap) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            InkWell(
              onTap: _daThanhToan ? null : onTap,
              child: Row(
                children: [
                  Text(
                    DateFormat('dd-MM-yyyy').format(date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (!_daThanhToan)
                    const Icon(Icons.edit_calendar, color: Colors.blue),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildStatusCard(String label, String value, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _buildDropdownCard(
    String label,
    String? currentValue,
    List<String> options,
    ValueChanged<String> onChanged,
    bool enabled,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        enabled
            ? SizedBox(
                width: 150,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: currentValue?.isEmpty ?? true ? null : currentValue,
                  hint: const Text("Chưa chọn"),
                  underline: const SizedBox(),
                  items: options
                      .map(
                        (opt) => DropdownMenuItem(value: opt, child: Text(opt)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) onChanged(val);
                  },
                ),
              )
            : Text(
                currentValue ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
      ],
    ),
  );

  // ===================== CRUD Mặt hàng =====================
  void _themMatHang() async {
    final tenController = TextEditingController();
    final soLuongController = TextEditingController(text: "1");
    final giaController = TextEditingController(text: "0");

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Thêm mặt hàng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tenController,
              decoration: const InputDecoration(labelText: "Tên hàng"),
            ),
            TextField(
              controller: soLuongController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: "Số lượng"),
            ),
            TextField(
              controller: giaController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              decoration: const InputDecoration(labelText: "Giá tiền (VND)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              if (tenController.text.trim().isEmpty) return;
              Navigator.pop(ctx, {
                "ten": tenController.text.trim(),
                "soLuong": int.tryParse(soLuongController.text) ?? 1,
                "gia": parseNumber(giaController.text),
              });
            },
            child: const Text("Thêm"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        hd.items.add(
          HoaDonItem(
            tenHang: result["ten"],
            soLuong: result["soLuong"],
            giaTien: result["gia"],
          ),
        );
        hd.tinhTongTien();
      });
    }
  }

  void _capNhatMatHang(int index) async {
    final item = hd.items[index];
    final tenController = TextEditingController(text: item.tenHang);
    final soLuongController = TextEditingController(
      text: item.soLuong.toString(),
    );
    final giaController = TextEditingController(
      text: formatNumber(item.giaTien),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cập nhật mặt hàng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tenController,
              decoration: const InputDecoration(labelText: "Tên hàng"),
            ),
            TextField(
              controller: soLuongController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: "Số lượng"),
            ),
            TextField(
              controller: giaController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              decoration: const InputDecoration(labelText: "Giá tiền (VND)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              if (tenController.text.trim().isEmpty) return;
              Navigator.pop(ctx, {
                "ten": tenController.text.trim(),
                "soLuong": int.tryParse(soLuongController.text) ?? 1,
                "gia": parseNumber(giaController.text),
              });
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        hd.items[index]
          ..tenHang = result["ten"]
          ..soLuong = result["soLuong"]
          ..giaTien = result["gia"];
        hd.tinhTongTien();
      });
    }
  }

  void _xoaMatHang(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa mặt hàng"),
        content: Text(
          "Bạn có chắc muốn xóa '${hd.items[index].tenHang}' không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        hd.items.removeAt(index);
        hd.tinhTongTien();
      });
    }
  }
}

// ===================== Thousands Formatter =====================
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.parse(digits);
    final newText = NumberFormat("#,###", "vi_VN").format(number);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
