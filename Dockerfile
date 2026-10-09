# Build stage
FROM golang:1.24-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -o /out/eevis-server .

# Runtime stage
FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /app
COPY --from=build /out/eevis-server ./eevis-server
COPY eevis ./eevis
COPY visual ./visual
ENV APP_HOST=0.0.0.0 \
    APP_ENV=production \
    USE_TLS=false
EXPOSE 8080
CMD ["./eevis-server"]
