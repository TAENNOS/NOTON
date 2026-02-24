# Worktree: feat/chat-notifications

## Scope
This worktree implements **chat** and **notifications** services only.
Do not modify other services or `packages/shared`.

## Services

### `apps/chat` (port 3004)
- ChannelsModule — `POST /channels`, `GET /channels/:id`, workspace-scoped
- MessagesModule — `POST /channels/:id/messages`, `GET /channels/:id/messages` (paginated)
  - Thread support: `threadId` foreign key on Message
- NATS publish `message.created` → `MessageCreatedPayload`

### `apps/notifications` (port 3008)
- NotificationsModule — `GET /notifications` (auth user's notifications), `PATCH /notifications/:id/read`
- PreferencesModule — `GET/PUT /notifications/preferences`
- Socket.IO gateway — emit `notification` event to specific user room
- NATS subscribe `message.created` → create Notification row → emit via Socket.IO

## Merge
This worktree merges **2nd** into main (after identity-gateway).
Can be merged in parallel with `feat/docs-realtime`.

## Key Types (from @noton/shared)
- `MessageCreatedPayload` — `{ channelId, threadId?, authorId, content, type }`
- `EVENTS.MESSAGE_CREATED` — `'message.created'`
- `MessageType` — `'text' | 'file' | 'system'`

## Dependencies
- identity service must be up for JWT validation
- NATS JetStream must be running

## Checklist
- [ ] `apps/chat/prisma/schema.prisma` — Channel, Message models (with threadId)
- [ ] `apps/chat/src/channels/` — ChannelsModule
- [ ] `apps/chat/src/messages/` — MessagesModule
- [ ] NATS publish `message.created` in MessagesService
- [ ] `apps/notifications/prisma/schema.prisma` — Notification, NotificationPreference models
- [ ] `apps/notifications/src/notifications/` — NotificationsModule
- [ ] `apps/notifications/src/preferences/` — PreferencesModule
- [ ] `apps/notifications/src/gateway/` — Socket.IO gateway
- [ ] NATS subscription for `message.created` in notifications AppModule
- [ ] `prisma migrate dev --name init-chat` (chat service)
- [ ] `prisma migrate dev --name init-notifications` (notifications service)
