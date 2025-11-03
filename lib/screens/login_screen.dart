import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'forgot_password_screen.dart'; // Import màn hình mới
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedLoginInfo();
  }

  /// ✅ Load thông tin nhớ đăng nhập, nhưng KHÔNG tự đăng nhập
  Future<void> _loadSavedLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username') ?? '';
    final savedPassword = prefs.getString('password') ?? '';
    final remember = prefs.getBool('rememberMe') ?? false;

    if (remember) {
      setState(() {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  /// ✅ Lưu hoặc xóa thông tin đăng nhập
  Future<void> _saveLoginInfo(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('username', username);
      await prefs.setString('password', password);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('username');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }
  }

  /// ✅ Hàm đăng nhập
  Future<void> _dangNhap() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final Map<String, dynamic>? loginData = await ApiService.dangNhap(
      username: username,
      password: password,
    );

    setState(() => _isLoading = false);

    if (loginData != null && loginData.containsKey('token')) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', loginData['token']);
      await prefs.setString('userName', loginData['userName'] ?? 'User');
      await prefs.setString(
        'userEmail',
        loginData['userEmail'] ?? 'email@example.com',
      );

      await _saveLoginInfo(username, password);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Sai tài khoản hoặc mật khẩu")),
        );
      }
    }
  }

  /// Ô nhập liệu có icon + ẩn hiện mật khẩu
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.deepPurple,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              )
            : null,
      ),
    );
  }

  /// Nút Gradient
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Nền gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  // ⭐️ ĐÂY LÀ PHẦN SỬA LỖI LOGIC
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Welcome!",
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            label: "Tài khoản",
                            icon: Icons.person,
                            controller: _usernameController,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: "Mật khẩu",
                            icon: Icons.lock,
                            controller: _passwordController,
                            isPassword: true,
                          ),
                          const SizedBox(height: 8),

                          // ✨ CẬP NHẬT ROW NÀY
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(
                                        () => _rememberMe = value ?? false,
                                      );
                                    },
                                  ),
                                  const Text("Ghi nhớ"),
                                ],
                              ),
                              // ✨ THÊM NÚT NÀY
                              TextButton(
                                child: const Text(
                                  "Quên mật khẩu?",
                                  style: TextStyle(color: Colors.deepPurple),
                                ),
                                onPressed: () {
                                  // Chuyển sang màn hình quên mật khẩu
                                  Navigator.pushNamed(
                                    context,
                                    '/forgot-password',
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildGradientButton("Login", _dangNhap),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Chưa có tài khoản? "),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/register',
                                  );
                                },
                                child: const Text(
                                  "Đăng ký",
                                  style: TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
