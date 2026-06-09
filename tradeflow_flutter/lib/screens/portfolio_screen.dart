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

class _PortfolioScreenState extends State<PortfolioScreen> {
  List<dynamic> _portfolio = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    try {
      final token = await AuthService().getToken();
      final response = await http.get(
        Uri.parse(Constants.portfolio),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _portfolio = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sellStock(Map<String, dynamic> item) async {
    final qtyController = TextEditingController(text: '1');
    final token = await AuthService().getToken();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sell ${item['stockSymbol']}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('You own ${item['quantity']} shares',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Quantity to sell',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1F1F1F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final response = await http.post(
                    Uri.parse(Constants.sellStock),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'stockId': item['stockId'] ?? 1,
                      'quantity': int.parse(qtyController.text),
                    }),
                  );
                  if (mounted) {
                    _loadPortfolio();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response.statusCode == 200
                            ? '✅ Sold successfully!'
                            : '❌ Failed to sell'),
                        backgroundColor: response.statusCode == 200
                            ? const Color(0xFF00C896)
                            : Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Sell',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalValue = _portfolio.fold(
        0, (sum, item) => sum + (item['totalValue'] ?? 0));
    double totalPnL = _portfolio.fold(
        0, (sum, item) => sum + (item['profitOrLoss'] ?? 0));
    bool isPnLPositive = totalPnL >= 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPortfolio,
          color: const Color(0xFF00C896),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Portfolio',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),

                      // Portfolio summary card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00C896).withOpacity(0.15),
                              const Color(0xFF00C896).withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00C896).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Value',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              '₹${totalValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  isPnLPositive
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: isPnLPositive
                                      ? const Color(0xFF00C896)
                                      : const Color(0xFFFF4444),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${isPnLPositive ? '+' : ''}₹${totalPnL.toStringAsFixed(2)} P&L',
                                  style: TextStyle(
                                    color: isPnLPositive
                                        ? const Color(0xFF00C896)
                                        : const Color(0xFFFF4444),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        '${_portfolio.length} Holdings',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF00C896)),
                  ),
                )
              else if (_portfolio.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.pie_chart_outline,
                              color: Colors.grey, size: 64),
                          SizedBox(height: 16),
                          Text('No holdings yet',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Buy stocks from Market tab',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _portfolio[index];
                        final pnl = item['profitOrLoss'] ?? 0.0;
                        final isPos = pnl >= 0;
                        final pnlColor = isPos
                            ? const Color(0xFF00C896)
                            : const Color(0xFFFF4444);

                        return GestureDetector(
                          onTap: () => _sellStock(item),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161616),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: pnlColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      item['stockSymbol']
                                          .substring(0, 1),
                                      style: TextStyle(
                                        color: pnlColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['stockSymbol'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      const SizedBox(height: 2),
                                      Text(
                                          '${item['quantity']} shares · Avg ₹${item['averageBuyPrice']}',
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${(item['totalValue'] ?? 0).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${isPos ? '+' : ''}₹${pnl.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: pnlColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _portfolio.length,
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