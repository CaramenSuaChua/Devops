






# --- Stage 1: Base ---
FROM node:18-alpine AS base
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --force

# FROM base AS test
# COPY . .
# # Stage này dùng để chạy test trong Jenkins
# RUN npm run test -- --watch=false --browsers=ChromeHeadless

# --- Stage 3: Build ---
FROM base AS build
COPY --from=base /app/node_modules ./node_modules
COPY . .
RUN npm run build -- --configuration production

# --- Stage 4: Production ---
FROM nginx:alpine AS production
ARG BUILD_DATE

# Nginx cần quyền ghi vào các thư mục cache và pid
RUN echo "Build Time: $BUILD_DATE" > /usr/share/nginx/html/build_info.txt && \
    apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime && \
    echo "Asia/Ho_Chi_Minh" > /etc/timezone && \
    # Cấu hình để Nginx chạy được với user thường
    chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

COPY --from=build /app/dist/angular-ecommerce /usr/share/nginx/html

# 3. Chuyển sang user nginx (user này có sẵn trong image nginx:alpine)
USER nginx

EXPOSE 80

ENTRYPOINT ["nginx", "-g", "daemon off;"]
