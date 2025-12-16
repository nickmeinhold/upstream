# Build stage
FROM dart:stable AS build

WORKDIR /app

# Copy pubspec files
COPY pubspec.* ./

# Get dependencies
RUN dart pub get

# Copy source code
COPY . .

# Compile to native executable
RUN dart compile exe bin/server.dart -o bin/server

# Runtime stage
FROM debian:bookworm-slim

# Install required runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy compiled binary
COPY --from=build /app/bin/server /app/bin/server

# Copy static web files (built by deploy.sh)
COPY static/ /app/static/

# Environment variables will be set in Cloud Run
ENV PORT=8080
ENV STATIC_PATH=/app/static

EXPOSE 8080

CMD ["/app/bin/server"]
