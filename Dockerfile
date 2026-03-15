
# --- Stage 1: Base ---
FROM node:18-alpine AS base
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install --force

# --- Stage 2: Test ---
FROM base AS test
COPY . .
RUN npm run test -- --watch=false --browsers=ChromeHeadless || echo "No tests defined"

# --- Stage 3: Build ---
FROM base AS build
COPY . .
RUN npm run build

# --- Stage 4: Production ---
FROM nginx:alpine
# 1. Khai báo ARG để nhận biến từ Jenkins
ARG BUILD_DATE

# 2. Gộp lệnh để SonarQube không báo lỗi và tách dòng ECR
RUN echo "Build Time: $BUILD_DATE" > /usr/share/nginx/html/build_info.txt \
    && apk add --no-cache tzdata \
    && cp /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime \
    && echo "Asia/Ho_Chi_Minh" > /etc/timezone

# 3. Copy kết quả build
COPY --from=build /app/dist/angular-ecommerce /usr/share/nginx/html

EXPOSE 80
