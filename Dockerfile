FROM quay.io/deis/lightweight-docker-go:v0.5.0 as builder
ARG BASE_PACKAGE_NAME
ARG LDFLAGS
ENV CGO_ENABLED=0
WORKDIR /go/src/$BASE_PACKAGE_NAME/
COPY cmd/ cmd/
COPY pkg/ pkg/
COPY vendor/ vendor/
RUN go build -o bin/hello-osiris -ldflags "$LDFLAGS" ./cmd/server

FROM scratch
ARG BASE_PACKAGE_NAME
COPY --from=builder /go/src/$BASE_PACKAGE_NAME/bin/ /hello-osiris/bin/
ENTRYPOINT ["/hello-osiris/bin/hello-osiris"]
EXPOSE 8080 8081 8082 4430
