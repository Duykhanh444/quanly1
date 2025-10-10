import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/bill_config.dart';

class VietQRWidget extends StatelessWidget {
  final String bankBin; // Mã BIN (6 số) theo chuẩn VietQR
  final String accountNumber;
  final String accountName;
  final int? amount; // VND (có thể null hoặc 0)
  final String addInfo;
  final bool isCashPayment; // true = tiền mặt -> ẩn QR

  const VietQRWidget({
    super.key,
    required this.bankBin,
    required this.accountNumber,
    required this.accountName,
    this.amount,
    this.addInfo = "",
    this.isCashPayment = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCashPayment) {
      return const Center(
        child: Text(
          "Thanh toán tiền mặt",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      );
    }

    // Sinh payload EMV chuẩn VietQR
    final payload = BillConfig.generateVietQRPayload(
      bankBin: bankBin,
      accountNumber: accountNumber,
      accountName: accountName,
      amount: amount ?? 0,
      addInfo: addInfo,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Quét mã để chuyển khoản",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Mã QR sinh trực tiếp từ payload EMV (không cần tải ảnh mạng)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: QrImageView(
            data: payload,
            size: 220,
            backgroundColor: Colors.white,
            version: QrVersions.auto,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          "Chủ TK: $accountName",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6C63FF),
          ),
        ),
        const SizedBox(height: 2),
        Text("Số TK: $accountNumber"),
        Text("Ngân hàng BIN: $bankBin"),
        if ((amount ?? 0) > 0) Text("Số tiền: ${amount!.toString()} VND"),
        if (addInfo.isNotEmpty) Text("Nội dung: $addInfo"),
      ],
    );
  }
}
