from typing import Iterable
from utils import log, soup_from_url, Recipe, Source
from bs4 import BeautifulSoup
import itertools

sfu = soup_from_url

base_page_url = "https://vegansontop.co.il/category/vegan-recipes/page/{page_num}/"


def fetch_recipes() -> Iterable[Recipe]:
    for i in itertools.count(start=1):
        log("page number %d" % i)
        current_page = sfu(base_page_url.format(page_num=i))

        if is_page_empty(current_page):
            break

        yield from get_recipes(current_page)


def get_recipes(page: BeautifulSoup) -> Iterable[Recipe]:
    for tag in page.find_all(class_="post"):
        log(tag)
        a_tag = tag.find("h2").find("a")
        link = a_tag.attrs["href"]
        page_img = a_tag.find(class_="pageim")

        yield Recipe(
            title=a_tag.text,
            url=link,
            ingredients=sfu(link).find(class_="pf-content").text,
            thumbnail=page_img.attrs["src"] if page_img is not None else "",
            source=Source.TIVONIOT)


def is_page_empty(page: BeautifulSoup) -> bool:
    return "לא נמצא" in page.text

