import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'market_screen.dart';
import 'portfolio_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isAdmin = false;

  // Keys let us call public refresh methods on each screen from here
  final GlobalKey<PortfolioScreenState> _portfolioKey = GlobalKey();
  final GlobalKey<WalletScreenState> _walletKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = await AuthService().getRole();
    setState(() => _isAdmin = role == 'ADMIN');
  }

  List<Widget> get _screens => [
        const MarketScreen(),
        PortfolioScreen(key: _portfolioKey),
        WalletScreen(key: _walletKey),
        if (_isAdmin) const AdminScreen(),
        const ProfileScreen(),
      ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);

    // Refresh data every time the person switches into these tabs,
    // so a Buy/Sell on Market is reflected immediately without
    // needing a manual pull-to-refresh.
    if (index == 1) {
      _portfolioKey.currentState?.refresh();
    } else if (index == 2) {
      _walletKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Market',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline_rounded),
              activeIcon: Icon(Icons.pie_chart_rounded),
              label: 'Portfolio',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
            if (_isAdmin)
              const BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings_outlined),
                activeIcon: Icon(Icons.admin_panel_settings),
                label: 'Admin',
              ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}