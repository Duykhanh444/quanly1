import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/nhanvien.dart';
import '../services/api_service.dart';
import '../api_config.dart';
import 'them_nhan_vien_screen.dart';
import 'chi_tiet_nhan_vien_screen.dart';
import 'hoa_don_screen.dart';
import 'kho_hang_screen.dart';
import '../main.dart';

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

  double _tinhTongLuongTatCa() {
    return danhSachNhanVien.fold(
      0,
      (sum, nv) => sum + (nv.tongTienDaNhan ?? 0),
    );
  }

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
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
                      const SizedBox(height: 8),
                      Text(
                        '💰 Tổng lương: ${numberFormat.format(_tinhTongLuongTatCa())} VND',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    "assets/icon/app_icon.png",
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Thanh tiêu đề + tìm kiếm
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
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 1.5,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              final reloaded = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChiTietNhanVienScreen(nhanVienId: nv.id),
                                ),
                              );

                              if (reloaded == true) {
                                _loadDanhSach();
                              }
                            },

                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(
                                      0xFF8E2DE2,
                                    ).withOpacity(0.1),
                                    backgroundImage:
                                        (nv.anhDaiDien != null &&
                                            nv.anhDaiDien!.isNotEmpty)
                                        ? NetworkImage(
                                            ApiService.getAnhUrl(nv.anhDaiDien),
                                          )
                                        : null,
                                    child:
                                        (nv.anhDaiDien == null ||
                                            nv.anhDaiDien!.isEmpty)
                                        ? const Icon(
                                            Icons.person,
                                            color: Color(0xFF4A00E0),
                                            size: 26,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nv.hoTen,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15.5,
                                            color: Color(0xFF4A00E0),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.phone,
                                              color: Colors.blueAccent,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                (nv.soDienThoai != null &&
                                                        nv
                                                            .soDienThoai!
                                                            .isNotEmpty)
                                                    ? nv.soDienThoai!
                                                    : "Chưa có số điện thoại",
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              color: Colors.orange,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                "Lương theo giờ: ${formatVND(nv.luongTheoGio)} VND",
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (nv.tongTienDaNhan != null)
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.monetization_on,
                                                color: Colors.green,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  "Tổng đã nhận: ${formatVND(nv.tongTienDaNhan!)} VND",
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  softWrap: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _xoaNhanVien(nv),
                                  ),
                                ],
                              ),
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
          if (index == 0)
            Navigator.pushReplacementNamed(context, '/danh-sach-nhan-vien');
          if (index == 1) Navigator.pushReplacementNamed(context, '/hoa-don');
          if (index == 2) Navigator.pushReplacementNamed(context, '/kho-hang');
          if (index == 3) Navigator.pushReplacementNamed(context, '/doanh-thu');
          if (index == 4) Navigator.pushReplacementNamed(context, '/home');
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
