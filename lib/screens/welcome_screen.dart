import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'splash_screen.dart'; // để dùng VLogoPainter

/// ================= WELCOME SCREEN =================
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _buttonController;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      _textController.forward();
    });

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.8,
      upperBound: 1.0,
    )..forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  /// Hàm chuyển trang với hiệu ứng Slide
  void navigateWithSlide(Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          final offsetAnimation =
              Tween<Offset>(
                begin: const Offset(1.0, 0.0), // từ phải sang
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            // ========== Logo ==========
            FadeTransition(
              opacity: _logoController,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, -0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _logoController,
                        curve: Curves.easeOut,
                      ),
                    ),
                child: Column(
                  children: const [
                    CustomPaint(size: Size(120, 120), painter: VLogoPainter()),
                    SizedBox(height: 12),
                    Text(
                      "VIETFLOW",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // ========== Text ==========
            FadeTransition(
              opacity: _textController,
              child: Column(
                children: const [
                  Text(
                    "Welcome!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Quản lý dễ dàng",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // ========== Buttons ==========
            ScaleTransition(
              scale: _buttonController,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => navigateWithSlide(const LoginScreen()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Đăng nhập",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => navigateWithSlide(const RegisterScreen()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Đăng ký",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
