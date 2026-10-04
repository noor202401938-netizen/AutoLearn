FROM node:20-slim

WORKDIR /app

RUN apt-get update && apt-get install -y openssl ca-certificates

# Install dependencies first (layer caching)
COPY package*.json ./
COPY prisma ./prisma/

RUN npm install

# Generate Prisma client
RUN npx prisma generate

# Copy source code and build
COPY . .
RUN npm run build

EXPOSE 3001

# Sync indexes and seed starter content (both idempotent), then start.
# No --accept-data-loss: a destructive schema change must be done by hand.
CMD ["sh", "-c", "npx prisma db push --skip-generate; npx ts-node --transpile-only prisma/seed.ts; npm start"]
