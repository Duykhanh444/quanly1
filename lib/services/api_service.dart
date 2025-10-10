import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../models/nhanvien.dart';
import '../models/workday.dart';
import '../models/khohang.dart';
import '../models/hoadon.dart';
import '../models/hoadon_item.dart';
import '../api_config.dart';
import '../api_config.dart'; // Đảm bảo đường dẫn đúng
import 'package:flutter/foundation.dart';

class ApiService {
  // --------------------- BASE URL ---------------------
  static String get _baseUrl => "${ApiConfig.host}/api";

  static String get baseUrlNhanVien => '$_baseUrl/NhanVien';
  static String get baseUrlKhoHang => '$_baseUrl/KhoHang';
  static String get baseUrlHoaDon => '$_baseUrl/HoaDon';

  // ⚠️ URL Auth
  static String get baseUrlAuth => '$_baseUrl/Auth';

  // ⚠️ Biến token
  static String? token;

  // --------------------- ĐĂNG KÝ ---------------------
  static Future<bool> dangKy({
    required String username,
    required String password,
    String? email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrlAuth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email ?? '$username@example.com',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Exception dangKy: $e');
      return false;
    }
  }

  // --------------------- ĐĂNG NHẬP ---------------------
  static Future<bool> dangNhap({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrlAuth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        token = data['token'];
        return true;
      } else {
        print('Login failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Exception dangNhap: $e');
    }
    return false;
  }

