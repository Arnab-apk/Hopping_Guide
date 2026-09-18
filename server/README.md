# Kolkata Puja Parikrama — High-Speed Squad WebSocket Server

Ultra-low latency (~15–40 ms) in-memory squad live tracking and location broadcast engine for Kolkata Puja Parikrama squads.

## 🚀 Key Highlights

- **Sub-50ms Latency**: Coordinates broadcast directly in RAM to squad members without blocking on disk writes.
- **Zero-Cost Free Tier**: Deployable on free tiers (Render, Fly.io, Railway) or locally.
- **Zero Vendor Lock-In**: Completely removes mandatory Firebase Realtime Database setup.
- **Auto-Scale with Redis**: Automatically uses Redis Pub/Sub if `REDIS_URL` is configured, or pure in-memory mode if omitted.
- **Robust Mobile Reconnection**: Client features exponential backoff and message buffering for crowded cellular network resilience.

---

## 🛠️ Local Development

### 1. Install & Build
```bash
cd server
npm install
npm run build
```

### 2. Start Locally
```bash
# Start production build
npm start

# Or develop with hot reloading
npm run dev
```

The server listens on `http://0.0.0.0:8080` (WebSocket at `ws://localhost:8080/squad`).

### 3. Run E2E Integration Test
```bash
npm run test
```

---

## ☁️ 1-Click Free Tier Deployments

### Render.com
1. Create a new **Web Service** on [Render](https://render.com).
2. Connect your GitHub repository and set **Root Directory** to `server`.
3. Set **Runtime** to `Node` or `Docker`.
4. Build Command: `npm install && npm run build`
5. Start Command: `npm start`
6. Health Check Path: `/health`

### Fly.io
```bash
cd server
fly launch
fly deploy
```

---

## 📱 Connecting the Flutter App

To connect the mobile app to your WebSocket server:
```bash
# For local Android emulator:
flutter run --dart-define=WEBSOCKET_SERVER_URL=ws://10.0.2.2:8080/squad

# For physical phone on same Wi-Fi:
flutter run --dart-define=WEBSOCKET_SERVER_URL=ws://192.168.x.x:8080/squad

# For deployed production server (e.g. Render / Fly):
flutter run --dart-define=WEBSOCKET_SERVER_URL=wss://your-squad-server.onrender.com/squad
```
