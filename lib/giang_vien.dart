import 'package:cloud_firestore/cloud_firestore.dart';

class GiangVien {
  final String idgv;
  final String fullname;
  final String image; // chuỗi base64, có thể rỗng
  final int sumClass;

  GiangVien({
    required this.idgv,
    required this.fullname,
    required this.image,
    required this.sumClass,
  });

  factory GiangVien.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return GiangVien(
      idgv: (d['IDGV'] ?? doc.id).toString(),
      fullname: (d['Fullname'] ?? '').toString(),
      image: (d['Image'] ?? '').toString(),
      sumClass: ((d['SumClass'] ?? 0) as num).toInt(),
    );
  }

  // Đúng 4 trường, không thêm trường nào khác
  Map<String, dynamic> toMap() => {
        'IDGV': idgv,
        'Fullname': fullname,
        'Image': image,
        'SumClass': sumClass,
      };
}