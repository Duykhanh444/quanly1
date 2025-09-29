// lib/utils/bill_config.dart
import 'dart:convert';

class BillConfig {
  static const shopName = "Cửa hàng ABC";
  static const shopAddress = "123 Đường A, Quận B, TP.HCM";
  static const shopPhone = "0123456789";

  static const shopBankBin = "970436";
  static const shopBankAccount = "0123456789";
  static const shopAccountName = "NGUYEN VAN A";

  static const Map<String, String> bankNameToBin = {
    "VIETCOMBANK": "970436",
    "TECHCOMBANK": "970407",
    "ACB": "970416",
    "BIDV": "970418",
    "VIETINBANK": "970415",
    "MBBANK": "970422",
    "VPBANK": "970432",
    "AGRIBANK": "970405",
    "SACOMBANK": "970403",
  };

  /// Tạo payload VietQR chuẩn EMVCo.
  /// - pointOfInitiation: '11' (static) hoặc '12' (dynamic) — thử đổi nếu bank báo invalid.
  /// - addInfoTag: subtag để đóng trong field 62 (ví dụ '01' hoặc '08') — một số bank yêu cầu subtag cụ thể.
  static String generateVietQRPayload({
    required String bankBin,
    required String accountNumber,
    required String accountName,
    required int amount,
    required String addInfo,
    String pointOfInitiation = '11',
    String addInfoTag = '01',
  }) {
    String tlv(String id, String value) {
      final len = utf8.encode(value).length.toString().padLeft(2, '0');
      return '$id$len$value';
    }

    // Merchant Account Info (ID=38)
    final merchantAccount =
        tlv('00', 'A000000727') +
        tlv('01', 'QRIBFTTA') +
        tlv('02', bankBin) +
        tlv('03', accountNumber);

    final sb = StringBuffer();
    sb.write(tlv('00', '01')); // Payload format indicator
    sb.write(tlv('01', pointOfInitiation)); // Point of initiation: '11' or '12'
    sb.write(tlv('38', merchantAccount));
    sb.write(tlv('52', '0000'));
    sb.write(tlv('53', '704'));
    if (amount > 0) sb.write(tlv('54', amount.toString()));
    sb.write(tlv('58', 'VN'));
    sb.write(tlv('59', accountName.toUpperCase()));
    sb.write(tlv('60', 'HO CHI MINH'));
    if (addInfo.isNotEmpty) sb.write(tlv('62', tlv(addInfoTag, addInfo)));

    final payloadWithoutCrc = sb.toString() + '6304';
    final crc = _crc16(payloadWithoutCrc.codeUnits);
    final crcHex = crc.toRadixString(16).toUpperCase().padLeft(4, '0');
    return payloadWithoutCrc + crcHex;
  }

  // CRC16-CCITT (poly 0x1021), tương thích chuẩn VietQR
  static int _crc16(List<int> bytes) {
    const poly = 0x1021;
    int crc = 0xFFFF;
    for (var b in bytes) {
      crc ^= (b & 0xFF) << 8;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ poly) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc & 0xFFFF;
  }
}
