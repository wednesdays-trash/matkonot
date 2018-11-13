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

        c = 0
        for recipe in module.fetch_recipes():
            c += 1
            time.sleep(REQUEST_INTERVAL_SECONDS)
            print(recipe.url)
            result.append(dataclasses.astuple(recipe))
            if c == 2:
                break

        return result

    return result_func


async def main():
    loop = asyncio.get_running_loop()

    sources = [anonymous, tivoniot]

    def create_task(source):
        return loop.run_in_executor(None, run_module(source))

    recipes_nested = await asyncio.gather(*map(create_task, sources))

    conn = sqlite3.connect("matkonot.db")
    cur = conn.cursor()

    recipes = chain.from_iterable(recipes_nested)
    cur.executemany("INSERT INTO recipes VALUES (?,?,?,?,?)", recipes)
    conn.commit()
    conn.close()


if __name__ == "__main__":
    asyncio.run(main())
