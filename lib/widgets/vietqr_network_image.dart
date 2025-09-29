// lib/widgets/vietqr_network_image.dart
import 'package:flutter/material.dart';

class VietQRNetworkImage extends StatelessWidget {
  final String bankCode; // VD: "ACB"
  final String accountNumber; // VD: "26537567"
  final int amount; // Số tiền VND
  final String addInfo; // Nội dung thanh toán
  final double size;

  const VietQRNetworkImage({
    super.key,
    required this.bankCode,
    required this.accountNumber,
    required this.amount,
    required this.addInfo,
    this.size = 220,
  });

  String get qrUrl {
    final encodedInfo = Uri.encodeComponent(addInfo);
    return 'https://img.vietqr.io/image/$bankCode-$accountNumber-qr_only.png?amount=$amount&addInfo=$encodedInfo';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        qrUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Text('Không tải được QR')),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
