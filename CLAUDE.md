# NOTON — Claude Code Guide

> Notion + Slack + n8n — self-hosted, privacy-first workspace platform

## Stack Quick Reference

| Layer | Technology |
|---|---|
| Monorepo | pnpm workspaces + Turborepo |
| Backend | NestJS microservices (Fastify adapter) |
| Transport | NATS JetStream (`@nestjs/microservices`) |
| Database | PostgreSQL 16 + Prisma ORM |
| Cache/Queue | Redis 7 + BullMQ |
| Real-time | y-websocket + Socket.IO |
| Storage | MinIO (S3-compatible) |
| AI | Ollama (local LLM) + pgvector (RAG) |
| Automation | n8n (self-hosted) |
| Mobile/Web | Flutter |
| Infra | Docker Compose (dev) |

## Service Port Map

| Service | Port | Package name |
|---|---|---|
| `gateway` | 3000 | `@noton/gateway` |
| `identity` | 3001 | `@noton/identity` |
| `docs` | 3002 | `@noton/docs` |
| `realtime` | 3003 | `@noton/realtime` |
| `chat` | 3004 | `@noton/chat` |
| `files` | 3005 | `@noton/files` |
| `automation` | 3006 | `@noton/automation` |
| `assistant` | 3007 | `@noton/assistant` |
| `notifications` | 3008 | `@noton/notifications` |
| `worker` | 3009 | `@noton/worker` |

## NestJS Module Pattern

Every feature module follows this structure:
```
src/
  <feature>/
    <feature>.module.ts
    <feature>.controller.ts   # REST endpoints
    <feature>.service.ts      # Business logic
    dto/
      create-<feature>.dto.ts
      update-<feature>.dto.ts
    entities/
      <feature>.entity.ts     # Prisma model wrapper (optional)
```

## NATS Pattern

```typescript
// Publishing (in service)
import { Inject } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { EVENTS } from '@noton/shared';

constructor(@Inject('NATS_SERVICE') private nats: ClientProxy) {}

this.nats.emit(EVENTS.MESSAGE_CREATED, payload); // fire-and-forget
this.nats.send(EVENTS.MESSAGE_CREATED, payload); // request-reply (returns Observable)

// Subscribing (in microservice controller)
@MessagePattern(EVENTS.MESSAGE_CREATED)
async handleMessageCreated(@Payload() data: MessageCreatedPayload) { ... }

@EventPattern(EVENTS.FILE_UPLOADED)
async handleFileUploaded(@Payload() data: FileUploadedPayload) { ... }
```

### NATS Module Registration
```typescript
ClientsModule.register([{
  name: 'NATS_SERVICE',
  transport: Transport.NATS,
  options: { servers: [process.env.NATS_URL] },
}])
```

## JWT Auth Pattern

```typescript
// Guard (gateway or individual service)
@UseGuards(JwtAuthGuard)
@Get('protected')
getProtected(@Request() req) {
  return req.user; // JwtPayload from @noton/shared
}

// JWT Strategy
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: process.env.JWT_SECRET,
    });
  }
  async validate(payload: JwtPayload) { return payload; }
}
```

## Prisma Workflow

```bash
# 1. Edit schema at apps/<service>/prisma/schema.prisma
# 2. Create migration (run from service directory)
pnpm --filter @noton/<service> exec prisma migrate dev --name <migration-name>

# 3. Generate client
pnpm --filter @noton/<service> exec prisma generate

# 4. IMPORTANT: commit prisma/migrations/ — it is NOT gitignored
```

## Running Services

```bash
# All services
pnpm dev

# Single service
pnpm dev --filter @noton/identity

# Build
pnpm build --filter @noton/gateway

# Infrastructure (Postgres, Redis, NATS, MinIO, Ollama)
docker compose -f infra/docker/docker-compose.dev.yml up -d
```

## Worktree Scope

This repo uses **5 git worktrees** for parallel development.
Each worktree has a `WORKTREE.md` describing its scope.

**Do not modify services outside your worktree's scope.**
**`packages/shared` edits require coordination** — all needed types were pre-added in Phase 0.

See `WORKTREE.md` in the active worktree for the specific services and tasks assigned.

### Merge Order
1. `feat/identity-gateway` → main (foundation)
2. `feat/docs-realtime` + `feat/chat-notifications` → main (parallel)
3. `feat/files-ai-worker` → main
4. `feat/flutter-apps` → main (after gateway API is stable)
