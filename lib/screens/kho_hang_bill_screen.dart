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

class KhoHangBillScreen extends StatefulWidget {
  final HoaDon hoaDon;
  final String phuongThuc;
  final VoidCallback? onConfirmPayment;

  const KhoHangBillScreen({
    super.key,
    required this.hoaDon,
    required this.phuongThuc,
    this.onConfirmPayment,
  });

  @override
  State<KhoHangBillScreen> createState() => _KhoHangBillScreenState();
}

class _KhoHangBillScreenState extends State<KhoHangBillScreen> {
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
    // ✅ Load font Unicode
    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
    );

    // ✅ Load logo
    final logoBytes = (await rootBundle.load(
      'assets/icon/app_icon.png',
    )).buffer.asUint8List();

    // ✅ Gán mặc định nếu thiếu thông tin tài khoản
    _accountController.text = _accountController.text.isEmpty
        ? "0000000000"
        : _accountController.text;
    _accountNameController.text = _accountNameController.text.isEmpty
        ? "Cửa Hàng ABC"
        : _accountNameController.text;

    // ✅ Tạo link QR thanh toán VietQR
    final qrUrl =
        "https://img.vietqr.io/image/${_bankName ?? 'ACB'}-${_accountController.text}-compact2.png"
        "?amount=${_amountController.text}&addInfo=Thanh toán PXK ${_hoaDon.maHoaDon}"
        "&accountName=${Uri.encodeComponent(_accountNameController.text)}";

    Uint8List? qrBytes;
    try {
      final response = await http.get(Uri.parse(qrUrl));
      if (response.statusCode == 200) qrBytes = response.bodyBytes;
    } catch (e) {
      debugPrint("Không thể tải QR: $e");
    }

    // ✅ Khởi tạo PDF
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
              // ================== HEADER ==================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Image(pw.MemoryImage(logoBytes), width: 60, height: 60),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
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
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        "ĐT: ${_shopPhoneController.text}",
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // ================== TIÊU ĐỀ ==================
              pw.Text(
                "PHIẾU XUẤT KHO",
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 16,
                  color: PdfColor.fromHex('#6C63FF'),
                ),
              ),
              pw.SizedBox(height: 10),

              // ================== THÔNG TIN PHIẾU ==================
              pw.Text(
                "Mã phiếu: ${_hoaDon.maHoaDon}",
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                "Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(_hoaDon.ngayLap ?? DateTime.now())}",
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                "Phương thức: ${widget.phuongThuc}",
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 8),

              pw.Divider(),
              pw.SizedBox(height: 6),

              // ================== BẢNG HÀNG HÓA ==================
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
                      _pdfCell("Số lượng", bold: true),
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

              // ================== TỔNG CỘNG ==================
              pw.Text(
                "TỔNG CỘNG: ${formatMoney(_hoaDon.tongTien)}",
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  color: PdfColor.fromHex('#6C63FF'),
                ),
              ),

              pw.SizedBox(height: 20),

              // ================== QR THANH TOÁN ==================
              if (isChuyenKhoan && qrBytes != null)
                pw.Column(
                  children: [
                    pw.Text(
                      "Vui lòng quét mã để thanh toán",
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Image(pw.MemoryImage(qrBytes), width: 250, height: 250),
                    pw.SizedBox(height: 8),
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
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      "Ngân hàng: ${_bankName ?? ''}",
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),

              pw.Spacer(),

              // ================== CHÂN TRANG ==================
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

  // ================== HÀM Ô BẢNG ==================
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

  // ================== IN HOẶC CHIA SẺ ==================
  Future<void> _printOrShare(bool share) async {
    final pdf = await _generatePdf();
    final bytes = await pdf.save();
    if (share) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'phieu_xuat_kho_${_hoaDon.maHoaDon}.pdf',
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
        title: const Text("Phiếu xuất kho"),
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
            // Header + chỉnh sửa
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
                  Text(
                    _shopAddressController.text,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "ĐT: ${_shopPhoneController.text}",
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    "(Bấm để chỉnh sửa thông tin cửa hàng)",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 30),
            _infoRow("Mã đơn", _hoaDon.maHoaDon),
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
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _showEditQrBottomSheet(context),
                    child: VietQRNetworkImage(
                      bankCode: _bankName ?? 'ACB',
                      accountNumber: _accountController.text,
                      amount: _hoaDon.tongTien,
                      addInfo: "Thanh toán PXK: ${_hoaDon.maHoaDon}",
                      size: 280,
                    ),
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
                ],
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

  // ---------------- bottom sheet ----------------
  Future<void> _showEditQrBottomSheet(BuildContext context) async {
    String selectedBank = _bankName ?? 'ACB';
    final accCtrl = TextEditingController(text: _accountController.text);
    final accNameCtrl = TextEditingController(
      text: _accountNameController.text,
    );
    final amountCtrl = TextEditingController(text: _amountController.text);

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Chỉnh sửa thông tin chuyển khoản",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedBank,
                    items: _bankList
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    decoration: const InputDecoration(labelText: "Ngân hàng"),
                    onChanged: (v) => selectedBank = v ?? 'ACB',
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: accCtrl,
                    decoration: const InputDecoration(
                      labelText: "Số tài khoản",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: accNameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Chủ tài khoản",
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(
                      labelText: "Số tiền (VND)",
                    ),
                    keyboardType: TextInputType.number,
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
                            await prefs.setString('defaultBank', selectedBank);
                            await prefs.setString(
                              'defaultAccount',
                              accCtrl.text,
                            );
                            await prefs.setString(
                              'defaultAccountName',
                              accNameCtrl.text,
                            );
                            await prefs.setString(
                              'defaultAmount',
                              amountCtrl.text,
                            );
                            setState(() {
                              _bankName = selectedBank;
                              _accountController.text = accCtrl.text;
                              _accountNameController.text = accNameCtrl.text;
                              _amountController.text = amountCtrl.text;
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
          ),
        );
      },
    );
  }

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
}
