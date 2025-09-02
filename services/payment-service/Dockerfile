FROM node:24-alpine

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies using pnpm
RUN corepack enable && corepack prepare pnpm@10.15.0 --activate
RUN pnpm install --frozen-lockfile --prod

# Copy source code
COPY . .

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# Start the application
CMD ["pnpm", "start"]