from bs4 import BeautifulSoup
from dataclasses import dataclass
import inspect
import logging
import requests
from typing import Any

LOG_FILE_NAME = "log"
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
    source: str


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


def log(message: Any) -> None:
    # figure out the calling file's name
    frame = inspect.currentframe()
    frame = inspect.getouterframes(frame)

    # the file name is represented using its full path. we only need
    # the actual name (without type extension).
    caller_name = frame[1].filename.split('/')[-1][:-3]

    logger = logging.getLogger(LOG_FILE_NAME)

    # this check is here because for some interesting reason entries are
    # duplicated without this check.
    if not logger.hasHandlers():
        handler = logging.FileHandler(LOG_FILE_NAME)
        handler.setFormatter(
            logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
        logger.addHandler(handler)
    logger.setLevel(logging.DEBUG)

    message_with_tag = "%s: %s" % (caller_name, str(message))
    logger.debug(message_with_tag)

