# SMS Actions

Enable SMS Forwarding in the GUI. This will configure `/tmp/smstools.cfg` with `eventhandler = /etc/forward`

Copy the original script:

    cp /etc/forward /etc/forward-original

Create directories /etc/sms-actions/...

    mkdir -p /etc/sms-actions/init

Then overwrite it with this custom script:

    tee /etc/forward <<EOF
    #!/bin/bash

    # Call the original script first
    [[ -x /etc/forward-original ]] && /etc/forward-original "$@" &

    . /lib/functions/modem.sh

    SCRIPTSDIR="/etc/sms-actions"

    # Initial scripts in init/ are always executed asynchronously
    D="$SCRIPTSDIR/init"
    scripts=$(ls "$D" | sort)
    for script in $scripts; do
      [[ -f "$D/$script" ]] && [[ -x "$D/$script" ]] && "$D/$script" "$@" &
    done

    # Normal scripts, ran asynchronously unless they have an extension ".wait"
    D="$SCRIPTSDIR"
    scripts=$(ls "$D" | sort)
    for script in $scripts; do
        [[ -x "$D/$script" ]] || continue
        [[ -f "$D/$script" ]] || continue
        if [[ "$script" =~ \.wait$ ]]; then
          "$D/$script" "$@"
        elif [[ "$script" =~ \.wait([0-9]+)$ ]]; then
          waitterm="${BASH_REMATCH[1]}"
          waitkill="$((waitterm + 5))" # extra 5 seconds before KILL
          timeout -k $waitkill $waitterm "$D/$script" "$@"
        else
          "$D/$script" "$@" &
        fi
    done

\
Implement some scripts in /etc/sms-actions/ 
