# 📈 Tradeflow — Virtual Stock Trading Platform

A full-stack paper trading application that simulates real stock market trading. Built with Spring Boot, Flutter, PostgreSQL, Redis, and WebSocket for live price updates.

> **Note:** This is a virtual trading simulator. All wallet balances and transactions use simulated money — not connected to any real payment system or stock exchange.


---

## ✨ Features

### User Features
- 🔐 JWT-based authentication (register/login)
- 📈 Real-time stock price simulation (updates every 5 seconds)
- 💼 Portfolio management — buy and sell stocks
- 💰 Virtual wallet with add/deduct balance
- 📊 Transaction history with P&L calculation
- 🌙 Dark / Light theme toggle

### Admin Features
- 👥 Manage all users (promote to admin, delete)
- 📋 Full stock CRUD (create, update, delete)
- 🛡️ Role-based access control (USER / ADMIN)

### Technical Features
- ⚡ Redis caching for stock data (10-min TTL)
- 🔄 WebSocket live price broadcasting (STOMP)
- 🐳 Docker + Docker Compose support
- 📖 Swagger/OpenAPI documentation
- ✅ Input validation and global exception handling

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                        │
│   Login · Market · Portfolio · Wallet · Admin        │
└──────────────────────┬──────────────────────────────┘
                       │ HTTP REST + JWT
                       ▼
┌─────────────────────────────────────────────────────┐
│              Spring Boot Backend                     │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │   Auth   │  │  Stock   │  │    Portfolio     │  │
│  │ Controller│  │ Service  │  │    Service       │  │
│  └──────────┘  └────┬─────┘  └──────────────────┘  │
│                     │                                │
│  ┌──────────────────▼──────────────────────────┐    │
│  │              Redis Cache                     │    │
│  │         (10-min TTL for stocks)              │    │
│  └─────────────────────────────────────────────┘    │
│                                                      │
│  ┌─────────────────────────────────────────────┐    │
│  │    WebSocket Scheduler (every 5 seconds)     │    │
│  │    Randomly fluctuates prices ±2%            │    │
│  └─────────────────────────────────────────────┘    │
└──────────────────────┬──────────────────────────────┘
                       │ JPA/Hibernate
                       ▼
┌─────────────────────────────────────────────────────┐
│                  PostgreSQL                          │
│   users · stocks · wallets · portfolio · transactions│
└─────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

### Backend
| Technology | Version | Purpose |
|-----------|---------|---------|
| Java | 17 | Language |
| Spring Boot | 4.0.6 | Backend framework |
| Spring Security | 7.x | JWT authentication |
| PostgreSQL | 15 | Primary database |
| Redis | 7 | Caching layer |
| WebSocket (STOMP) | - | Live price updates |
| Docker | - | Containerization |
| Swagger/OpenAPI | 3.x | API documentation |
| Lombok | - | Boilerplate reduction |

### Frontend
| Technology | Version | Purpose |
|-----------|---------|---------|
| Flutter | 3.44.1 | Cross-platform UI |
| Dart | 3.12.1 | Language |
| Provider | 6.x | State management |
| HTTP | 1.x | REST API calls |
| Flutter Secure Storage | 9.x | JWT token storage |
| Shimmer | 3.x | Loading animations |

---

## 📁 Project Structure

```
tradeflow/
├── tradeflow-backend/          # Spring Boot API
│   ├── src/main/java/com/tradeflow/tradeflow/
│   │   ├── config/             # Security, CORS, Redis, WebSocket configs
│   │   ├── controller/         # REST endpoints
│   │   ├── service/            # Business logic
│   │   ├── entity/             # JPA entities
│   │   ├── repository/         # Spring Data repositories
│   │   ├── dto/                # Request/Response DTOs
│   │   ├── exception/          # Custom exceptions + global handler
│   │   ├── security/           # JWT filter and service
│   │   └── websocket/          # STOMP scheduler and controller
│   ├── Dockerfile
│   └── docker-compose.yml
│
└── tradeflow_flutter/          # Flutter mobile/web app
    └── lib/
        ├── main.dart
        ├── theme/              # Dark/Light theme
        ├── providers/          # Theme provider
        ├── services/           # API service layer
        ├── screens/            # UI screens
        └── utils/              # Constants, helpers
```

