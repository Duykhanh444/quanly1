import 'package:flutter/material.dart';

class DanhSachNhanVienScreen extends StatelessWidget {
  const DanhSachNhanVienScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách nhân viên')),
      body: const Center(child: Text('Danh sách nhân viên sẽ hiển thị ở đây')),
    );
  }
}
