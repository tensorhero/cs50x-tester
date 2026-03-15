# Docker Build Context Setup
#
# This Dockerfile builds cs50x-tester using the published tester-utils from GitHub
# Build from the cs50x-tester directory:
#   cd cs50x-tester
#   docker build -t ghcr.io/tensorhero/cs50x-tester .

# Stage 1: Build the Go binary
FROM golang:1.24-bookworm AS builder

WORKDIR /app

# Copy go module files first for better caching
COPY go.mod go.sum ./

# Download dependencies from GitHub
RUN go mod download

# Copy the rest of the project
COPY . .

# Build the binary with CGO enabled (required for SQLite)
RUN CGO_ENABLED=1 GOOS=linux go build \
    -o cs50x-tester \
    -ldflags="-s -w" \
    .

# Stage 2: Runtime image with all dependencies
FROM debian:bookworm-slim

# Install runtime dependencies:
# - clang: C compiler for C problems
# - python3: Python interpreter for Python problems  
# - python3-pip: pip for Python package management
# - python3-venv: virtual environment support
# - sqlite3: SQLite database for SQL problems
# - valgrind: memory leak detection (optional but recommended)
# - ca-certificates: for HTTPS connections
RUN apt-get update && apt-get install -y \
    clang \
    python3 \
    python3-pip \
    python3-venv \
    sqlite3 \
    valgrind \
    ca-certificates \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages globally for all stages
RUN pip3 install --no-cache-dir --break-system-packages \
    flask \
    flask-session \
    cs50 \
    requests

# Create a non-root user for running tests
RUN useradd -m -s /bin/bash tester

# Copy the binary from builder
COPY --from=builder /app/cs50x-tester /usr/local/bin/cs50x-tester

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER tester

# Default command shows help
ENTRYPOINT ["cs50x-tester"]
CMD ["--help"]