---

## 🚦 API Endpoints

### Auth
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/register` | ❌ | Register new user |
| POST | `/api/auth/login` | ❌ | Login and get JWT token |

### Stocks
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/stocks` | ✅ | Get all stocks |
| GET | `/api/stocks/{id}` | ✅ | Get stock by ID |

### Wallet
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/wallet` | ✅ | Get wallet balance |
| POST | `/api/wallet/add` | ✅ | Add virtual balance |
| POST | `/api/wallet/deduct` | ✅ | Deduct balance |

### Portfolio
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/portfolio` | ✅ | Get holdings with P&L |
| POST | `/api/portfolio/buy` | ✅ | Buy a stock |
| POST | `/api/portfolio/sell` | ✅ | Sell a stock |
| GET | `/api/portfolio/transactions` | ✅ | Get transaction history |

### Admin (ADMIN role only)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/admin/users` | 🔑 | Get all users |
| PUT | `/api/admin/users/{id}/make-admin` | 🔑 | Promote to admin |
| DELETE | `/api/admin/users/{id}` | 🔑 | Delete user |
| POST | `/api/admin/stocks` | 🔑 | Create stock |
| PUT | `/api/admin/stocks/{id}` | 🔑 | Update stock |
| DELETE | `/api/admin/stocks/{id}` | 🔑 | Delete stock |

> ✅ = JWT token required · 🔑 = ADMIN role required

---

## ⚙️ Environment Variables

Set these in Railway (or `.env` locally):

```env
SPRING_DATASOURCE_URL=jdbc:postgresql://<host>:<port>/<db>
SPRING_DATASOURCE_USERNAME=<username>
SPRING_DATASOURCE_PASSWORD=<password>
JWT_SECRET=<your-256-bit-secret>
JWT_EXPIRATION=86400000
SPRING_DATA_REDIS_HOST=<redis-host>
SPRING_DATA_REDIS_PORT=6379
```

---

## 🐳 Run with Docker

```bash
# Clone the repo
git clone https://github.com/yourusername/tradeflow.git
cd tradeflow/tradeflow-backend

# Start everything (app + PostgreSQL + Redis)
docker compose up --build
```

---

## 💻 Run Locally

### Backend
```bash
cd tradeflow-backend

# Make sure PostgreSQL and Redis are running locally
# Then:
mvn spring-boot:run
```

### Flutter
```bash
cd tradeflow_flutter

# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Build APK
flutter build apk --release
```

---

## 🔑 Default Test Accounts

| Email | Password | Role |
|-------|----------|------|
| admin@gmail.com | 123456 | ADMIN |
| ayush@gmail.com | 123456 | USER |

> To set an account as ADMIN, run this SQL in PostgreSQL:
> ```sql
> UPDATE users SET role = 'ADMIN' WHERE email = 'your@email.com';
> ```

---

## 📱 Screenshots

> Add screenshots here after deployment

---

## 🗺️ Roadmap

- [ ] Build release APK
- [ ] Real-time WebSocket in Flutter (native STOMP)
- [ ] Stock detail screen with price chart
- [ ] Push notifications on price alerts
- [ ] Biometric login
- [ ] Portfolio performance graph

---

## 👨‍💻 Author

**MD Aman**
- BCA Student | Software Developer
- [GitHub](https://github.com/Md-Aman45)
- [Linkdln](https://www.linkedin.com/in/md-aman-7941a0355/)

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

> Built as a portfolio project to demonstrate full-stack development with Spring Boot and Flutter.
