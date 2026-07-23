FROM golang:1.22-alpine AS builder
WORKDIR /build
RUN apk add --no-cache git
RUN git clone --depth 1 https://github.com/corazawaf/coraza-proxy-wasm.git .
RUN go build -o coraza-proxy .

FROM alpine:latest
RUN apk add --no-cache ca-certificates
COPY --from=builder /build/coraza-proxy /usr/local/bin/
ENTRYPOINT ["coraza-proxy"]