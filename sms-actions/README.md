# SMS Actions

Enable SMS Forwarding in the GUI. This will configure `/tmp/smstools.cfg` with `eventhandler = /etc/forward`

Create directories /etc/sms-actions/...

    mkdir -p /etc/sms-actions/init

Copy the original script:

    cp /etc/forward /etc/forward-original

Then overwrite it with this [custom script](./forward):

    wget -O /etc/forward "https://github.com/davidedg/gl-inet-customisations/raw/refs/heads/main/sms-actions/forward"
\
Implement some scripts in /etc/sms-actions/ 
