# ------------------------------
# Stage 1 – Build the frontend
# ------------------------------
FROM node:22-alpine AS builder

# Create working directory
WORKDIR /app

# Install dependencies first (better caching)
COPY package*.json ./
RUN npm ci

# Copy rest of the code
COPY . .

# Build the production bundle
RUN npm run build


# ------------------------------
# Stage 2 – Serve with NGINX
# ------------------------------
FROM nginx:1.25-alpine

# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Run NGINX in the foreground
CMD ["nginx", "-g", "daemon off;"]
