import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/khohang.dart';
import '../services/api_service.dart';

class ThemKhoHangScreen extends StatefulWidget {
  final KhoHang? kho; // nếu null thì thêm mới, ngược lại là sửa

  const ThemKhoHangScreen({Key? key, this.kho}) : super(key: key);

  @override
  _ThemKhoHangScreenState createState() => _ThemKhoHangScreenState();
}

class _ThemKhoHangScreenState extends State<ThemKhoHangScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenController = TextEditingController();
  final _ghiChuController = TextEditingController();
  final _giaTriController = TextEditingController(); // thêm giá trị kho

  DateTime? _ngayNhap;
  DateTime? _ngayXuat;

  final _currencyFormat = NumberFormat("#,##0", "vi_VN"); // định dạng VNĐ

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

  String _unFormatCurrency(String value) {
    return value.replaceAll('.', '').replaceAll(',', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kho == null ? "Thêm Kho Hàng" : "Sửa Kho Hàng"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
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
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Nhập tên kho" : null,
                    ),
                    TextFormField(
                      controller: _giaTriController,
                      decoration: const InputDecoration(
                        labelText: "Giá Trị Kho Hàng (VNĐ)",
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
                    TextFormField(
                      controller: _ghiChuController,
                      decoration: const InputDecoration(labelText: "Ghi Chú"),
                    ),
                    const SizedBox(height: 16),

                    // Ngày nhập
                    ListTile(
                      title: Text(
                        _ngayNhap == null
                            ? "Chọn ngày nhập"
                            : "Ngày nhập: ${_ngayNhap!.day}/${_ngayNhap!.month}/${_ngayNhap!.year}",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _ngayNhap ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _ngayNhap = picked;
                          });
                        }
                      },
                    ),

                    // Ngày xuất (nếu có)
                    ListTile(
                      title: Text(
                        _ngayXuat == null
                            ? "Chưa xuất"
                            : "Ngày xuất: ${_ngayXuat!.day}/${_ngayXuat!.month}/${_ngayXuat!.year}",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _ngayXuat ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _ngayXuat = picked;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A00E0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Lưu",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final giaTriDouble =
                              double.tryParse(
                                _unFormatCurrency(_giaTriController.text),
                              ) ??
                              0;

                          KhoHang kho = KhoHang(
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
                          Navigator.pop(context, true); // trả về true để reload
                        }
                      },
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
