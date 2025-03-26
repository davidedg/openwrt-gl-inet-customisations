# SMS Actions

Override stock SMS processing script with custom ones.

\
Step 1:
\
Enable SMS Forwarding in the GUI (you can forward to e-mail)
\
This will configure `/tmp/smstools.cfg` with `eventhandler = /etc/forward`
\
\
Step 2: 
\
Create directories /etc/sms-actions/...

    mkdir -p /etc/sms-actions/pre /etc/sms-actions/post

Copy the original script:

    cp /etc/forward /etc/forward-original

Then overwrite it with this [custom script](./forward):

    wget -O /etc/forward "https://github.com/davidedg/gl-inet-customisations/raw/refs/heads/main/sms-actions/forward"
    chmod +x /etc/forward

Implement some scripts in /etc/sms-actions/pre or /etc/sms-actions/post - see [examples](./scripts/)

    wget -O /etc/sms-actions/pre/01-smsactions.wait30 "https://github.com/davidedg/gl-inet-customisations/raw/refs/heads/main/sms-actions/scripts/pre/01-smsactions.wait30"
    chmod +x /etc/sms-actions/pre/01-smsactions.wait30
