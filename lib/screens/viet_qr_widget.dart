// lib/widgets/viet_qr_widget.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/bill_config.dart';

class VietQRWidget extends StatelessWidget {
  final String bankBin; // BIN (6 digits) - dùng cho payload EMV
  final String accountNumber;
  final String accountName;
  final int amount; // VND (ví dụ 10000)
  final String addInfo;
  final bool isCashPayment; // true = tiền mặt -> ẩn QR

  const VietQRWidget({
    super.key,
    required this.bankBin,
    required this.accountNumber,
    required this.accountName,
    required this.amount,
    required this.addInfo,
    required this.isCashPayment,
  });

  @override
  Widget build(BuildContext context) {
    if (isCashPayment) return const SizedBox.shrink();

    // Sinh payload EMV (chuẩn VietQR)
    final payload = BillConfig.generateVietQRPayload(
      bankBin: bankBin,
      accountNumber: accountNumber,
      accountName: accountName,
      amount: amount,
      addInfo: addInfo,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Quét mã để chuyển khoản",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // QR from payload (recommended)
        QrImageView(data: payload, size: 220, backgroundColor: Colors.white),
        const SizedBox(height: 8),
        Text(
          "Chủ TK: $accountName",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text("Số TK: $accountNumber"),
        Text("Ngân hàng BIN: $bankBin"),
        Text("Số tiền: ${amount.toString()} VND"),
        if (addInfo.isNotEmpty) Text("Nội dung: $addInfo"),
      ],
    );
  }
}
