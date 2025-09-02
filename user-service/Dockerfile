# Use a small base image
FROM node:24-alpine

WORKDIR /app
ENV NODE_ENV=production

# Enable Corepack and pin pnpm version
RUN corepack enable && corepack prepare pnpm@10.15.0 --activate

# Install prod deps only using lockfile
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod --frozen-lockfile

# Copy app source
COPY index.js .

EXPOSE 3000
CMD ["node", "index.js"]