#!/usr/bin/env bash
# scripts/switch_account.sh paper|live
#
# Switches which IBKR account ibc-totp logs into, without destroying either
# credential set. docker/tws.secrets.paper and docker/tws.secrets.live are
# the two permanent sources (create with the same interactive-prompt
# pattern used originally -- read/read -s into $u/$p/$t, never paste
# secrets into chat); docker/tws.secrets (what the container actually
# reads) is always a copy of whichever was last selected.
#
# Also flips ibc-start.sh's --mode flag to match -- using paper credentials
# with --mode=live (or vice versa) is exactly the kind of mismatch that put
# the very first successful auto-TOTP login on the live account by accident
# (2026-08-01). Keeping credentials and mode switched together in one step
# is the whole point of this script.
set -euo pipefail
cd "$(dirname "$0")/.."

mode="${1:-}"
case "$mode" in
  paper) src="docker/tws.secrets.paper" ;;
  live)  src="docker/tws.secrets.live"  ;;
  *)
    echo "usage: $0 paper|live" >&2
    exit 1
    ;;
esac

if [ ! -f "$src" ]; then
    echo "missing $src -- nothing to switch to" >&2
    exit 1
fi

cp "$src" docker/tws.secrets
chmod 600 docker/tws.secrets
sed -i "s/--mode=\(live\|paper\)/--mode=$mode/" docker/ibc-start.sh

echo "Switched to $mode: docker/tws.secrets <- $src, ibc-start.sh --mode=$mode"
echo "Apply it with:  docker compose down -v && docker compose up -d --build"
if [ "$mode" = "live" ]; then
    echo "NOTE: this account has real trading capability -- confirm intent before restarting."
fi
