PODMAN version
==========

On a host (e.g. a free cloud instance with a static IP):

Install Podman, add a dedicated user:

    sudo apt install -y podman
    sudo adduser --disabled-password sshpodman
    sudo loginctl enable-linger sshpodman
    sudo apt install systemd-container


Prepare an SSH key:

    ssh-keygen -t ed25519 -f /tmp/sshtunnel_id_ed25519 -N ""

Copy the public part on the podman unit file and transfer the private file to the device, to `/etc/config/sshtunnel_id_ed25519`

\
Prepare Podman on the dedicated user:

    sudo machinectl shell sshpodman@

    # now as the dedicated user:
    mkdir -p ~/.config/containers/systemd
    echo 'unqualified-search-registries = ["docker.io"]' >> ~/.config/containers/registries.conf

\
Run a containerised ssh server on a dedicated port - adjust PUBLIC_KEY to your env.

    sudo machinectl shell sshpodman@
    
    # now as the dedicated user:
    mkdir ~/data
    podman pull lscr.io/linuxserver/openssh-server
    
    cat <<EOF > ~/.config/containers/systemd/sshpodman.container
    # sshdocker.container
    [Container]
    ContainerName=sshpodman
    Environment=TZ=Etc/UTC SUDO_ACCESS=false PASSWORD_ACCESS=false "PUBLIC_KEY=ssh-ed25519 AAA... root@GLDEVICE" USER_NAME=gldevice LOG_STDOUT=false
    HostName=sshpodman
    Image=lscr.io/linuxserver/openssh-server:latest
    AutoUpdate=registry
    PodmanArgs=--ipc private
    PublishPort=2222:2222
    PublishPort=2022:2022
    Volume=%h/data:/config
    
    [Service]
    Restart=always
    TimeoutStartSec=10
    
    [Install]
    WantedBy=default.target
    EOF


On the OpenWRT device, prepare sshtunnel:

    opkg install sshtunnel
    cat <<EOF > /etc/config/sshtunnel
    config server cloudserver
        option user gldevice
        option hostname     1.2.3.4
        option port 2222
        option IdentityFile /etc/config/sshtunnel_id_ed25519
        option retrydelay 15
    
    config tunnelR ssh
            option server           cloudserver
            option remoteaddress    *
            option remoteport       2022
            option localaddress     127.0.0.1
            option localport        22
    EOF

Start it:

    /etc/init.d/sshtunnel start

On the Cloud server, connect to the tunneled port:

    sudo -i -u sshpodman /bin/bash -c "podman exec -it sshpodman ssh localhost -p 2022"

\
Security:
-------------

\
Harden SSH configuration: see [sshtunnel_sshd_config.txt](./sshtunnel_sshd_config.txt)

Harden SSH logging: Monitor /home/sshdocker/config/logs/openssh/current with Fail2Ban or [SSHGuard](./sshtunnel_sshguard.txt)

Harden IPTables configuration: see [sshtunnel_iptables.txt](./sshtunnel_iptables.txt)

Remember to keep your docker image updates: see [podman_update.txt](./podman_update.txt)

\
Reinstallation/FW Updates:
-------------

\
Upon firmware updates, the package might be lost. You might want to set up a cron job to [reinstall](../reinit-after-upgrade/reinit-after-upgrade.sh) it at the subsequent boot:

        * * * * * [ -f /root/reinit_complete ] || /etc/config/reinit-after-upgrade.bash


\
Docs/Credits:
-------------
[https://giacomo.coletto.io/blog/podman-quadlets/](https://giacomo.coletto.io/blog/podman-quadlets/)
\
[https://mag37.org/posts/guide_podman_quadlets/](https://mag37.org/posts/guide_podman_quadlets/)
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
\
[https://www.sshguard.net/](https://www.sshguard.net/)
\
[https://containrrr.dev/watchtower/](https://containrrr.dev/watchtower/)
