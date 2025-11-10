"""Extract definition from existing Kindle dictionaries (For example https://akishop.com.vn/tong-hop-tu-dien-cho-kindle-nd49491.html)

Steps
1. If necessary, use DeDRM Calibre plugin (https://github.com/apprenticeharper/DeDRM_tools/) to remove DRM
2. Use KindleUnpack -r to extract raw data from .prc/.mobi file
3. Run following code to extract and cleanup definitions to a tab-seperated file format
4. Now the output can be run through PyGlossary to convert to many dictionary formats
"""

import re
from email.quoprimime import header_decode
from html import unescape

from bs4 import BeautifulSoup


def striphtml(data):
    p = re.compile(r"<.*?>")
    return p.sub("", data)


folder = r"./ext-dict/"

FILE_DATA = {
    "SPDict-Irregular-Verbs.html": {
        "encoding": "utf-8",
        "pattern": r"<i>(.+?)</i><br> @ <br>-- > (.+?) <br><mbp:pagebreak/><idx:entry>",
        "remove": r"<[(/i|b|u)\s]*>",
        "replace": [],
        "skips": 0,
    },
    "Wikipedia/mobi7/Wikipedia.rawml": {
        "encoding": "utf-8",
        "pattern": r"<h1>(.+?)<\/h1>(.+?)<br>",
        "remove": r"<[(/i|b|u)\s]*>",
        "replace": [],
        "skips": 0,
    },
    "Bach khoa toan thu/mobi7/Bach khoa toan thu.rawml": {
        "encoding": "utf-8",
        "pattern": r"<h1>(.+?)<\/h1>(.+?)<mbp:pagebreak\/>",
        "remove": r"<[(/i|b|u|p|span|font|em|div)\s].*?>",
        "replace": [],
        "skips": 0,
    },
    "Duc - Viet - Ho Ngoc Duc/mobi7/Duc - Viet - Ho Ngoc Duc.rawml": {
        "encoding": "cp1252",
        "pattern": r"<h3>(.+?)</h3>(.+?)<br/> <mbp:pagebreak/>",
        "replace": [],
        "remove": r"<[(/i|b|u)\s]*>",
        "skips": 0,
    },
    "Dictionary of Computing/mobi7/Dictionary of Computing.rawml": {
        "encoding": "utf-8",
        "pattern": r"<h3>(.+?)</h3>(.+?)<mbp:pagebreak/>",
        "replace": [],
        "remove": r"",
        "skips": 4,
    },
    "Nhat - Viet/mobi7/Nhat - Viet.rawml": {
        "encoding": "utf-8",
        "pattern": r"<h2>(.+?)</h2>(.+?)<mbp:pagebreak/>",
        "replace": [],
        "remove": r"",
        "skips": 2,
    },
    "Phap-Viet - Ho Ngoc Duc/mobi7/Phap-Viet - Ho Ngoc Duc.rawml": {
        "encoding": "cp1252",
        "pattern": r"<h3>(.+?)</h3>(.+?)<br/> <mbp:pagebreak/>",
        "replace": [],
        "remove": r"<[(/i|b|u)\s]*>",
        "skips": 0,
    },
    "Tieng Viet - Ho Ngoc Duc/mobi7/Tieng Viet - Ho Ngoc Duc.rawml": {
        "encoding": "cp1252",
        "pattern": r"<h3>(.+?)</h3>(.+?) <mbp:pagebreak/>",
        "replace": [],
        "remove": r"<[(/i|b|u)\s]*>",
        "skips": 0,
    },
    "WordNet 2.0/mobi7/WordNet 2.0.rawml": {
        "encoding": "cp1252",
        "pattern": r"<h3>(.+?)</h3>(.+?) <mbp:pagebreak/>",
        "replace": [],
        "remove": r"<[(/i|b|u)\s]*>",
        "skips": 0,
    },
    "Viet - Nhat NXBVHTT/mobi7/Viet - Nhat NXBVHTT.rawml": {
        "encoding": "utf-8",
        "pattern": r"<h2>(.+?)<\/h2>(.+?) <mbp:pagebreak/>",
        "replace": [],
        "remove": r"",
        "skips": 0,
    },
    "britannica_com - Unknown/mobi7/britannica_com - Unknown.rawml": {
        "encoding": "utf-8",
        "pattern": r"<h2>(.+?)<\/h2>(.+?) <mbp:pagebreak/>",
        "replace": [],
        "remove": r'<[(/i|b|u)\s]*>|<a href="http:\/\/www\.babylon\.com\/redirects\/redir\.cgi\?type=britannica&query=.+?">Learn more at Britannica\.com<\/a>',
        "skips": 0,
    },
    "Tu dien Han ngu - hhh/mobi7/Tu dien Han ngu - hhh.rawml": {
        "encoding": "utf-8",
        "pattern": r'<font size="7">(.+?)<\/font>(.+?)<mbp:pagebreak\/>',
        "replace": [],
        "remove": r"",
        "skips": 0,
        "strip_html": True,
    },
    "SPDict-English-Grammar.rawml": {
        "encoding": "utf-8",
        "pattern": r"<i>(.+?)</i><br>(.+?)<br><mbp:pagebreak/><idx:entry>",
        "remove": r"<[(/i|b|u)\s]*>",
        "replace": [("<a filepos=XXXXXXXXXX >", "")],
        "skips": 0,
    },
    "SPDict-Viet-Anh.rawml": {
        "encoding": "utf-8",
        "pattern": r"<i>.+?</i>(.+?)<br>(.+?)<mbp:pagebreak/><idx:entry>",
        #        'pattern': r'<i>.+?</i><br> <b>(.+?)</b><br>(.+?)<br><mbp:pagebreak/><idx:entry>',
        "remove": r"<[(/i|b|u|br)\s]*>",
        "replace": [],
        "skips": 0,
    },
    "SPDict-Anh-Viet.rawml": {
        "encoding": "utf-8",
        "pattern": r"<i>(.+?)</i>(.+?)<mbp:pagebreak/>",
        "remove": r"<[(/i|b|u|br)\s]*>",
        "replace": [('<font color="#FF0000"> ', " ")],
        "skips": 0,
    },
}

