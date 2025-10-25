import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_tools/qr_code_tools.dart';

import '../models/khohang.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'chi_tiet_kho_hang_screen.dart';
import 'them_kho_hang_screen.dart';

class KhoHangScreen extends StatefulWidget {
  const KhoHangScreen({super.key});

  @override
  State<KhoHangScreen> createState() => _KhoHangScreenState();
}

class _KhoHangScreenState extends State<KhoHangScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<KhoHang> _danhSachKho = [];
  List<KhoHang> _filteredKho = [];
  bool _isLoading = true;
  String _searchText = "";

  int _tongHoatDong = 0;
  int _tongDaXuat = 0;

  final int _currentIndex = 2;

  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDanhSach();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _loadDanhSach() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.wait([
      ApiService.layDanhSachKhoHang().then((ds) {
        if (mounted) {
          setState(() {
            _danhSachKho = ds;
            _tongHoatDong = ds.where((k) => k.trangThai == "Hoạt động").length;
            _tongDaXuat = ds.where((k) => k.trangThai == "Đã xuất").length;
            _applySearch();
          });
        }
      }),
      Provider.of<NotificationService>(
        context,
        listen: false,
      ).loadNotifications(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applySearch() {
    if (_searchText.isEmpty) {
      _filteredKho = List.from(_danhSachKho);
    } else {
      _filteredKho = _danhSachKho
          .where(
            (k) => (k.tenKho ?? "").toLowerCase().contains(
              _searchText.toLowerCase(),
            ),
          )
          .toList();
    }
  }

  Future<void> _xoaKhoHang(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa kho hàng"),
        content: const Text("Bạn có chắc muốn xóa kho này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.xoaKhoHang(id);
      await _loadDanhSach();
    }
  }

  Future<void> _xoaTatCaLichSu() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa tất cả lịch sử"),
        content: const Text("Bạn có chắc muốn xóa toàn bộ kho đã xuất không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (var kho in _danhSachKho.where((k) => k.trangThai == "Đã xuất")) {
        await ApiService.xoaKhoHang(kho.id);
      }
      await _loadDanhSach();
    }
  }

  String _formatDate(DateTime date) => DateFormat("dd/MM/yyyy").format(date);

  String _formatCurrency(num? value) {
    if (value == null) return "0 đ";
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(value)} VND";
  }

  Future<void> _moCameraQuetQR() async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.deepPurple,
            title: const Text("Quét mã QR"),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.flash_on),
                onPressed: () => _scannerController.toggleTorch(),
              ),
              IconButton(
                icon: const Icon(Icons.cameraswitch),
                onPressed: () => _scannerController.switchCamera(),
              ),
            ],
          ),
          body: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) async {
                  final barcode = capture.barcodes.first.rawValue ?? "";
                  if (barcode.isNotEmpty) {
                    Navigator.pop(ctx);
                    try {
                      final dataQR = Uri.splitQueryString(barcode);
                      final tenHang = dataQR['tenHang'] ?? 'Không tên';
                      final giaTri =
                          double.tryParse(dataQR['giaTri'] ?? '0') ?? 0;
                      final ghiChu = dataQR['ghiChu'] ?? '';
                      final tonTai = _danhSachKho.any(
                        (k) =>
                            (k.tenKho ?? "").toLowerCase() ==
                            tenHang.toLowerCase(),
                      );

                      if (!tonTai) {
                        final khoMoi = KhoHang(
                          id: 0,
                          tenKho: tenHang,
                          ghiChu: ghiChu,
                          giaTri: giaTri,
                          ngayNhap: DateTime.now(),
                          trangThai: "Hoạt động",
                        );
                        await ApiService.themHoacSuaKhoHang(khoMoi);
                        await _loadDanhSach();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("✅ Đã tạo kho mới: $tenHang"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("⚠️ Kho '$tenHang' đã tồn tại!"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("❌ Lỗi khi đọc mã QR: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.image, color: Colors.white),
                    label: const Text(
                      "Chọn ảnh để quét",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _quetTuAnh();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _quetTuAnh() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final result = await QrCodeToolsPlugin.decodeFrom(picked.path);
      if (result != null && result.isNotEmpty) {
        final dataQR = Uri.splitQueryString(result);
        final tenHang = dataQR['tenHang'] ?? 'Không tên';
        final giaTri = double.tryParse(dataQR['giaTri'] ?? '0') ?? 0;
        final ghiChu = dataQR['ghiChu'] ?? '';
        final tonTai = _danhSachKho.any(
          (k) => (k.tenKho ?? "").toLowerCase() == tenHang.toLowerCase(),
        );

        if (!tonTai) {
          final khoMoi = KhoHang(
            id: 0,
            tenKho: tenHang,
            ghiChu: ghiChu,
            giaTri: giaTri,
            ngayNhap: DateTime.now(),
            trangThai: "Hoạt động",
          );
          await ApiService.themHoacSuaKhoHang(khoMoi);
          await _loadDanhSach();
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("✅ Đã tạo kho mới: $tenHang")));
        } else {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("⚠️ Kho '$tenHang' đã tồn tại!")),
          );
        }
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy mã QR trong ảnh")),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi quét ảnh: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat("dd/MM/yyyy").format(DateTime.now());

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Danh sách kho hàng",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          today,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Consumer<NotificationService>(
                          builder: (context, service, child) {
                            return Stack(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/notifications',
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  tooltip: 'Thông báo',
                                ),
                                if (service.unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '${service.unreadCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.qr_code_2,
                            color: Colors.white,
                            size: 30,
                          ),
                          tooltip: "Quét mã QR",
                          onPressed: _moCameraQuetQR,
                        ),
                        const SizedBox(width: 4),
                        Image.asset(
                          "assets/icon/app_icon.png",
                          width: 46,
                          height: 46,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAnimatedBox(
                      "Kho Hàng Nhập",
                      _tongHoatDong,
                      Colors.green,
                      0, // <--- THAY ĐỔI Ở ĐÂY
                    ),
                    _buildAnimatedBox(
                      "Kho Hàng Xuất",
                      _tongDaXuat,
                      Colors.orange,
                      1, // <--- THAY ĐỔI Ở ĐÂY
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Tìm kiếm kho hàng...",
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                        _applySearch();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF4A00E0),
              labelColor: const Color(0xFF4A00E0),
              unselectedLabelColor: Colors.grey,
              tabs: [
                const Tab(text: "Kho Hàng Nhập"),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Kho Hàng Xuất"),
                      const SizedBox(width: 4),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: _xoaTatCaLichSu,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [_buildList("Hoạt động"), _buildList("Đã xuất")],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A00E0),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ThemKhoHangScreen()),
          );
          if (result == true) await _loadDanhSach();
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF4A00E0),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == _currentIndex) return;
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/danh-sach-nhan-vien');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/hoa-don');
              break;
            case 2:
              // Current screen
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/doanh-thu');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/home');
              break;
          }
        },
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

  // <--- BẮT ĐẦU HÀM ĐƯỢC CẬP NHẬT --->
  Widget _buildAnimatedBox(String title, int count, Color color, int tabIndex) {
    return Expanded(
      child: InkWell(
        onTap: () {
          _tabController.animateTo(tabIndex);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "$count",
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // <--- KẾT THÚC HÀM ĐƯỢC CẬP NHẬT --->

  Widget _buildList(String trangThai) {
    final ds = _filteredKho.where((k) => k.trangThai == trangThai).toList();
    if (ds.isEmpty) return const Center(child: Text("Không có dữ liệu"));

    return ListView.builder(
      itemCount: ds.length,
      itemBuilder: (context, index) {
        final kho = ds[index];
        final start = kho.ngayNhap ?? DateTime.now();
        final end = kho.ngayXuat ?? DateTime.now();
        final soNgay = end.difference(start).inDays;
        final statusColor = kho.trangThai == "Hoạt động"
            ? Colors.green
            : Colors.grey;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChiTietKhoHangScreen(kho: kho),
                  ),
                );
                if (result != null) await _loadDanhSach();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _xoaKhoHang(kho.id),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: statusColor,
                            child: Text(
                              kho.tenKho!.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kho.tenKho ?? "",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (kho.ghiChu != null &&
                                    kho.ghiChu!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      kho.ghiChu!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  "Ngày nhập: ${_formatDate(start)}${kho.ngayXuat != null ? " | Ngày xuất: ${_formatDate(end)}" : ""}",
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                if (soNgay > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "$soNgay ngày trong kho",
                                      style: TextStyle(
                                        color: Colors.blue[800],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                if (kho.giaTri != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      "Giá trị: ${_formatCurrency(kho.giaTri)}",
                                      style: const TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (kho.trangThai != "Đã xuất")
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ThemKhoHangScreen(kho: kho),
                            ),
                          );
                          if (result == true) await _loadDanhSach();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
