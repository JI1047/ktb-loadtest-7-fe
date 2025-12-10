# ===============================
# Stage 1: Builder
# ===============================
FROM node:20-alpine AS builder
WORKDIR /app

# 빌드 타임 환경변수
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}

# package 파일만 먼저 복사 (캐시 최적화)
COPY package.json package-lock.json ./

# ✅ npm ci (더 빠르고 정확)
RUN npm ci

# 소스 복사
COPY . .

# Next.js 빌드
RUN npm run build


# ===============================
# Stage 2: Runner (최소 런타임)
# ===============================
FROM node:20-alpine AS runner
WORKDIR /app

# non-root 유저
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# ✅ standalone 결과물만 복사
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# 권한 정리
RUN chown -R nextjs:nodejs /app

USER nextjs

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000
CMD ["node", "server.js"]
