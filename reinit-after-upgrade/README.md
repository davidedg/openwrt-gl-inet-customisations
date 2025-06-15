Reinstallation/FW Updates:
-------------

Upon firmware updates, configuration might be lost.
\
You might want to set up a cron job to [reinstall](../reinit-after-upgrade/reinit-after-upgrade.sh) it at the subsequent boot:

    * * * * * [ -f /root/reinit_complete ] || /etc/config/reinit-after-upgrade.bash
