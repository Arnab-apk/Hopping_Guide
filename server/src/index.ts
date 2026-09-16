import http from 'http';
import { URL } from 'url';
import { WebSocketServer, WebSocket } from 'ws';
import dotenv from 'dotenv';
import { SquadManager } from './squad-manager';
import { handleClientMessage, sendJson, sendError } from './handlers';

dotenv.config();

const PORT = parseInt(process.env.PORT || '8080', 10);
const HOST = process.env.HOST || '0.0.0.0';

const manager = new SquadManager();

// Create HTTP server for health checks & WebSocket upgrade
const server = http.createServer((req, res) => {
  const reqUrl = req.url || '/';
  const parsed = new URL(reqUrl, `http://${req.headers.host || 'localhost'}`);

  if (parsed.pathname === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(
      JSON.stringify({
        status: 'ok',
        service: 'puja-squad-websocket-server',
        uptimeSeconds: Math.floor(process.uptime()),
        timestamp: Date.now(),
      })
    );
    return;
  }

  if (parsed.pathname === '/stats') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(
      JSON.stringify({
        status: 'ok',
        ...manager.getStats(),
        timestamp: Date.now(),
      })
    );
    return;
  }

  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('Not Found');
});

// Create WebSocket server
const wss = new WebSocketServer({ noServer: true });

server.on('upgrade', (request, socket, head) => {
  const reqUrl = request.url || '/';
  const parsed = new URL(reqUrl, `http://${request.headers.host || 'localhost'}`);

  if (parsed.pathname !== '/squad' && parsed.pathname !== '/ws') {
    socket.write('HTTP/1.1 404 Not Found\r\n\r\n');
    socket.destroy();
    return;
  }

  // Extract auth/user token
  const token = parsed.searchParams.get('token') || parsed.searchParams.get('userId');
  const userId = token ? token.trim() : `guest_${Math.random().toString(36).substring(2, 9)}`;

  wss.handleUpgrade(request, socket, head, (ws) => {
    wss.emit('connection', ws, request, userId);
  });
});

wss.on('connection', (ws: WebSocket, _request: http.IncomingMessage, userId: string) => {
  console.log(`[Server] WebSocket connection established for user: ${userId}`);
  manager.registerConnection(userId, ws);

  // Send connection ack
  sendJson(ws, {
    type: 'connection_established',
    user_id: userId,
    server_timestamp: Date.now(),
  });

  ws.on('message', (data: Buffer | string) => {
    handleClientMessage(ws, userId, data.toString(), manager);
  });

  ws.on('error', (err) => {
    console.error(`[Server] Error for user ${userId}:`, err);
  });

  ws.on('close', (code, reason) => {
    console.log(`[Server] Connection closed for user ${userId} (code: ${code}, reason: ${reason.toString()})`);
    const disc = manager.handleDisconnect(userId);
    if (disc) {
      manager.broadcast(disc.squadCode, {
        type: 'member_left',
        squad_code: disc.squadCode,
        member_id: userId,
        server_timestamp: Date.now(),
      });
    }
  });
});

server.listen(PORT, HOST, () => {
  console.log('====================================================');
  console.log(`🚀 Kolkata Puja Squad WebSocket Server`);
  console.log(`📡 Listening on http://${HOST}:${PORT}`);
  console.log(`🔌 WebSocket Endpoint: ws://${HOST}:${PORT}/squad`);
  console.log(`🩺 Health Check: http://${HOST}:${PORT}/health`);
  console.log('====================================================');
});

// Graceful shutdown
function shutdown(signal: string) {
  console.log(`\n[Server] Received ${signal}, gracefully shutting down...`);
  wss.close(() => {
    server.close(() => {
      console.log('[Server] Server closed successfully');
      process.exit(0);
    });
  });

  setTimeout(() => {
    console.error('[Server] Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, 5000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
