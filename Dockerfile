FROM golang:1.23-alpine AS builder
WORKDIR /src
COPY go.mod ./
COPY go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /kvstore ./cmd/kvstore

FROM alpine:3.20
RUN adduser -D -u 1000 appuser
COPY --from=builder /kvstore /usr/local/bin/kvstore
USER appuser
EXPOSE 8080
ENTRYPOINT ["kvstore"]
