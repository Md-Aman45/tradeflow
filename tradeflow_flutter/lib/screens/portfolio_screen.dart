import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../services/auth_service.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _portfolio = [];
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  late TabController _tabController;

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
        http.get(Uri.parse(Constants.portfolio), headers: headers),
        http.get(Uri.parse(Constants.transactions), headers: headers),
      ]);
      setState(() {
        if (results[0].statusCode == 200) {
          _portfolio = jsonDecode(results[0].body);
        }
        if (results[1].statusCode == 200) {
          _transactions = jsonDecode(results[1].body);
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showSellSheet(Map<String, dynamic> item) async {
    final qtyCtrl = TextEditingController(text: '1');
    final token = await AuthService().getToken();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final qty = int.tryParse(qtyCtrl.text) ?? 1;
          return Padding(
            padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF333333)
                          : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['stockSymbol'],
                            style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('You own ${item['quantity']} shares',
                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: 13)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('SELL',
                          style: TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quantity',
                              style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _qtyBtn(Icons.remove, () {
                                if (qty > 1) {
                                  qtyCtrl.text = (qty - 1).toString();
                                  setS(() {});
                                }
                              }, isDark),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  controller: qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  onChanged: (_) => setS(() {}),
                                  style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF222222)
                                        : const Color(0xFFF5F5F5),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none),
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _qtyBtn(Icons.add, () {
                                if (qty < (item['quantity'] as int)) {
                                  qtyCtrl.text = (qty + 1).toString();
                                  setS(() {});
                                }
                              }, isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final res = await http.post(
                        Uri.parse(Constants.sellStock),
                        headers: {
                          'Authorization': 'Bearer $token',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({
                          'stockId': item['portfolioId'],
                          'quantity': qty,
                        }),
                      );
                      if (mounted) {
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.statusCode == 200
                                ? '✅ Sold $qty shares of ${item['stockSymbol']}'
                                : '❌ Failed to sell'),
                            backgroundColor: res.statusCode == 200
                                ? const Color(0xFF1DB954)
                                : const Color(0xFFE53935),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Sell Shares',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222222) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A), size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? const Color(0xFF888888) : const Color(0xFF999999);
    final borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);

    double totalValue = _portfolio.fold(
        0.0, (s, i) => s + ((i['totalValue'] ?? 0) as num).toDouble());
    double totalPnL = _portfolio.fold(
        0.0, (s, i) => s + ((i['profitOrLoss'] ?? 0) as num).toDouble());
    bool isPnLPos = totalPnL >= 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Portfolio',
                      style: TextStyle(
                          color: textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPnLPos
                            ? [
                                const Color(0xFF1DB954).withOpacity(0.15),
                                const Color(0xFF1DB954).withOpacity(0.05),
                              ]
                            : [
                                const Color(0xFFE53935).withOpacity(0.15),
                                const Color(0xFFE53935).withOpacity(0.05),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isPnLPos
                            ? const Color(0xFF1DB954).withOpacity(0.2)
                            : const Color(0xFFE53935).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current Value',
                                  style: TextStyle(
                                      color: subColor, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                '₹${totalValue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('P&L',
                                style: TextStyle(
                                    color: subColor, fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                    isPnLPos
                                        ? Icons.arrow_drop_up
                                        : Icons.arrow_drop_down,
                                    color: isPnLPos
                                        ? const Color(0xFF1DB954)
                                        : const Color(0xFFE53935),
                                    size: 20),
                                Text(
                                  '₹${totalPnL.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isPnLPos
                                        ? const Color(0xFF1DB954)
                                        : const Color(0xFFE53935),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF1DB954),
                    unselectedLabelColor: subColor,
                    indicatorColor: const Color(0xFF1DB954),
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    dividerColor: borderColor,
                    tabs: [
                      Tab(text: 'Holdings (${_portfolio.length})'),
                      Tab(text: 'History (${_transactions.length})'),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1DB954)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Holdings tab
                        _portfolio.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.pie_chart_outline,
                                        color: subColor, size: 56),
                                    const SizedBox(height: 12),
                                    Text('No holdings yet',
                                        style: TextStyle(
                                            color: subColor, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text('Buy stocks from Market tab',
                                        style: TextStyle(
                                            color: subColor, fontSize: 12)),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadData,
                                color: const Color(0xFF1DB954),
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 12, 20, 20),
                                  itemCount: _portfolio.length,
                                  separatorBuilder: (_, __) => Divider(
                                      color: borderColor,
                                      height: 1,
                                      indent: 56),
                                  itemBuilder: (_, i) => _buildHoldingTile(
                                      _portfolio[i], isDark, textColor, subColor),
                                ),
                              ),

                        // History tab
                        _transactions.isEmpty
                            ? Center(
                                child: Text('No transactions yet',
                                    style: TextStyle(color: subColor)),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 12, 20, 20),
                                itemCount: _transactions.length,
                                separatorBuilder: (_, __) =>
                                    Divider(color: borderColor, height: 1),
                                itemBuilder: (_, i) => _buildTxTile(
                                    _transactions[i], isDark, textColor, subColor),
                              ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldingTile(Map<String, dynamic> item, bool isDark,
      Color textColor, Color subColor) {
    final pnl = (item['profitOrLoss'] ?? 0) as num;
    final isPos = pnl >= 0;
    final pnlColor =
        isPos ? const Color(0xFF1DB954) : const Color(0xFFE53935);

    return InkWell(
      onTap: () => _showSellSheet(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: pnlColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  item['stockSymbol'].toString().substring(0, 1),
                  style: TextStyle(
                      color: pnlColor,
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
                  Text(item['stockSymbol'],
                      style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                      '${item['quantity']} shares · Avg ₹${item['averageBuyPrice']}',
                      style: TextStyle(color: subColor, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${(item['totalValue'] ?? 0).toStringAsFixed(2)}',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                        isPos
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: pnlColor,
                        size: 16),
                    Text(
                      '₹${pnl.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                          color: pnlColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTxTile(Map<String, dynamic> tx, bool isDark,
      Color textColor, Color subColor) {
    final isBuy = tx['type'] == 'BUY';
    final color =
        isBuy ? const Color(0xFFE53935) : const Color(0xFF1DB954);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
                isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tx['type']} ${tx['stockSymbol'] ?? ''}',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${tx['quantity']} shares @ ₹${tx['price']}',
                    style: TextStyle(color: subColor, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${isBuy ? '-' : '+'}₹${tx['totalAmount']}',
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}