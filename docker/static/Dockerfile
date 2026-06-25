# ──────────────────────────────────────────────
# Dockerfile — GoLabs Static Site (HTML estático)
# ──────────────────────────────────────────────

FROM nginx:1.25-alpine

# Eliminar contenido default de nginx
RUN rm -rf /usr/share/nginx/html/*

# Copiar archivos HTML estáticos
COPY . /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
    CMD wget -qO- http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
