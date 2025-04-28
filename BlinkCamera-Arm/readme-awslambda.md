Blink Cameras arming via script ran on AWS Lambda
=================================================

Based on the amazing [blinkpy](https://pypi.org/project/blinkpy/) library.

The local version running on the device works, but is very slow (> 30 seconds).

This version uses AWS Lambda function to offload the task.

To call the lambda function url, we use IAM_URL authentication, with SigV4 created by [aws-curl](https://github.com/sormy/aws-curl)

Install the aws-curl script, along with its dependencies:

    opkg update && opkg install coreutils-od coreutils-paste
    curl -s https://raw.githubusercontent.com/sormy/aws-curl/master/aws-curl -o /mnt/sda1/aws-curl
    chmod +x /mnt/sda1/aws-curl

Use the script below to trigger the lambda:

    #!/bin/sh
    export AWS_ACCESS_KEY_ID="AK..."
    export AWS_SECRET_ACCESS_KEY="..."
    export AWS_REGION="eu-north-1"
    export FUNCTION_URL="https://qq....lambda-url.eu-north-1.on.aws/"
    export AWS_DEFAULT_REGION=$AWS_REGION
    
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <arm|disarm>"
        exit 1
    fi
    
    if [ "$1" = "arm" ]; then
    
      ./aws-curl --request POST \
        --header "Content-Type: application/json" \
        --data '{"action":"arm"}' \
        --region "$AWS_REGION" \
        --service lambda \
        "$FUNCTION_URL"
    
    elif [ "$1" = "disarm" ]; then
    
      ./aws-curl --request POST \
        --header "Content-Type: application/json" \
        --data '{"action":"disarm"}' \
        --region "$AWS_REGION" \
        --service lambda \
        "$FUNCTION_URL"
    
    else
        echo "Invalid argument. Use 'arm' or 'disarm'."
        exit 1
    fi

triggered by [TriggerHappy](../triggerhappy-scripts/triggerhappy.md) (adapt it, no need to use chroot).

The lambda function is as simple as:

    import json
    import asyncio
    import sys
    from aiohttp import ClientSession
    from blinkpy.blinkpy import Blink
    from blinkpy.auth import Auth
    from blinkpy.helpers.util import json_load
    
    CREDFILE = "blink-creds.json"
    BLINKMODULE = "your-module-name"
    
    async def start(session: ClientSession):
        blink = Blink(session=session)
        blink.auth = Auth(await json_load(CREDFILE), session=session)
        await blink.start()
        return blink
    
    async def blinkit(armed):
        session = ClientSession()
        blink = await start(session)
        await blink.sync[BLINKMODULE].async_arm(armed)
        await session.close()
    
    def lambda_handler(event, context):
        body = json.loads(event["body"])
        action = body.get("action", "unknown")
        if action == "arm":
            loop = asyncio.get_event_loop()
            loop.run_until_complete(blinkit(True))
            return {"statusCode": 200, "body": json.dumps({"message": "System armed"})}
        elif action == "disarm":
            loop = asyncio.get_event_loop()
            loop.run_until_complete(blinkit(False))
            return {"statusCode": 200, "body": json.dumps({"message": "System disarmed"})}
        else:
            return {"statusCode": 400, "body": json.dumps({"error": "Invalid action"})}

with a [Layer](https://github.com/awsdocs/aws-lambda-developer-guide/tree/main/sample-apps/layer-python/layer) using this requirements.txt:

    python-dateutil>=2.8.1
    requests>=2.24.0
    python-slugify>=4.0.1
    sortedcontainers~=2.4.0
    aiohttp>=3.8.4
    aiofiles>=23.1.0
    blinkpy>=0.23.0


The IAM user needs a policy with:

    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "VisualEditor0",
                "Effect": "Allow",
                "Action": "lambda:InvokeFunctionUrl",
                "Resource": "arn:aws:lambda:*:*:function:name-of-function"
            }
        ]
    }
