import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email; // Nhận email từ màn hình trước

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    final token = _tokenController.text.trim();
    final newPassword = _passwordController.text.trim();

    if (token.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập đủ mã và mật khẩu mới")),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Mật khẩu mới phải ít nhất 6 ký tự")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ApiService.resetPassword(
      email: widget.email, // Lấy email đã được truyền vào
      token: token,
      newPassword: newPassword,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Đổi mật khẩu thành công! Vui lòng đăng nhập lại."),
            backgroundColor: Colors.green,
          ),
        );
        // Quay về màn hình đăng nhập
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Mã khôi phục không đúng hoặc đã hết hạn."),
          ),
        );
      }
    }
  }

  // --- SAO CHÉP CÁC HÀM HELPER TỪ LOGINSCREEN ---
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
          ),
        ),
        alignment: Alignment.center,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
  // --- KẾT THÚC HELPER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Đặt Lại Mật Khẩu",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Email: ${widget.email}",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Kiểm tra email và nhập mã khôi phục cùng mật khẩu mới của bạn.",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        label: "Mã khôi phục (từ email)",
                        icon: Icons.vpn_key,
                        controller: _tokenController,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: "Mật khẩu mới",
                        icon: Icons.lock,
                        controller: _passwordController,
                        isPassword: true,
                      ),
                      const SizedBox(height: 20),
                      _buildGradientButton("Lưu mật khẩu", _resetPassword),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
