#!/usr/bin/env bash

# AVOID INVOKING THIS SCRIPT DIRECTLY -- USE `make build-client`

set -euxo pipefail

function build {
  goos=$1
  goarch=$2
  GOOS=${goos} GOARCH=${goarch} go build -o bin/hello-osiris-client-${goos}-${goarch} ./cmd/client
}

build linux amd64
build darwin amd64
build windows amd64
