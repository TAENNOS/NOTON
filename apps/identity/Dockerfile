FROM node:20-alpine AS builder
WORKDIR /app
RUN npm install -g pnpm
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY packages/ ./packages/
COPY apps/identity/ ./apps/identity/
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @noton/identity run db:generate
RUN pnpm --filter @noton/identity build

FROM node:20-alpine AS runner
WORKDIR /app
RUN npm install -g pnpm
COPY --from=builder /app/package.json /app/pnpm-workspace.yaml ./
COPY --from=builder /app/packages/ ./packages/
COPY --from=builder /app/apps/identity/package.json ./apps/identity/
COPY --from=builder /app/apps/identity/dist/ ./apps/identity/dist/
COPY --from=builder /app/apps/identity/prisma/ ./apps/identity/prisma/
RUN pnpm install --prod --frozen-lockfile
EXPOSE 3001
CMD ["node", "apps/identity/dist/main.js"]
