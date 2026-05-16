# Install steamcmd & user steam
FROM debian:trixie-slim AS steamcmd

ARG PID=1000

ENV USER=steam
ENV HOME=/home/${USER}
ENV STEAMCMD=${HOME}/steamcmd

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    lib32gcc-s1 lib32stdc++6 wget ca-certificates && \
    useradd -m -u ${PID} -d ${HOME} -s /bin/bash ${USER} && \
    mkdir -p ${STEAMCMD} && \
    wget -qO- https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xz -C ${STEAMCMD} --strip-components=0 && \
    mkdir -p ${HOME}/.steam/sdk32 ${HOME}/.steam/sdk64 && \
    ln -sf ${STEAMCMD}/linux32/steamclient.so ${HOME}/.steam/sdk32/steamclient.so && \
    ln -sf ${STEAMCMD}/linux64/steamclient.so ${HOME}/.steam/sdk64/steamclient.so && \
    ln -sf ${STEAMCMD}/linux32/steamclient.so /usr/lib/x86_64-linux-gnu/steamclient.so && \
    chown -R steam:steam ${HOME} && \
    apt-get clean && \
    rm -rf \
    /tmp/* \
    /var/lib/apt/lists/*

USER steam


# Downloads hlds build 8684
FROM steamcmd AS hlds

ENV STEAMCMD=${HOME}/steamcmd
ENV HLDS=${HOME}/hlds

RUN mkdir -p ${HLDS}/logs && \
    "${STEAMCMD}/steamcmd.sh" \
    +force_install_dir "${HLDS}" \
    +login anonymous \
    +app_set_config 90 mod cstrike \
    +app_update 90 -beta steam_legacy validate \
    +quit && \
    touch "${HLDS}/{banned.cfg,listip.cfg}" && \
    chmod +x "${HLDS}/hlds_run" && \
    rm -rf \
    ${STEAMCMD}/package \
    ${STEAMCMD}/public \
    ${STEAMCMD}/linux32/steamcmd \
    ${HOME}/Steam/logs/* \
    ${HOME}/Steam/appcache/*


# Add ReHLDS, Metamod-r, ReUnion, AmxModX and specific configs
FROM hlds AS hlds-classic

ENV STEAMCMD=${HOME}/steamcmd
ENV HLDS=${HOME}/hlds
ENV GLIBC_TUNABLES="glibc.rtld.execstack=2"

WORKDIR "${HLDS}"

# Install ReHLDS
COPY --chmod=755 --chown=steam:steam shared/rehlds/*.so .

COPY --chmod=755 --chown=steam:steam shared/rehlds/hl* .

COPY --chmod=755 --chown=steam:steam shared/rehlds/valve/dlls/director.so valve/dlls/

# Install Metamod-r
RUN mkdir -p cstrike/addons/{metamod,reunion,revoice,amxmodx}

COPY --chmod=755 --chown=steam:steam shared/metamod-r/addons/metamod/metamod_i386.so cstrike/addons/metamod/

COPY --chmod=755 --chown=steam:steam shared/metamod-r/addons/metamod/plugins.ini cstrike/addons/metamod/

COPY --chmod=755 --chown=steam:steam servers/classic/liblist.gam cstrike/liblist.gam

# Install ReUnion
COPY --chmod=755 --chown=steam:steam shared/reunion/reunion_mm_i386.so cstrike/addons/reunion/

COPY --chmod=755 --chown=steam:steam shared/reunion/reunion.cfg cstrike/

# Install ReVoice

# server, rcon, vac respectively
EXPOSE 27015/udp 27015/tcp 26900/udp

CMD ["./hlds_run", "-game", "cstrike", "+ip", "0.0.0.0", "+port", "27015", "-maxplayers", "32", "-sys_ticrate", "1000", "-noipx", "-sport", "26900", "-tos", "-pingboost", "2"]
