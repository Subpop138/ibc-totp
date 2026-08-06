#!/usr/bin/env bash
# One-shot test launch of IB Gateway via IBC, on the dedicated :1 display.
#
# Hardened 2026-08-04: credentials are written into config.ini's
# IbLoginId/IbPassword fields (same mechanism already used for
# TwsTotpSecret) instead of being passed as --user=/--pw= CLI arguments.
# Those flags are forwarded verbatim into the java process's own argv,
# which any local `ps aux` reveals in plaintext -- confirmed the hard way
# during the first test run. Omitting --user/--pw entirely makes IBC read
# credentials from config.ini instead, which never appears in the process
# table (only file permissions gate it, same as tws.secrets already).
set -uo pipefail
cd "$HOME/ibc-totp/native"

export DISPLAY=:1
export IBC_INI="$HOME/ibc-totp/native/config.ini"
export IBC_PATH="$HOME/ibc-totp/native/IBC"
export TWS_SETTINGS_PATH="$HOME/Jts"

# shellcheck source=tws.secrets
. "$HOME/ibc-totp/native/tws.secrets.master"

# Write credentials + TOTP secret into config.ini -- never passed as argv.
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

"${IBC_PATH}/scripts/ibcstart.sh" stable --gateway \
    --tws-path="$HOME/ibgateway-native" \
    --tws-settings-path="${TWS_SETTINGS_PATH}" \
    --ibc-path="${IBC_PATH}" \
    --ibc-ini="${IBC_INI}" \
    --mode=live \
    --java-path=/usr/lib/jvm/java-25-openjdk-amd64/bin
