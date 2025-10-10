import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../models/hoadon.dart';
import '../widgets/vietqr_network_image.dart';
import '../utils/bill_config.dart';

class BillScreen extends StatefulWidget {
  final HoaDon hoaDon;
  final String phuongThuc;
  final VoidCallback? onConfirmPayment;

  const BillScreen({
    super.key,
    required this.hoaDon,
    required this.phuongThuc,
    this.onConfirmPayment,
  });

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  late HoaDon _hoaDon;

  String? _bankName;
  final _accountController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _amountController = TextEditingController();

  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _shopPhoneController = TextEditingController();

  final _bankList = ['ACB', 'MBB', 'VCB', 'TCB', 'BIDV', 'VPB'];

  bool get isChuyenKhoan => widget.phuongThuc.toLowerCase().contains('chuyển');

  @override
  void initState() {
    super.initState();
    _hoaDon = widget.hoaDon;
    _amountController.text = _hoaDon.tongTien.toString();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bankName = prefs.getString('defaultBank') ?? 'ACB';
      _accountController.text =
          prefs.getString('defaultAccount') ?? BillConfig.shopBankAccount;
      _accountNameController.text =
          prefs.getString('defaultAccountName') ?? BillConfig.shopAccountName;

      _shopNameController.text =
          prefs.getString('shopName') ?? BillConfig.shopName;
      _shopAddressController.text =
          prefs.getString('shopAddress') ?? BillConfig.shopAddress;
      _shopPhoneController.text =
          prefs.getString('shopPhone') ?? BillConfig.shopPhone;
    });
  }

  String formatMoney(num n) =>
      NumberFormat('#,###', 'vi_VN').format(n) + ' VND';

  // ---------------- PDF ----------------
  Future<pw.Document> _generatePdf() async {
    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
    );

    final logoBytes = (await rootBundle.load(
      'assets/icon/app_icon.png',
    )).buffer.asUint8List();

    // ⚠️ Bỏ vietqr_logo.png (nếu không có) vì lỗi asset missing
    // Nếu muốn hiển thị logo VietQR, tải file vietqr_logo.png và khai báo trong pubspec.yaml:
    // assets:
    //   - assets/images/vietqr_logo.png

    // ✅ Tạo link QR chuẩn VietQR
    final qrUrl =
        "https://img.vietqr.io/image/${_bankName ?? 'ACB'}-${_accountController.text}-qr_only.png"
        "?amount=${_hoaDon.tongTien.toInt()}"
        "&addInfo=${Uri.encodeComponent("Thanh toán HĐ ${_hoaDon.maHoaDon}")}"
        "&accountName=${Uri.encodeComponent(_accountNameController.text)}";

    Uint8List? qrBytes;
    try {
      final response = await http.get(Uri.parse(qrUrl));
      if (response.statusCode == 200) {
        qrBytes = response.bodyBytes;
      } else {
        debugPrint("Không thể tải QR từ VietQR (mã ${response.statusCode})");
      }
    } catch (e) {
      debugPrint("Lỗi khi tải QR: $e");
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Image(pw.MemoryImage(logoBytes), width: 60, height: 60),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    children: [
                      pw.Text(
                        _shopNameController.text,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 18,
                          color: PdfColor.fromHex('#6C63FF'),
                        ),
                      ),
                      pw.Text(
                        _shopAddressController.text,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        "ĐT: ${_shopPhoneController.text}",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "HÓA ĐƠN BÁN HÀNG",
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 16,
                  color: PdfColor.fromHex('#6C63FF'),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                "Mã hóa đơn: ${_hoaDon.maHoaDon}",
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                "Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(_hoaDon.ngayLap ?? DateTime.now())}",
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                "Phương thức: ${widget.phuongThuc}",
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(),

              // Bảng hàng hóa
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey600,
                  width: 0.5,
                ),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _pdfCell("Tên hàng", bold: true),
                      _pdfCell("SL", bold: true),
                      _pdfCell("Giá", bold: true),
                      _pdfCell("Thành tiền", bold: true),
                    ],
                  ),
                  ..._hoaDon.items.map(
                    (e) => pw.TableRow(
                      children: [
                        _pdfCell(e.tenHang),
                        _pdfCell("${e.soLuong}"),
                        _pdfCell(formatMoney(e.giaTien)),
                        _pdfCell(formatMoney(e.thanhTien())),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "TỔNG CỘNG: ${formatMoney(_hoaDon.tongTien)}",
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  color: PdfColor.fromHex('#6C63FF'),
                ),
              ),
              pw.SizedBox(height: 16),

              // ✅ QR Thanh toán VietQR chuẩn
              if (isChuyenKhoan && qrBytes != null)
                pw.Column(
                  children: [
                    pw.Image(pw.MemoryImage(qrBytes), width: 220, height: 220),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      _accountNameController.text,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 12,
                        color: PdfColor.fromHex('#6C63FF'),
                      ),
                    ),
                    pw.Text(
                      "STK: ${_accountController.text}",
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      "Ngân hàng: ${_bankName ?? ''}",
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),

              pw.Spacer(),
              pw.Text(
                "Xin cảm ơn quý khách!",
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  color: PdfColor.fromHex('#6C63FF'),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  Future<void> _printOrShare(bool share) async {
    final pdf = await _generatePdf();
    final bytes = await pdf.save();
    if (share) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'hoa_don_${_hoaDon.maHoaDon}.pdf',
      );
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hóa đơn bán hàng"),
        backgroundColor: const Color(0xFF6C63FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printOrShare(false),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _printOrShare(true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showEditShopInfo,
              child: Column(
                children: [
                  Image.asset(
                    "assets/icon/app_icon.png",
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _shopNameController.text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  Text(_shopAddressController.text),
                  Text("ĐT: ${_shopPhoneController.text}"),
                  const Text(
                    "(Bấm để chỉnh sửa thông tin cửa hàng)",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 30),
            _infoRow("Mã hóa đơn", _hoaDon.maHoaDon),
            _infoRow(
              "Ngày tạo",
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(_hoaDon.ngayLap ?? DateTime.now()),
            ),
            _infoRow("Phương thức", widget.phuongThuc),
            const Divider(),
            ..._hoaDon.items.map(
              (it) => _infoRow(
                it.tenHang,
                "${it.soLuong} × ${formatMoney(it.giaTien)} = ${formatMoney(it.thanhTien())}",
              ),
            ),
            const Divider(),
            _infoRow("TỔNG CỘNG", formatMoney(_hoaDon.tongTien), bold: true),
            const SizedBox(height: 16),
            if (isChuyenKhoan)
              GestureDetector(
                onTap: _showEditBankInfo,
                child: Column(
                  children: [
                    VietQRNetworkImage(
                      bankCode: _bankName ?? 'ACB',
                      accountNumber: _accountController.text,
                      amount: _hoaDon.tongTien,
                      addInfo: "Thanh toán HĐ: ${_hoaDon.maHoaDon}",
                      size: 280,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _accountNameController.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                    Text("STK: ${_accountController.text}"),
                    Text("Ngân hàng: ${_bankName ?? ''}"),
                    const Text(
                      "(Bấm vào mã QR để chỉnh sửa thông tin tài khoản)",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              const Center(child: Text("Thanh toán tiền mặt")),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, color: Colors.black),
              label: const Text(
                "Xác nhận thanh toán",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                widget.onConfirmPayment?.call();
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String left, String right, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: bold
                  ? const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    )
                  : const TextStyle(color: Colors.black87),
            ),
          ),
          Flexible(
            child: Text(
              right,
              textAlign: TextAlign.right,
              style: bold
                  ? const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    )
                  : const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- chỉnh sửa cửa hàng ----------------
  Future<void> _showEditShopInfo() async {
    final nameCtrl = TextEditingController(text: _shopNameController.text);
    final addressCtrl = TextEditingController(
      text: _shopAddressController.text,
    );
    final phoneCtrl = TextEditingController(text: _shopPhoneController.text);

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Chỉnh sửa thông tin cửa hàng",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Tên cửa hàng"),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: "Địa chỉ"),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: "Số điện thoại"),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Hủy"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                        ),
                        child: const Text(
                          "Lưu",
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('shopName', nameCtrl.text);
                          await prefs.setString(
                            'shopAddress',
                            addressCtrl.text,
                          );
                          await prefs.setString('shopPhone', phoneCtrl.text);
                          setState(() {
                            _shopNameController.text = nameCtrl.text;
                            _shopAddressController.text = addressCtrl.text;
                            _shopPhoneController.text = phoneCtrl.text;
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- chỉnh sửa ngân hàng ----------------
  Future<void> _showEditBankInfo() async {
    final bankCtrl = TextEditingController(text: _bankName);
    final accCtrl = TextEditingController(text: _accountController.text);
    final accNameCtrl = TextEditingController(
      text: _accountNameController.text,
    );

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Chỉnh sửa thông tin tài khoản ngân hàng",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _bankName,
                  decoration: const InputDecoration(labelText: "Ngân hàng"),
                  items: _bankList
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => bankCtrl.text = v ?? 'ACB',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: accNameCtrl,
                  decoration: const InputDecoration(labelText: "Tên tài khoản"),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: accCtrl,
                  decoration: const InputDecoration(labelText: "Số tài khoản"),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Hủy"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                        ),
                        child: const Text(
                          "Lưu",
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('defaultBank', bankCtrl.text);
                          await prefs.setString('defaultAccount', accCtrl.text);
                          await prefs.setString(
                            'defaultAccountName',
                            accNameCtrl.text,
                          );
                          setState(() {
                            _bankName = bankCtrl.text;
                            _accountController.text = accCtrl.text;
                            _accountNameController.text = accNameCtrl.text;
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
