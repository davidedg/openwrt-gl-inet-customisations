SSH Tunnel
==========

On a host (e.g. a free cloud instance with a static IP):

Install Docker Compose, add a dedicated user:

    apt install -y docker.io docker-compose-v2
    adduser sshdocker
    adduser sshdocker docker
    

As the dedicated user, run a dockerised ssh server on a dedicated port:
Adjust PUID, PGID and PUBLIC_KEY to your env.

    sudo -i -u sshdocker
    # now as the dedicated user:
    docker pull linuxserver/openssh-server
    cat <<EOF > docker-compose.yml
    ---
    services:
      openssh-server:
        image: lscr.io/linuxserver/openssh-server:latest
        container_name: openssh-server
        hostname: openssh-server
        environment:
          - PUID=1000
          - PGID=1000
          - TZ=Etc/UTC
          - SUDO_ACCESS=false
          - PASSWORD_ACCESS=false
          - PUBLIC_KEY=ssh-ed25519 AAAA.... root@GLDEVICE
          - USER_NAME=gldevice
          - LOG_STDOUT=true
        volumes:
          - /home/sshdocker/config:/config
        ports:
          - 2222:2222
          - 1022:1022
        restart: unless-stopped
    EOF

    docker compose up


On the OpenWRT device, prepare sshtunnel:

    opkg install sshtunnel
    cat <<EOF > /etc/config/sshtunnel
    config server cloudserver
        option user gldevice
        option hostname     1.2.3.4
        option port 2222
        option retrydelay 15
    
    config tunnelR ssh
            option server           cloudserver
            option remoteaddress    *
            option remoteport       1022
            option localaddress     127.0.0.1
            option localport        22
    EOF

Start it:

    /etc/init.d/sshtunnel start

On the Cloud server, connect to the tunneled port:

    docker exec -it  openssh-server ssh localhost -p 1022

\
Harden SSH configuration: see [sshtunnel_sshd_config.txt](./sshtunnel_sshd_config.txt)

\
Harden IPTables configuration: see [sshtunnel_iptables.txt](./sshtunnel_iptables.txt)

\
Docs/Credits:
\
[https://openwrt.org/docs/guide-user/services/ssh/sshtunnel](https://openwrt.org/docs/guide-user/services/ssh/sshtunnel)
\
[https://openwrt.org/docs/guide-user/security/dropbear.public-key.auth](https://openwrt.org/docs/guide-user/security/dropbear.public-key.auth)
\
[https://github.com/linuxserver/docker-openssh-server](https://github.com/linuxserver/docker-openssh-server)
\
[https://gist.github.com/ssalonen/9755dfd631a60951a369d563bb20cd71](https://gist.github.com/ssalonen/9755dfd631a60951a369d563bb20cd71)
\
[https://github.com/chr0mag/geoipsets](https://github.com/chr0mag/geoipsets)
