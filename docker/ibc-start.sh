#!/usr/bin/env bash

mkdir -p "${HOME}/jts"
chmod 755 "${HOME}/jts"
export IBC_INI="${HOME}/IBC/config.ini"
export IBC_PATH="${HOME}/IBC"
export TWS_PATH="${HOME}/ibkr-tws"
export TWS_VERSION="${TWS_BUILD:-stable}"
export TWS_SETTINGS_PATH="${HOME}/jts"
# shellcheck source=tws.secrets
. "${TWS_CREDS_FILE}"

# Write TOTP secret to config if provided in secrets
if [[ -n "${TWS_TOTP_SECRET}" ]]; then
    if grep -q "^TwsTotpSecret=" "${IBC_INI}"; then
        sed -i "s/^TwsTotpSecret=.*/TwsTotpSecret=${TWS_TOTP_SECRET}/" "${IBC_INI}"
    else
        echo "TwsTotpSecret=${TWS_TOTP_SECRET}" >> "${IBC_INI}"
    fi
fi

find "${IBC_PATH}" -iname "*.sh" -exec chmod +x {} +

# wait, X11 might not yet be available.

MAX_RETRIES=10
attempt=0

while [[ "${attempt}" -lt "${MAX_RETRIES}" ]]; do
    attempt=$((attempt + 1))
    echo "IBC start attempt ${attempt}/${MAX_RETRIES}..."
    sleep 15
    if "${IBC_PATH}/scripts/ibcstart.sh" "${TWS_VERSION}" --tws-path="${TWS_PATH}" --tws-settings-path="${TWS_SETTINGS_PATH}" --ibc-path="${IBC_PATH}" --ibc-ini="${IBC_INI}" --mode=live --java-path="/home/tws" --user="${TWS_USERNAME}" --pw="${TWS_PASSWORD}"; then
        attempt=0
    fi
done

echo "*** IBC failed after ${MAX_RETRIES} consecutive attempts, giving up ***" >&2
exit 1