  static Map<String, String> get _headersAuth => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // --------------------- NHÂN VIÊN ---------------------
  static Future<List<NhanVien>> layDanhSachNhanVien() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrlNhanVien),
        headers: _headersAuth,
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => NhanVien.fromJson(e)).toList();
      }
    } catch (e) {
      print('Exception layDanhSachNhanVien: $e');
    }
    return [];
  }

  static Future<NhanVien?> layChiTietNhanVien(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrlNhanVien/$id'),
        headers: _headersAuth,
      );
      if (response.statusCode == 200) {
        return NhanVien.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Exception layChiTietNhanVien: $e');
    }
    return null;
  }

  static Future<NhanVien?> themHoacSuaNhanVien(
    NhanVien nv, {
    File? anhDaiDien,
  }) async {
    final isEdit = nv.id != 0;
    final uri = Uri.parse(
      isEdit ? '$baseUrlNhanVien/${nv.id}' : baseUrlNhanVien,
    );
    var request = isEdit
        ? http.MultipartRequest('PUT', uri)
        : http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields
      ..['hoTen'] = nv.hoTen
      ..['soDienThoai'] = nv.soDienThoai
      ..['chucVu'] = nv.chucVu
      ..['luongTheoGio'] = nv.luongTheoGio.toStringAsFixed(0);

    if (anhDaiDien != null) {
      final mimeTypeData = lookupMimeType(anhDaiDien.path)?.split('/');
      request.files.add(
        await http.MultipartFile.fromPath(
          'anhDaiDien',
          anhDaiDien.path,
          contentType: mimeTypeData != null
              ? MediaType(mimeTypeData[0], mimeTypeData[1])
              : MediaType('image', 'jpeg'),
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return NhanVien.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Exception themHoacSuaNhanVien: $e');
    }
    return null;
  }

  static Future<bool> xoaNhanVien(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrlNhanVien/$id'),
        headers: _headersAuth,
      );
      return response.statusCode == 204;
    } catch (e) {
      print('Exception xoaNhanVien: $e');
      return false;
    }
  }

  static Future<NhanVien?> chamCong(int nhanVienId, WorkDay wd) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrlNhanVien/$nhanVienId/WorkDays'),
        headers: _headersAuth,
        body: jsonEncode({
          'ngay': wd.ngay.toIso8601String(),
          'soGio': wd.soGio,
        }),
      );
      if (response.statusCode == 200)
        return NhanVien.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('Exception chamCong: $e');
    }
    return null;
  }

  static Future<NhanVien?> suaWorkDay(int nhanVienId, WorkDay wd) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrlNhanVien/$nhanVienId/WorkDays/${wd.id}'),
        headers: _headersAuth,
        body: jsonEncode({
          'ngay': wd.ngay.toIso8601String(),
          'soGio': wd.soGio,
        }),
      );
      if (response.statusCode == 200)
        return NhanVien.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('Exception suaWorkDay: $e');
    }
    return null;
  }

  static Future<NhanVien?> xoaWorkDay(int nhanVienId, int workDayId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrlNhanVien/$nhanVienId/WorkDays/$workDayId'),
        headers: _headersAuth,
      );
      if (response.statusCode == 200)
        return NhanVien.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('Exception xoaWorkDay: $e');
    }
    return null;
  }

  // --------------------- KHO HÀNG ---------------------
  static Future<List<KhoHang>> layDanhSachKhoHang() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrlKhoHang),
        headers: _headersAuth,
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => KhoHang.fromJson(e)).toList();
      }
    } catch (e) {
      print('Exception layDanhSachKhoHang: $e');
    }
    return [];
  }

  static Future<KhoHang?> layChiTietKhoHang(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrlKhoHang/$id'),
        headers: _headersAuth,
      );
      if (response.statusCode == 200)
        return KhoHang.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('Exception layChiTietKhoHang: $e');
    }
    return null;
  }

  static Future<KhoHang?> themHoacSuaKhoHang(KhoHang sp) async {
    final isEdit = sp.id != 0;
    final uri = Uri.parse(isEdit ? '$baseUrlKhoHang/${sp.id}' : baseUrlKhoHang);
    try {
      final response = isEdit
          ? await http.put(
              uri,
              headers: _headersAuth,
              body: jsonEncode(sp.toJson()),
            )
          : await http.post(
              uri,
              headers: _headersAuth,
              body: jsonEncode(sp.toJson()),
            );
      if (response.statusCode == 200 || response.statusCode == 201)
        return KhoHang.fromJson(jsonDecode(response.body));
      if (response.statusCode == 204) return sp;
    } catch (e) {
      print('Exception themHoacSuaKhoHang: $e');
    }
    return null;
  }

  static Future<KhoHang?> capNhatKhoHang(KhoHang sp) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrlKhoHang/${sp.id}'),
        headers: _headersAuth,
        body: jsonEncode(sp.toJson()),
      );
      if (response.statusCode == 200)
        return KhoHang.fromJson(jsonDecode(response.body));
      if (response.statusCode == 204) return sp;
    } catch (e) {
      print('Exception capNhatKhoHang: $e');
    }
    return null;
  }

  static Future<bool> xoaKhoHang(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrlKhoHang/$id'),
        headers: _headersAuth,
      );
      return response.statusCode == 204;
    } catch (e) {
      print('Exception xoaKhoHang: $e');
      return false;
    }
  }

  static Future<KhoHang?> xuatKhoHang(int id) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrlKhoHang/Xuat/$id'),
        headers: _headersAuth,
      );
      if (response.statusCode == 200)
        return KhoHang.fromJson(jsonDecode(response.body));
      if (response.statusCode == 204)
        return KhoHang(id: id, trangThai: "Đã xuất", ngayXuat: DateTime.now());
    } catch (e) {
      print('Exception xuatKhoHang: $e');
    }
    return null;
  }

  // --------------------- HÓA ĐƠN ---------------------
  static Future<List<HoaDon>> layDanhSachHoaDon() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrlHoaDon),
        headers: _headersAuth,
      );
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .map((e) => HoaDon.fromJson(e))
            .toList();
      } else {
        throw Exception("Lỗi server: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception layDanhSachHoaDon: $e");
      return [];
    }
  }

  static Future<HoaDon?> layChiTietHoaDon(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrlHoaDon/$id'),
        headers: _headersAuth,
      );
      if (response.statusCode == 200)
        return HoaDon.fromJson(jsonDecode(response.body));
    } catch (e) {
      print("Exception layChiTietHoaDon: $e");
    }
    return null;
  }

  static Future<HoaDon?> themHoaDon(HoaDon hd) async {
    hd.tinhTongTien();
    try {
      final response = await http.post(
        Uri.parse(baseUrlHoaDon),
        headers: _headersAuth,
        body: jsonEncode(hd.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201)
        return HoaDon.fromJson(jsonDecode(response.body));
    } catch (e) {
      print("Exception themHoaDon: $e");
    }
    return null;
  }

  static Future<HoaDon?> suaHoaDon(HoaDon hd) async {
    hd.tinhTongTien();
    try {
      final response = await http.put(
        Uri.parse('$baseUrlHoaDon/${hd.id}'),
        headers: _headersAuth,
        body: jsonEncode(hd.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201)
        return HoaDon.fromJson(jsonDecode(response.body));
      if (response.statusCode == 204) return hd;
    } catch (e) {
      print("Exception suaHoaDon: $e");
    }
    return null;
  }

  static Future<HoaDon?> themHoacSuaHoaDon(HoaDon hd) async =>
      hd.id == 0 ? await themHoaDon(hd) : await suaHoaDon(hd);

  static Future<bool> capNhatTrangThaiHoaDon(int id, String trangThai) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrlHoaDon/$id/trangthai'),
        headers: _headersAuth,
        body: jsonEncode({'trangThai': trangThai}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Exception capNhatTrangThaiHoaDon: $e");
      return false;
    }
  }

  static Future<bool> xoaHoaDon(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrlHoaDon/$id'),
        headers: _headersAuth,
      );
      return response.statusCode == 204;
    } catch (e) {
      print("Exception xoaHoaDon: $e");
      return false;
    }
  }

  static Future<bool> xoaHoaDonObj(HoaDon hd) async => await xoaHoaDon(hd.id);

  static Future<bool> xoaTatCaHoaDon() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrlHoaDon/xoa-tat-ca'),
        headers: _headersAuth,
      );
      return response.statusCode == 204;
    } catch (e) {
      print("Exception xoaTatCaHoaDon: $e");
      return false;
    }
  }

  static Future<bool> xoaTatCaHoaDonDaThanhToan() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrlHoaDon/xoa-tat-ca-da-thanh-toan'),
        headers: _headersAuth,
      );
      return response.statusCode == 204;
    } catch (e) {
      print('Exception xoaTatCaHoaDonDaThanhToan: $e');
      return false;
    }
  }

  static Future<HoaDon?> taoHoaDonTheoMa(String maSanPham) async {
    try {
      final url = Uri.parse('$baseUrlHoaDon/tao-theo-ma/$maSanPham');
      final response = await http.post(url, headers: _headersAuth);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return HoaDon.fromJson(jsonDecode(response.body));
      } else {
        debugPrint(
          '❌ Lỗi tạo hóa đơn theo mã: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('🔥 Exception taoHoaDonTheoMa: $e');
    }
    return null;
  }

  // --------------------- ẢNH ---------------------
  static String getAnhUrl(String? path) {
    if (path == null || path.isEmpty) {
      return "${ApiConfig.host}/images/placeholder.jpg";
    }
    if (path.startsWith('http')) return path;
    // ✅ Sửa đúng đường dẫn ảnh theo thư mục thực tế
    return "${ApiConfig.host}/uploads/$path";
  }

  // --------------------- KIỂM TRA KẾT NỐI SERVER ---------------------
  static Future<bool> checkConnection() async {
    try {
      final uri = Uri.parse("${ApiConfig.host}/health"); // đã bỏ /api
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print("Exception checkConnection: $e");
      return false;
    }
  }

  // --------------------- TÀI KHOẢN ---------------------
  /// Cập nhật thông tin hồ sơ người dùng
  static Future<bool> updateProfile({
    required String username,
    required String email,
    String? newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrlAuth/update-profile'),
        headers: _headersAuth,
        body: jsonEncode({
          'username': username,
          'email': email,
          if (newPassword != null && newPassword.isNotEmpty)
            'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 200 hoặc 204 chấp nhận là thành công tuỳ backend
        return true;
      } else {
        print(
          "❌ updateProfile thất bại: ${response.statusCode} ${response.body}",
        );
        return false;
      }
    } catch (e) {
      print("Exception updateProfile: $e");
      return false;
    }
  }

  /// Đổi mật khẩu (tên tiếng Việt)
  static Future<bool> doiMatKhau({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrlAuth/change-password'),
        headers: _headersAuth,
        body: jsonEncode({
          'currentPassword': oldPassword, // ✅ tên đúng với API backend
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Đổi mật khẩu thành công");
        return true;
      } else {
        print("❌ doiMatKhau thất bại: ${response.statusCode} ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception doiMatKhau: $e");
      return false;
    }
  }

  /// Alias bằng tiếng Anh để UI gọi nếu dùng tên changePassword(...)
  static Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return await doiMatKhau(oldPassword: oldPassword, newPassword: newPassword);
  }

  static Future<bool> themHoacSuaKhoHangJson(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$_baseUrl/KhoHang/ThemHoacSua');
      debugPrint('📡 Gửi yêu cầu tới: $url');
      debugPrint('📦 Dữ liệu gửi đi: ${jsonEncode(data)}');

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // ✅ Chỉ dùng POST (backend đã tự xử lý thêm/sửa)
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Thêm/Sửa kho hàng thành công');
        return true;
      } else {
        debugPrint('❌ Lỗi API (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('🔥 Lỗi khi gọi API ThêmHoặcSửaKhoHang: $e');
      return false;
    }
  }

  // 🧩 Kiểm tra kho hàng theo mã
  static Future<KhoHang?> timKhoTheoMa(String maKho) async {
    try {
      final url = Uri.parse('$baseUrlKhoHang/TimTheoMa/$maKho');
      final response = await http.get(url, headers: _headersAuth);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return KhoHang.fromJson(data);
      }
    } catch (e) {
      print("Exception timKhoTheoMa: $e");
    }
    return null;
  }

  // 🧩 Tạo kho mới nếu chưa tồn tại (sau khi quét QR)
  static Future<KhoHang?> taoKhoSauKhiQuetQR(
    Map<String, dynamic> dataQR,
  ) async {
    try {
      final maKho = dataQR['maKho'];
      if (maKho == null) return null;

      // 1️⃣ Kiểm tra tồn tại
      final khoTonTai = await timKhoTheoMa(maKho);
      if (khoTonTai != null) {
        print('⚠️ Kho đã tồn tại: ${khoTonTai.tenKho}');
        return khoTonTai;
      }

      // 2️⃣ Tạo mới kho nếu chưa có
      final khoMoi = KhoHang(
        id: 0,
        tenKho: dataQR['tenKho'] ?? 'Kho chưa đặt tên',
        ghiChu: dataQR['ghiChu'] ?? '', // nếu có trong QR
        giaTri: 0.0, // hoặc để null nếu không có
        ngayNhap: DateTime.now(),
        trangThai: 'Hoạt động',
      );

      final response = await http.post(
        Uri.parse(baseUrlKhoHang),
        headers: _headersAuth,
        body: jsonEncode(khoMoi.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Tạo kho hàng mới thành công: ${data['tenKho']}');
        return KhoHang.fromJson(data);
      } else {
        print('❌ Tạo kho thất bại: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Exception taoKhoSauKhiQuetQR: $e');
    }
    return null;
  }
}
