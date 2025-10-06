# syntax=docker/dockerfile:1.7
# run : docker compose up -d --build

############################
# Stage 1: Build (Go 1.25.1 + Alpine 3.22)
############################
FROM golang:1.25.1-alpine3.22 AS builder

WORKDIR /src

RUN apk add --no-cache git

# Cache module deps
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download && go mod verify

# Copy source and build tiny static binary
COPY . .
RUN --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 \
    go build -trimpath -ldflags="-s -w" -o /out/fiber-app ./server.go

############################
# Stage 2: Runtime (Alpine 3.22)
############################
FROM alpine:3.22

WORKDIR /app

# Copy binary with final ownership and drop privileges by UID
COPY --from=builder --chown=10001:10001 /out/fiber-app /app/fiber-app
USER 10001:10001

ENTRYPOINT ["/app/fiber-app"]