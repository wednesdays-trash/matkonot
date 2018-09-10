from enum import Enum
from bs4 import BeautifulSoup
from dataclasses import dataclass
import requests

parser = "html.parser"
URL = str


class Source:
    ANONYMOUS = "אנונימוס"
    TIVONIOT = "טבעוניות נהנות יותר"


@dataclass
class Recipe:
    title: str
    url: URL
    ingredients: str
    thumbnail: URL
    source: Source


def soup_from_url(url: URL) -> BeautifulSoup:
    resp = requests.get(
        url,
        headers={
            "user-agent": "Mozilla/5.0 (X11; Linux x86_64) "
            "AppleWebKit/537.36 (KHTML, like Gecko)"
            "Chrome/65.0.3325.181 Safari/537.36"
        })
    return BeautifulSoup(resp.text, parser)


def find_first(pred, coll):
    return next(filter(pred, coll))
