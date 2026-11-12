import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'giang_vien.dart';
import 'giang_vien_form_page.dart';
import 'widgets.dart';

class DsGiangVienPage extends StatefulWidget {
  const DsGiangVienPage({super.key});

  @override
  State<DsGiangVienPage> createState() => _DsGiangVienPageState();
}

class _DsGiangVienPageState extends State<DsGiangVienPage> {
  static Stream<QuerySnapshot<Map<String, dynamic>>> _taoStream() =>
      FirebaseFirestore.instance.collection('GiangVien').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream = _taoStream();
  final _searchCtrl = TextEditingController();
  String _keyword = '';
  String _locLop = 'all';
  String _sortKey = 'idgv';
  bool _asc = true;
  int _tab = 0; // 0 = Dashboard, 1 = Quản lý giảng viên (chỉ có trên web)

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------- Xử lý dữ liệu ----------
  List<GiangVien> _xuLy(List<GiangVien> all) {
    final k = _keyword.toLowerCase();
    final list = all.where((g) {
      final okTen = k.isEmpty ||
          g.fullname.toLowerCase().contains(k) ||
          g.idgv.toLowerCase().contains(k);
      final okLop = switch (_locLop) {
        'zero' => g.sumClass == 0,
        'low' => g.sumClass >= 1 && g.sumClass <= 5,
        'high' => g.sumClass > 5,
        _ => true,
      };
      return okTen && okLop;
    }).toList();

    list.sort((a, b) {
      int c;
      switch (_sortKey) {
        case 'name':
          c = a.fullname.toLowerCase().compareTo(b.fullname.toLowerCase());
          break;
        case 'sum':
          c = a.sumClass.compareTo(b.sumClass);
          break;
        default:
          c = a.idgv.toLowerCase().compareTo(b.idgv.toLowerCase());
      }
      return _asc ? c : -c;
    });
    return list;
  }

  int get _sortIndex => _sortKey == 'name' ? 1 : (_sortKey == 'sum' ? 3 : 0);

  void _sapXep(String key) => setState(() {
        if (_sortKey == key) {
          _asc = !_asc;
        } else {
          _sortKey = key;
          _asc = true;
        }
      });

