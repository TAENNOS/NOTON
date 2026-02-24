FROM node:20-alpine AS builder
WORKDIR /app
RUN npm install -g pnpm
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY packages/ ./packages/
COPY apps/notifications/ ./apps/notifications/
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @noton/notifications run db:generate
RUN pnpm --filter @noton/notifications build

FROM node:20-alpine AS runner
WORKDIR /app
RUN npm install -g pnpm
COPY --from=builder /app/package.json /app/pnpm-workspace.yaml ./
COPY --from=builder /app/packages/ ./packages/
COPY --from=builder /app/apps/notifications/package.json ./apps/notifications/
COPY --from=builder /app/apps/notifications/dist/ ./apps/notifications/dist/
COPY --from=builder /app/apps/notifications/prisma/ ./apps/notifications/prisma/
RUN pnpm install --prod --frozen-lockfile
EXPOSE 3008
CMD ["node", "apps/notifications/dist/main.js"]
