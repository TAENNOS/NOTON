import { NestFactory } from '@nestjs/core';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import fastifyHttpProxy from '@fastify/http-proxy';
import fastifyRateLimit from '@fastify/rate-limit';
import { AppModule } from './app.module';
import type { JwtPayload } from '@noton/shared';
import type { FastifyRequest, FastifyReply } from 'fastify';

// ── Public paths that skip JWT verification ─────────────────────────────────
const PUBLIC_PATHS = new Set([
  '/api/identity/auth/register',
  '/api/identity/auth/login',
  '/api/identity/auth/refresh',
]);

// ── Upstream service map ─────────────────────────────────────────────────────
const SERVICES = [
  {
    prefix: '/api/identity',
    envKey: 'IDENTITY_SERVICE_URL',
    defaultUrl: 'http://localhost:3001',
  },
  {
    prefix: '/api/docs',
    envKey: 'DOCS_SERVICE_URL',
    defaultUrl: 'http://localhost:3002',
  },
  {
    prefix: '/api/realtime',
    envKey: 'REALTIME_SERVICE_URL',
    defaultUrl: 'http://localhost:3003',
  },
  {
    prefix: '/api/chat',
    envKey: 'CHAT_SERVICE_URL',
    defaultUrl: 'http://localhost:3004',
  },
  {
    prefix: '/api/files',
    envKey: 'FILES_SERVICE_URL',
    defaultUrl: 'http://localhost:3005',
  },
  {
    prefix: '/api/automation',
    envKey: 'AUTOMATION_SERVICE_URL',
    defaultUrl: 'http://localhost:3006',
  },
  {
    prefix: '/api/assistant',
    envKey: 'ASSISTANT_SERVICE_URL',
    defaultUrl: 'http://localhost:3007',
  },
  {
    prefix: '/api/notifications',
    envKey: 'NOTIFICATIONS_SERVICE_URL',
    defaultUrl: 'http://localhost:3008',
  },
] as const;

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({ logger: { level: 'warn' } }),
  );

  const config = app.get(ConfigService);
  const jwtService = app.get(JwtService);
  const isDev = config.get('NODE_ENV', 'development') !== 'production';

  // ── Global prefix for NestJS-handled routes (e.g. GET /api/health) ────────
  app.setGlobalPrefix('api');

  // ── CORS ──────────────────────────────────────────────────────────────────
  app.enableCors({
    origin: config.get('CORS_ORIGIN', '*'),
    credentials: true,
  });

  // ── Rate limiting ─────────────────────────────────────────────────────────
  // 10 req/s per IP in production, relaxed in development
  await app.register(fastifyRateLimit as any, {
    max: isDev ? 200 : 10,
    timeWindow: '1 second',
    keyGenerator: (req: FastifyRequest) =>
      (req.headers['x-forwarded-for'] as string)?.split(',')[0].trim() ??
      req.ip,
    errorResponseBuilder: (_req: FastifyRequest, context: { max: number; ttl: number }) => ({
      statusCode: 429,
      error: 'Too Many Requests',
      message: `Rate limit exceeded. Max ${context.max} requests/s. Retry after ${context.ttl}ms.`,
    }),
  });

  // ── JWT preHandler (shared across all proxied routes) ─────────────────────
  const jwtPreHandler = async (
    request: FastifyRequest,
    reply: FastifyReply,
  ) => {
    // Strip query string before matching
    const path = request.url.split('?')[0];
    if (PUBLIC_PATHS.has(path)) return;

    const authHeader = request.headers['authorization'];
    if (typeof authHeader !== 'string' || !authHeader.startsWith('Bearer ')) {
      return reply
        .code(401)
        .send({ statusCode: 401, message: 'Unauthorized' });
    }

    try {
      const token = authHeader.slice(7);
      const payload = jwtService.verify<JwtPayload>(token);
      // Attach decoded payload so upstream services can trust x-user-* headers
      (request as any).user = payload;
      request.headers['x-user-id'] = payload.sub;
      request.headers['x-user-email'] = payload.email;
    } catch {
      return reply
        .code(401)
        .send({ statusCode: 401, message: 'Unauthorized' });
    }
  };

  // ── Register one proxy plugin per upstream service ────────────────────────
  for (const { prefix, envKey, defaultUrl } of SERVICES) {
    const upstream = config.get<string>(envKey, defaultUrl);

    await app.register(fastifyHttpProxy as any, {
      upstream,
      prefix,
      rewritePrefix: '',
      preHandler: jwtPreHandler,
      httpMethods: ['DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT'],
      // Propagate upstream error responses as-is
      replyOptions: {
        rewriteRequestHeaders: (
          _req: FastifyRequest,
          headers: Record<string, string>,
        ) => headers,
      },
    });
  }

  const port = config.get<number>('PORT', 3000);
  await app.listen(port, '0.0.0.0');
  console.log(`[gateway] running on port ${port}`);
  console.log(`[gateway] proxying ${SERVICES.length} upstream services`);
}

bootstrap();
