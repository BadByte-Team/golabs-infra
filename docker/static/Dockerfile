# ── Stage 1: Generate challenge assets ──
FROM python:3.12-slim AS builder

RUN pip install --no-cache-dir Pillow piexif

WORKDIR /build
COPY scripts/generate_assets.py /build/
COPY public/assets/team_lead_original.png /input/team_lead_original.png

RUN python /build/generate_assets.py

# ── Stage 2: Serve with Nginx ──
FROM nginx:alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static site
COPY public/ /usr/share/nginx/html/

# Copy generated assets (overwrite/add)
COPY --from=builder /output/team_lead.jpg /usr/share/nginx/html/assets/team_lead.jpg
COPY --from=builder /output/sample_capture.pcap /usr/share/nginx/html/assets/sample_capture.pcap
COPY --from=builder /output/incident_logs.zip /usr/share/nginx/html/assets/incident_logs.zip

# Remove source image (shouldn't be served)
RUN rm -f /usr/share/nginx/html/assets/team_lead_original.png

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
