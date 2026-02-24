import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as http from 'http';
import { WebSocketServer } from 'ws';
import { Server as SocketIOServer } from 'socket.io';
import type { Socket } from 'socket.io';
import type { JwtPayload } from '@noton/shared';
import { AppModule } from './app.module';
import { PresenceService } from './presence/presence.service';

async function bootstrap() {
  // NestJS DI context — no HTTP server (pure WebSocket service)
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn', 'log'],
  });

  const config = app.get(ConfigService);
  const jwtService = app.get(JwtService);
  const presenceService = app.get(PresenceService);
  const port = config.get<number>('PORT', 3003);

  // ── y-websocket dynamic import (ESM package) ─────────────────────────────
  type SetupFn = (ws: any, req: any, opts?: { docName?: string; gc?: boolean }) => void;
  let setupWSConnection: SetupFn = (_ws, _req, _opts) => {
    console.warn('[realtime] setupWSConnection not available — y-websocket not loaded');
  };
  try {
    const mod = await import('y-websocket/bin/utils');
    setupWSConnection = (mod as any).setupWSConnection;
    console.log('[realtime] y-websocket loaded');
  } catch (err: any) {
    console.warn('[realtime] y-websocket/bin/utils import failed:', err.message);
  }

  // ── Plain HTTP server (minimal — health only) ─────────────────────────────
  const httpServer = http.createServer((_req, res) => {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', service: 'realtime', port }));
  });

  // ── Socket.IO — presence ──────────────────────────────────────────────────
  const io = new SocketIOServer(httpServer, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
    path: '/presence',
  });

  // JWT auth middleware
  io.use((socket: Socket, next) => {
    const token = (socket.handshake.auth?.token ??
      socket.handshake.query?.token) as string | undefined;
    if (!token) return next(new Error('Unauthorized'));
    try {
      const payload = jwtService.verify<JwtPayload>(token);
      (socket as any).user = payload;
      next();
    } catch {
      next(new Error('Unauthorized'));
    }
  });

  io.on('connection', (socket: Socket) => {
    const user = (socket as any).user as JwtPayload;
    const documentId = socket.handshake.query.documentId as string | undefined;

    if (documentId) {
      socket.join(documentId);
      presenceService.join(documentId, socket.id, user);
      io.to(documentId).emit('presence:update', {
        documentId,
        users: presenceService.getPresence(documentId),
      });
    }

    socket.on('disconnect', () => {
      if (documentId) {
        presenceService.leave(documentId, socket.id);
        io.to(documentId).emit('presence:update', {
          documentId,
          users: presenceService.getPresence(documentId),
        });
      } else {
        const affected = presenceService.leaveAll(socket.id);
        for (const docId of affected) {
          io.to(docId).emit('presence:update', {
            documentId: docId,
            users: presenceService.getPresence(docId),
          });
        }
      }
    });
  });

  // ── WebSocket server — y-websocket (Yjs collaboration) ───────────────────
  const wss = new WebSocketServer({ noServer: true });

  wss.on('connection', (ws, req) => {
    const url = new URL(req.url!, `http://localhost`);
    const docName = url.searchParams.get('room') ?? 'default';
    setupWSConnection(ws, req, { docName, gc: true });
  });

  // Route HTTP upgrade: /yjs → wss, everything else → Socket.IO
  httpServer.on('upgrade', (req, socket, head) => {
    const url = new URL(req.url!, 'http://localhost');
    if (url.pathname !== '/yjs') return; // Socket.IO handles /presence

    const token = url.searchParams.get('token');
    if (!token) {
      socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
      socket.destroy();
      return;
    }
    try {
      jwtService.verify(token);
    } catch {
      socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
      socket.destroy();
      return;
    }

    wss.handleUpgrade(req, socket, head, (ws) => wss.emit('connection', ws, req));
  });

  httpServer.listen(port, '0.0.0.0', () => {
    console.log(`[realtime] running on port ${port}`);
    console.log(`[realtime]   ws://localhost:${port}/yjs?room=<docId>&token=<jwt>`);
    console.log(`[realtime]   ws://localhost:${port}/presence?documentId=<docId>`);
  });
}

bootstrap();
