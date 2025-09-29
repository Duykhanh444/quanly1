import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  // 🔹 Hàm kiểm tra password hợp lệ
  String? _validatePassword(String password) {
    if (password.length < 6) {
      return "⚠️ Mật khẩu phải ít nhất 6 ký tự";
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "⚠️ Mật khẩu phải chứa ít nhất 1 chữ in hoa (A-Z)";
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "⚠️ Mật khẩu phải chứa ít nhất 1 chữ thường (a-z)";
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "⚠️ Mật khẩu phải chứa ít nhất 1 số (0-9)";
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return "⚠️ Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt (!@#\$...)";
    }
    return null; // hợp lệ
  }

  Future<void> _dangKy() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Vui lòng nhập tên đăng nhập và mật khẩu"),
        ),
      );
      return;
    }

    // Kiểm tra password theo quy tắc
    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(passwordError)));
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    final success = await ApiService.dangKy(
      username: username,
      password: password,
      email: email.isEmpty ? null : email,
    );

    if (mounted) setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Đăng ký thành công")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Đăng ký thất bại")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng ký"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: "Tên đăng nhập",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mật khẩu",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email (tùy chọn)",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _dangKy,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Đăng ký", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            const Text(
              "🔑 Quy tắc mật khẩu:\n"
              "• Ít nhất 6 ký tự\n"
              "• Có chữ in hoa (A-Z)\n"
              "• Có chữ thường (a-z)\n"
              "• Có số (0-9)\n"
              "• Có ký tự đặc biệt (!@#...)\n",
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
