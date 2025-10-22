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
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _shopPhoneController = TextEditingController();

  final _bankList = ['ACB', 'MBB', 'VCB', 'TCB', 'BIDV', 'VPB'];

  bool get isChuyenKhoan => widget.phuongThuc.toLowerCase().contains('chuyển');

  @override
  void initState() {
    super.initState();
    _hoaDon = widget.hoaDon;
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

  String formatMoney(num n, {bool showUnit = true}) =>
      NumberFormat('#,###', 'vi_VN').format(n) + (showUnit ? ' VND' : '');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hóa đơn"),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () => _printOrShare(false),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _printOrShare(true),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(textTheme),
                    const Divider(height: 32),
                    _buildInvoiceInfo(textTheme),
                    const SizedBox(height: 24),
                    _buildItemsTable(textTheme),
                    const Divider(height: 24),
                    _buildFooter(textTheme),
                  ],
                ),
              ),
            ),
          ),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: _showEditShopInfo,
            child: Row(
              children: [
                Image.asset("assets/icon/app_icon.png", width: 40, height: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _shopNameController.text,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "ĐT: ${_shopPhoneController.text}",
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Text(
            "HOÁ ĐƠN",
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceInfo(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("KHÁCH HÀNG:", style: textTheme.labelSmall),
              Text(
                "Khách lẻ",
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(_shopAddressController.text, style: textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Mã HĐ: ${_hoaDon.maHoaDon}",
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Ngày: ${DateFormat('dd/MM/yyyy').format(_hoaDon.ngayLap ?? DateTime.now())}",
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsTable(TextTheme textTheme) {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      columnWidths: const {
        0: FlexColumnWidth(4),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(2.5),
        3: FlexColumnWidth(2.8),
      },
      children: [
        TableRow(
          children: [
            _tableHeader("Tên hàng"),
            _tableHeader("SL", alignment: TextAlign.center),
            _tableHeader("Đơn giá", alignment: TextAlign.right),
            _tableHeader("Thành tiền", alignment: TextAlign.right),
          ],
        ),
        ..._hoaDon.items.map((item) {
          return TableRow(
            children: [
              _tableCell(item.tenHang),
              _tableCell(item.soLuong.toString(), alignment: TextAlign.center),
              _tableCell(
                formatMoney(item.giaTien, showUnit: false),
                alignment: TextAlign.right,
              ),
              _tableCell(
                formatMoney(item.thanhTien(), showUnit: false),
                alignment: TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }

  // ✅ SỬA LẠI HÀM NÀY
  Widget _buildFooter(TextTheme textTheme) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Cột thông tin thanh toán (bên trái) ---
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Thông tin Thanh toán",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isChuyenKhoan)
                    GestureDetector(
                      onTap: _showEditBankInfo,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ngân hàng: ${_bankName ?? ''}",
                            style: textTheme.bodySmall,
                          ),
                          Text(
                            "Tên TK: ${_accountNameController.text}",
                            style: textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "STK: ${_accountController.text}",
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          VietQRNetworkImage(
                            bankCode: _bankName ?? 'ACB',
                            accountNumber: _accountController.text,
                            amount: _hoaDon.tongTien,
                            addInfo: "Thanh toan HD: ${_hoaDon.maHoaDon}",
                            size: 120,
                          ),
                        ],
                      ),
                    )
                  else
                    Text(widget.phuongThuc, style: textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // --- Cột tổng cộng (bên phải) ---
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ✅ Bỏ dòng "Tổng cộng" và "Thuế"
                  _summaryRow("Thành tiền:", formatMoney(_hoaDon.tongTien)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          "Xin cảm ơn quý khách!",
          style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        label: const Text(
          "Xác nhận đã thanh toán",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6200EE),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 4,
        ),
        onPressed: () {
          widget.onConfirmPayment?.call();
          Navigator.pop(context, true);
        },
      ),
    );
  }

  Widget _tableHeader(String text, {TextAlign alignment = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        textAlign: alignment,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _tableCell(String text, {TextAlign alignment = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(text, textAlign: alignment),
    );
  }

  // ✅ SỬA LẠI HÀM NÀY ĐỂ FIX LỖI TRÀN VÀ XUỐNG DÒNG
  Widget _summaryRow(String label, String value) {
    final style = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity, // Cho phép FittedBox có chiều rộng tối đa
          child: FittedBox(
            fit: BoxFit.scaleDown, // Tự động co nhỏ chữ nếu cần
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: style,
              maxLines: 1, // Luôn chỉ hiển thị trên 1 dòng
              softWrap: false, // Không tự động xuống dòng
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  //      CÁC HÀM LOGIC CÒN LẠI (GIỮ NGUYÊN)
  // ==========================================================

  // (Dán các hàm _showEditShopInfo, _showEditBankInfo, _printOrShare, _generatePdf, _pdfCell của bạn vào đây)
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
                          style: TextStyle(color: Colors.white),
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

  Future<void> _showEditBankInfo() async {
    String? tempBankName = _bankName;
    final accCtrl = TextEditingController(text: _accountController.text);
    final accNameCtrl = TextEditingController(
      text: _accountNameController.text,
    );

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
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
                      value: tempBankName,
                      decoration: const InputDecoration(labelText: "Ngân hàng"),
                      items: _bankList
                          .map(
                            (b) => DropdownMenuItem(value: b, child: Text(b)),
                          )
                          .toList(),
                      onChanged: (v) => setStateModal(() => tempBankName = v),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: accNameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Tên tài khoản",
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: accCtrl,
                      decoration: const InputDecoration(
                        labelText: "Số tài khoản",
                      ),
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
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(
                                'defaultBank',
                                tempBankName ?? 'ACB',
                              );
                              await prefs.setString(
                                'defaultAccount',
                                accCtrl.text,
                              );
                              await prefs.setString(
                                'defaultAccountName',
                                accNameCtrl.text,
                              );
                              setState(() {
                                _bankName = tempBankName;
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
      },
    );
  }

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
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Image(
                        pw.MemoryImage(logoBytes),
                        width: 40,
                        height: 40,
                      ),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _shopNameController.text,
                            style: pw.TextStyle(font: fontBold, fontSize: 16),
                          ),
                          pw.Text(
                            "ĐT: ${_shopPhoneController.text}",
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Text(
                    "HOÁ ĐƠN",
                    style: pw.TextStyle(font: fontBold, fontSize: 22),
                  ),
                ],
              ),
              pw.Divider(height: 32),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "KHÁCH HÀNG:",
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                      ),
                      pw.Text("Khách lẻ", style: pw.TextStyle(font: fontBold)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _shopAddressController.text,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Mã HĐ: ${_hoaDon.maHoaDon}",
                        style: pw.TextStyle(font: fontBold),
                      ),
                      pw.Text(
                        "Ngày: ${DateFormat('dd/MM/yyyy').format(_hoaDon.ngayLap ?? DateTime.now())}",
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey),
                  ),
                ),
                cellPadding: const pw.EdgeInsets.symmetric(vertical: 8),
                headers: ["Tên hàng", "SL", "Đơn giá", "Thành tiền"],
                data: _hoaDon.items
                    .map(
                      (item) => [
                        item.tenHang,
                        item.soLuong.toString(),
                        formatMoney(item.giaTien, showUnit: false),
                        formatMoney(item.thanhTien(), showUnit: false),
                      ],
                    )
                    .toList(),
                columnWidths: const {
                  0: pw.FlexColumnWidth(4),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(2.5),
                  3: pw.FlexColumnWidth(2.5),
                },
              ),
              pw.Divider(),
              pw.SizedBox(height: 24),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "Thông tin Thanh toán",
                          style: pw.TextStyle(font: fontBold),
                        ),
                        pw.SizedBox(height: 8),
                        if (isChuyenKhoan) ...[
                          pw.Text(
                            "Ngân hàng: ${_bankName ?? ''}",
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          pw.Text(
                            "Tên TK: ${_accountNameController.text}",
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          pw.Text(
                            "STK: ${_accountController.text}",
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          pw.SizedBox(height: 12),
                          if (qrBytes != null)
                            pw.Image(
                              pw.MemoryImage(qrBytes),
                              width: 120,
                              height: 120,
                            ),
                        ] else
                          pw.Text(widget.phuongThuc),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Tổng cộng:"),
                            pw.Text(formatMoney(_hoaDon.tongTien)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Thuế (0%):"),
                            pw.Text(formatMoney(0)),
                          ],
                        ),
                        pw.Divider(height: 16),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              "Thành tiền:",
                              style: pw.TextStyle(font: fontBold, fontSize: 14),
                            ),
                            pw.Text(
                              formatMoney(_hoaDon.tongTien),
                              style: pw.TextStyle(font: fontBold, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  "Xin cảm ơn quý khách!",
                  style: pw.TextStyle(
                    font: fontBold,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

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
}
