import 'package:flutter/material.dart';
import '../models/khohang.dart';
import '../services/api_service.dart';

class ThemKhoHangScreen extends StatefulWidget {
  final KhoHang? kho; // nếu null thì thêm mới, ngược lại là sửa

  ThemKhoHangScreen({this.kho});

  @override
  _ThemKhoHangScreenState createState() => _ThemKhoHangScreenState();
}

class _ThemKhoHangScreenState extends State<ThemKhoHangScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenController = TextEditingController();
  final _ghiChuController = TextEditingController();

  DateTime? _ngayNhap;
  DateTime? _ngayXuat;

  @override
  void initState() {
    super.initState();
    if (widget.kho != null) {
      _tenController.text = widget.kho!.tenKho ?? "";
      _ghiChuController.text = widget.kho!.ghiChu ?? "";
      _ngayNhap = widget.kho!.ngayNhap;
      _ngayXuat = widget.kho!.ngayXuat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kho == null ? "Thêm Kho Hàng" : "Sửa Kho Hàng"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tenController,
                decoration: InputDecoration(labelText: "Tên Kho Hàng"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Nhập tên kho" : null,
              ),
              TextFormField(
                controller: _ghiChuController,
                decoration: InputDecoration(labelText: "Ghi Chú"),
              ),
              const SizedBox(height: 16),

              // Ngày nhập
              ListTile(
                title: Text(
                  _ngayNhap == null
                      ? "Chọn ngày nhập"
                      : "Ngày nhập: ${_ngayNhap!.day}/${_ngayNhap!.month}/${_ngayNhap!.year}",
                ),
                trailing: Icon(Icons.calendar_today),
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
                trailing: Icon(Icons.calendar_today),
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
                child: Text("Lưu"),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    KhoHang kho = KhoHang(
                      id: widget.kho?.id ?? 0,
                      tenKho: _tenController.text,
                      ghiChu: _ghiChuController.text,
                      ngayNhap: _ngayNhap ?? DateTime.now(),
                      ngayXuat: _ngayXuat,
                      trangThai: _ngayXuat == null ? "Hoạt động" : "Đã xuất",
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
    );
  }
}
