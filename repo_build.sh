#!/bin/bash
[ -n "$1" ] || { echo "pass version"; exit 1; }
set -x
git clone https://github.com/tailscale/tailscale.git
cd tailscale
git checkout "$1"
git apply ../tailscale.patch
cp ../build.sh .
mkdir -p dist
docker run -it --rm -v "$PWD":/app -w /app alpine sh build.sh
mkdir -p ../dist/"$1"
mv dist/* ../dist/"$1"
rm -rf tailscale
