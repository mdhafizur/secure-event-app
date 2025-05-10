# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy all files needed for build first
COPY package*.json tsconfig.json ./
COPY src/ src/

# Install ALL dependencies and build
RUN npm ci && npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

# ✅ Install PM2 globally
RUN npm install -g pm2

# Copy only production dependencies definition
COPY package*.json ./

# Install only production dependencies without running prepare script
RUN npm ci --omit=dev --ignore-scripts

# Copy built files from builder
COPY --from=builder /app/dist ./dist

# Expose the application port
EXPOSE 3000

# # Start the application
# CMD ["node", "dist/server.js"]

# ✅ Start app using PM2 in cluster mode
CMD ["pm2-runtime", "dist/server.js", "-i", "2"]