file = r"SPDict-Anh-Viet.rawml"

filepath = folder + file

print(f"Parsing {file}")

file_encoding = FILE_DATA[file]["encoding"]
skips = FILE_DATA[file]["skips"]

DEBUG = False

word_mark = "<idx:orth"

with open(filepath, encoding=file_encoding) as f:
    html = f.read()

    # HTML entities need to unescape to create Unicode chars
    if file_encoding == "cp1252":
        html = unescape(html)

    # Print the extracted data

    # outhtml = remove_tags(html, file)
    # print(outhtml)

    pattern = re.compile(FILE_DATA[file]["pattern"])

    with open(filepath.replace(".rawml", ".tab"), "w", encoding="utf-8") as out:
        count = 1
        print("Start matching...")

        print(f"Head word marks: {html.count(word_mark)}")

        for match in pattern.finditer(html):
            if count <= skips:
                continue

            headword = match.group(1).strip()
            definition = match.group(2).strip()

            definition = definition.replace(f"@{headword}", "")

            # StarDict metadata
            if headword.find("00-database") >= 0:
                continue

            definition = definition.replace("\t", " ")

            if DEBUG:
                print(f"{headword}\t{definition}\n\n")

            definition = re.sub(FILE_DATA[file]["remove"], "", definition)
            headword = re.sub(FILE_DATA[file]["remove"], "", headword)

            for org, new in FILE_DATA[file]["replace"]:
                headword = headword.replace(org, new)

            for org, new in FILE_DATA[file]["replace"]:
                definition = definition.replace(org, new)

            headword = headword.strip()
            definition = definition.strip()

            if "recover_mark" in FILE_DATA[file] and headword.find("[VV]") >= 0:
                pos = definition.find("-")
                headword = definition[:pos]
                definition = definition[pos + 2 :]

            if "strip_html" in FILE_DATA[file] and FILE_DATA[file]["strip_html"]:
                definition = striphtml(definition)

            if DEBUG:
                print(f"{headword}\t{definition}\n\n")

            if not headword or not definition:
                print(f"Warning: something is empty |{headword}|\t|{definition}|")
                continue

            count += 1

            out.writelines(f"{headword}\t{definition}\n")

    print(f"No. of items: {count}")

print(f"Done")
