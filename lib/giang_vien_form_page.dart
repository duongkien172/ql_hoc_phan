import 'widgets.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'giang_vien.dart';

class GiangVienFormPage extends StatefulWidget {
  final GiangVien? giangVien; // null = thêm mới, khác null = sửa
  const GiangVienFormPage({super.key, this.giangVien});

  @override
  State<GiangVienFormPage> createState() => _GiangVienFormPageState();
}

class _GiangVienFormPageState extends State<GiangVienFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _tenCtrl = TextEditingController();
  final _soLopCtrl = TextEditingController();

  Uint8List? _anhBytes;
  String _anhBase64 = '';
  bool _dangLuu = false;

  bool get _laSua => widget.giangVien != null;

  @override
  void initState() {
    super.initState();
    final gv = widget.giangVien;
    if (gv != null) {
      _idCtrl.text = gv.idgv;
      _tenCtrl.text = gv.fullname;
      _soLopCtrl.text = gv.sumClass.toString();
      _anhBase64 = gv.image;
      if (gv.image.isNotEmpty) {
        try {
          _anhBytes = base64Decode(gv.image);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _tenCtrl.dispose();
    _soLopCtrl.dispose();
    super.dispose();
  }

  Future<void> _chonAnh(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 60,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _anhBytes = bytes;
      _anhBase64 = base64Encode(bytes);
    });
  }

  void _thongBao(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _luu() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _dangLuu = true);
    try {
      final id = _idCtrl.text.trim();
      final ref = FirebaseFirestore.instance.collection('GiangVien').doc(id);

      if (!_laSua && (await ref.get()).exists) {
        _thongBao('Mã giảng viên "$id" đã tồn tại');
        return;
      }

      final gv = GiangVien(
        idgv: id,
        fullname: _tenCtrl.text.trim(),
        image: _anhBase64,
        sumClass: int.parse(_soLopCtrl.text.trim()),
      );
      await ref.set(gv.toMap()); // luôn đúng 4 trường

      if (!mounted) return;
      _thongBao(_laSua ? 'Đã cập nhật giảng viên' : 'Đã thêm giảng viên');
      Navigator.pop(context);
    } catch (e) {
      _thongBao('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  @override
   Widget _nutAnh(IconData icon, String nhan, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: kAccent, size: 28),
              const SizedBox(height: 4),
              Text(nhan, style: const TextStyle(fontSize: 12, color: kAccent)),
            ],
          ),
        ),
      );

  InputDecoration _kieu(String nhan) => InputDecoration(
        labelText: nhan,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text(_laSua ? 'Sửa Giảng Viên' : 'Thêm Giảng Viên Mới'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!kIsWeb)
                          _nutAnh(Icons.camera_alt, 'Chụp ảnh',
                              () => _chonAnh(ImageSource.camera)),
                        GestureDetector(
                          onTap: () => _chonAnh(ImageSource.gallery),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: const Color(0xFFDCE4F5),
                            backgroundImage: _anhBytes != null
                                ? MemoryImage(_anhBytes!)
                                : null,
                            child: _anhBytes == null
                                ? const Icon(Icons.person,
                                    size: 50, color: kPrimary)
                                : null,
                          ),
                        ),
                        _nutAnh(Icons.photo_library, 'Chọn ảnh',
                            () => _chonAnh(ImageSource.gallery)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _idCtrl,
                      readOnly: _laSua,
                      decoration:
                          _kieu('Mã Giảng viên (IDGV)').copyWith(filled: _laSua),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Vui lòng nhập mã giảng viên';
                        if (s.contains('/')) return 'Mã không được chứa dấu /';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tenCtrl,
                      decoration: _kieu('Họ và Tên (Fullname)'),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Vui lòng nhập họ tên'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _soLopCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _kieu('Tổng số lớp (SumClass)'),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null) return 'Vui lòng nhập số nguyên';
                        if (n < 0) return 'Số lớp không được âm';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                                backgroundColor: kAccent,
                                minimumSize: const Size.fromHeight(48)),
                            onPressed: _dangLuu ? null : _luu,
                            icon: _dangLuu
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check),
                            label: Text(_laSua ? 'CẬP NHẬT' : 'LƯU'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48)),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            label: const Text('HỦY'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}