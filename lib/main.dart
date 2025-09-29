import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/danh_sach_nhan_vien_screen.dart';
import 'screens/kho_hang_screen.dart';
import 'screens/hoa_don_screen.dart';
import 'services/api_service.dart';
import 'screens/show_qr_screen.dart';
import 'api_config.dart';
import 'screens/api_settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();
  runApp(const QuanLyXuongApp());
}

class QuanLyXuongApp extends StatelessWidget {
  const QuanLyXuongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ApiConfig.hostNotifier,
      builder: (context, host, _) {
        return MaterialApp(
          title: 'Quản Lý Xưởng Gỗ',
          theme: ThemeData(primarySwatch: Colors.blue),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          routes: {
            '/login': (context) => LoginScreen(),
            '/register': (context) => RegisterScreen(),
            '/home': (context) => HomeScreen(),
            '/danh-sach-nhan-vien': (context) => DanhSachNhanVienScreen(),
            '/kho-hang': (context) => KhoHangScreen(),
            '/hoa-don': (context) => HoaDonScreen(),
            '/cai-dat-api': (context) => ApiSettingsScreen(),
            '/show-qr': (context) => ShowQrScreen(),
          },
        );
      },
    );
  }
}

/// ================= SPLASH SCREEN =================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  void _checkToken() async {
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      ApiService.token = token; // load token vào ApiService
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// ================= HOME SCREEN =================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
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
    if (mounted) setState(() => _soNhanVien = ds.length);
  }

  Future<void> _loadSoKhoHang() async {
    final ds = await ApiService.layDanhSachKhoHang();
    if (mounted) setState(() => _soSanPham = ds.length);
  }

  Future<void> _loadSoHoaDon() async {
    final ds = await ApiService.layDanhSachHoaDon();
    if (mounted) setState(() => _soHoaDon = ds.length);
  }

  String getToday() => DateFormat("dd/MM/yyyy").format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Quản Lý Xưởng Gỗ",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal[400],
        elevation: 8,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/cai-dat-api'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              ApiService.token = null;
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.teal[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Trang chủ",
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                  Text(
                    getToday(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
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
            await Navigator.pushReplacementNamed(
              context,
              '/danh-sach-nhan-vien',
            );
          if (index == 1)
            await Navigator.pushReplacementNamed(context, '/hoa-don');
          if (index == 2)
            await Navigator.pushReplacementNamed(context, '/kho-hang');
        },
        backgroundColor: Colors.teal[400],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(20),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
