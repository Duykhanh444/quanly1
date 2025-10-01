import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase Auth Mock
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import '../services/api_service.dart';
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

  late MockFirebaseAuth _mockAuth;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _mockAuth = MockFirebaseAuth(); // tạo auth giả
  }

  /// Load thông tin đăng nhập từ SharedPreferences
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString("username") ?? "";
    final savedPassword = prefs.getString("password") ?? "";
    final remember = prefs.getBool("rememberMe") ?? false;

    if (remember) {
      setState(() {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  /// Lưu thông tin đăng nhập nếu người dùng chọn "Remember me"
  Future<void> _saveUserInfo(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString("username", username);
      await prefs.setString("password", password);
      await prefs.setBool("rememberMe", true);
    } else {
      await prefs.remove("username");
      await prefs.remove("password");
      await prefs.setBool("rememberMe", false);
    }
  }

  /// Lưu user đã đăng nhập
  Future<void> _saveLoggedInUser(String username, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("userName", username);
    await prefs.setString("userEmail", email);
  }

  /// Đăng nhập bằng API
  void _dangNhap() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ApiService.dangNhap(
      username: username,
      password: password,
    );

    setState(() => _isLoading = false);

    if (success) {
      await _saveUserInfo(username, password);
      await _saveLoggedInUser(username, "$username@gmail.com");
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("❌ Đăng nhập thất bại")));
      }
    }
  }

  /// Đăng nhập bằng Google (mock)
  Future<void> _loginWithGoogleMock() async {
    try {
      final mockUser = MockUser(
        isAnonymous: false,
        uid: "mock_uid_123",
        email: "mockuser@gmail.com",
        displayName: "Mock User",
      );

      final auth = MockFirebaseAuth(mockUser: mockUser);
      final result = await auth.signInWithCredential(
        GoogleAuthProvider.credential(
          idToken: "fake-id-token",
          accessToken: "fake-access-token",
        ),
      );

      final user = result.user;
      if (user != null) {
        await _saveLoggedInUser(user.displayName ?? "", user.email ?? "");
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Google login lỗi (mock): $e")));
    }
  }

  /// Nút Gradient đẹp
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

  /// Ô nhập liệu custom
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
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Text(
                  "Welcome !",
                  style: TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Form Login
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
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
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() => _rememberMe = value ?? false);
                            },
                          ),
                          const Text("Remember me"),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildGradientButton("Login", _dangNhap),
                      const SizedBox(height: 16),

                      // Đăng ký
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("New user? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const Text("OR"),
                      const SizedBox(height: 16),

                      // Social login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _loginWithGoogleMock,
                            icon: const Icon(
                              Icons.g_mobiledata,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.facebook,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.apple,
                              color: Colors.black,
                              size: 40,
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
    );
  }
}
