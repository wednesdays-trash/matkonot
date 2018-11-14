from datetime import datetime
import asyncio
import sqlite3
import dataclasses
import time
from itertools import chain

from typing import Callable, List
from utils import Recipe

import anonymous
import tivoniot

REQUEST_INTERVAL_SECONDS = 3


def run_module(module) -> Callable[[], List[Recipe]]:
    def result_func():
        result = []

        for recipe in module.fetch_recipes():
            time.sleep(REQUEST_INTERVAL_SECONDS)
            result.append(dataclasses.astuple(recipe))

        return result

    return result_func


async def main():
    loop = asyncio.get_running_loop()

    sources = [anonymous, tivoniot]

    def create_task(source):
        return loop.run_in_executor(None, run_module(source))

    recipes_nested = await asyncio.gather(*map(create_task, sources))

    date = datetime.now().strftime("%d_%m_%Y")

    conn = sqlite3.connect("recipes_%s.db" % date)
    cur = conn.cursor()

    recipes = chain.from_iterable(recipes_nested)
    cur.execute("CREATE TABLE recipes (title text, url text, ingredients text, thumbnail_url text, source text)")
    cur.executemany("INSERT INTO recipes VALUES (?,?,?,?,?)", recipes)
    conn.commit()
    conn.close()


if __name__ == "__main__":
    asyncio.run(main())
