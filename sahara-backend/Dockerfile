# ============================================
# Sahara Fuel SaaS - Production Dockerfile
# ============================================
FROM node:18-alpine AS base

WORKDIR /app

# تثبيت الاعتمادات
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# نسخ الكود
COPY . .

# إزالة الملفات غير الضرورية
RUN rm -rf .env .env.* .git tests *.md

# إعدادات الأمان
RUN addgroup -g 1001 -S nodejs && \
  adduser -S sahara -u 1001 && \
  chown -R sahara:nodejs /app

USER sahara

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["node", "src/server.js"]
