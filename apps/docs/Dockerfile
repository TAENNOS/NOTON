FROM node:20-alpine AS builder
WORKDIR /app
RUN npm install -g pnpm
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY packages/ ./packages/
COPY apps/docs/ ./apps/docs/
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @noton/docs run db:generate
RUN pnpm --filter @noton/docs build

FROM node:20-alpine AS runner
WORKDIR /app
RUN npm install -g pnpm
COPY --from=builder /app/package.json /app/pnpm-workspace.yaml ./
COPY --from=builder /app/packages/ ./packages/
COPY --from=builder /app/apps/docs/package.json ./apps/docs/
COPY --from=builder /app/apps/docs/dist/ ./apps/docs/dist/
COPY --from=builder /app/apps/docs/prisma/ ./apps/docs/prisma/
RUN pnpm install --prod --frozen-lockfile
EXPOSE 3002
CMD ["node", "apps/docs/dist/main.js"]
