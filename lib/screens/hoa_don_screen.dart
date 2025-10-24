// lib/screens/hoa_don_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/hoadon.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'chi_tiet_hoa_don_screen.dart';
import 'quet_ma_screen.dart';

class HoaDonScreen extends StatefulWidget {
  const HoaDonScreen({super.key});

  @override
  State<HoaDonScreen> createState() => _HoaDonScreenState();
}

class _HoaDonScreenState extends State<HoaDonScreen>
    with SingleTickerProviderStateMixin {
  List<HoaDon> dsHoaDon = [];
  bool _isLoading = true;
  late TabController _tabController;

  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDanhSach();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ... (Các hàm _loadDanhSach, _applySearch, _formatMoney, _xoaHoaDon, _xoaTatCaDaThanhToan giữ nguyên) ...
  Future<void> _loadDanhSach() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.wait([
      ApiService.layDanhSachHoaDon()
          .then((list) {
            if (mounted) {
              setState(() {
                dsHoaDon = list;
              });
            }
          })
          .catchError((_) {
            if (mounted) {
              setState(() {
                dsHoaDon = [];
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

  List<HoaDon> get _chuaThanhToan =>
      _applySearch(dsHoaDon.where((hd) => hd.trangThai != "Đã thanh toán"));

  List<HoaDon> get _daThanhToan =>
      _applySearch(dsHoaDon.where((hd) => hd.trangThai == "Đã thanh toán"));

  List<HoaDon> _applySearch(Iterable<HoaDon> list) {
    if (_searchQuery.isEmpty) return list.toList();
    return list
        .where(
          (hd) =>
              hd.maHoaDon.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  String _formatMoney(int value) =>
      NumberFormat("#,###", "vi_VN").format(value);

  Future<void> _xoaHoaDon(HoaDon hd) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc chắn muốn xóa hóa đơn ${hd.maHoaDon}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final success = await ApiService.xoaHoaDon(hd.id);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã xóa hóa đơn")));
      await _loadDanhSach();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Xóa hóa đơn thất bại")));
    }
  }

  Future<void> _xoaTatCaDaThanhToan() async {
    if (_daThanhToan.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text(
          "Bạn có chắc chắn muốn xóa tất cả ${_daThanhToan.length} hóa đơn đã thanh toán?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa tất cả"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đang xóa ${_daThanhToan.length} hóa đơn...")),
    );

    for (var hd in _daThanhToan) {
      await ApiService.xoaHoaDon(hd.id);
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã xóa xong")));
    }
    await _loadDanhSach();
  }

  @override
  Widget build(BuildContext context) {
    // ✨ Lấy lời chào và ngày tháng
    final String greeting = _getGreeting();
    final String today = DateFormat("dd/MM/yyyy").format(DateTime.now());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDanhSach,
        child: Column(
          children: [
            // ✨ BẮT ĐẦU PHẦN HEADER ĐÃ SỬA
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 10,
                16,
                12,
              ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting, // Sử dụng lời chào động
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              today,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // ... (Phần Consumer<NotificationService> và Image.asset giữ nguyên) ...
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                          Image.asset(
                            "assets/icon/app_icon.png",
                            width: 90,
                            height: 90,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ✨ SỬA: Bọc các ô tóm tắt bằng LayoutBuilder
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Đặt một ngưỡng (breakpoint). Nếu chiều rộng nhỏ hơn ngưỡng này, layout sẽ chuyển thành dạng cột.
                      const double breakpoint = 380.0;
                      if (constraints.maxWidth < breakpoint) {
                        // Giao diện cho màn hình hẹp (dạng cột)
                        return Column(
                          children: [
                            _buildSummaryBox(
                              "Chưa thanh toán",
                              _chuaThanhToan.length,
                              Colors.orangeAccent,
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryBox(
                              "Đã thanh toán",
                              _daThanhToan.length,
                              Colors.greenAccent,
                            ),
                          ],
                        );
                      } else {
                        // Giao diện cho màn hình rộng (dạng hàng)
                        return Row(
                          children: [
                            Expanded(
                              child: _buildSummaryBox(
                                "Chưa thanh toán",
                                _chuaThanhToan.length,
                                Colors.orangeAccent,
                              ),
                            ),
                            Expanded(
                              child: _buildSummaryBox(
                                "Đã thanh toán",
                                _daThanhToan.length,
                                Colors.greenAccent,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 12),
                  // ... (Phần còn lại của header giữ nguyên) ...
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Danh sách hóa đơn",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const QuetMaScreen(),
                                ),
                              );

                              if (result != null && result is String) {
                                final hoaDon = await ApiService.taoHoaDonTheoMa(
                                  result,
                                );

                                if (hoaDon != null) {
                                  if (!context.mounted) return;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChiTietHoaDonScreen(hd: hoaDon),
                                    ),
                                  );
                                  await _loadDanhSach();
                                } else {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "❌ Không tìm thấy sản phẩm hoặc lỗi khi tạo hóa đơn",
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _isSearching ? Icons.close : Icons.search,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                if (_isSearching) {
                                  _isSearching = false;
                                  _searchQuery = "";
                                  _searchController.clear();
                                } else {
                                  _isSearching = true;
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_sweep,
                              color: Colors.white,
                            ),
                            onPressed: _xoaTatCaDaThanhToan,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_isSearching)
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Tìm kiếm theo mã hóa đơn...",
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                ],
              ),
            ),

            // ✨ KẾT THÚC PHẦN HEADER ĐÃ SỬA
            Material(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF4A00E0),
                labelColor: const Color(0xFF4A00E0),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "Chưa thanh toán"),
                  Tab(text: "Đã thanh toán"),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(_chuaThanhToan),
                        _buildList(_daThanhToan),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A00E0),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChiTietHoaDonScreen(),
            ),
          );
          if (result != null) {
            await _loadDanhSach();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex == index) return;
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/danh-sach-nhan-vien');
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/kho-hang');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/doanh-thu');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/home');
              break;
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

  Widget _buildList(List<HoaDon> list) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          _isSearching ? "Không tìm thấy kết quả" : "Không có hóa đơn",
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final hd = list[index];
        final color = hd.trangThai == "Đã thanh toán"
            ? Colors.green
            : Colors.orange;
        final ngay = hd.ngayLap != null
            ? DateFormat('dd/MM/yyyy').format(hd.ngayLap!)
            : "-";

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: ListTile(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChiTietHoaDonScreen(hd: hd)),
              );
              await _loadDanhSach();
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            title: Text(
              "Mã: ${hd.maHoaDon}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              "Loại: ${hd.loaiHoaDon ?? "Chưa chọn"}\n"
              "SL mặt hàng: ${hd.items.length}\n"
              "Ngày lập: $ngay\n"
              "Tổng tiền: ${_formatMoney(hd.tongTien)} VND\n"
              "Thanh toán: ${hd.phuongThuc ?? "Chưa chọn"}",
              style: const TextStyle(height: 1.4),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hd.trangThai != "Đã thanh toán")
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _xoaHoaDon(hd),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hd.trangThai ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✨ SỬA: Gỡ bỏ Expanded ra khỏi hàm này để nó linh hoạt hơn
  Widget _buildSummaryBox(String title, int count, Color color) {
    return Container(
      // margin không cần thiết nếu parent xử lý (nhưng giữ lại cũng không sao)
      // margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        // ✨ Dùng Row để icon và text nằm cạnh nhau đẹp hơn
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
        ],
      ),
    );
  }

  // ✨ MỚI: Thêm hàm lấy lời chào theo buổi
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Chào buổi sáng,';
    }
    if (hour < 18) {
      return 'Chào buổi chiều,';
    }
    return 'Chào buổi tối,';
  }
}
