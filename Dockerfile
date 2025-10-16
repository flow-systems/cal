# Cal.com Production Dockerfile for Coolify
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

# Accept build arguments from Coolify
ARG NEXTAUTH_SECRET
ARG CALENDSO_ENCRYPTION_KEY
ARG DATABASE_URL
ARG NEXT_PUBLIC_WEBAPP_URL
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

# Set required environment variables for build
ENV NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
ENV CALENDSO_ENCRYPTION_KEY=${CALENDSO_ENCRYPTION_KEY}
ENV DATABASE_URL=${DATABASE_URL}
ENV NEXT_PUBLIC_WEBAPP_URL=${NEXT_PUBLIC_WEBAPP_URL}
ENV NEXT_PUBLIC_WEBSITE_URL=${NEXT_PUBLIC_WEBSITE_URL}

# Copy everything from deps stage (includes node_modules in all workspace packages)
COPY --from=deps /app ./

# Generate Prisma Client
RUN yarn workspace @calcom/prisma prisma generate

# Remove test files that may cause TypeScript compilation issues
RUN find . -type d -name "test" -o -name "tests" -o -name "__tests__" | grep -v node_modules | xargs rm -rf || true
RUN find . -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" -o -name "*.spec.tsx" | grep -v node_modules | xargs rm -f || true

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

