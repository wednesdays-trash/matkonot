from functools import reduce
from typing import Iterable, Optional, Set
from utils import soup_from_url, Recipe, URL, Source
from bs4 import BeautifulSoup
import re
import operator

main_page_url = "https://veg.anonymous.org.il/cat12.html"
category_pattern = re.compile("cat[0-9]+.html")


def fetch_recipes() -> Iterable[Recipe]:
    index = soup_from_url(main_page_url)

    for link in get_categories_links(index):
        page = soup_from_url(link)
        yield from recipes_in_category(page)


def get_categories_links(main_page: BeautifulSoup) -> Set[URL]:
    def all_links():
        for tag in main_page.find_all(href=category_pattern):
            yield "https://veg.anonymous.org.il/" + tag.attrs["href"]

    # converting to set to mitigate duplicates
    return set(all_links())


def recipes_in_category(category_page: BeautifulSoup) -> Iterable[Recipe]:
    for item in category_page.find_all(class_="subcategoryItem"):
        a = item.find("a")

        yield parse_recipe(url=a.attrs["href"],
                           title=a.text.strip())


def parse_recipe(url: URL, title: str) -> Recipe:
    page = soup_from_url(url)

    def ingredients_gen():
        for ing in page.find_all(class_="ingredient"):
            yield ing.text

    # concatenate the ingredients into one string
    ingredients = reduce(operator.add, ingredients_gen(), "")

    thumbnail_url = find_recipe_thumbnail(page)

    return Recipe(
        title=title,
        url=url,
        ingredients=ingredients,
        thumbnail=thumbnail_url if thumbnail_url is not None else "",
        source=Source.ANONYMOUS)


def find_recipe_thumbnail(recipe_page: BeautifulSoup) -> Optional[URL]:
    image_div = recipe_page.find(class_="recipe_image")
    if image_div:
        return image_div.find("img").attrs["src"]
    return None
