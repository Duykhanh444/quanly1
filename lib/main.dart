import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'screens/danh_sach_nhan_vien_screen.dart';
import 'screens/kho_hang_screen.dart';
import 'screens/hoa_don_screen.dart';
import 'package:quan_ly_xuong/services/api_service.dart';
import 'screens/show_qr_screen.dart'; // ✅ import thêm

// ✅ import ApiConfig & màn hình Cài đặt API
import 'api_config.dart';
import 'screens/api_settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init(); // ✅ load host từ SharedPreferences
  runApp(QuanLyXuongApp());
}

class QuanLyXuongApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ApiConfig.hostNotifier, // ✅ lắng nghe host thay đổi
      builder: (context, host, _) {
        return MaterialApp(
          title: 'Quản Lý Xưởng Gỗ',
          theme: ThemeData(primarySwatch: Colors.blue),
          debugShowCheckedModeBanner: false,
          home: HomeScreen(),
          routes: {
            '/danh-sach-nhan-vien': (context) => DanhSachNhanVienScreen(),
            '/kho-hang': (context) => KhoHangScreen(),
            '/hoa-don': (context) => HoaDonScreen(),
            '/cai-dat-api': (context) =>
                const ApiSettingsScreen(), // ✅ thêm route mới
            '/show-qr': (context) => const ShowQrScreen(), // ✅ thêm route mới
          },
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _soNhanVien = 0;
  int _soSanPham = 0;
  int _soHoaDon = 0;

  @override
  void initState() {
    super.initState();
    _loadSoNhanVien();
    _loadSoKhoHang();
    _loadSoHoaDon();
  }

  Future<void> _loadSoNhanVien() async {
    final ds = await ApiService.layDanhSachNhanVien();
    setState(() => _soNhanVien = ds.length);
  }

  Future<void> _loadSoKhoHang() async {
    final ds = await ApiService.layDanhSachKhoHang();
    setState(() => _soSanPham = ds.length);
  }

  Future<void> _loadSoHoaDon() async {
    final ds = await ApiService.layDanhSachHoaDon();
    setState(() => _soHoaDon = ds.length);
  }

  String getToday() => DateFormat("dd/MM/yyyy").format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Quản Lý Xưởng Gỗ",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black38,
                offset: Offset(1, 2),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal[400],
        elevation: 8,
        shadowColor: Colors.tealAccent.withOpacity(0.6),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/cai-dat-api',
              ); // ✅ mở màn hình cài đặt API
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Header nhỏ phía trên
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.teal[300],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Home",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(2, 2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    getToday(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cards gọn hàng
            Expanded(
              child: ListView(
                physics: BouncingScrollPhysics(),
                children: [
                  buildStatCard(
                    title: "Tổng số nhân viên",
                    value: "$_soNhanVien",
                    color: Colors.blue,
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        '/danh-sach-nhan-vien',
                      );
                      _loadSoNhanVien();
                    },
                  ),
                  buildStatCard(
                    title: "Tổng số hóa đơn",
                    value: "$_soHoaDon",
                    color: Colors.purple,
                    onTap: () async {
                      await Navigator.pushNamed(context, '/hoa-don');
                      _loadSoHoaDon();
                    },
                  ),
                  buildStatCard(
                    title: "Kho Hàng",
                    value: "$_soSanPham",
                    color: Colors.teal,
                    onTap: () async {
                      await Navigator.pushNamed(context, '/kho-hang');
                      _loadSoKhoHang();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          setState(() => _currentIndex = index);

          if (index == 0)
            await Navigator.pushNamed(context, '/danh-sach-nhan-vien');
          if (index == 1) await Navigator.pushNamed(context, '/hoa-don');
          if (index == 2) await Navigator.pushNamed(context, '/kho-hang');
        },
        backgroundColor: Colors.teal[400],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black38, offset: Offset(1, 2), blurRadius: 2),
          ],
        ),
        unselectedLabelStyle: TextStyle(
          shadows: [
            Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Nhân Viên"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Hóa Đơn"),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: "Kho Hàng",
          ),
        ],
      ),
    );
  }

  Widget buildStatCard({
    required String title,
    required String value,
    required Color color,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: StatefulBuilder(
        builder: (context, setState) {
          bool _isPressed = false;
          return Listener(
            onPointerDown: (_) => setState(() => _isPressed = true),
            onPointerUp: (_) => setState(() => _isPressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(20),
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: [color.withOpacity(_isPressed ? 0.75 : 0.9), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: _isPressed ? 8 : 16,
                    offset: Offset(0, _isPressed ? 3 : 6),
                  ),
                ],
              ),
              transform: Matrix4.identity()..scale(_isPressed ? 0.96 : 1.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(1, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
