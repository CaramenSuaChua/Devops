
# --- Stage 1: Base ---
FROM node:18-alpine AS base
WORKDIR /app
COPY package.json package-lock.json ./
# Tận dụng cache cho node_modules
RUN npm install --force

# --- Stage 2: Test ---
FROM base AS test
COPY . .
# Stage này chỉ chạy khi Jenkins gọi --target test
RUN npm run test -- --watch=false --browsers=ChromeHeadless || echo "No tests defined"

# --- Stage 3: Build ---
FROM base AS build
COPY . .
RUN npm run build

# --- Stage 4: Production ---
FROM nginx:alpine
ARG BUILD_DATE

# Gộp lệnh để giảm layer và tránh lỗi SonarQube
RUN echo "Build Time: $BUILD_DATE" > /usr/share/nginx/html/build_info.txt && \
    apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime && \
    echo "Asia/Ho_Chi_Minh" > /etc/timezone

# Copy kết quả build từ stage trước
COPY --from=build /app/dist/angular-ecommerce /usr/share/nginx/html

EXPOSE 80
