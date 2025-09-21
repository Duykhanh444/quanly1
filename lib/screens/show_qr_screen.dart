import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quan_ly_xuong/api_config.dart';

class ShowQrScreen extends StatelessWidget {
  const ShowQrScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final host = ApiConfig.host;

    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code API"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(data: host, version: QrVersions.auto, size: 250.0),
            const SizedBox(height: 20),
            const Text(
              "Quét QR này để nhận API host:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              host,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
