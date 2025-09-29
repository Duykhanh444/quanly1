import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _hoaDon = widget.hoaDon;
    _amountController.text = _hoaDon.tongTien.toString();

    _loadSavedDefaults();

    if (_hoaDon.supplierBankName != null) _bankName = _hoaDon.supplierBankName;
    if (_hoaDon.supplierAccount != null)
      _accountController.text = _hoaDon.supplierAccount!;
    if (_hoaDon.supplierAccountName != null)
      _accountNameController.text = _hoaDon.supplierAccountName!;

    // Chuẩn hóa ngân hàng, tránh lỗi Dropdown null/trùng
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
    });
  }

  Future<void> _saveDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defaultBank', _bankName ?? '');
    await prefs.setString('defaultAccount', _accountController.text);
    await prefs.setString('defaultAccountName', _accountNameController.text);
  }

  @override
  void dispose() {
    _accountController.dispose();
    _accountNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get isNhap => _hoaDon.loaiHoaDon == 'Nhập';
  bool get isChuyenKhoan => widget.phuongThuc.toLowerCase().contains('chuyển');
  bool get isTienMat => widget.phuongThuc.toLowerCase().contains('mặt');

  String formatMoney(int n) =>
      NumberFormat('#,###', 'vi_VN').format(n) + ' VND';

  int get amountValue =>
      int.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d]'), '')) ??
      _hoaDon.tongTien;

  String get selectedBankBin =>
      BillConfig.bankNameToBin[_bankName?.toUpperCase() ?? 'ACB'] ??
      BillConfig.shopBankBin;

  String get selectedAccountNumber => _accountController.text.isNotEmpty
      ? _accountController.text
      : BillConfig.shopBankAccount;

  String get selectedAccountName => _accountNameController.text.isNotEmpty
      ? _accountNameController.text
      : BillConfig.shopAccountName;

  Future<void> _editQRInfo() async {
    final bankController = TextEditingController(text: _bankName);
    final accountController = TextEditingController(
      text: _accountController.text,
    );
    final accountNameController = TextEditingController(
      text: _accountNameController.text,
    );
    final amountController = TextEditingController(
      text: _amountController.text,
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chỉnh sửa thông tin QR"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: bankController.text.toUpperCase(),
                decoration: const InputDecoration(labelText: 'Ngân hàng'),
                items: BillConfig.bankNameToBin.keys
                    .map(
                      (b) => DropdownMenuItem(
                        value: b.toUpperCase(),
                        child: Text(b),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  bankController.text = v ?? bankController.text;
                  _updateQR(
                    bankController.text,
                    accountController.text,
                    accountNameController.text,
                    amountController.text,
                  );
                },
              ),
              TextField(
                controller: accountController,
                decoration: const InputDecoration(labelText: 'Số tài khoản'),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  _updateQR(
                    bankController.text,
                    val,
                    accountNameController.text,
                    amountController.text,
                  );
                },
              ),
              TextField(
                controller: accountNameController,
                decoration: const InputDecoration(labelText: 'Chủ tài khoản'),
                onChanged: (val) {
                  _updateQR(
                    bankController.text,
                    accountController.text,
                    val,
                    amountController.text,
                  );
                },
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Số tiền (VND)'),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  _updateQR(
                    bankController.text,
                    accountController.text,
                    accountNameController.text,
                    val,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              _saveDefaults();
              Navigator.pop(context);
            },
            child: const Text("Lưu mặc định"),
          ),
        ],
      ),
    );
  }

  void _updateQR(
    String bank,
    String account,
    String accountName,
    String amount,
  ) {
    setState(() {
      _bankName = bank;
      _accountController.text = account;
      _accountNameController.text = accountName;
      _amountController.text = amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hóa đơn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              BillConfig.shopName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(BillConfig.shopAddress, textAlign: TextAlign.center),
            Text('ĐT: ${BillConfig.shopPhone}', textAlign: TextAlign.center),
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
                '${it.soLuong} x ${formatMoney(it.giaTien)} = ${formatMoney(it.thanhTien())}',
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
                child: Text('Thanh toán tiền mặt - Không cần QR'),
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
