import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'giang_vien.dart';

class ThemGiangVienPage extends StatefulWidget {
  const ThemGiangVienPage({super.key});

  @override
  State<ThemGiangVienPage> createState() => _ThemGiangVienPageState();
}

class _ThemGiangVienPageState extends State<ThemGiangVienPage> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _tenCtrl = TextEditingController();
  final _soLopCtrl = TextEditingController();

  Uint8List? _anhBytes; // dùng để xem trước
  String _anhBase64 = ''; // giá trị lưu vào trường Image
  bool _dangLuu = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _tenCtrl.dispose();
    _soLopCtrl.dispose();
    super.dispose();
  }

  Future<void> _chonAnh() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 60,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes(); // chạy được cả Web lẫn Android
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

      if ((await ref.get()).exists) {
        _thongBao('Mã giảng viên "$id" đã tồn tại');
        return;
      }

      final gv = GiangVien(
        idgv: id,
        fullname: _tenCtrl.text.trim(),
        image: _anhBase64,
        sumClass: int.parse(_soLopCtrl.text.trim()),
      );
      await ref.set(gv.toMap());

      if (!mounted) return;
      _thongBao('Đã thêm giảng viên');
      Navigator.pop(context);
    } catch (e) {
      _thongBao('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm giảng viên')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _chonAnh,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage:
                          _anhBytes != null ? MemoryImage(_anhBytes!) : null,
                      child: _anhBytes == null
                          ? const Icon(Icons.add_a_photo, size: 36)
                          : null,
                    ),
                  ),
                  TextButton(
                    onPressed: _chonAnh,
                    child: const Text('Chọn ảnh'),
                  ),
                  TextFormField(
                    controller: _idCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mã giảng viên (IDGV)',
                      border: OutlineInputBorder(),
                    ),
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
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên (Fullname)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Vui lòng nhập họ tên'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _soLopCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tổng số lớp (SumClass)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null) return 'Vui lòng nhập số nguyên';
                      if (n < 0) return 'Số lớp không được âm';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _dangLuu ? null : _luu,
                      child: _dangLuu
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}