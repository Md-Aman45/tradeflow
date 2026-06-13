import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../services/auth_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _wallet;
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService().getToken();
      final headers = {'Authorization': 'Bearer $token'};
      final results = await Future.wait([
        http.get(Uri.parse(Constants.wallet), headers: headers),
        http.get(Uri.parse(Constants.transactions), headers: headers),
      ]);
      setState(() {
        if (results[0].statusCode == 200) _wallet = jsonDecode(results[0].body);
        if (results[1].statusCode == 200) _transactions = jsonDecode(results[1].body);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddMoneySheet() async {
    final ctrl = TextEditingController();
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
            Text('Add Money',
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Enter amount to add to wallet',
                style: TextStyle(color: isDark ? const Color(0xFF888888) : const Color(0xFF999999), fontSize: 13)),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222222) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    fontSize: 28, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                      color: Color(0xFF1DB954), fontSize: 28, fontWeight: FontWeight.bold),
                  hintText: '0',
                  hintStyle: TextStyle(
                      color: isDark ? const Color(0xFF444444) : const Color(0xFFCCCCCC),
                      fontSize: 28),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [1000, 5000, 10000, 25000, 50000].map((amt) {
                return GestureDetector(
                  onTap: () => ctrl.text = amt.toString(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DB954).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.25)),
                    ),
                    child: Text('+₹${amt >= 1000 ? '${amt ~/ 1000}K' : amt}',
                        style: const TextStyle(color: Color(0xFF1DB954), fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.isEmpty) return;
                  Navigator.pop(ctx);
                  final res = await http.post(
                    Uri.parse(Constants.addBalance),
                    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                    body: jsonEncode({'amount': double.parse(ctrl.text)}),
                  );
                  if (mounted) {
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res.statusCode == 200
                          ? '✅ ₹${ctrl.text} added to wallet'
                          : '❌ Failed to add money'),
                      backgroundColor: res.statusCode == 200 ? const Color(0xFF1DB954) : const Color(0xFFE53935),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Money', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
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
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF1DB954),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wallet', style: TextStyle(color: textColor, fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),

                      // Balance card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1DB954), Color(0xFF16A34A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1DB954).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Available Balance',
                                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.circle, color: Colors.white, size: 8),
                                      SizedBox(width: 4),
                                      Text('Virtual', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isLoading ? '...' : '₹${_wallet?['balance'] ?? '0.00'}',
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showAddMoneySheet,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Money', style: TextStyle(fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1DB954),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Transactions', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${_transactions.length} total', style: TextStyle(color: subColor, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFF1DB954)),
                  )),
                )
              else if (_transactions.isEmpty)
                SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(children: [
                      Icon(Icons.receipt_long_outlined, color: subColor, size: 56),
                      const SizedBox(height: 12),
                      Text('No transactions yet', style: TextStyle(color: subColor, fontSize: 14)),
                    ]),
                  )),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final tx = _transactions[i];
                        final isBuy = tx['type'] == 'BUY';
                        final color = isBuy ? const Color(0xFFE53935) : const Color(0xFF1DB954);
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(isBuy ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${tx['type']} ${tx['stockSymbol'] ?? ''}',
                                            style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text('${tx['quantity']} shares @ ₹${tx['price']}',
                                            style: TextStyle(color: subColor, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${isBuy ? '-' : '+'}₹${tx['totalAmount']}',
                                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            if (i < _transactions.length - 1)
                              Divider(color: borderColor, height: 1, indent: 56),
                          ],
                        );
                      },
                      childCount: _transactions.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}