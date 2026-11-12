import 'widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _hienMatKhau = false;
  bool _dangNhap = false;
  String? _loi;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String _dichLoi(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Thử quá nhiều lần, vui lòng đợi một lúc';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng';
      default:
        return 'Đăng nhập thất bại (${e.code})';
    }
  }

  Future<void> _dangNhapAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _dangNhap = true;
      _loi = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      // Thành công: AuthGate tự chuyển sang màn hình danh sách
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _loi = _dichLoi(e));
    } catch (e) {
      if (mounted) setState(() => _loi = 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _dangNhap = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                                    const VkuLogo(size: 56),
                  const SizedBox(height: 8),
                  const Text(
                    'Đăng nhập quản trị',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Vui lòng nhập email';
                      if (!s.contains('@')) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_hienMatKhau,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_hienMatKhau
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _hienMatKhau = !_hienMatKhau),
                      ),
                    ),
                    validator: (v) => (v ?? '').isEmpty
                        ? 'Vui lòng nhập mật khẩu'
                        : null,
                    onFieldSubmitted: (_) => _dangNhapAdmin(),
                  ),
                  if (_loi != null) ...[
                    const SizedBox(height: 12),
                    Text(_loi!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _dangNhap ? null : _dangNhapAdmin,
                      child: _dangNhap
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Đăng nhập'),
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