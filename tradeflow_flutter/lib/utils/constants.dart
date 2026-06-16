class Constants {
  static const String baseUrl = 'http://localhost:8080';

  // Auth
  static const String register = '$baseUrl/api/auth/register';
  static const String login = '$baseUrl/api/auth/login';

  // Stocks
  static const String stocks = '$baseUrl/api/stocks';

  // Wallet
  static const String wallet = '$baseUrl/api/wallet';
  static const String addBalance = '$baseUrl/api/wallet/add';
  static const String deductBalance = '$baseUrl/api/wallet/deduct';

  // Portfolio
  static const String portfolio = '$baseUrl/api/portfolio';
  static const String buyStock = '$baseUrl/api/portfolio/buy';
  static const String sellStock = '$baseUrl/api/portfolio/sell';
  static const String transactions = '$baseUrl/api/portfolio/transactions';

  // Admin
  static const String adminUsers = '$baseUrl/api/admin/users';
  static const String adminStocks = '$baseUrl/api/admin/stocks';

  // WebSocket — SockJS endpoint
  static const String wsUrl = 'http://localhost:8080/ws';
}