"""Find Wikimedia Commons photos for 2024 candidates that have none yet.

Reads the names with a null photo from lib/data/results_2024.dart, searches
Wikidata by name and accepts a match only when exactly one result is an Indian
politician (by description) with an image (P18) and a label/alias equal to the
name. Writes PHOTO lines to tools/data/photos-extra.txt.
"""
import json
import re
import time
import urllib.parse
import urllib.request

UA = {"User-Agent": "VoteWalaDataBot/1.0 (https://github.com/janapalaashok/VoteWala)"}


stats = {"errors": 0, "searched": 0, "with_hits": 0, "politician": 0, "name_match": 0, "with_image": 0}


def get(url, params):
    full = url + "?" + urllib.parse.urlencode({**params, "format": "json"})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(full, headers=UA), timeout=60) as r:
                return json.load(r)
        except Exception as e:
            if attempt == 2:
                stats["errors"] += 1
                if stats["errors"] <= 3:
                    print("ERROR", url, e)
            time.sleep(2 + attempt * 3)
    return {}


def norm(s):
    return re.sub(r"[^a-z]", "", s.lower())


src = open("lib/data/results_2024.dart", encoding="utf-8").read()
names = sorted(set(re.findall(r'Contestant2024\("([^"]+)", \'\w+\', \d+, null\)', src)))
print(f"searching {len(names)} names")

out = []
for name in names:
    hits = get("https://www.wikidata.org/w/api.php",
               {"action": "wbsearchentities", "search": name, "language": "en", "limit": 7, "type": "item"})
    stats["searched"] += 1
    if hits.get("search"):
        stats["with_hits"] += 1
    ids = [h["id"] for h in hits.get("search", [])
           if "politician" in h.get("description", "").lower()
           and any(w in h.get("description", "").lower() for w in ("india", "andhra", "telugu"))]
    if not ids:
        continue
    stats["politician"] += 1
    ents = get("https://www.wikidata.org/w/api.php",
               {"action": "wbgetentities", "ids": "|".join(ids), "props": "claims|labels|aliases|descriptions",
                "languages": "en"}).get("entities", {})
    good = []
    for qid, e in ents.items():
        labels = [e.get("labels", {}).get("en", {}).get("value", "")]
        labels += [a["value"] for a in e.get("aliases", {}).get("en", [])]
        if norm(name) not in {norm(l) for l in labels}:
            continue
        stats["name_match"] += 1
        p18 = e.get("claims", {}).get("P18")
        if p18:
            stats["with_image"] += 1
        if p18:
            good.append((qid, p18[0]["mainsnak"]["datavalue"]["value"],
                         e.get("descriptions", {}).get("en", {}).get("value", "")))
    if len(good) != 1:
        continue
    qid, file, desc = good[0]
    info = get("https://commons.wikimedia.org/w/api.php",
               {"action": "query", "titles": "File:" + file, "prop": "imageinfo", "iiprop": "url",
                "iiurlwidth": 240})
    pages = info.get("query", {}).get("pages", {})
    thumb = next((p["imageinfo"][0].get("thumburl") for p in pages.values() if p.get("imageinfo")), None)
    if thumb:
        line = {"name": name, "url": thumb, "qid": qid, "desc": desc}
        out.append(line)
        print("PHOTO|" + json.dumps(line, ensure_ascii=False))

with open("tools/data/photos-extra.txt", "w", encoding="utf-8") as f:
    for line in out:
        f.write("PHOTO|" + json.dumps(line, ensure_ascii=False) + "\n")
print(f"found {len(out)} of {len(names)}", stats)
