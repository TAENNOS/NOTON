FROM node:20-alpine AS builder
WORKDIR /app
RUN npm install -g pnpm
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY packages/ ./packages/
COPY apps/automation/ ./apps/automation/
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @noton/automation run db:generate
RUN pnpm --filter @noton/automation build

FROM node:20-alpine AS runner
WORKDIR /app
RUN npm install -g pnpm
COPY --from=builder /app/package.json /app/pnpm-workspace.yaml ./
COPY --from=builder /app/packages/ ./packages/
COPY --from=builder /app/apps/automation/package.json ./apps/automation/
COPY --from=builder /app/apps/automation/dist/ ./apps/automation/dist/
COPY --from=builder /app/apps/automation/prisma/ ./apps/automation/prisma/
RUN pnpm install --prod --frozen-lockfile
EXPOSE 3006
CMD ["node", "apps/automation/dist/main.js"]
