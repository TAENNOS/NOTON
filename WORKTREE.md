# Worktree: feat/identity-gateway

## Scope
This worktree implements **identity** and **gateway** services only.
Do not modify other services or `packages/shared`.

## Services

### `apps/identity` (port 3001)
- PrismaModule — connect to identity DB
- UsersModule — User CRUD, `findByEmail`, `findById`
- AuthModule
  - `POST /auth/register` — create user, return `AuthTokensDto`
  - `POST /auth/login` — validate password, return `AuthTokensDto`
  - `POST /auth/refresh` — rotate refresh token
- JwtStrategy (Passport) — validates `Authorization: Bearer <token>`
- JwtAuthGuard — `@UseGuards(JwtAuthGuard)`
- `prisma migrate dev` — commit `prisma/migrations/`

### `apps/gateway` (port 3000)
- JwtAuthGuard — applied globally or per-route
- Reverse proxy routes to all services:
  - `/api/identity/**` → `http://localhost:3001`
  - `/api/docs/**` → `http://localhost:3002`
  - `/api/chat/**` → `http://localhost:3004`
  - `/api/files/**` → `http://localhost:3005`
  - `/api/automation/**` → `http://localhost:3006`
  - `/api/assistant/**` → `http://localhost:3007`
  - `/api/notifications/**` → `http://localhost:3008`
- Rate limiting — `@nestjs/throttler` (10 req/s default)

## Merge
This worktree merges **1st** into main. All other worktrees depend on the JWT contract established here.

## Key Types (from @noton/shared)
- `JwtPayload` — `{ sub, email, iat?, exp? }`
- `AuthTokensDto` — `{ accessToken, refreshToken, expiresIn }`
- `UserDto` — `{ id, email, displayName, avatarUrl?, createdAt }`

## Checklist
- [ ] `apps/identity/prisma/schema.prisma` — User model with password hash
- [ ] `apps/identity/src/auth/` — AuthModule, AuthService, AuthController
- [ ] `apps/identity/src/users/` — UsersModule, UsersService
- [ ] `apps/identity/src/auth/strategies/jwt.strategy.ts`
- [ ] `apps/identity/src/auth/guards/jwt-auth.guard.ts`
- [ ] `prisma migrate dev --name init-users`
- [ ] `apps/gateway/src/` — proxy config, throttler, JWT guard
- [ ] Integration: `curl -X POST http://localhost:3001/auth/register`
