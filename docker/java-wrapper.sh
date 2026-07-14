#!/usr/bin/env bash
# Point directly to GraalVM
GRAALVM_BIN=$(find /nix/store -name "graalvm-ce-21*" -type d -print -quit 2>/dev/null)/bin/java

if [ -x "$GRAALVM_BIN" ]; then
  exec "$GRAALVM_BIN" "$@"
else
  echo "GraalVM not found!" >&2
  exit 1
fi
