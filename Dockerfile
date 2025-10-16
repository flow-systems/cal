# Cal.com Production Dockerfile for Coolify
# Multi-stage build for optimal image size and security

# Stage 1: Dependencies
FROM node:20-alpine AS deps
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app

# Enable Corepack for Yarn v3+
RUN corepack enable && corepack prepare yarn@3.4.1 --activate

# Copy package manager files
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn

# Copy all package.json files from workspace
COPY apps/web/package.json ./apps/web/package.json
COPY apps/api/package.json ./apps/api/package.json
COPY apps/api/v1/package.json ./apps/api/v1/package.json
COPY apps/api/v2/package.json ./apps/api/v2/package.json

# Copy workspace packages (only top-level package.json files that exist)
COPY packages/prisma/package.json ./packages/prisma/package.json
COPY packages/app-store/package.json ./packages/app-store/package.json
COPY packages/app-store-cli/package.json ./packages/app-store-cli/package.json
COPY packages/config/package.json ./packages/config/package.json
COPY packages/dayjs/package.json ./packages/dayjs/package.json
COPY packages/emails/package.json ./packages/emails/package.json
COPY packages/eslint-config/package.json ./packages/eslint-config/package.json
COPY packages/eslint-plugin/package.json ./packages/eslint-plugin/package.json
COPY packages/features/package.json ./packages/features/package.json
COPY packages/kysely/package.json ./packages/kysely/package.json
COPY packages/lib/package.json ./packages/lib/package.json
COPY packages/trpc/package.json ./packages/trpc/package.json
COPY packages/tsconfig/package.json ./packages/tsconfig/package.json
COPY packages/types/package.json ./packages/types/package.json
COPY packages/ui/package.json ./packages/ui/package.json
COPY packages/debugging/package.json ./packages/debugging/package.json

# Copy packages with subdirectories
COPY packages/embeds ./packages/embeds
COPY packages/platform ./packages/platform

# Install dependencies
RUN yarn install --immutable

# Stage 2: Builder
FROM node:20-alpine AS builder
RUN apk add --no-cache libc6-compat openssl git
WORKDIR /app

# Enable Corepack
RUN corepack enable && corepack prepare yarn@3.4.1 --activate

# Set build environment variables
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=8192"
ENV NEXT_TELEMETRY_DISABLED=1
ENV SKIP_ENV_CHECK=1

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/.yarn ./.yarn
COPY --from=deps /app/.yarnrc.yml ./.yarnrc.yml

# Copy source code
COPY . .

# Generate Prisma Client
RUN yarn workspace @calcom/prisma prisma generate

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

# Copy workspace packages
COPY --from=builder --chown=nextjs:nodejs /app/packages ./packages
COPY --from=builder --chown=nextjs:nodejs /app/apps/web ./apps/web

# Copy node_modules
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/apps/web/node_modules ./apps/web/node_modules

# Set correct permissions
RUN chown -R nextjs:nodejs /app

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/version', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start the application using dumb-init for proper signal handling
CMD ["dumb-init", "yarn", "workspace", "@calcom/web", "start"]

