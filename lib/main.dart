// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/notification_service.dart';
import 'screens/notification_screen.dart';
import 'screens/account_settings_screen.dart';
import 'screens/doanh_thu_screen.dart';
import 'screens/danh_sach_nhan_vien_screen.dart';
import 'screens/kho_hang_screen.dart';
import 'screens/hoa_don_screen.dart';
import 'screens/show_qr_screen.dart';
import 'screens/api_settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

// ✨ THÊM 2 IMPORT CHO MÀN HÌNH MỚI ✨
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';

import 'models/hoadon.dart';
import 'models/khohang.dart';
import 'models/nhanvien.dart';
import 'services/api_service.dart';
import 'api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();

  runApp(
    ChangeNotifierProvider(
      create: (context) => NotificationService(),
      child: const QuanLyXuongApp(),
    ),
  );
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
              background: const Color(0xFFF4F6FD),
            ),
          ),
          debugShowCheckedModeBanner: false,
          builder: EasyLoading.init(),
          onGenerateRoute: _buildPageRoute, // Sử dụng hàm này
          home: const SplashScreen(),
        );
      },
    );
  }

  /// 🔹 Custom animation khi chuyển trang (ĐÃ CẬP NHẬT)
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

      // ✨ THÊM 2 CASE MỚI CHO QUÊN MẬT KHẨU ✨
      case '/forgot-password':
        page = const ForgotPasswordScreen();
        break;
      case '/reset-password':
        // Lấy email từ arguments khi chuyển trang
        final email = settings.arguments as String?;
        page = ResetPasswordScreen(email: email ?? 'Lỗi email');
        break;
      // ✨ KẾT THÚC PHẦN THÊM MỚI ✨

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
      case '/notifications':
        page = const NotificationScreen();
        break;
      default:
        page = const SplashScreen(); // Mặc định về Splash nếu route lạ
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
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );

    _controller.forward();
    _navigateToWelcome(); // Luôn gọi hàm này
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToWelcome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/welcome');
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  "assets/icon/app_icon.png",
                  width: 150,
                  height: 150,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                "VIETFLOW",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
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
        elevation: 0,
        backgroundColor: const Color(0xFF4A00E0),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
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
  String _userName = "User";
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? currentUserName = prefs.getString("userName");

    if (currentUserName == null ||
        currentUserName.isEmpty ||
        currentUserName == "User") {
      try {
        final userInfo = await ApiService.layThongTinCaNhan();
        currentUserName = userInfo['username'];
        String? storedEmail = userInfo['email'];

        await prefs.setString("userName", currentUserName ?? "User");
        if (storedEmail != null) {
          await prefs.setString("userEmail", storedEmail);
        }
      } catch (e) {
        print("Lỗi khi tải thông tin cá nhân: $e");
        currentUserName = "User";
      }
    }

    String avatarKey = "userAvatar_$currentUserName";
    String? currentUserAvatarPath = prefs.getString(avatarKey);

    if (mounted) {
      setState(() {
        _userName = currentUserName ?? "User";
        _avatarPath = currentUserAvatarPath;
      });
    }
  }

  Future<void> _loadData() async {
    EasyLoading.show(status: 'Đang tải...');
    await Future.wait([
      _loadSoNhanVien(),
      _loadSoKhoHang(),
      _loadSoHoaDon(),
      _loadDoanhThu(),
      Provider.of<NotificationService>(
        context,
        listen: false,
      ).loadNotifications(),
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

  Future<void> _showAccountSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AccountSheet(),
    ).then((_) {
      _loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadData();
                  await _loadUserData();
                },
                color: Theme.of(context).primaryColor,
                child: GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    _buildCard(
                      icon: Icons.people_outline,
                      title: "Nhân Viên",
                      subtitle: "$_soNhanVien nhân viên",
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/danh-sach-nhan-vien',
                      ).then((_) => _loadSoNhanVien()),
                    ),
                    _buildCard(
                      icon: Icons.receipt_long_outlined,
                      title: "Hóa Đơn",
                      subtitle: "$_soHoaDon hóa đơn",
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/hoa-don',
                      ).then((_) => _loadSoHoaDon()),
                    ),
                    _buildCard(
                      icon: Icons.inventory_2_outlined,
                      title: "Kho Hàng",
                      subtitle: "$_soSanPham sản phẩm",
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/kho-hang',
                      ).then((_) => _loadSoKhoHang()),
                    ),
                    _buildCard(
                      icon: Icons.bar_chart_outlined,
                      title: "Doanh Thu",
                      subtitle: NumberFormat.currency(
                        locale: 'vi_VN',
                        symbol: '₫',
                      ).format(_tongDoanhThuThang),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          setState(() => _currentIndex = index);
          if (index == 0) {
            await Navigator.pushNamed(context, '/danh-sach-nhan-vien');
          } else if (index == 1) {
            await Navigator.pushNamed(context, '/hoa-don');
          } else if (index == 2) {
            await Navigator.pushNamed(context, '/kho-hang');
          } else if (index == 3) {
            await Navigator.pushNamed(context, '/doanh-thu');
          } else if (index == 4) {
            await _showAccountSheet();
          }
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) setState(() => _currentIndex = 0);
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A00E0),
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        elevation: 5,
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showAccountSheet,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              backgroundImage: _avatarPath != null
                  ? FileImage(File(_avatarPath!))
                  : null,
              child: _avatarPath == null
                  ? const Icon(Icons.person, size: 28, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showAccountSheet,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Chào buổi sáng,",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Image.asset("assets/icon/app_icon.png", width: 60, height: 60),
          const SizedBox(width: 8),
          Consumer<NotificationService>(
            builder: (context, service, child) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: title == 'Doanh Thu' ? 15 : 14,
                      fontWeight: title == 'Doanh Thu'
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: title == 'Doanh Thu'
                          ? const Color(0xFF4A00E0)
                          : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ],
          ),
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
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    String currentUserName = prefs.getString("userName") ?? "Tên người dùng";
    String avatarKey = "userAvatar_$currentUserName";

    setState(() {
      _userName = currentUserName;
      _userEmail = prefs.getString("userEmail") ?? "email@example.com";
      _avatarPath = prefs.getString(avatarKey);
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    // Không xóa avatar
    await prefs.remove("userName");
    await prefs.remove("userEmail");
    ApiService.token = null;

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _viewAvatar() async {
    if (_avatarPath == null) {
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InteractiveViewer(
                panEnabled: false,
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(File(_avatarPath!), fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "Đóng",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    PermissionStatus status;
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      if (Platform.isAndroid) {
        status = await Permission.storage.request();
      } else {
        status = await Permission.photos.request();
      }
    }

    if (status.isGranted) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 70,
      );

      if (image != null && mounted) {
        final prefs = await SharedPreferences.getInstance();
        String currentUserName = prefs.getString("userName") ?? "User";
        if (currentUserName == "User" || currentUserName.isEmpty) {
          EasyLoading.showError('Không thể lưu avatar, vui lòng thử lại.');
          return;
        }
        String avatarKey = "userAvatar_$currentUserName";

        await prefs.setString(avatarKey, image.path);

        setState(() {
          _avatarPath = image.path;
        });
      }
    } else {
      if (mounted) {
        EasyLoading.showError(
          'Bạn cần cấp quyền để dùng tính năng này',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAvatar(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: _viewAvatar,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: const Color(0xFF4A00E0).withOpacity(0.2),
                      backgroundImage: _avatarPath != null
                          ? FileImage(File(_avatarPath!))
                          : null,
                      child: _avatarPath == null
                          ? const Icon(
                              Icons.person,
                              size: 55,
                              color: Color(0xFF4A00E0),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        onTap: _showAvatarOptions,
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Color(0xFF4A00E0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _userEmail,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _buildMenuItem(
                icon: Icons.qr_code_2,
                title: "Mã QR",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, "/show-qr");
                },
              ),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: "Cài đặt tài khoản",
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountSettingsScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 24, indent: 16, endIndent: 16),
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
        ),
      ),
    );
  }

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
