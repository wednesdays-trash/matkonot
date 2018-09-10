import sqlite3
import dataclasses

import anonymous
import tivoniot


def fetch_recipes():
    sources = [tivoniot, anonymous]

    for s in sources:
        for recipe in s.fetch_recipes():
            yield dataclasses.astuple(recipe)


if __name__ == "__main__":
    conn = sqlite3.connect("matkonot.db")
    c = conn.cursor()

    recipes = fetch_recipes()
    c.executemany("INSERT INTO recipes VALUES (?,?,?,?,?)", recipes)
    conn.commit()
    conn.close()