  // ---------- Hành động ----------
  void _thongBao(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _moForm([GiangVien? gv]) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GiangVienFormPage(giangVien: gv)),
      );

  Future<void> _xacNhanXoa(GiangVien gv) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa giảng viên "${gv.fullname}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kRed),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (dongY != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('GiangVien')
          .doc(gv.idgv)
          .delete();
      _thongBao('Đã xóa giảng viên');
    } catch (e) {
      _thongBao('Lỗi: $e');
    }
  }

  void _lamMoi() {
    setState(() => _stream = _taoStream());
    _thongBao('Đã làm mới dữ liệu');
  }

  Future<void> _dangXuat() => FirebaseAuth.instance.signOut();

  void _xemChiTiet(GiangVien gv) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimary, kAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          GvAvatar(base64Str: gv.image, radius: 64),
                          const SizedBox(height: 14),
                          Text(
                            gv.fullname,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Thông tin giảng viên',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _chiTietDong(
                        icon: Icons.badge_outlined,
                        nhan: 'Mã giảng viên',
                        giaTri: gv.idgv,
                      ),
                      const SizedBox(height: 12),
                      _chiTietDong(
                        icon: Icons.class_outlined,
                        nhan: 'Tổng số lớp',
                        giaTri: '${gv.sumClass} lớp',
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: FilledButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Đóng'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chiTietDong({
    required IconData icon,
    required String nhan,
    required String giaTri,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFDCE4F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nhan,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 3),
                  Text(giaTri,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );

  void _xuatJson(List<GiangVien> all) {
    final json = const JsonEncoder.withIndent('  ')
        .convert(all.map((g) => g.toMap()).toList());
    final xem = json.length > 3000
        ? '${json.substring(0, 3000)}\n... (hiển thị rút gọn, bản sao chép là đầy đủ)'
        : json;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xuất dữ liệu JSON'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${all.length} giảng viên. Bấm "Sao chép" rồi dán vào '
                  'file giangvien.json.'),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 260),
                padding: const EdgeInsets.all(8),
                color: const Color(0xFFF1F4FA),
                child: SingleChildScrollView(
                  child: SelectableText(xem,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          FilledButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Sao chép'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (ctx.mounted) Navigator.pop(ctx);
              _thongBao('Đã sao chép JSON vào clipboard');
            },
          ),
        ],
      ),
    );
  }

  // ---------- Thành phần giao diện dùng chung ----------
  Widget _card(
          {required Widget child,
          EdgeInsets padding = const EdgeInsets.all(16)}) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: child,
      );

  Widget _oTimKiem() => TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _keyword = v.trim()),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên hoặc mã giảng viên...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _keyword.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _keyword = '');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

  Widget _nutLoc() => PopupMenuButton<String>(
        tooltip: 'Lọc theo số lớp',
        initialValue: _locLop,
        onSelected: (v) => setState(() => _locLop = v),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'all', child: Text('Tất cả')),
          PopupMenuItem(value: 'zero', child: Text('Chưa có lớp (0)')),
          PopupMenuItem(value: 'low', child: Text('Từ 1 đến 5 lớp')),
          PopupMenuItem(value: 'high', child: Text('Trên 5 lớp')),
        ],
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _locLop == 'all' ? Colors.white : const Color(0xFFDCE4F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black26),
          ),
          child: const Icon(Icons.filter_list),
        ),
      );

  Widget _nutSapXep() => PopupMenuButton<String>(
        tooltip: 'Sắp xếp',
        onSelected: _sapXep,
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'idgv', child: Text('Theo mã (IDGV)')),
          PopupMenuItem(value: 'name', child: Text('Theo họ tên')),
          PopupMenuItem(value: 'sum', child: Text('Theo số lớp')),
        ],
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black26),
          ),
          child: Icon(_asc ? Icons.arrow_upward : Icons.arrow_downward),
        ),
      );

  Widget _iconBtn(IconData icon, Color color, String tip, VoidCallback onTap) =>
      Tooltip(
        message: tip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      );

  Widget _thongKe(IconData icon, String nhan, String giaTri, Color mau) =>
      SizedBox(
        width: 250,
        child: _card(
          child: Row(
            children: [
              CircleAvatar(
                  radius: 24,
                  backgroundColor: mau,
                  child: Icon(icon, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(giaTri,
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold)),
                    Text(nhan,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  // ---------- Bố cục WEB ----------
  Widget _webLayout(List<GiangVien> all) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: Row(
              children: [
                _sidebar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _tab == 0 ? _dashboard(all) : _bangGiangVien(all),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          const VkuLogo(size: 30),
          const SizedBox(width: 12),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Đại Học CNTT và Truyền thông Việt-Hàn',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text('QUẢN LÝ GIẢNG VIÊN',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimary)),
            ],
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFDCE4F5),
            child: Icon(Icons.person, color: kPrimary),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Admin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(email,
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout, color: kPrimary),
            onPressed: _dangXuat,
          ),
        ],
      ),
    );
  }

  Widget _sidebar() => Container(
        width: 230,
        color: kPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _menuItem(Icons.dashboard, 'Dashboard', 0),
            const SizedBox(height: 4),
            _menuItem(Icons.groups, 'Quản lý giảng viên', 1),
          ],
        ),
      );

  Widget _menuItem(IconData icon, String nhan, int idx) {
    final chon = _tab == idx;
    return Material(
      color: chon ? const Color(0x2EFFFFFF) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _tab = idx),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(nhan,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboard(List<GiangVien> all) {
    final tongLop = all.fold<int>(0, (s, g) => s + g.sumClass);
    final tb = all.isEmpty ? 0.0 : tongLop / all.length;
    final top = [...all]..sort((a, b) => b.sumClass.compareTo(a.sumClass));
    final maxLop = top.isEmpty ? 0 : top.first.sumClass;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TỔNG QUAN',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: kPrimary)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _thongKe(Icons.groups, 'Tổng giảng viên', '${all.length}',
                  kAccent),
              _thongKe(Icons.class_, 'Tổng số lớp', '$tongLop', kGreen),
              _thongKe(Icons.bar_chart, 'Trung bình lớp / giảng viên',
                  tb.toStringAsFixed(1), const Color(0xFFF2994A)),
            ],
          ),
          const SizedBox(height: 24),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top 5 giảng viên nhiều lớp nhất',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (top.isEmpty) const Text('Chưa có dữ liệu'),
                for (final g in top.take(5))
                  ListTile(
                    leading: GvAvatar(base64Str: g.image),
                    title: Text(g.fullname),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: LinearProgressIndicator(
                        value: maxLop == 0 ? 0 : g.sumClass / maxLop,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    trailing: Text('${g.sumClass} lớp',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangGiangVien(List<GiangVien> all) {
    final list = _xuLy(all);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DANH SÁCH GIẢNG VIÊN',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: kPrimary)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(width: 320, child: _oTimKiem()),
              _nutLoc(),
              OutlinedButton.icon(
                onPressed: () => _xuatJson(all),
                icon: const Icon(Icons.data_object),
                label: const Text('Xuất JSON'),
              ),
              FilledButton.icon(
                onPressed: () => _moForm(),
                style: FilledButton.styleFrom(backgroundColor: kAccent),
                icon: const Icon(Icons.add),
                label: const Text('Thêm giảng viên'),
              ),
              FilledButton.icon(
                onPressed: _lamMoi,
                style: FilledButton.styleFrom(backgroundColor: kGreen),
                icon: const Icon(Icons.refresh),
                label: const Text('Làm mới'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('Không có giảng viên phù hợp'))
                : LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: c.maxWidth),
                          child: DataTable(
                            sortColumnIndex: _sortIndex,
                            sortAscending: _asc,
                            showCheckboxColumn: false,
                            headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFF1F4FA)),
                            dataRowMinHeight: 56,
                            dataRowMaxHeight: 64,
                            columns: [
                              DataColumn(
                                label: const Text('IDGV',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                onSort: (_, __) => _sapXep('idgv'),
                              ),
                              DataColumn(
                                label: const Text('Fullname',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                onSort: (_, __) => _sapXep('name'),
                              ),
                              const DataColumn(
                                label: Text('Image',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: const Text('SumClass',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                onSort: (_, __) => _sapXep('sum'),
                              ),
                              const DataColumn(
                                label: Text('Hành động',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                            rows: [
                              for (final g in list)
                                DataRow(
                                  onSelectChanged: (_) => _xemChiTiet(g),
                                  cells: [
                                    DataCell(Text(g.idgv)),
                                    DataCell(Text(g.fullname)),
                                    DataCell(
                                        GvAvatar(base64Str: g.image, radius: 18)),
                                    DataCell(Text('${g.sumClass}')),
                                    DataCell(Row(
                                      children: [
                                        _iconBtn(Icons.edit, kAccent, 'Sửa',
                                            () => _moForm(g)),
                                        const SizedBox(width: 8),
                                        _iconBtn(Icons.delete, kRed, 'Xóa',
                                            () => _xacNhanXoa(g)),
                                      ],
                                    )),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text('Hiển thị ${list.length}/${all.length} giảng viên',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  // ---------- Bố cục DI ĐỘNG ----------
  Widget _thongKeNho(String nhan, String giaTri, IconData icon, Color mau) =>
      _card(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(icon, color: mau),
            const SizedBox(width: 8),
            Text(giaTri,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Expanded(
                child: Text(nhan,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54))),
          ],
        ),
      );

  Widget _nenVuot(Color mau, IconData icon, String nhan, Alignment can) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration:
            BoxDecoration(color: mau, borderRadius: BorderRadius.circular(12)),
        alignment: can,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 6),
            Text(nhan, style: const TextStyle(color: Colors.white)),
          ],
        ),
      );

  Widget _mobileLayout(List<GiangVien> all) {
    final list = _xuLy(all);
    final tongLop = all.fold<int>(0, (s, g) => s + g.sumClass);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: const Text('VKU - Quản lý Giảng viên',
            style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Xuất JSON',
            icon: const Icon(Icons.data_object),
            onPressed: () => _xuatJson(all),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: _dangXuat,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        onPressed: () => _moForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(child: _oTimKiem()),
                const SizedBox(width: 8),
                _nutLoc(),
                const SizedBox(width: 8),
                _nutSapXep(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                    child: _thongKeNho(
                        'Giảng viên', '${all.length}', Icons.groups, kAccent)),
                const SizedBox(width: 8),
                Expanded(
                    child: _thongKeNho(
                        'Tổng số lớp', '$tongLop', Icons.class_, kGreen)),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('Không có giảng viên phù hợp'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final g = list[i];
                      return Dismissible(
                        key: ValueKey(g.idgv),
                        background: _nenVuot(
                            kAccent, Icons.edit, 'Sửa', Alignment.centerLeft),
                        secondaryBackground: _nenVuot(
                            kRed, Icons.delete, 'Xóa', Alignment.centerRight),
                        confirmDismiss: (dir) async {
                          if (dir == DismissDirection.startToEnd) {
                            await _moForm(g);
                          } else {
                            await _xacNhanXoa(g);
                          }
                          return false; // danh sách tự cập nhật qua stream
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            onTap: () => _xemChiTiet(g),
                            leading: GvAvatar(base64Str: g.image, radius: 26),
                            title: Text(g.fullname,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                'IDGV: ${g.idgv}\nSumClass: ${g.sumClass}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Sửa thông tin',
                                  color: kAccent,
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _moForm(g),
                                ),
                                IconButton(
                                  tooltip: 'Xóa giảng viên',
                                  color: kRed,
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _xacNhanXoa(g),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('Lỗi: ${snap.error}')));
        }
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final all = snap.data!.docs.map(GiangVien.fromDoc).toList();
        return LayoutBuilder(
          builder: (context, c) =>
              c.maxWidth >= 800 ? _webLayout(all) : _mobileLayout(all),
        );
      },
    );
  }
}