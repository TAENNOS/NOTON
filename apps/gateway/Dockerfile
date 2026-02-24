# ── Build stage ───────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app
RUN npm install -g pnpm
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY packages/ ./packages/
COPY apps/gateway/ ./apps/gateway/
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @noton/gateway build

# ── Production stage ──────────────────────────────────────────────────────────
FROM node:20-alpine AS runner
WORKDIR /app
RUN npm install -g pnpm
COPY --from=builder /app/package.json /app/pnpm-workspace.yaml ./
COPY --from=builder /app/packages/ ./packages/
COPY --from=builder /app/apps/gateway/package.json ./apps/gateway/
COPY --from=builder /app/apps/gateway/dist/ ./apps/gateway/dist/
RUN pnpm install --prod --frozen-lockfile
EXPOSE 3000
CMD ["node", "apps/gateway/dist/main.js"]
