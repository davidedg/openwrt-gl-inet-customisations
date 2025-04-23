import asyncio
import sys
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
    if len(sys.argv) < 2:
        print("Usage: python script.py [arm|disarm]")
        return

    action = sys.argv[1].lower()
    if action not in ["arm", "disarm"]:
        print("Invalid action. Use 'arm' or 'disarm'.")
        return

    session = ClientSession()
    blink = await start(session)
    for name, camera in blink.cameras.items():
        print(name)

    if action == "arm":
        print("ARMING...")
        await blink.sync[BLINKMODULE].async_arm(True)
    elif action == "disarm":
        print("DISARMING...")
        await blink.sync[BLINKMODULE].async_arm(False)

    await blink.save(CREDFILE)
    await session.close()


if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
