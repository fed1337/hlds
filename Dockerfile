FROM cm2network/steamcmd:latest

ENV HLDS_DIR="/home/steam/hlds" \
    STEAMCMD_DIR="/home/steam/steamcmd"

WORKDIR ${HLDS_DIR}

RUN mkdir -p logs && \
    "${STEAMCMD_DIR}/steamcmd.sh" \
    +force_install_dir "${HLDS_DIR}" \
    +login anonymous \
    +app_set_config 90 mod cstrike \
    +app_update 90 -beta steam_legacy validate \
    +quit && \
    chmod +x "${HLDS_DIR}/hlds_run" && \
    rm -rf \
    /home/steam/steamcmd/package \
    /home/steam/steamcmd/public \
    /home/steam/steamcmd/linux32/steamcmd \
    /home/steam/Steam/logs/* \
    /home/steam/Steam/appcache/*

# server, rcon, vac respectively
EXPOSE 27015/udp 27015/tcp 26900/udp

CMD ["./hlds_run", "-game", "cstrike", "+ip", "0.0.0.0", "+port", "27015", "-maxplayers", "32", "-sys_ticrate", "1000", "-noipx", "-sport", "26900", "-tos", "-pingboost", "2"]
