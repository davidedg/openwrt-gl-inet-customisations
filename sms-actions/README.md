# SMS Actions

Override stock SMS processing script with custom ones.


- Enable SMS Forwarding in the GUI (you can forward to e-mail)
  
  This will configure `/tmp/smstools.cfg` with `eventhandler = /etc/forward`


- Create directories /etc/sms-actions/...

      mkdir -p /etc/config/sms-actions/pre /etc/config/sms-actions/post

- Copy the original script:

      cp /etc/forward /etc/forward-original

- Then overwrite it with this [custom script](./forward):

      wget -O /etc/forward "https://github.com/davidedg/gl-inet-customisations/raw/refs/heads/main/sms-actions/forward"
      chmod +x /etc/forward

- Implement some scripts in /etc/config/sms-actions/pre or /etc/config/sms-actions/post - see [examples](./scripts/)

      wget -O /etc/config/sms-actions/pre/01-smsactions.wait30 "https://github.com/davidedg/gl-inet-customisations/raw/refs/heads/main/sms-actions/scripts/pre/01-smsactions.wait30"
      chmod +x /etc/config/sms-actions/pre/01-smsactions.wait30
