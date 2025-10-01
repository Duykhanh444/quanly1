import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/nhanvien.dart';
import '../services/api_service.dart';
import '../api_config.dart';
import 'them_nhan_vien_screen.dart';
import 'chi_tiet_nhan_vien_screen.dart';
import 'hoa_don_screen.dart';
import 'kho_hang_screen.dart';
import '../main.dart'; // 🔹 để gọi MyApp khi quay về Trang chủ

class DanhSachNhanVienScreen extends StatefulWidget {
  const DanhSachNhanVienScreen({Key? key}) : super(key: key);

  @override
  State<DanhSachNhanVienScreen> createState() => _DanhSachNhanVienScreenState();
}

class _DanhSachNhanVienScreenState extends State<DanhSachNhanVienScreen> {
  List<NhanVien> danhSachNhanVien = [];
  List<NhanVien> danhSachLoc = [];
  bool isLoading = true;
  final NumberFormat numberFormat = NumberFormat('#,###', 'vi_VN');
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDanhSach();

    ApiConfig.hostNotifier.addListener(() {
      _loadDanhSach();
    });

    _searchController.addListener(() {
      _locNhanVien(_searchController.text);
    });
  }

  Future<void> _loadDanhSach() async {
    setState(() => isLoading = true);
    danhSachNhanVien = await ApiService.layDanhSachNhanVien() ?? [];
    danhSachLoc = List.from(danhSachNhanVien);
    setState(() => isLoading = false);
  }

  void _locNhanVien(String query) {
    if (query.isEmpty) {
      setState(() => danhSachLoc = List.from(danhSachNhanVien));
    } else {
      setState(() {
        danhSachLoc = danhSachNhanVien.where((nv) {
          final ten = nv.hoTen.toLowerCase();
          final sdt = (nv.soDienThoai ?? "").toLowerCase();
          final q = query.toLowerCase();
          return ten.contains(q) || sdt.contains(q);
        }).toList();
      });
    }
  }

  String formatVND(double value) => numberFormat.format(value);

  Future<void> _themNhanVien() async {
    final result = await Navigator.push<NhanVien>(
      context,
      MaterialPageRoute(builder: (_) => const ThemNhanVienScreen()),
    );
    if (result != null) {
      setState(() {
        danhSachNhanVien.add(result);
        _locNhanVien(_searchController.text);
      });
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
        setState(() {
          danhSachNhanVien[index] = result;
          _locNhanVien(_searchController.text);
        });
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
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final deleted = await ApiService.xoaNhanVien(nv.id);
    if (deleted == true) {
      setState(() {
        danhSachNhanVien.removeWhere((e) => e.id == nv.id);
        _locNhanVien(_searchController.text);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xóa thành công')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xóa thất bại')));
    }
  }

  Widget _buildAvatar(NhanVien nv) {
    final hasAvatar = nv.anhDaiDien != null && nv.anhDaiDien!.isNotEmpty;
    final url = hasAvatar ? ApiService.getAnhUrl(nv.anhDaiDien) : null;

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF8E2DE2).withOpacity(0.2),
      backgroundImage: hasAvatar ? NetworkImage(url!) : null,
      child: !hasAvatar
          ? const Icon(Icons.person, color: Color(0xFF4A00E0), size: 28)
          : null,
    );
  }

  String getChaoBuoi() {
    final gio = DateTime.now().hour;
    if (gio < 12) return "Chào buổi sáng,";
    if (gio < 18) return "Chào buổi chiều,";
    return "Chào buổi tối,";
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A00E0),
        onPressed: _themNhanVien,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Chào + ngày
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getChaoBuoi(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      today,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                // Logo
                Row(
                  children: const [
                    Icon(Icons.warehouse, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      "VIETFLOW",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tiêu đề + tìm kiếm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Danh sách nhân viên",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A00E0),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Tìm theo tên hoặc số điện thoại...",
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF4A00E0),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách nhân viên
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4A00E0)),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF4A00E0),
                    onRefresh: _loadDanhSach,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: danhSachLoc.length,
                      itemBuilder: (_, index) {
                        final nv = danhSachLoc[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: _buildAvatar(nv),
                            title: Text(
                              nv.hoTen,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF4A00E0),
                              ),
                            ),
                            subtitle: Text(
                              '${nv.chucVu} • Lương: ${formatVND(nv.luongTheoGio)} VND',
                              style: const TextStyle(color: Colors.black54),
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
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF8E2DE2),
                                  ),
                                  onPressed: () => _suaNhanVien(nv),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _xoaNhanVien(nv),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);

          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/danh-sach-nhan-vien');
          }
          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/hoa-don');
          }
          if (index == 2) {
            Navigator.pushReplacementNamed(context, '/kho-hang');
          }
          if (index == 3) {
            Navigator.pushReplacementNamed(context, '/doanh-thu');
          }
          if (index == 4) {
            // 👉 về HomeScreen trong QuanLyXuongApp
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A00E0),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Nhân Viên"),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Hóa Đơn",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: "Kho Hàng",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Doanh Thu",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        ],
      ),
    );
  }
}
