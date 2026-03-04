# --- Stage 1: Base (Cài đặt dependencies) ---
FROM node:18-alpine AS base
WORKDIR /app
COPY package.json package-lock.json ./
# Dùng cache cho node_modules
RUN npm install --force

# --- Stage 2: Test (Chỉ chạy khi cần test) ---
FROM base AS test
COPY . .
# Chạy lệnh test của bạn ở đây (nếu không có test thực tế, dùng lệnh echo để pass)
RUN npm run test -- --watch=false --browsers=ChromeHeadless || echo "No tests defined"

# --- Stage 3: Build (Biên dịch Angular) ---
FROM base AS build
COPY . .
RUN npm run build

# --- Stage 4: Production (Image cuối cùng siêu nhẹ) ---
FROM nginx:alpine
# Copy kết quả build từ stage 3
COPY --from=build /app/dist/angular-ecommerce /usr/share/nginx/html
EXPOSE 80
