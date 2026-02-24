FROM node:20-alpine AS builder
WORKDIR /app
RUN npm install -g pnpm
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY packages/ ./packages/
COPY apps/files/ ./apps/files/
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @noton/files run db:generate
RUN pnpm --filter @noton/files build

FROM node:20-alpine AS runner
WORKDIR /app
RUN npm install -g pnpm
COPY --from=builder /app/package.json /app/pnpm-workspace.yaml ./
COPY --from=builder /app/packages/ ./packages/
COPY --from=builder /app/apps/files/package.json ./apps/files/
COPY --from=builder /app/apps/files/dist/ ./apps/files/dist/
COPY --from=builder /app/apps/files/prisma/ ./apps/files/prisma/
RUN pnpm install --prod --frozen-lockfile
EXPOSE 3005
CMD ["node", "apps/files/dist/main.js"]
