  import 'dart:convert';
  import 'dart:io';
  import 'package:http/http.dart' as http;
  import 'package:http_parser/http_parser.dart';
  import '../models/nhanvien.dart';
  import '../models/workday.dart';
  import '../models/khohang.dart';
  import '../models/hoadon.dart';
  import '../models/hoadon_item.dart';
  import '../api_config.dart';

  class ApiService {
    // --------------------- BASE URL ---------------------
    static String get _baseUrl => "${ApiConfig.host}/api";

    static String get baseUrlNhanVien => '$_baseUrl/NhanVien';
    static String get baseUrlKhoHang => '$_baseUrl/KhoHang';
    static String get baseUrlHoaDon => '$_baseUrl/HoaDon';
    static String get baseUrlDoanhThu => '$_baseUrl/DoanhThu';

    // --------------------- NHÂN VIÊN ---------------------
    static Future<List<NhanVien>> layDanhSachNhanVien() async {
      try {
        final response = await http.get(Uri.parse(baseUrlNhanVien));
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
        final response = await http.get(Uri.parse('$baseUrlNhanVien/$id'));
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

      request.fields
        ..['hoTen'] = nv.hoTen
        ..['soDienThoai'] = nv.soDienThoai
        ..['chucVu'] = nv.chucVu
        ..['luongTheoGio'] = nv.luongTheoGio.toStringAsFixed(0);

      if (anhDaiDien != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'anhDaiDien',
            anhDaiDien.path,
            contentType: MediaType('image', 'jpeg'),
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
        final response = await http.delete(Uri.parse('$baseUrlNhanVien/$id'));
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
          headers: {'Content-Type': 'application/json'},
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
          headers: {'Content-Type': 'application/json'},
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
        final response = await http.get(Uri.parse(baseUrlKhoHang));
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
        final response = await http.get(Uri.parse('$baseUrlKhoHang/$id'));
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
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(sp.toJson()),
              )
            : await http.post(
                uri,
                headers: {'Content-Type': 'application/json'},
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
          headers: {'Content-Type': 'application/json'},
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
        final response = await http.delete(Uri.parse('$baseUrlKhoHang/$id'));
        return response.statusCode == 204;
      } catch (e) {
        print('Exception xoaKhoHang: $e');
        return false;
      }
    }

    static Future<KhoHang?> xuatKhoHang(int id) async {
      try {
        final response = await http.put(Uri.parse('$baseUrlKhoHang/Xuat/$id'));
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
        final response = await http.get(Uri.parse(baseUrlHoaDon));
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

    static Future<HoaDon?> themHoaDon(HoaDon hd) async {
      hd.tinhTongTien();
      try {
        final response = await http.post(
          Uri.parse(baseUrlHoaDon),
          headers: {'Content-Type': 'application/json'},
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
          headers: {'Content-Type': 'application/json'},
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
          headers: {'Content-Type': 'application/json'},
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
        final response = await http.delete(Uri.parse('$baseUrlHoaDon/$id'));
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
        );
        return response.statusCode == 204;
      } catch (e) {
        print("Exception xoaTatCaHoaDon: $e");
        return false;
      }
    }

    static Future<HoaDon?> layChiTietHoaDon(int id) async {
      try {
        final response = await http.get(Uri.parse('$baseUrlHoaDon/$id'));
        if (response.statusCode == 200)
          return HoaDon.fromJson(jsonDecode(response.body));
      } catch (e) {
        print("Exception layChiTietHoaDon: $e");
      }
      return null;
    }

    static Future<HoaDon?> capNhatHoaDon(HoaDon hd) async {
      hd.tinhTongTien();
      try {
        final response = await http.put(
          Uri.parse('$baseUrlHoaDon/${hd.id}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(hd.toJson()),
        );
        if (response.statusCode == 200 || response.statusCode == 201)
          return HoaDon.fromJson(jsonDecode(response.body));
        if (response.statusCode == 204) return hd;
      } catch (e) {
        print("Exception capNhatHoaDon: $e");
      }
      return null;
    }

    static Future<bool> xoaTatCaHoaDonDaThanhToan() async {
      try {
        final response = await http.delete(
          Uri.parse('$baseUrlHoaDon/xoa-tat-ca-da-thanh-toan'),
        );
        return response.statusCode == 204;
      } catch (e) {
        print('Exception xoaTatCaHoaDonDaThanhToan: $e');
        return false;
      }
    }

    // --------------------- DOANH THU ---------------------
    static Future<double> layTongHoaDonNhapThang(int thang, int nam) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrlDoanhThu/hoa-don-nhap/$nam/$thang'),
        );
        if (response.statusCode == 200)
          return double.tryParse(response.body) ?? 0;
      } catch (e) {
        print('Exception layTongHoaDonNhapThang: $e');
      }
      return 0;
    }

    static Future<double> layTongHoaDonXuatThang(int thang, int nam) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrlDoanhThu/hoa-don-xuat/$nam/$thang'),
        );
        if (response.statusCode == 200)
          return double.tryParse(response.body) ?? 0;
      } catch (e) {
        print('Exception layTongHoaDonXuatThang: $e');
      }
      return 0;
    }

    static Future<double> layTongLuongNhanVienThang(int thang, int nam) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrlDoanhThu/luong-nhan-vien/$nam/$thang'),
        );
        if (response.statusCode == 200)
          return double.tryParse(response.body) ?? 0;
      } catch (e) {
        print('Exception layTongLuongNhanVienThang: $e');
      }
      return 0;
    }

    static Future<double> layPhatSinhThang(int thang, int nam) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrlDoanhThu/phat-sinh/$nam/$thang'),
        );
        if (response.statusCode == 200)
          return double.tryParse(response.body) ?? 0;
      } catch (e) {
        print('Exception layPhatSinhThang: $e');
      }
      return 0;
    }

    static Future<double> tinhDoanhThuThang(int thang, int nam) async {
      final xuat = await layTongHoaDonXuatThang(thang, nam);
      final nhap = await layTongHoaDonNhapThang(thang, nam);
      final luong = await layTongLuongNhanVienThang(thang, nam);
      final phatSinh = await layPhatSinhThang(thang, nam);
      return xuat - (nhap + luong + phatSinh);
    }

    static Future<List<Map<String, dynamic>>> layDoanhThu12ThangGanNhat() async {
      final now = DateTime.now();
      List<Map<String, dynamic>> result = [];

      for (int i = 0; i < 12; i++) {
        int thang = now.month - i;
        int nam = now.year;
        if (thang <= 0) {
          thang += 12;
          nam -= 1;
        }
        double doanhThu = await tinhDoanhThuThang(thang, nam);
        result.add({"Thang": "$thang/$nam", "DoanhThu": doanhThu});
      }

      return result.reversed.toList();
    }

    //// Trả về URL đầy đủ của ảnh. Nếu path null hoặc rỗng, trả về placeholder.
    static String getAnhUrl(String? path) {
      // Nếu path null hoặc rỗng, trả về URL placeholder
      if (path == null || path.isEmpty) {
        return "${ApiConfig.host}/images/placeholder.jpg"; // bạn có thể đổi URL placeholder
      }

      // Nếu path đã là URL hoàn chỉnh, trả thẳng
      if (path.startsWith('http')) return path;

      // Ghép host + path
      return "${ApiConfig.host}/$path";
    }
  }
