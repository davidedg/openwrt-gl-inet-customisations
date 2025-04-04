import asyncio
from aiohttp import ClientSession
from blinkpy.blinkpy import Blink
from blinkpy.auth import Auth
from blinkpy.helpers.util import json_load

CREDFILE = "blink-creds.json"
BLINKMODULE = "Enter-your-module-name-here"

async def start(session: ClientSession):
    blink = Blink(session=session)
    blink.auth = Auth(await json_load(CREDFILE), session=session)
    await blink.start()
    return blink


async def main():
    session = ClientSession()
    blink = await start(session)
    for name, camera in blink.cameras.items():
        print(name)
    print ("ARMING...")
    await blink.sync[BLINKMODULE].async_arm(True)
    await blink.save(CREDFILE)
    await session.close()


if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
