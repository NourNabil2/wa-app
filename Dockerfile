# ============================================================
#  Fastway Mobile (Flutter Web) — Production Dockerfile
#  Multi-stage: Flutter build → Nginx static server
# ============================================================

# ── Stage 1: Flutter Web Build ───────────────────────────────
FROM ghcr.io/cirruslabs/flutter:3.41.4 AS flutter-build

WORKDIR /app

# FLUTTER_ALLOW_ROOT suppresses the "running as root" warning in Docker
ENV FLUTTER_ALLOW_ROOT=true

# ── Build arg for API base URL ────────────────────────────────
# Pass via:
#   AWS (default): docker build .
#   Main:          docker build --build-arg BASE_URL=https://fastway.atwdemo.com/api/v1 .
ARG BASE_URL=https://fastway.atwdemo.com/api/v1

# Copy dependency files first to leverage Docker layer caching
COPY pubspec.yaml pubspec.lock ./

# Fetch dependencies AND build in one mounted step so /root/.pub-cache
# is available to both flutter pub get AND flutter build web.
# (BuildKit cache mounts only live for the duration of the RUN that
# declares them — a separate RUN would see an empty /root/.pub-cache.)
RUN --mount=type=cache,target=/root/.pub-cache \
    flutter pub get

# Copy the remaining application source code
COPY . .

# Run analysis + build in the same cache-mounted step so dart2js/dart2wasm
# can resolve package paths written into package_config.json by pub get.
RUN --mount=type=cache,target=/root/.pub-cache \
    flutter analyze --no-fatal-infos --no-fatal-warnings || true && \
    flutter build web \
        -v \
        --release \
        --pwa-strategy=none \
        --dart-define=USE_LOCAL=false \
        --dart-define=BASE_URL=${BASE_URL}



# ── Stage 2: Nginx static server ─────────────────────────────
FROM nginx:1.27-alpine

# Remove default Nginx config
RUN rm /etc/nginx/conf.d/default.conf

# SPA-aware Nginx config
COPY docker/nginx/mobile.conf /etc/nginx/conf.d/default.conf

# Copy built Flutter Web app
COPY --from=flutter-build /app/build/web /usr/share/nginx/html

# Healthcheck
# Use 127.0.0.1 explicitly — Alpine resolves 'localhost' to ::1 (IPv6)
# but nginx only listens on IPv4 unless [::]:80 is also added.
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1/index.html || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
