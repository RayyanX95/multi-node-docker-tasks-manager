# ------------------------------
# Stage 1 – Build the backend
# ------------------------------
FROM node:22-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm install

COPY . .

RUN npm run build

# ------------------------------
# Stage 2 – Run the application
# ------------------------------
FROM node:22-alpine AS runner

WORKDIR /app

COPY --from=builder /app/dist ./

COPY package.json package-lock.json ./

RUN npm install  --omit=dev

CMD ["node", "index.js"]

EXPOSE 4000

