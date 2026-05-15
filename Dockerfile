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

FROM steamcmd AS hlds

ENV STEAMCMD=${HOME}/steamcmd
ENV HLDS=${HOME}/hlds
ENV GLIBC_TUNABLES="glibc.rtld.execstack=2"

WORKDIR ${HLDS}

RUN mkdir -p logs && \
    "${STEAMCMD}/steamcmd.sh" \
    +force_install_dir "${HLDS}" \
    +login anonymous \
    +app_set_config 90 mod cstrike \
    +app_update 90 -beta steam_legacy validate \
    +quit && \
    chmod +x "${HLDS}/hlds_run" && \
    rm -rf \
    ${STEAMCMD}/package \
    ${STEAMCMD}/public \
    ${STEAMCMD}/linux32/steamcmd \
    ${HOME}/Steam/logs/* \
    ${HOME}/Steam/appcache/*

# server, rcon, vac respectively
EXPOSE 27015/udp 27015/tcp 26900/udp

CMD ["./hlds_run", "-game", "cstrike", "+ip", "0.0.0.0", "+port", "27015", "-maxplayers", "32", "-sys_ticrate", "1000", "-noipx", "-sport", "26900", "-tos", "-pingboost", "2"]
