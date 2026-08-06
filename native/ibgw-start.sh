#!/usr/bin/env bash
# Production launcher for the native IB Gateway (master login, all 3 real
# IBKR accounts), run under systemd as ibgw-gateway.service.
#
# Hardened 2026-08-04: credentials are written into config.ini's
# IbLoginId/IbPassword/TwsTotpSecret fields (never passed as --user=/--pw=
# CLI args, which land in plaintext in the java process's own argv --
# visible to any local `ps aux`, confirmed the hard way during initial
# testing). config.ini is chmod 600, same protection as tws.secrets.master.
#
# ibcstart.sh runs its own internal restart loop for graceful cases (cold
# restart, IBC auto-restart file) without this script exiting. This script
# only exits on unrecoverable conditions (e.g. IBC gives up entirely) --
# systemd's Restart=always on ibgw-gateway.service is the outer safety net
# for those cases and for any hard crash.
set -uo pipefail
cd "$HOME/ibc-totp/native"

export DISPLAY=:1
export IBC_INI="$HOME/ibc-totp/native/config.ini"
export IBC_PATH="$HOME/ibc-totp/native/IBC"
export TWS_SETTINGS_PATH="$HOME/Jts"

# shellcheck source=tws.secrets.master
. "$HOME/ibc-totp/native/tws.secrets.master"

set_ini() {
    local key="$1" val="$2"
    if grep -q "^${key}=" "${IBC_INI}"; then
        sed -i "s#^${key}=.*#${key}=${val}#" "${IBC_INI}"
    else
        echo "${key}=${val}" >> "${IBC_INI}"
    fi
}
set_ini "IbLoginId" "${TWS_USERNAME}"
set_ini "IbPassword" "${TWS_PASSWORD}"
if [[ -n "${TWS_TOTP_SECRET:-}" ]]; then
    set_ini "TwsTotpSecret" "${TWS_TOTP_SECRET}"
fi
chmod 600 "${IBC_INI}"

find "${IBC_PATH}" -iname "*.sh" -exec chmod +x {} +

exec "${IBC_PATH}/scripts/ibcstart.sh" stable --gateway \
    --tws-path="$HOME/ibgateway-native" \
    --tws-settings-path="${TWS_SETTINGS_PATH}" \
    --ibc-path="${IBC_PATH}" \
    --ibc-ini="${IBC_INI}" \
    --mode=live \
    --java-path=/usr/lib/jvm/java-25-openjdk-amd64/bin
