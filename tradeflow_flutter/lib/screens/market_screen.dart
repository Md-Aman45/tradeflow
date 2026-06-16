import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  List<dynamic> _stocks = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  bool _wsConnected = false;
  String _search = '';
  StompClient? _stompClient;

  @override
  void initState() {
    super.initState();
    _loadStocks();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    super.dispose();
  }

  void _connectWebSocket() {
    _stompClient = StompClient(
      config: StompConfig(
        url: Constants.wsUrl,
        onConnect: (frame) {
          setState(() => _wsConnected = true);

          // Subscribe to all stock updates
          _stompClient!.subscribe(
            destination: '/topic/stocks',
            callback: (frame) {
              if (frame.body != null) {
                final update = jsonDecode(frame.body!);
                _updateStock(update);
              }
            },
          );

          // Request current prices
          _stompClient!.send(destination: '/app/subscribe-stocks');
        },
        onDisconnect: (_) => setState(() => _wsConnected = false),
        onWebSocketError: (_) => setState(() => _wsConnected = false),
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _stompClient!.activate();
  }

  void _updateStock(dynamic update) {
    setState(() {
      final index = _stocks.indexWhere((s) => s['id'] == update['stockId']);
      if (index != -1) {
        _stocks[index] = {
          ..._stocks[index],
          'price': update['price'],
          'changePercent': update['changePercent'],
        };
        _applySearch();
      }
    });
  }

  void _applySearch() {
    _filtered = _stocks
        .where((s) =>
            s['symbol'].toString().toUpperCase().contains(_search.toUpperCase()) ||
            s['companyName'].toString().toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  Future<void> _loadStocks() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService().getToken();
      final res = await http.get(Uri.parse(Constants.stocks),
          headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _stocks = data;
          _filtered = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      _search = query;
      _applySearch();
    });
  }

  Future<void> _showBuySheet(Map<String, dynamic> stock) async {
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
          final total = (stock['price'] as num) * qty;
          return Padding(
            padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stock['symbol'],
                            style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(stock['companyName'],
                            style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${stock['price']}',
                            style: const TextStyle(
                                color: Color(0xFF1DB954),
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(
                          '${(stock['changePercent'] ?? 0) >= 0 ? '+' : ''}${(stock['changePercent'] ?? 0).toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: (stock['changePercent'] ?? 0) >= 0
                                ? const Color(0xFF1DB954)
                                : const Color(0xFFE53935),
                            fontSize: 13,
                          ),
                        ),
                      ],
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
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _qtyButton(Icons.remove, () {
                                if (qty > 1) { qtyCtrl.text = (qty - 1).toString(); setS(() {}); }
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
                                    fillColor: isDark ? const Color(0xFF222222) : const Color(0xFFF5F5F5),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _qtyButton(Icons.add, () {
                                qtyCtrl.text = (qty + 1).toString(); setS(() {});
                              }, isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Total',
                            style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text('₹${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Color(0xFF1DB954),
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final res = await http.post(
                        Uri.parse(Constants.buyStock),
                        headers: {
                          'Authorization': 'Bearer $token',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({'stockId': stock['id'], 'quantity': qty}),
                      );
                      if (mounted) {
                        final ok = res.statusCode == 200;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? '✅ Bought $qty shares of ${stock['symbol']}'
                              : '❌ ${jsonDecode(res.body)['message'] ?? 'Failed'}'),
                          backgroundColor: ok ? const Color(0xFF1DB954) : const Color(0xFFE53935),
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
                    child: Text('Buy ${stock['symbol']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
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
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
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
                      Text('Market',
                          style: TextStyle(
                              color: textColor, fontSize: 26, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                              color: _wsConnected
                                  ? const Color(0xFF1DB954)
                                  : const Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _wsConnected ? 'Live prices' : 'Connecting...',
                            style: TextStyle(
                              color: _wsConnected
                                  ? const Color(0xFF1DB954)
                                  : const Color(0xFFE53935),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _loadStocks,
                    icon: Icon(Icons.refresh_rounded, color: subColor),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  onChanged: _onSearch,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search stocks...',
                    hintStyle: TextStyle(color: subColor, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: subColor, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // List
            Expanded(
              child: _isLoading
                  ? _buildShimmer(isDark)
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, color: subColor, size: 48),
                              const SizedBox(height: 12),
                              Text('No stocks found',
                                  style: TextStyle(color: subColor, fontSize: 14)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadStocks,
                          color: const Color(0xFF1DB954),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                Divider(color: borderColor, height: 1, indent: 60),
                            itemBuilder: (_, i) =>
                                _buildStockTile(_filtered[i], isDark, textColor, subColor),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockTile(Map<String, dynamic> stock, bool isDark,
      Color textColor, Color subColor) {
    final change = (stock['changePercent'] ?? 0.0) as num;
    final isPos = change >= 0;
    final changeColor = isPos ? const Color(0xFF1DB954) : const Color(0xFFE53935);

    return InkWell(
      onTap: () => _showBuySheet(stock),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  stock['symbol'].toString().substring(0, 1),
                  style: TextStyle(
                      color: changeColor, fontSize: 16, fontWeight: FontWeight.bold),
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
                          color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(stock['companyName'],
                      style: TextStyle(color: subColor, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${stock['price']}',
                    style: TextStyle(
                        color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(isPos ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: changeColor, size: 16),
                    Text('${change.abs().toStringAsFixed(2)}%',
                        style: TextStyle(
                            color: changeColor, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 8,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
        highlightColor: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(width: 42, height: 42,
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(height: 14, width: 80,
                      decoration: BoxDecoration(color: Colors.white,
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 11, width: 140,
                      decoration: BoxDecoration(color: Colors.white,
                          borderRadius: BorderRadius.circular(4))),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(height: 14, width: 60,
                    decoration: BoxDecoration(color: Colors.white,
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(height: 11, width: 40,
                    decoration: BoxDecoration(color: Colors.white,
                        borderRadius: BorderRadius.circular(4))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}