# Converts Pleco-formatted input data file to Tab-separated values (TSV) format for PyGlossary
import os
from os.path import join

from tools_configs import DICT_DIR
import glob

# dict_names = ["char_dict_pleco.txt", "radical_lookup_pleco.txt", "radical_name_pleco.txt", "tvb_pleco.txt"]
dict_names = glob.glob("dict/*.txt")

replaces = {
    chr(0xEAB1): "<br>",
    chr(0xEAB2): "<b>",
    chr(0xEAB3): "</b>",
    chr(0xEAB4): "<i>",
    chr(0xEAB5): "</i>",
    chr(0xEAB8): "",
    chr(0xEABB): "",
    "": "",
    "": "",
    "": "",
}

for filepath in dict_names:
    print(f"{filepath} being read")
    with open(filepath, "r", encoding="utf-8") as fread:
        name, ext = os.path.splitext(filepath)
        contents = fread.read()

        for key in replaces:
            contents = contents.replace(key, replaces[key])

        lines = contents.split("\n")

        outpath = filepath.replace(".txt", ".tab")
        with open(outpath, "w", encoding="utf-8") as fwrite:
            for num, line in enumerate(lines[1:], start=1):
                if not line.strip():
                    continue

                items = line.split("\t")
                assert len(items) == 3
                fwrite.write(f"{items[0]}\t{items[1]}<br>{items[2]}\n")

        print(f"\t{outpath} written")
