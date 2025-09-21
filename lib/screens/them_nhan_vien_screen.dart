import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/nhanvien.dart';
import '../services/api_service.dart';
import '../api_config.dart'; // 👈 thêm dòng này để dùng ApiConfig

class ThemNhanVienScreen extends StatefulWidget {
  final NhanVien? nhanVien; // null = thêm, không null = sửa

  const ThemNhanVienScreen({Key? key, this.nhanVien}) : super(key: key);

  @override
  State<ThemNhanVienScreen> createState() => _ThemNhanVienScreenState();
}

class _ThemNhanVienScreenState extends State<ThemNhanVienScreen> {
  final _formKey = GlobalKey<FormState>();
  final hoTenController = TextEditingController();
  final sdtController = TextEditingController();
  final chucVuController = TextEditingController();
  final luongController = TextEditingController();
  File? anhFile;

  final NumberFormat numberFormat = NumberFormat.decimalPattern('vi_VN');

  @override
  void initState() {
    super.initState();
    if (widget.nhanVien != null) {
      hoTenController.text = widget.nhanVien!.hoTen;
      sdtController.text = widget.nhanVien!.soDienThoai;
      chucVuController.text = widget.nhanVien!.chucVu;
      luongController.text = numberFormat.format(widget.nhanVien!.luongTheoGio);
    }
  }

  @override
  void dispose() {
    hoTenController.dispose();
    sdtController.dispose();
    chucVuController.dispose();
    luongController.dispose();
    super.dispose();
  }

  Future<void> chonAnh() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => anhFile = File(pickedFile.path));
    }
  }

  Future<void> luuNhanVien() async {
    if (!_formKey.currentState!.validate()) return;

    // Bỏ dấu phân cách
    String rawLuong = luongController.text
        .replaceAll('.', '')
        .replaceAll(',', '');
    double luong = double.tryParse(rawLuong) ?? 0;

    NhanVien nvMoi = NhanVien(
      id: widget.nhanVien?.id ?? 0,
      hoTen: hoTenController.text,
      soDienThoai: sdtController.text,
      chucVu: chucVuController.text,
      luongTheoGio: luong,
      anhDaiDien: widget.nhanVien?.anhDaiDien,
    );

    final ketQua = await ApiService.themHoacSuaNhanVien(
      nvMoi,
      anhDaiDien: anhFile,
    );

    if (!mounted) return;

    if (ketQua != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lưu thành công')));
      // Trả về NhanVien vừa lưu để reload danh sách
      Future.microtask(() => Navigator.pop(context, ketQua));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lưu thất bại')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.nhanVien == null ? 'Thêm nhân viên' : 'Sửa nhân viên',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: chonAnh,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: anhFile != null
                      ? FileImage(anhFile!)
                      : (widget.nhanVien?.anhDaiDien != null
                            ? NetworkImage(
                                    '${ApiConfig.host}/uploads/${widget.nhanVien!.anhDaiDien}', // 👈 sửa chỗ này
                                  )
                                  as ImageProvider
                            : null),
                  child: anhFile == null && widget.nhanVien?.anhDaiDien == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: hoTenController,
                decoration: const InputDecoration(labelText: 'Họ tên'),
                validator: (v) => v == null || v.isEmpty ? 'Nhập họ tên' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: sdtController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nhập số điện thoại' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: chucVuController,
                decoration: const InputDecoration(labelText: 'Chức vụ'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nhập chức vụ' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: luongController,
                decoration: const InputDecoration(
                  labelText: 'Lương theo giờ (VND)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  String raw = value.replaceAll('.', '').replaceAll(',', '');
                  if (raw.isEmpty) return;
                  final newVal = numberFormat.format(int.parse(raw));
                  if (newVal != value) {
                    luongController.value = TextEditingValue(
                      text: newVal,
                      selection: TextSelection.collapsed(offset: newVal.length),
                    );
                  }
                },
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nhập lương';
                  String raw = v.replaceAll('.', '').replaceAll(',', '');
                  if (double.tryParse(raw) == null) return 'Lương phải là số';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: luuNhanVien,
                  child: const Text('Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
