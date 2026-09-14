#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

PKGVER="$1"
ARCH="x86_64"
STAGE="typeshi-bin-stage"
OUT="typeshi-bin-${PKGVER}-${ARCH}.tar.gz"

rm -rf "$STAGE"
mkdir -p "$STAGE/usr/bin"
mkdir -p "$STAGE/usr/share/applications"
mkdir -p "$STAGE/usr/share/icons/hicolor/scalable/apps"

strip --strip-unneeded build/typeshi
cp build/typeshi "$STAGE/usr/bin/typeshi"
cp typeshi.desktop "$STAGE/usr/share/applications/typeshi.desktop"
cp application/assets/typeShi.svg "$STAGE/usr/share/icons/hicolor/scalable/apps/typeshi.svg"

tar -czf "$OUT" -C "$STAGE" .
sha256sum "$OUT"
rm -rf "$STAGE"

echo "Built: $OUT"
