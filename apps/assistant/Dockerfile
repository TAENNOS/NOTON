FROM node:20-alpine AS builder
WORKDIR /app
RUN npm install -g pnpm
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY packages/ ./packages/
COPY apps/assistant/ ./apps/assistant/
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @noton/assistant run db:generate
RUN pnpm --filter @noton/assistant build

FROM node:20-alpine AS runner
WORKDIR /app
RUN npm install -g pnpm
COPY --from=builder /app/package.json /app/pnpm-workspace.yaml ./
COPY --from=builder /app/packages/ ./packages/
COPY --from=builder /app/apps/assistant/package.json ./apps/assistant/
COPY --from=builder /app/apps/assistant/dist/ ./apps/assistant/dist/
COPY --from=builder /app/apps/assistant/prisma/ ./apps/assistant/prisma/
RUN pnpm install --prod --frozen-lockfile
EXPOSE 3007
CMD ["node", "apps/assistant/dist/main.js"]
