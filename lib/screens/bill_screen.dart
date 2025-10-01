import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/hoadon.dart';
import '../utils/bill_config.dart';
import '../widgets/vietqr_network_image.dart';

class BillScreen extends StatefulWidget {
  final HoaDon hoaDon;
  final String phuongThuc;
  final VoidCallback? onConfirmPayment;

  const BillScreen({
    Key? key,
    required this.hoaDon,
    required this.phuongThuc,
    this.onConfirmPayment,
  }) : super(key: key);

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  late HoaDon _hoaDon;

  String? _bankName;
  final _accountController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _amountController = TextEditingController();

  // ✅ Shop info
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _shopPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hoaDon = widget.hoaDon;
    _amountController.text = _hoaDon.tongTien.toString();
    _loadSavedDefaults();

    if (_hoaDon.supplierBankName != null) _bankName = _hoaDon.supplierBankName;
    if (_hoaDon.supplierAccount != null) {
      _accountController.text = _hoaDon.supplierAccount!;
    }
    if (_hoaDon.supplierAccountName != null) {
      _accountNameController.text = _hoaDon.supplierAccountName!;
    }

    if (_bankName == null ||
        !BillConfig.bankNameToBin.keys
            .map((e) => e.toUpperCase())
            .contains(_bankName!.toUpperCase())) {
      _bankName = BillConfig.bankNameToBin.keys.first.toUpperCase();
    } else {
      _bankName = _bankName!.toUpperCase();
    }
  }

  Future<void> _loadSavedDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bankName = prefs.getString('defaultBank')?.toUpperCase() ?? _bankName;
      _accountController.text =
          prefs.getString('defaultAccount') ?? _accountController.text;
      _accountNameController.text =
          prefs.getString('defaultAccountName') ?? _accountNameController.text;

      _shopNameController.text =
          prefs.getString('shopName') ?? BillConfig.shopName;
      _shopAddressController.text =
          prefs.getString('shopAddress') ?? BillConfig.shopAddress;
      _shopPhoneController.text =
          prefs.getString('shopPhone') ?? BillConfig.shopPhone;
    });
  }

  Future<void> _saveShopInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopName', _shopNameController.text);
    await prefs.setString('shopAddress', _shopAddressController.text);
    await prefs.setString('shopPhone', _shopPhoneController.text);
  }

  Future<void> _saveDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defaultBank', _bankName ?? '');
    await prefs.setString('defaultAccount', _accountController.text);
    await prefs.setString('defaultAccountName', _accountNameController.text);
  }

  bool get isChuyenKhoan => widget.phuongThuc.toLowerCase().contains('chuyển');
  bool get isTienMat => widget.phuongThuc.toLowerCase().contains('mặt');

  String formatMoney(int n) =>
      NumberFormat('#,###', 'vi_VN').format(n) + ' VND';

  int get amountValue =>
      int.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d]'), '')) ??
      _hoaDon.tongTien;

  String get selectedAccountNumber => _accountController.text.isNotEmpty
      ? _accountController.text
      : BillConfig.shopBankAccount;

  String get selectedAccountName => _accountNameController.text.isNotEmpty
      ? _accountNameController.text
      : BillConfig.shopAccountName;

  // ✅ tạo PDF
  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                _shopNameController.text,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(_shopAddressController.text),
              pw.Text("ĐT: ${_shopPhoneController.text}"),
              pw.Divider(),
              pw.Text("Hóa đơn: ${_hoaDon.maHoaDon}"),
              pw.Text(
                "Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(_hoaDon.ngayLap ?? DateTime.now())}",
              ),
              pw.Text("Thanh toán: ${widget.phuongThuc}"),
              pw.Divider(),
              ..._hoaDon.items.map(
                (it) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(it.tenHang),
                    pw.Text(
                      "${it.soLuong} x ${formatMoney(it.giaTien)} = ${formatMoney(it.thanhTien())}",
                    ),
                  ],
                ),
              ),
              pw.Divider(),
              pw.Text(
                "TỔNG CỘNG: ${formatMoney(_hoaDon.tongTien)}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  Future<void> _printBill() async {
    final pdf = await _generatePdf();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _shareBill() async {
    final pdf = await _generatePdf();
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'hoa_don_${_hoaDon.maHoaDon}.pdf',
    );
  }

  // ✅ Dialog sửa Shop Info
  void _editShopInfo() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Sửa thông tin cửa hàng"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _shopNameController,
                decoration: const InputDecoration(labelText: "Tên cửa hàng"),
              ),
              TextField(
                controller: _shopAddressController,
                decoration: const InputDecoration(labelText: "Địa chỉ"),
              ),
              TextField(
                controller: _shopPhoneController,
                decoration: const InputDecoration(labelText: "Số điện thoại"),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveShopInfo();
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }

  // ✅ Dialog sửa QR Info (đã thêm chọn ngân hàng)
  void _editQRInfo() {
    // Khởi tạo temporary values để chỉnh trong dialog
    String? tempBank = _bankName;
    final tempAccountController = TextEditingController(
      text: _accountController.text,
    );
    final tempAccountNameController = TextEditingController(
      text: _accountNameController.text,
    );
    final tempAmountController = TextEditingController(
      text: _amountController.text,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Sửa thông tin chuyển khoản"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dropdown chọn ngân hàng
                    DropdownButtonFormField<String>(
                      value: tempBank,
                      decoration: const InputDecoration(labelText: "Ngân hàng"),
                      items: BillConfig.bankNameToBin.keys.map((bank) {
                        // giữ hiển thị theo key gốc nhưng value là uppercase
                        return DropdownMenuItem(
                          value: bank.toUpperCase(),
                          child: Text(bank),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          tempBank = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: tempAccountNameController,
                      decoration: const InputDecoration(
                        labelText: "Tên tài khoản",
                      ),
                    ),
                    TextField(
                      controller: tempAccountController,
                      decoration: const InputDecoration(
                        labelText: "Số tài khoản",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: tempAmountController,
                      decoration: const InputDecoration(labelText: "Số tiền"),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Ghi lại giá trị vào controller chính và lưu defaults
                    _bankName = tempBank ?? _bankName;
                    _accountController.text = tempAccountController.text;
                    _accountNameController.text =
                        tempAccountNameController.text;
                    _amountController.text = tempAmountController.text;

                    await _saveDefaults();
                    setState(() {}); // cập nhật giao diện chính
                    Navigator.pop(ctx);
                  },
                  child: const Text("Lưu"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa đơn'),
        actions: [
          IconButton(icon: const Icon(Icons.print), onPressed: _printBill),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareBill),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _editShopInfo,
              child: Column(
                children: [
                  Text(
                    _shopNameController.text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    _shopAddressController.text,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "ĐT: ${_shopPhoneController.text}",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(),
            _infoRow('Mã HĐ', _hoaDon.maHoaDon),
            _infoRow(
              'Ngày',
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(_hoaDon.ngayLap ?? DateTime.now()),
            ),
            _infoRow('Loại', _hoaDon.loaiHoaDon ?? ''),
            _infoRow('Thanh toán', widget.phuongThuc),
            const Divider(),
            ..._hoaDon.items.map(
              (it) => _infoRow(
                it.tenHang,
                "${it.soLuong} x ${formatMoney(it.giaTien)} = ${formatMoney(it.thanhTien())}",
              ),
            ),
            const Divider(),
            _infoRow('TỔNG CỘNG', formatMoney(_hoaDon.tongTien), bold: true),
            const SizedBox(height: 12),
            if (isChuyenKhoan) ...[
              const Center(
                child: Text(
                  'Chạm vào QR hoặc thông tin để sửa trực tiếp',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _editQRInfo,
                child: Center(
                  child: VietQRNetworkImage(
                    bankCode: _bankName ?? 'ACB',
                    accountNumber: selectedAccountNumber,
                    amount: amountValue,
                    addInfo: "Thanh toan HD: ${_hoaDon.maHoaDon}",
                    size: 230,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _editQRInfo,
                child: Column(
                  children: [
                    Text(
                      selectedAccountName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(selectedAccountNumber),
                    Text('Ngân hàng: ${_bankName ?? 'VN (shop)'}'),
                  ],
                ),
              ),
            ] else if (isTienMat)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Thanh toán tiền mặt'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (widget.onConfirmPayment != null) widget.onConfirmPayment!();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade400,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Xác nhận thanh toán'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String l, String r, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l,
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          Flexible(
            child: Text(
              r,
              textAlign: TextAlign.right,
              style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
            ),
          ),
        ],
      ),
    );
  }
}
