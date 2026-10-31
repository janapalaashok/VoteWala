"""Dump the 2024 Andhra Pradesh result tables (Assembly + Lok Sabha) from
Wikipedia as JSON lines, plus each winner's Wikipedia lead image.

Run by .github/workflows/fetch-data.yml; output is read from the job log.
"""
import json
import urllib.parse
import urllib.request

from bs4 import BeautifulSoup

API = "https://en.wikipedia.org/w/api.php"
UA = {"User-Agent": "VoteWalaDataBot/1.0 (https://github.com/janapalaashok/VoteWala)"}
PAGES = {
    "assembly": "2024_Andhra_Pradesh_Legislative_Assembly_election",
    "loksabha": "2024_Indian_general_election_in_Andhra_Pradesh",
}


def api(params):
    url = API + "?" + urllib.parse.urlencode({**params, "format": "json", "formatversion": 2})
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
        return json.load(r)


def cell(td):
    links = [a["href"].removeprefix("/wiki/") for a in td.find_all("a", href=True)
             if a["href"].startswith("/wiki/") and ":" not in a["href"][6:]]
    return {"t": " ".join(td.get_text(" ", strip=True).split()), "l": links}


titles = set()
for kind, page in PAGES.items():
    html = api({"action": "parse", "page": page, "prop": "text"})["parse"]["text"]
    soup = BeautifulSoup(html, "html.parser")
    for ti, table in enumerate(soup.find_all("table", class_="wikitable")):
        rows = table.find_all("tr")
        if len(rows) < 20:
            continue
        print(f"TABLE|{kind}|{ti}|{len(rows)}")
        for tr in rows:
            cells = [cell(td) for td in tr.find_all(["th", "td"])]
            print(f"ROW|{kind}|{ti}|" + json.dumps(cells, ensure_ascii=False))
            for c in cells:
                titles.update(c["l"])

titles = sorted(t for t in titles if "election" not in t.lower() and "constituency" not in t.lower())
for i in range(0, len(titles), 50):
    batch = [urllib.parse.unquote(t).replace("_", " ") for t in titles[i:i + 50]]
    data = api({"action": "query", "prop": "pageimages", "piprop": "thumbnail", "pithumbsize": 240,
                "redirects": 1, "titles": "|".join(batch)})
    q = data["query"]
    redirects = {r["to"]: r["from"] for r in q.get("redirects", [])}
    normalized = {n["to"]: n["from"] for n in q.get("normalized", [])}
    for p in q["pages"]:
        if "thumbnail" in p:
            src = redirects.get(p["title"], p["title"])
            src = normalized.get(src, src)
            print("IMG|" + json.dumps({"title": src, "url": p["thumbnail"]["source"]}, ensure_ascii=False))
