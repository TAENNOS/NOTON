# NOTON

> Notion + Slack + n8n — self-hosted, privacy-first workspace platform

## Stack

| Layer | Technology |
|---|---|
| Monorepo | pnpm workspaces + Turborepo |
| Backend | NestJS microservices (Fastify) |
| Transport | NATS JetStream |
| Database | PostgreSQL 16 + Prisma |
| Cache/Queue | Redis 7 + BullMQ |
| Real-time | y-websocket + Socket.IO |
| Storage | MinIO (S3-compatible) |
| AI | Ollama (local LLM) + pgvector (RAG) |
| Automation | n8n (self-hosted) |
| Mobile/Web | Flutter |
| Infra | Docker Compose (dev) |

## Services

| Service | Port | Description |
|---|---|---|
| `gateway` | 3000 | API Gateway — auth proxy, routing |
| `identity` | 3001 | Auth, Users — JWT, OAuth |
| `docs` | 3002 | Documents — Yjs blocks, versions |
| `realtime` | 3003 | y-websocket, Socket.IO, presence |
| `chat` | 3004 | Channels, threads, messages |
| `files` | 3005 | S3/MinIO presign, metadata |
| `automation` | 3006 | n8n proxy, webhooks, triggers |
| `assistant` | 3007 | Ollama RAG, AI completions |
| `notifications` | 3008 | In-app & websocket notifications |
| `worker` | 3009 | Indexing, embeddings (BullMQ) |

## Quick Start

```bash
# 1. Install dependencies
pnpm install

# 2. Start infrastructure
docker compose -f infra/docker/docker-compose.dev.yml up -d

# 3. Copy and edit env files
cp .env.example .env
# Edit each apps/<service>/.env

# 4. Run all services in dev mode
pnpm dev
```

## Project Structure

```
NOTON/
├── apps/           # NestJS services + Flutter apps
├── packages/       # Shared code and configs
│   ├── shared/     # Shared TypeScript types, DTOs, constants
│   └── tsconfig/   # Shared TypeScript configurations
└── infra/
    └── docker/     # Docker Compose for local development
```
