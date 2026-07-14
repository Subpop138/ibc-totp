FROM nixos/nix:latest

ARG IBC_VERSION=3.23.0
ARG TWS_BUILD=stable

# Install packages (cached layer — changes here invalidate only this RUN)
#
# Use `zulu21` (Azul Zulu 21) — the same JRE vendor TWS itself bundles
# (see `jreVersion="17.0.16.0.101-zulu"` in install4j's i4jparams.conf).
# Pair with `openjfx21` because TWS's launcher uses `--add-exports` flags
# for `javafx.*` modules that Zulu doesn't ship — a later RUN adds the
# openjfx classpath into IBC.
#
# The base image's `<nixpkgs>` channel points at nixos-unstable.
RUN nix-env -f '<nixpkgs>' -iA \
      zulu21 \
      openjfx21 \
      curl unzip \
      xorg-server xauth xvfb-run x11vnc \
      openbox tint2 \
      chromium \
      bash coreutils findutils gnused gnugrep util-linux

ENV PATH="/root/.nix-profile/bin:${PATH}"

# Create user manually (nixos/nix has immutable /etc/passwd and /etc/group)
RUN mkdir -p /home/tws && \
  echo "tws:x:1000:1000::/home/tws:/bin/sh" >> /etc/passwd && \
  echo "tws:x:1000:" >> /etc/group && \
  chown -R 1000:1000 /home/tws

USER tws
WORKDIR /home/tws

# Install IBKR TWS.
#
# install4j's bundled launcher calls "$app_java_home/bin/java" — that
# points to the bundled JRE which (a) can't run on NixOS (no
# /lib64/ld-linux-x86-64.so.2) and (b) has a strict version check
# (17.0.16.0.101 only). We patch the launcher to invoke the bare
# `java` command instead, which resolves to the zulu21 in
# /root/.nix-profile/bin/java. Same trick the flake.nix devShell uses.
#
# This sidesteps both the "no dynamic linker" failure and the
# strict-version check in one move.
RUN set -eux; \
    BUILD="${TWS_BUILD}"; \
    mkdir -p "ibkr-tws/${BUILD}"; \
    curl -fsSL \
      "https://download2.interactivebrokers.com/installers/tws/latest-standalone/tws-latest-standalone-linux-x64.sh" \
      -o /tmp/tws-installer.sh; \
    sed -i 's|\$INSTALL4J_JAVA_PREFIX "\$app_java_home/bin/java"|java|g' /tmp/tws-installer.sh; \
    printf '%s\n%s\n%s\n' "/home/tws/ibkr-tws/${BUILD}" "y" "n" \
      | bash /tmp/tws-installer.sh -- -c; \
    rm -f /tmp/tws-installer.sh; \
    test -d "ibkr-tws/${BUILD}" || { echo "TWS install failed"; exit 1; }; \
    # Patch the installed TWS launcher too — the installer produces its own \
    # copy at ${BUILD}/tws with the same JVM-strictness bugs. The installed \
    # launcher uses '$INSTALL4J_JAVA_PREFIX exec "$app_java_home/bin/java"' \
    # (note the optional `exec`); both forms get the same `java` swap. \
    for f in "ibkr-tws/${BUILD}/tws" "ibkr-tws/${BUILD}"/.*.sh; do \
      if [ -f "$f" ] && grep -q '"\$app_java_home/bin/java"' "$f"; then \
        sed -i 's|\$INSTALL4J_JAVA_PREFIX\( exec\)\? "\$app_java_home/bin/java"|java|g' "$f"; \
        echo "Patched launcher: $f"; \
      fi; \
    done; \
    ls -la "ibkr-tws/${BUILD}"

# Install IBC (from local build with TOTP support)
USER root
COPY IBC /home/tws/IBC/
RUN find /home/tws/IBC -name "*.sh" -type f -exec chmod +x {} \; && \
  chown -R tws:tws /home/tws/IBC

ENV TZ="Asia/Jerusalem"
ENV DISPLAY=:0
ENV XDG_CONFIG_HOME=/home/tws
ENV FONTCONFIG_FILE=/etc/fonts/fonts.conf

USER root
COPY ibc-config.ini /home/tws/IBC/
COPY ibkr-entrypoint.sh /docker-entrypoint.sh
COPY ibc-start.sh /ibc-start.sh
# /home/tws/java is required by ibcstart.sh when --java-path=/home/tws is set \
# (it does `[[ ! -e "$java_path/java" ]]` and aborts otherwise). The wrapper \
# just exec's the system java. \
COPY --chmod=0755 java-wrapper.sh /home/tws/java
RUN chown -R tws:tws /home/tws

USER tws
ENV PATH="/home/tws:${PATH}"

# Make TWS_BUILD available to scripts that read it at runtime.
ENV TWS_BUILD=${TWS_BUILD}

CMD [ "bash", "/docker-entrypoint.sh" ]
