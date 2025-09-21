import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/nhanvien.dart';
import '../services/api_service.dart';
import '../api_config.dart';
import 'them_nhan_vien_screen.dart';
import 'chi_tiet_nhan_vien_screen.dart';

class DanhSachNhanVienScreen extends StatefulWidget {
  const DanhSachNhanVienScreen({Key? key}) : super(key: key);

  @override
  State<DanhSachNhanVienScreen> createState() => _DanhSachNhanVienScreenState();
}

class _DanhSachNhanVienScreenState extends State<DanhSachNhanVienScreen> {
  List<NhanVien> danhSachNhanVien = [];
  bool isLoading = true;
  final NumberFormat numberFormat = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _loadDanhSach();

    // ✅ Lắng nghe host thay đổi
    ApiConfig.hostNotifier.addListener(() {
      _loadDanhSach();
    });
  }

  Future<void> _loadDanhSach() async {
    setState(() => isLoading = true);
    danhSachNhanVien = await ApiService.layDanhSachNhanVien() ?? [];
    setState(() => isLoading = false);
  }

  String formatVND(double value) => numberFormat.format(value);

  Future<void> _themNhanVien() async {
    final result = await Navigator.push<NhanVien>(
      context,
      MaterialPageRoute(builder: (_) => const ThemNhanVienScreen()),
    );

    if (result != null) {
      setState(() => danhSachNhanVien.add(result));
    }
  }

  Future<void> _suaNhanVien(NhanVien nv) async {
    final result = await Navigator.push<NhanVien>(
      context,
      MaterialPageRoute(builder: (_) => ThemNhanVienScreen(nhanVien: nv)),
    );

    if (result != null) {
      int index = danhSachNhanVien.indexWhere((e) => e.id == result.id);
      if (index != -1) {
        setState(() => danhSachNhanVien[index] = result);
      }
    }
  }

  Future<void> _xoaNhanVien(NhanVien nv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc muốn xóa nhân viên ${nv.hoTen}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final deleted = await ApiService.xoaNhanVien(nv.id);
    if (deleted == true) {
      setState(() => danhSachNhanVien.removeWhere((e) => e.id == nv.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xóa thành công')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xóa thất bại')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách nhân viên')),
      floatingActionButton: FloatingActionButton(
        onPressed: _themNhanVien,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDanhSach,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: danhSachNhanVien.length,
                itemBuilder: (_, index) {
                  final nv = danhSachNhanVien[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        // ✅ Sử dụng host động từ ApiConfig
                        backgroundImage: nv.anhDaiDien != null
                            ? NetworkImage(ApiService.getAnhUrl(nv.anhDaiDien))
                            : null,
                        child: nv.anhDaiDien == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(nv.hoTen),
                      subtitle: Text(
                        '${nv.chucVu} • Lương: ${formatVND(nv.luongTheoGio)} VND',
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChiTietNhanVienScreen(nhanVienId: nv.id),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _suaNhanVien(nv),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _xoaNhanVien(nv),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
