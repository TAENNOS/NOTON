FROM node:20-alpine AS builder
WORKDIR /app
RUN npm install -g pnpm
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY packages/ ./packages/
COPY apps/realtime/ ./apps/realtime/
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @noton/realtime build

FROM node:20-alpine AS runner
WORKDIR /app
RUN npm install -g pnpm
COPY --from=builder /app/package.json /app/pnpm-workspace.yaml ./
COPY --from=builder /app/packages/ ./packages/
COPY --from=builder /app/apps/realtime/package.json ./apps/realtime/
COPY --from=builder /app/apps/realtime/dist/ ./apps/realtime/dist/
RUN pnpm install --prod --frozen-lockfile
EXPOSE 3003
CMD ["node", "apps/realtime/dist/main.js"]
