import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hoadon.dart';
import '../models/khohang.dart';
import '../models/nhanvien.dart';

// ===== Firebase Auth + Google Mock =====
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'screens/doanh_thu_screen.dart';

// ===== Screens & Services =====
import 'screens/danh_sach_nhan_vien_screen.dart';
import 'screens/kho_hang_screen.dart';
import 'screens/hoa_don_screen.dart';
import 'services/api_service.dart';
import 'screens/show_qr_screen.dart';
import 'api_config.dart';
import 'screens/api_settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

/// Mock Firebase & Google Sign-In (để test)
final mockGoogleSignIn = MockGoogleSignIn();
final mockFirebaseAuth = MockFirebaseAuth(
  mockUser: MockUser(
    isAnonymous: false,
    email: 'mockuser@gmail.com',
    displayName: 'Mock User',
    uid: 'mock-uid-123',
  ),
);

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
          title: 'Quản Lý',
          theme: ThemeData(
            fontFamily: 'Roboto',
            primaryColor: const Color(0xFF4A00E0), // tím đậm
            colorScheme: ColorScheme.fromSwatch().copyWith(
              secondary: const Color(0xFF8E2DE2), // tím nhạt
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          routes: {
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/danh-sach-nhan-vien': (context) => const DanhSachNhanVienScreen(),
            '/kho-hang': (context) => KhoHangScreen(),
            '/hoa-don': (context) => const HoaDonScreen(),
            '/cai-dat-api': (context) => const ApiSettingsScreen(),
            '/show-qr': (context) => const ShowQrScreen(),
            '/doanh-thu': (context) => const DoanhThuScreen(),
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
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      ApiService.token = token;
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warehouse, size: 100, color: Colors.white),
              SizedBox(height: 20),
              Text(
                "VIETFLOW",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 30),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= WELCOME SCREEN =================
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A00E0),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Cài đặt API",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApiSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warehouse, size: 100, color: Colors.white),
            const SizedBox(height: 30),
            const Text(
              "Welcome!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Quản lý dễ dàng",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4A00E0),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Đăng nhập", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Đăng ký", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
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
  double _tongDoanhThuThang = 0;
  double _tongDoanhThuNam = 0;

  @override
  void initState() {
    super.initState();
    _loadSoNhanVien();
    _loadSoKhoHang();
    _loadSoHoaDon();
    _loadDoanhThu();
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

  Future<void> _loadDoanhThu() async {
    final hoaDonList = await ApiService.layDanhSachHoaDon();
    final khoHangList = await ApiService.layDanhSachKhoHang();
    final nhanVienList = await ApiService.layDanhSachNhanVien();

    double tongHoaDon = 0;
    double tongKho = 0;
    double tongLuong = 0;

    final now = DateTime.now();

    // ✅ Hóa đơn
    for (HoaDon hd in hoaDonList) {
      if (hd.ngayLap != null &&
          hd.ngayLap!.month == now.month &&
          hd.ngayLap!.year == now.year) {
        if (hd.loaiHoaDon?.toLowerCase() == "xuất") {
          tongHoaDon += hd.tongTien.toDouble();
        } else if (hd.loaiHoaDon?.toLowerCase() == "nhập") {
          tongHoaDon -= hd.tongTien.toDouble();
        }
      }
    }

    // ✅ Kho hàng
    for (KhoHang kho in khoHangList) {
      if (kho.ngayNhap != null &&
          kho.ngayNhap!.month == now.month &&
          kho.ngayNhap!.year == now.year) {
        if (kho.trangThai == "Đã xuất") {
          tongKho += kho.giaTri ?? 0;
        } else if (kho.trangThai == "Hoạt động") {
          tongKho -= kho.giaTri ?? 0;
        }
      }
    }

    // ✅ Nhân viên
    for (NhanVien nv in nhanVienList) {
      for (var wd in nv.workDays) {
        if (wd.ngay.month == now.month && wd.ngay.year == now.year) {
          tongLuong += nv.luongTheoGio * wd.soGio;
        }
      }
    }

    // ✅ Tổng doanh thu tháng (giống DoanhThuScreen)
    final tongThang = tongHoaDon + tongKho - tongLuong;

    if (mounted) {
      setState(() {
        _tongDoanhThuThang = tongThang;
      });
    }
  }

  String getToday() => DateFormat("dd/MM/yyyy").format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Chào buổi sáng,\n${getToday()}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.warehouse, color: Colors.white, size: 28),
                        SizedBox(width: 6),
                        Text(
                          "VIETFLOW",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      buildCardItem(
                        icon: Icons.people,
                        title: "Nhân Viên",
                        subtitle: "$_soNhanVien nhân viên",
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            '/danh-sach-nhan-vien',
                          );
                          _loadSoNhanVien();
                        },
                      ),
                      buildCardItem(
                        icon: Icons.receipt,
                        title: "Hóa Đơn",
                        subtitle: "$_soHoaDon hóa đơn",
                        onTap: () async {
                          await Navigator.pushNamed(context, '/hoa-don');
                          _loadSoHoaDon();
                        },
                      ),
                      buildCardItem(
                        icon: Icons.warehouse,
                        title: "Kho Hàng",
                        subtitle: "$_soSanPham sản phẩm",
                        onTap: () async {
                          await Navigator.pushNamed(context, '/kho-hang');
                          _loadSoKhoHang();
                        },
                      ),
                      buildCardItem(
                        icon: Icons.bar_chart,
                        title: "Doanh Thu",
                        subtitle:
                            "Tháng ${DateTime.now().month}: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(_tongDoanhThuThang)}\n",
                        onTap: () async {
                          await Navigator.pushNamed(context, '/doanh-thu');
                          _loadDoanhThu();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          setState(() => _currentIndex = index);
          if (index == 0) {
            await Navigator.pushNamed(context, '/danh-sach-nhan-vien');
          }
          if (index == 1) {
            await Navigator.pushNamed(context, '/hoa-don');
          }
          if (index == 2) {
            await Navigator.pushNamed(context, '/kho-hang');
          }
          if (index == 3) {
            await Navigator.pushNamed(context, '/doanh-thu');
          }
          if (index == 4) {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => const AccountSheet(),
            );
          }
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A00E0),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Nhân Viên"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Hóa Đơn"),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: "Kho Hàng",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Doanh Thu",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: "Tài khoản",
          ),
        ],
      ),
    );
  }

  Widget buildCardItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF4A00E0).withOpacity(0.1),
              child: Icon(icon, size: 28, color: const Color(0xFF4A00E0)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class AccountSheet extends StatefulWidget {
  const AccountSheet({super.key});

  @override
  State<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<AccountSheet> {
  String _userName = "Tên người dùng";
  String _userEmail = "email@example.com";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString("userName") ?? "Tên người dùng";
      _userEmail = prefs.getString("userEmail") ?? "email@example.com";
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    final username = prefs.getString("username");
    final password = prefs.getString("password");
    final remember = prefs.getBool("rememberMe") ?? false;

    await prefs.clear();

    if (remember) {
      await prefs.setString("username", username ?? "");
      await prefs.setString("password", password ?? "");
      await prefs.setBool("rememberMe", true);
    }

    ApiService.token = null;

    if (mounted) {
      Navigator.pushReplacementNamed(context, "/welcome");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF4A00E0),
            child: const Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            _userName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(_userEmail, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Cài đặt"),
            onTap: () {
              Navigator.pushNamed(context, "/settings");
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Đăng xuất"),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
