# Worktree: feat/files-ai-worker

## Scope
This worktree implements **files**, **automation**, **assistant**, and **worker** services only.
Do not modify other services or `packages/shared`.

## Services

### `apps/files` (port 3005)
- FilesModule — upload presign URL, download presign URL, metadata CRUD
- S3 presign via MinIO (`@aws-sdk/client-s3` + `@aws-sdk/s3-request-presigner`)
- NATS publish `file.uploaded` → `FileUploadedPayload`

### `apps/automation` (port 3006)
- WebhooksModule — inbound webhook receiver → NATS publish
- N8nModule — HTTP proxy to n8n instance (http://localhost:5678)

### `apps/assistant` (port 3007)
- ConversationsModule — conversation CRUD
- OllamaModule — streaming chat via Ollama (`ollama` npm package)
- EmbeddingsModule — pgvector RAG (store + similarity search)

### `apps/worker` (port 3009)
- BullMQ queues: `indexing`, `embeddings`
- IndexingProcessor — triggered by NATS `file.uploaded`
- EmbeddingsProcessor — chunks text, calls Ollama embeddings, stores pgvector

## Merge
This worktree merges **3rd** into main (after docs-realtime + chat-notifications).

## Key Types (from @noton/shared)
- `FileUploadedPayload` — `{ fileId, workspaceId, uploaderId, mimeType, bucketKey }`
- `EmbeddingJobPayload` — `{ resourceId, resourceType, content }`
- `EVENTS.FILE_UPLOADED` — `'file.uploaded'`

## Dependencies
- NATS JetStream must be running
- MinIO must be running (port 9000)
- Redis must be running (BullMQ)
- Ollama must be running (port 11434)

## Checklist
- [ ] `apps/files/prisma/schema.prisma` — File model
- [ ] `apps/files/src/files/` — FilesModule (presign + metadata)
- [ ] `apps/automation/src/webhooks/` — WebhooksModule
- [ ] `apps/automation/src/n8n/` — N8nModule (proxy)
- [ ] `apps/assistant/prisma/schema.prisma` — Conversation, Message, Embedding models
- [ ] `apps/assistant/src/conversations/` — ConversationsModule
- [ ] `apps/assistant/src/ollama/` — OllamaModule
- [ ] `apps/assistant/src/embeddings/` — EmbeddingsModule
- [ ] `apps/worker/src/processors/` — IndexingProcessor, EmbeddingsProcessor
- [ ] `prisma migrate dev` for files + assistant
