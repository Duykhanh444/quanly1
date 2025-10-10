// lib/screens/them_kho_hang_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/khohang.dart';
import '../services/api_service.dart';

class ThemKhoHangScreen extends StatefulWidget {
  final KhoHang? kho;

  const ThemKhoHangScreen({Key? key, this.kho}) : super(key: key);

  @override
  State<ThemKhoHangScreen> createState() => _ThemKhoHangScreenState();
}

class _ThemKhoHangScreenState extends State<ThemKhoHangScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenController = TextEditingController();
  final _ghiChuController = TextEditingController();
  final _giaTriController = TextEditingController();
  DateTime? _ngayNhap;
  DateTime? _ngayXuat;

  final _currencyFormat = NumberFormat("#,##0", "vi_VN");

  @override
  void initState() {
    super.initState();
    if (widget.kho != null) {
      _tenController.text = widget.kho!.tenKho ?? "";
      _ghiChuController.text = widget.kho!.ghiChu ?? "";
      _giaTriController.text = widget.kho!.giaTri != null
          ? _currencyFormat.format(widget.kho!.giaTri)
          : "";
      _ngayNhap = widget.kho!.ngayNhap;
      _ngayXuat = widget.kho!.ngayXuat;
    }
  }

  @override
  void dispose() {
    _tenController.dispose();
    _ghiChuController.dispose();
    _giaTriController.dispose();
    super.dispose();
  }

  // 🔹 Xóa định dạng tiền tệ để lấy số gốc
  String _unFormatCurrency(String value) {
    return value.replaceAll('.', '').replaceAll(',', '');
  }

  // 🧾 Xuất PDF có QR + Barcode
  Future<void> _xuatPDF(String data, String tenHang) async {
    final pdf = pw.Document();

    final qrImage = await QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
    ).toImageData(300);
    final qrBytes = qrImage!.buffer.asUint8List();

    final roboto = await PdfGoogleFonts.robotoRegular();
    final robotoBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                "MÃ QR & BARCODE HÀNG HÓA",
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  font: robotoBold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Image(pw.MemoryImage(qrBytes), width: 180, height: 180),
              pw.SizedBox(height: 20),
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: tenHang,
                width: 200,
                height: 60,
                drawText: true,
              ),
              pw.SizedBox(height: 16),
              pw.Text("Tên hàng: $tenHang", style: pw.TextStyle(font: roboto)),
              pw.Text(
                "Ngày tạo: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}",
                style: pw.TextStyle(font: roboto),
              ),
            ],
          ),
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/$tenHang.pdf");
    await file.writeAsBytes(await pdf.save());

    await Printing.sharePdf(bytes: await pdf.save(), filename: "$tenHang.pdf");
  }

  // 🔹 Tạo QR và xuất PDF
  void _taoQR() {
    if (_tenController.text.isEmpty || _giaTriController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập tên và giá trị kho!")),
      );
      return;
    }

    final dataQR = Uri(
      queryParameters: {
        'tenHang': _tenController.text,
        'giaTri': _unFormatCurrency(_giaTriController.text),
        'ghiChu': _ghiChuController.text,
        'soLuong': '1',
      },
    ).query;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("📦 Mã QR hàng hóa"),
        content: SizedBox(
          width: 220,
          height: 260,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(data: dataQR, version: QrVersions.auto, size: 180),
              const SizedBox(height: 8),
              Text(
                _tenController.text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Đóng"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _xuatPDF(dataQR, _tenController.text);
            },
            child: const Text("🧾 Xuất PDF"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kho == null ? "Thêm Kho Hàng" : "Sửa Kho Hàng"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _tenController,
                      decoration: const InputDecoration(
                        labelText: "Tên Kho Hàng",
                        prefixIcon: Icon(Icons.store, color: Colors.deepPurple),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Nhập tên kho" : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _giaTriController,
                      decoration: const InputDecoration(
                        labelText: "Giá Trị Kho Hàng (VNĐ)",
                        prefixIcon: Icon(
                          Icons.monetization_on,
                          color: Colors.green,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          if (newValue.text.isEmpty) {
                            return newValue.copyWith(text: '');
                          }
                          final int value = int.parse(
                            newValue.text.replaceAll('.', ''),
                          );
                          final newText = _currencyFormat.format(value);
                          return TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(
                              offset: newText.length,
                            ),
                          );
                        }),
                      ],
                      validator: (val) => val == null || val.isEmpty
                          ? "Nhập giá trị kho"
                          : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _ghiChuController,
                      decoration: const InputDecoration(
                        labelText: "Ghi Chú",
                        prefixIcon: Icon(Icons.note_alt, color: Colors.orange),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ListTile(
                      leading: const Icon(
                        Icons.calendar_month,
                        color: Colors.teal,
                      ),
                      title: Text(
                        _ngayNhap == null
                            ? "Ngày nhập"
                            : "Ngày nhập: ${_ngayNhap!.day}/${_ngayNhap!.month}/${_ngayNhap!.year}",
                      ),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _ngayNhap ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _ngayNhap = picked);
                        }
                      },
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.local_shipping,
                        color: Colors.redAccent,
                      ),
                      title: Text(
                        _ngayXuat == null
                            ? "Ngày xuất"
                            : "Ngày xuất: ${_ngayXuat!.day}/${_ngayXuat!.month}/${_ngayXuat!.year}",
                      ),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _ngayXuat ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _ngayXuat = picked);
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        "Lưu",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B9DF9),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 5,
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final giaTriDouble =
                              double.tryParse(
                                _unFormatCurrency(_giaTriController.text),
                              ) ??
                              0;

                          final kho = KhoHang(
                            id: widget.kho?.id ?? 0,
                            tenKho: _tenController.text,
                            ghiChu: _ghiChuController.text,
                            giaTri: giaTriDouble,
                            ngayNhap: _ngayNhap ?? DateTime.now(),
                            ngayXuat: _ngayXuat,
                            trangThai: _ngayXuat == null
                                ? "Hoạt động"
                                : "Đã xuất",
                          );

                          await ApiService.themHoacSuaKhoHang(kho);
                          Navigator.pop(context, true);
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // 🔘 Nút tạo QR (đã bỏ quét QR)
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code, color: Colors.white),
                        label: const Text(
                          "Tạo Mã QR",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _taoQR,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
