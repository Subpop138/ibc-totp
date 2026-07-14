#!/usr/bin/env bash
# IBC launches us with absolute path checked as `${java_path}/java`.
# Forward to whatever java is on PATH (the zulu21 we installed).
exec /root/.nix-profile/bin/java "$@"
