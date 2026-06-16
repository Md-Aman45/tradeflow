import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../services/auth_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _users = [];
  List<dynamic> _stocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService().getToken();
      final headers = {'Authorization': 'Bearer $token'};
      final results = await Future.wait([
        http.get(Uri.parse(Constants.adminUsers), headers: headers),
        http.get(Uri.parse(Constants.stocks), headers: headers),
      ]);
      setState(() {
        if (results[0].statusCode == 200) _users = jsonDecode(results[0].body);
        if (results[1].statusCode == 200) _stocks = jsonDecode(results[1].body);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeAdmin(Map<String, dynamic> user) async {
    final token = await AuthService().getToken();
    final res = await http.put(
      Uri.parse('${Constants.adminUsers}/${user['id']}/make-admin'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (mounted) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.statusCode == 200
            ? '✅ ${user['name']} is now ADMIN'
            : '❌ Failed'),
        backgroundColor: res.statusCode == 200
            ? const Color(0xFF1DB954)
            : const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1A1A)
                : Colors.white,
        title: const Text('Delete User',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Delete ${user['email']}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Color(0xFFE53935)))),
        ],
      ),
    );
    if (confirm != true) return;
    final token = await AuthService().getToken();
    final res = await http.delete(
      Uri.parse('${Constants.adminUsers}/${user['id']}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (mounted) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.statusCode == 200 ? '✅ User deleted' : '❌ Failed'),
        backgroundColor: res.statusCode == 200
            ? const Color(0xFF1DB954)
            : const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _showAddStockSheet() async {
    final symbolCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final changeCtrl = TextEditingController();
    final token = await AuthService().getToken();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Add New Stock',
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _sheetField('Symbol (e.g. AAPL)', symbolCtrl, isDark),
            const SizedBox(height: 12),
            _sheetField('Company Name', companyCtrl, isDark),
            const SizedBox(height: 12),
            _sheetField('Price', priceCtrl, isDark,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _sheetField('Change %', changeCtrl, isDark,
                keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final res = await http.post(
                    Uri.parse(Constants.adminStocks),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'symbol': symbolCtrl.text.toUpperCase(),
                      'companyName': companyCtrl.text,
                      'price': double.parse(priceCtrl.text),
                      'changePercent': double.parse(changeCtrl.text),
                      'marketStatus': 'OPEN',
                    }),
                  );
                  if (mounted) {
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res.statusCode == 201
                          ? '✅ Stock added!'
                          : '❌ Failed to add stock'),
                      backgroundColor: res.statusCode == 201
                          ? const Color(0xFF1DB954)
                          : const Color(0xFFE53935),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Stock',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStock(Map<String, dynamic> stock) async {
    final token = await AuthService().getToken();
    final res = await http.delete(
      Uri.parse('${Constants.adminStocks}/${stock['id']}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (mounted) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.statusCode == 200 ? '✅ Stock deleted' : '❌ Failed'),
        backgroundColor: res.statusCode == 200
            ? const Color(0xFF1DB954)
            : const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Widget _sheetField(String hint, TextEditingController ctrl, bool isDark,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1A1A1A), fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
            fontSize: 14),
        filled: true,
        fillColor: isDark ? const Color(0xFF222222) : const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1DB954), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? const Color(0xFF888888) : const Color(0xFF999999);
    final borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Panel',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
                      Text('Manage users & stocks',
                          style: TextStyle(color: subColor, fontSize: 13)),
                    ],
                  ),
                  IconButton(
                    onPressed: _loadData,
                    icon: Icon(Icons.refresh_rounded, color: subColor),
                  ),
                ],
              ),
            ),

            // Stats row
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    _statChip('${_users.length} Users',
                        Icons.people, const Color(0xFF3B82F6), isDark),
                    const SizedBox(width: 10),
                    _statChip('${_stocks.length} Stocks',
                        Icons.bar_chart, const Color(0xFF1DB954), isDark),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1DB954),
                unselectedLabelColor: subColor,
                indicatorColor: const Color(0xFF1DB954),
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                dividerColor: borderColor,
                tabs: const [
                  Tab(text: 'Users'),
                  Tab(text: 'Stocks'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1DB954)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Users tab
                        RefreshIndicator(
                          onRefresh: _loadData,
                          color: const Color(0xFF1DB954),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                            itemCount: _users.length,
                            separatorBuilder: (_, __) =>
                                Divider(color: borderColor, height: 1, indent: 56),
                            itemBuilder: (_, i) {
                              final user = _users[i];
                              final isAdmin = user['role'] == 'ADMIN';
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42, height: 42,
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? const Color(0xFFF59E0B).withOpacity(0.1)
                                            : const Color(0xFF3B82F6).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          (user['name'] ?? 'U').substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                              color: isAdmin
                                                  ? const Color(0xFFF59E0B)
                                                  : const Color(0xFF3B82F6),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(user['name'] ?? '',
                                              style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 2),
                                          Text(user['email'] ?? '',
                                              style: TextStyle(
                                                  color: subColor, fontSize: 12),
                                              overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? const Color(0xFFF59E0B).withOpacity(0.1)
                                            : const Color(0xFF3B82F6).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(user['role'] ?? 'USER',
                                          style: TextStyle(
                                              color: isAdmin
                                                  ? const Color(0xFFF59E0B)
                                                  : const Color(0xFF3B82F6),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 4),
                                    PopupMenuButton(
                                      icon: Icon(Icons.more_vert,
                                          color: subColor, size: 20),
                                      color: isDark
                                          ? const Color(0xFF1A1A1A)
                                          : Colors.white,
                                      itemBuilder: (_) => [
                                        if (!isAdmin)
                                          PopupMenuItem(
                                            onTap: () => _makeAdmin(user),
                                            child: const Row(children: [
                                              Icon(Icons.admin_panel_settings,
                                                  size: 16,
                                                  color: Color(0xFFF59E0B)),
                                              SizedBox(width: 8),
                                              Text('Make Admin'),
                                            ]),
                                          ),
                                        PopupMenuItem(
                                          onTap: () => _deleteUser(user),
                                          child: const Row(children: [
                                            Icon(Icons.delete_outline,
                                                size: 16, color: Color(0xFFE53935)),
                                            SizedBox(width: 8),
                                            Text('Delete',
                                                style: TextStyle(
                                                    color: Color(0xFFE53935))),
                                          ]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Stocks tab
                        RefreshIndicator(
                          onRefresh: _loadData,
                          color: const Color(0xFF1DB954),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                            itemCount: _stocks.length,
                            separatorBuilder: (_, __) =>
                                Divider(color: borderColor, height: 1, indent: 56),
                            itemBuilder: (_, i) {
                              final stock = _stocks[i];
                              final change = (stock['changePercent'] ?? 0) as num;
                              final isPos = change >= 0;
                              final color = isPos
                                  ? const Color(0xFF1DB954)
                                  : const Color(0xFFE53935);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42, height: 42,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          stock['symbol'].toString().substring(0, 1),
                                          style: TextStyle(
                                              color: color,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(stock['symbol'],
                                              style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 2),
                                          Text(stock['companyName'],
                                              style: TextStyle(
                                                  color: subColor, fontSize: 12),
                                              overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('₹${stock['price']}',
                                            style: TextStyle(
                                                color: textColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600)),
                                        Row(children: [
                                          Icon(
                                              isPos
                                                  ? Icons.arrow_drop_up
                                                  : Icons.arrow_drop_down,
                                              color: color, size: 14),
                                          Text('${change.abs().toStringAsFixed(2)}%',
                                              style: TextStyle(
                                                  color: color,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500)),
                                        ]),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Color(0xFFE53935), size: 20),
                                      onPressed: () => _deleteStock(stock),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStockSheet,
        backgroundColor: const Color(0xFF1DB954),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _statChip(String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}