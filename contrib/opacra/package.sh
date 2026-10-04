#!/usr/bin/env bash
# Packages the built explorer (build/xmrblocks + templates) with the deploy files.
#   contrib/opacra/package.sh [version]     -> dist/opacra-explorer-<version>-linux-x64.tar.gz
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VER="${1:-v0.1.0}"
NAME="opacra-explorer-$VER-linux-x64"
OUT="$ROOT/dist/$NAME"
rm -rf "$OUT"; mkdir -p "$OUT"
cp "$ROOT/build/xmrblocks" "$OUT/"
strip "$OUT/xmrblocks"
cp -r "$ROOT/src/templates" "$OUT/templates"
cp "$ROOT/contrib/opacra/explorer-setup.sh" "$ROOT/contrib/opacra/opacra-explorer.service" \
   "$ROOT/contrib/opacra/nginx-explorer.conf" "$ROOT/LICENSE" "$ROOT/OPACRA.md" "$OUT/"
tar -C "$ROOT/dist" -czf "$ROOT/dist/$NAME.tar.gz" "$NAME"
(cd "$ROOT/dist" && sha256sum "$NAME.tar.gz" > "$NAME.tar.gz.sha256")
cat "$ROOT/dist/$NAME.tar.gz.sha256"
