FROM nixos/nix:latest

ARG IBC_VERSION=3.23.0

RUN nix-env -f '<nixpkgs>' -iA \
  openjdk21

# Install packages
RUN nix-env -f '<nixpkgs>' -iA \
  javaPackages.openjfx21 \
  curl unzip \
  xorg.xorgserver xorg.xauth xvfb-run x11vnc \
  openbox tint2 \
  bash coreutils findutils gnused gnugrep util-linux

ENV PATH="/root/.nix-profile/bin:${PATH}"

# Create user manually (nixos/nix has immutable /etc/passwd and /etc/group)
RUN mkdir -p /home/tws && \
  echo "tws:x:1000:1000::/home/tws:/bin/sh" >> /etc/passwd && \
  echo "tws:x:1000:" >> /etc/group && \
  chown -R 1000:1000 /home/tws

USER tws
WORKDIR /home/tws

# Install IBKR TWS - use temporary OpenJDK for installer only
RUN mkdir -p ibkr-tws/1044 && \
    curl -sL "https://download2.interactivebrokers.com/installers/tws/latest-standalone/tws-latest-standalone-linux-x64.sh" -o /tmp/tws-installer.sh && \
    sed -i 's|\$INSTALL4J_JAVA_PREFIX "\\$app_java_home/bin/java"|/nix/store/*jdk*/bin/java|' /tmp/tws-installer.sh && \
    echo -e "/home/tws/ibkr-tws/1044\ny\nn" | bash /tmp/tws-installer.sh -- -c && \
    rm -rf /tmp/tws-installer.sh

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
RUN chmod +x /home/tws/java && chown tws:tws /home/tws/java

USER tws
ENV PATH="/home/tws:${PATH}"

CMD [ "bash", "/docker-entrypoint.sh" ]
