# ──────────────────────────────────────────
# Dockerfile — GoLabs UI (Vue 3 + Vuetify)
# ──────────────────────────────────────────

# ── Stage 1: Build ──
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar dependencias primero (cache de Docker layers)
COPY ui/package*.json ./

RUN npm ci --prefer-offline --no-audit

# Copiar código fuente
COPY ui/ .

# Build de producción
RUN npm run build

# ── Stage 2: Serve con Nginx ──
FROM nginx:1.25-alpine

# Eliminar config default de nginx
RUN rm -rf /usr/share/nginx/html/*

# Copiar build de Vue
COPY --from=builder /app/dist /usr/share/nginx/html

# El ConfigMap de K8s monta la config personalizada de nginx
# Pero incluimos una default por si se corre standalone
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
    CMD wget -qO- http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
