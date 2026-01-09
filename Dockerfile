# Cal.com Production Dockerfile for Coolify/Dokploy
# Multi-stage build for optimal image size and security

# Stage 1: Dependencies
FROM node:20-alpine AS deps
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app

# Enable Corepack for Yarn v3+
RUN corepack enable && corepack prepare yarn@3.4.1 --activate

# Copy entire source (needed for Yarn workspaces to resolve correctly)
COPY . .

# Install all dependencies (including devDependencies needed for build)
RUN yarn install --frozen-lockfile

# Stage 2: Builder
FROM node:20-alpine AS builder
RUN apk add --no-cache libc6-compat openssl git
WORKDIR /app

# Enable Corepack
RUN corepack enable && corepack prepare yarn@3.4.1 --activate

# Accept build arguments from Coolify/Dokploy
# NOTE: Dokploy must pass these as build arguments (--build-arg)
# If variables are set in Dokploy but not passed as build args, the build will fail
ARG NEXTAUTH_SECRET
ARG CALENDSO_ENCRYPTION_KEY
ARG DATABASE_URL
ARG NEXT_PUBLIC_WEBAPP_URL

# Optional arguments
ARG NEXT_PUBLIC_WEBSITE_URL
ARG EMAIL_FROM
ARG EMAIL_SERVER_HOST
ARG EMAIL_SERVER_PORT
ARG EMAIL_SERVER_USER
ARG EMAIL_SERVER_PASSWORD

# Set build environment variables
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=8192"
ENV NEXT_TELEMETRY_DISABLED=1
ENV TURBO_TELEMETRY_DISABLED=1
ENV SKIP_ENV_CHECK=1

# Set required environment variables for build from ARG values
ENV NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
ENV CALENDSO_ENCRYPTION_KEY=${CALENDSO_ENCRYPTION_KEY}
ENV DATABASE_URL=${DATABASE_URL}
ENV NEXT_PUBLIC_WEBAPP_URL=${NEXT_PUBLIC_WEBAPP_URL}
ENV NEXT_PUBLIC_WEBSITE_URL=${NEXT_PUBLIC_WEBSITE_URL}

# Validate required environment variables before build
# This will fail early with clear error messages
RUN echo "Validating required build arguments..." && \
    if [ -z "${NEXTAUTH_SECRET}" ] || [ "${NEXTAUTH_SECRET}" = "" ]; then \
      echo "" >&2; \
      echo "❌ ERROR: NEXTAUTH_SECRET is required but not set" >&2; \
      echo "" >&2; \
      echo "In Dokploy, you need to configure these as BUILD ARGUMENTS, not just environment variables." >&2; \
      echo "Check your Dokploy project settings for 'Build Arguments' or 'Docker Build Args' section." >&2; \
      echo "" >&2; \
      echo "Required build arguments:" >&2; \
      echo "  - NEXTAUTH_SECRET" >&2; \
      echo "  - CALENDSO_ENCRYPTION_KEY" >&2; \
      echo "  - DATABASE_URL" >&2; \
      echo "  - NEXT_PUBLIC_WEBAPP_URL" >&2; \
      echo "" >&2; \
      exit 1; \
    fi && \
    if [ -z "${CALENDSO_ENCRYPTION_KEY}" ] || [ "${CALENDSO_ENCRYPTION_KEY}" = "" ]; then \
      echo "❌ ERROR: CALENDSO_ENCRYPTION_KEY is required but not set" >&2; \
      echo "Configure it as a BUILD ARGUMENT in Dokploy settings" >&2; \
      exit 1; \
    fi && \
    if [ -z "${DATABASE_URL}" ] || [ "${DATABASE_URL}" = "" ]; then \
      echo "❌ ERROR: DATABASE_URL is required but not set" >&2; \
      echo "Configure it as a BUILD ARGUMENT in Dokploy settings" >&2; \
      exit 1; \
    fi && \
    if [ -z "${NEXT_PUBLIC_WEBAPP_URL}" ] || [ "${NEXT_PUBLIC_WEBAPP_URL}" = "" ]; then \
      echo "❌ ERROR: NEXT_PUBLIC_WEBAPP_URL is required but not set" >&2; \
      echo "Configure it as a BUILD ARGUMENT in Dokploy settings" >&2; \
      exit 1; \
    fi && \
    echo "✓ All required build arguments are set"

# Copy everything from deps stage (includes node_modules in all workspace packages)
COPY --from=deps /app ./

# Generate Prisma Client
RUN yarn workspace @calcom/prisma prisma generate

# Remove test files that may cause TypeScript compilation issues
RUN find . -path "*/node_modules" -prune -o -type d \( -name "test" -o -name "tests" -o -name "__tests__" -o -name "playwright" -o -name "fixtures" \) -print -exec rm -rf {} + 2>/dev/null || true
RUN find . -path "*/node_modules" -prune -o -type f \( -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" -o -name "*.spec.tsx" -o -name "*.e2e.ts" \) -print -delete 2>/dev/null || true
RUN rm -rf ./apps/web/test ./apps/web/playwright ./tests ./playwright.config.ts ./vitest.config.ts ./vitest.workspace.ts ./setupVitest.ts 2>/dev/null || true

# Build the application
RUN yarn turbo run build --filter=@calcom/web...

# Stage 3: Runner - Production image
FROM node:20-alpine AS runner
RUN apk add --no-cache libc6-compat openssl dumb-init
WORKDIR /app

# Enable Corepack
RUN corepack enable && corepack prepare yarn@3.4.1 --activate

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy necessary files from builder
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/yarn.lock ./yarn.lock
COPY --from=builder /app/.yarnrc.yml ./.yarnrc.yml
COPY --from=builder /app/.yarn ./.yarn
COPY --from=builder /app/turbo.json ./turbo.json
# Copy i18n files required by packages/config/next-i18next.config.js
COPY --from=builder /app/i18n.json ./i18n.json
COPY --from=builder /app/i18n.lock ./i18n.lock

# Copy workspace packages
COPY --from=builder --chown=nextjs:nodejs /app/packages ./packages
COPY --from=builder --chown=nextjs:nodejs /app/apps/web ./apps/web

# Copy scripts needed for startup (migrations, etc.)
COPY --from=builder --chown=nextjs:nodejs /app/scripts ./scripts

# Copy node_modules
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/apps/web/node_modules ./apps/web/node_modules

# Copy Prisma schema for migrations
COPY --from=builder /app/packages/prisma/schema.prisma ./packages/prisma/schema.prisma
COPY --from=builder /app/packages/prisma/migrations ./packages/prisma/migrations

# Set correct permissions and make scripts executable
RUN chown -R nextjs:nodejs /app && \
    chmod +x /app/scripts/*.sh 2>/dev/null || true

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/version', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Run migrations, seed app store, then start the application
# Note: prisma migrate deploy only applies pending migrations (safe to run multiple times)
CMD ["dumb-init", "sh", "-c", "cd /app && if [ -n \"$DATABASE_URL\" ]; then echo 'Running database migrations...' && yarn workspace @calcom/prisma db-deploy 2>&1 && echo 'Migrations completed.' || (echo 'Migration error, but continuing...' && true); echo 'Seeding app store...' && (yarn workspace @calcom/prisma seed-app-store 2>&1 || echo 'Seed skipped (non-fatal)'); else echo 'WARNING: DATABASE_URL not set, skipping migrations'; fi && echo 'Starting application...' && yarn workspace @calcom/web start"]
