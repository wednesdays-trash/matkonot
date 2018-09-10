import sqlite3
from dataclasses import astuple

import anonymous
import tivoniot


def fetch_recipes():
    sources = [anonymous, tivoniot]

    for s in sources:
        for x in s.fetch_recipes():
            yield astuple(x)


if __name__ == "__main__":
    conn = sqlite3.connect("matkonot.db")
    c = conn.cursor()

    recipes = fetch_recipes()
    c.executemany("INSERT INTO recipes VALUES (?,?,?,?,?)", recipes)
    conn.commit()
    conn.close()

