# ──────────────────────────────────────
# Dockerfile — GoLabs API (multi-stage)
# ──────────────────────────────────────

# ── Stage 1: Build ──
FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /app

# Copiar dependencias primero (cache de Docker layers)
COPY go.mod go.sum ./
RUN go mod download

# Copiar código fuente
COPY . .

# Compilar binario estático
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /golabs-api ./cmd/api

# ── Stage 2: Runtime ──
FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata

# Usuario no-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app
COPY --from=builder /golabs-api .
COPY --from=builder /app/configs/ configs/

# Cambiar a usuario no-root
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=5s --retries=3 \
    CMD wget -qO- http://localhost:8080/healthz/ready || exit 1

ENTRYPOINT ["./golabs-api"]
