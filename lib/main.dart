// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'screens/account_settings_screen.dart';
import 'screens/doanh_thu_screen.dart';
import 'screens/danh_sach_nhan_vien_screen.dart';
import 'screens/kho_hang_screen.dart';
import 'screens/hoa_don_screen.dart';
import 'screens/show_qr_screen.dart';
import 'screens/api_settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

import 'models/hoadon.dart';
import 'models/khohang.dart';
import 'models/nhanvien.dart';
import 'services/api_service.dart';
import 'api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();

  runApp(const QuanLyXuongApp());
  configLoading();
}

/// 🔹 EasyLoading config
void configLoading() {
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.circle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.white
    ..backgroundColor = const Color(0xFF4A00E0)
    ..indicatorColor = Colors.white
    ..textColor = Colors.white
    ..maskColor = Colors.black.withOpacity(0.4)
    ..userInteractions = false
    ..dismissOnTap = false;
}

/// ================== APP ROOT ==================
class QuanLyXuongApp extends StatelessWidget {
  const QuanLyXuongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ApiConfig.hostNotifier,
      builder: (context, host, _) {
        return MaterialApp(
          title: 'Quản Lý Xưởng',
          theme: ThemeData(
            fontFamily: 'Roboto',
            primaryColor: const Color(0xFF4A00E0),
            colorScheme: ColorScheme.fromSwatch().copyWith(
              secondary: const Color(0xFF8E2DE2),
            ),
          ),
          debugShowCheckedModeBanner: false,
          builder: EasyLoading.init(),
          onGenerateRoute: _buildPageRoute,
          home: const SplashScreen(),
        );
      },
    );
  }

  /// 🔹 Custom animation khi chuyển trang
  Route<dynamic> _buildPageRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/welcome':
        page = const WelcomeScreen();
        break;
      case '/login':
        page = const LoginScreen();
        break;
      case '/register':
        page = const RegisterScreen();
        break;
      case '/home':
        page = const HomeScreen();
        break;
      case '/danh-sach-nhan-vien':
        page = const DanhSachNhanVienScreen();
        break;
      case '/kho-hang':
        page = KhoHangScreen();
        break;
      case '/hoa-don':
        page = const HoaDonScreen();
        break;
      case '/cai-dat-api':
        page = const ApiSettingsScreen();
        break;
      case '/show-qr':
        page = const ShowQrScreen();
        break;
      case '/doanh-thu':
        page = const DoanhThuScreen();
        break;
      default:
        page = const SplashScreen();
    }

    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        const begin = Offset(0.1, 0.1);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

/// ================== SPLASH SCREEN ==================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _checkToken();
  }

  Future<void> _checkToken() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      ApiService.token = token;
      if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (context.mounted) Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeIn,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/icon/app_icon.png",
                  width: 180,
                  height: 180,
                ),
                const SizedBox(height: 20),
                const Text(
                  "VIETFLOW",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 30),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ================== WELCOME SCREEN ==================
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
            onPressed: () => Navigator.pushNamed(context, '/cai-dat-api'),
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
            Image.asset("assets/icon/app_icon.png", width: 180, height: 180),
            const SizedBox(height: 30),
            const Text(
              "Welcome!",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Quản lý dễ dàng cùng VIETFLOW",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
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
              onPressed: () => Navigator.pushNamed(context, '/register'),
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

/// ================== HOME SCREEN ==================
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    EasyLoading.show(status: 'Đang tải...');
    await Future.wait([
      _loadSoNhanVien(),
      _loadSoKhoHang(),
      _loadSoHoaDon(),
      _loadDoanhThu(),
    ]);
    EasyLoading.dismiss();
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

    for (KhoHang kho in khoHangList) {
      if (kho.ngayNhap != null &&
          kho.ngayNhap!.month == now.month &&
          kho.ngayNhap!.year == now.year) {
        tongKho += kho.giaTri ?? 0;
      }
    }

    for (NhanVien nv in nhanVienList) {
      for (var wd in nv.workDays) {
        if (wd.ngay.month == now.month && wd.ngay.year == now.year) {
          tongLuong += nv.luongTheoGio * wd.soGio;
        }
      }
    }

    if (mounted) {
      setState(() {
        _tongDoanhThuThang = tongHoaDon + tongKho - tongLuong;
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Chào buổi sáng,",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          getToday(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    // ✅ Logo gọn ở góc phải
                    Image.asset(
                      "assets/icon/app_icon.png",
                      width: 100,
                      height: 100,
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
                      _buildCard(
                        icon: Icons.people,
                        title: "Nhân Viên",
                        subtitle: "$_soNhanVien nhân viên",
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/danh-sach-nhan-vien',
                        ).then((_) => _loadSoNhanVien()),
                      ),
                      _buildCard(
                        icon: Icons.receipt,
                        title: "Hóa Đơn",
                        subtitle: "$_soHoaDon hóa đơn",
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/hoa-don',
                        ).then((_) => _loadSoHoaDon()),
                      ),
                      _buildCard(
                        icon: Icons.warehouse,
                        title: "Kho Hàng",
                        subtitle: "$_soSanPham sản phẩm",
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/kho-hang',
                        ).then((_) => _loadSoKhoHang()),
                      ),
                      _buildCard(
                        icon: Icons.bar_chart,
                        title: "Doanh Thu",
                        subtitle:
                            "Tháng ${DateTime.now().month}: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(_tongDoanhThuThang)}",
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/doanh-thu',
                        ).then((_) => _loadDoanhThu()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // ✅ Taskbar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          setState(() => _currentIndex = index);
          if (index == 0)
            await Navigator.pushNamed(context, '/danh-sach-nhan-vien');
          if (index == 1) await Navigator.pushNamed(context, '/hoa-don');
          if (index == 2) await Navigator.pushNamed(context, '/kho-hang');
          if (index == 3) await Navigator.pushNamed(context, '/doanh-thu');
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

  Widget _buildCard({
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

/// ================== ACCOUNT SHEET ==================
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

  /// 🔹 Lấy thông tin user từ SharedPreferences
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString("userName") ?? "Tên người dùng";
      _userEmail = prefs.getString("userEmail") ?? "email@example.com";
    });
  }

  /// 🔹 Đăng xuất (chỉ xóa token)
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    ApiService.token = null;

    if (mounted) {
      Navigator.pushReplacementNamed(context, "/welcome");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar + Info
          CircleAvatar(
            radius: 45,
            backgroundColor: const Color(0xFF4A00E0).withOpacity(0.2),
            child: const Icon(Icons.person, size: 55, color: Color(0xFF4A00E0)),
          ),
          const SizedBox(height: 12),
          Text(
            _userName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            _userEmail,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Menu Options
          _buildMenuItem(
            icon: Icons.qr_code,
            title: "Mã QR",
            onTap: () => Navigator.pushNamed(context, "/show-qr"),
          ),
          _buildMenuItem(
            icon: Icons.settings,
            title: "Cài đặt tài khoản",
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountSettingsScreen(),
                ),
              );
              if (result == true) {
                await _loadUser();
              }
            },
          ),
          _buildMenuItem(
            icon: Icons.api,
            title: "Cài đặt API",
            onTap: () => Navigator.pushNamed(context, "/cai-dat-api"),
          ),
          const Divider(height: 24),

          // Logout Button
          ElevatedButton.icon(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A00E0),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }

  /// Custom item widget
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF4A00E0).withOpacity(0.1),
        child: Icon(icon, color: const Color(0xFF4A00E0)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
