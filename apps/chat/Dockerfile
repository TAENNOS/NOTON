FROM node:20-alpine AS builder
WORKDIR /app
RUN npm install -g pnpm
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY packages/ ./packages/
COPY apps/chat/ ./apps/chat/
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @noton/chat run db:generate
RUN pnpm --filter @noton/chat build

FROM node:20-alpine AS runner
WORKDIR /app
RUN npm install -g pnpm
COPY --from=builder /app/package.json /app/pnpm-workspace.yaml ./
COPY --from=builder /app/packages/ ./packages/
COPY --from=builder /app/apps/chat/package.json ./apps/chat/
COPY --from=builder /app/apps/chat/dist/ ./apps/chat/dist/
COPY --from=builder /app/apps/chat/prisma/ ./apps/chat/prisma/
RUN pnpm install --prod --frozen-lockfile
EXPOSE 3004
CMD ["node", "apps/chat/dist/main.js"]
