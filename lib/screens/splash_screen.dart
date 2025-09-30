import 'package:flutter/material.dart';
import 'welcome_screen.dart';

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

    // Sau 2 giây tự chuyển sang WelcomeScreen
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A00E0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            /// Logo chữ V
            CustomPaint(size: Size(120, 120), painter: VLogoPainter()),
            SizedBox(height: 20),
            Text(
              "VIETFLOW",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= V LOGO PAINTER =================
class VLogoPainter extends CustomPainter {
  const VLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.2); // điểm bắt đầu bên trái
    path.lineTo(size.width * 0.5, size.height * 0.8); // xuống giữa
    path.lineTo(size.width * 0.9, size.height * 0.2); // lên bên phải

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
