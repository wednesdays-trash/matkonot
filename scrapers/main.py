import sqlite3
import dataclasses
import time

import anonymous
import tivoniot

REQUEST_INTERVAL_SECONDS = 3


def fetch_recipes():
    sources = [anonymous, tivoniot]

    for s in sources:
        for recipe in s.fetch_recipes():
            time.sleep(REQUEST_INTERVAL_SECONDS)
            yield dataclasses.astuple(recipe)


if __name__ == "__main__":
    conn = sqlite3.connect("matkonot.db")
    c = conn.cursor()

    recipes = fetch_recipes()
    c.executemany("INSERT INTO recipes VALUES (?,?,?,?,?)", recipes)
    conn.commit()
    conn.close()

