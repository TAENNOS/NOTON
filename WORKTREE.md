# Worktree: feat/docs-realtime

## Scope
This worktree implements **docs** and **realtime** services only.
Do not modify other services or `packages/shared`.

## Services

### `apps/realtime` (port 3003)
- y-websocket server — `documentId` = room name
- Socket.IO presence gateway — track online users per document
- JWT middleware — verify token on WebSocket handshake
- `ws://localhost:3003/yjs` — Yjs collaboration endpoint
- `ws://localhost:3003/presence` — presence endpoint

### `apps/docs` (port 3002)
- WorkspacesModule — `POST /workspaces`, `GET /workspaces/:id`
- DocumentsModule — `POST /documents`, `GET /documents/:id`, `PATCH /documents/:id`
- YjsModule — store serialized Yjs state in Postgres (`yjsState BYTEA`)
- VersionsModule — snapshot Yjs state on save
- NATS publish `doc.updated` → `DocUpdatedPayload`

## Merge
This worktree merges **2nd** into main (after identity-gateway).
Can be merged in parallel with `feat/chat-notifications`.

## Key Types (from @noton/shared)
- `DocUpdatedPayload` — `{ documentId, workspaceId, updatedBy }`
- `EVENTS.DOC_UPDATED` — `'doc.updated'`
- `BlockType` — union of block type strings

## Dependencies
- identity service must be up for JWT validation
- NATS JetStream must be running

## Checklist
- [ ] `apps/realtime/src/yjs/` — y-websocket server setup
- [ ] `apps/realtime/src/presence/` — Socket.IO gateway with JWT middleware
- [ ] `apps/docs/prisma/schema.prisma` — Workspace, Document, Version models
- [ ] `apps/docs/src/workspaces/` — WorkspacesModule
- [ ] `apps/docs/src/documents/` — DocumentsModule
- [ ] `apps/docs/src/yjs/` — YjsModule (BYTEA storage)
- [ ] `apps/docs/src/versions/` — VersionsModule
- [ ] NATS client registered in docs AppModule
- [ ] `prisma migrate dev --name init-docs`
