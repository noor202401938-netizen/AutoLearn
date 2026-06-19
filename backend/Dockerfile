FROM node:20-slim

WORKDIR /app

RUN apt-get update && apt-get install -y openssl

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

# Run migrations, seed, then start the server
CMD ["sh", "-c", "npx prisma db push --accept-data-loss && node -e \"require('ts-node').register({transpileOnly:true}); require('./prisma/seed.ts')\" 2>/dev/null || true && npm start"]
