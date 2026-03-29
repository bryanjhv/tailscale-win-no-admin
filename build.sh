#!/bin/bash
set -x
apk add --no-cache bash curl git
git config --global --add safe.directory '*'
TS_USE_TOOLCHAIN=1 GOOS=windows GOARCH=amd64 ./build_dist.sh -o dist/tailscale.exe -v ./cmd/tailscale
TS_USE_TOOLCHAIN=1 GOOS=windows GOARCH=amd64 ./build_dist.sh -o dist/tailscaled.exe -v ./cmd/tailscaled
