#!/usr/bin/env python

import glob
import os
import argparse

def main():
    parser = argparse.ArgumentParser(
        description="Convert HTML tab-based .tab files to Pleco-formatted (.txt)"
    )
    parser.add_argument(
        "--folder",
        default="dict",
        help="Folder containing the source files (default: dict)"
    )
    parser.add_argument(
        "--pattern",
        default="*.tab",
        help="File pattern to match (default: *.tab)"
    )

    args = parser.parse_args()

    search_path = os.path.join(args.folder, args.pattern)
    dict_names = glob.glob(search_path)

    replaces = {
        "<br>": chr(0xEAB1),
        "<b>":  chr(0xEAB2),
        "</b>": chr(0xEAB3),
        "<i>":  chr(0xEAB4),
        "</i>": chr(0xEAB5),
        "<ol>": chr(0xEAB1),
        "</ol>": "",
        "<li>": "• ",
        "</li>": ""
    }

    for filepath in dict_names:
        if "Inflections" in filepath:
            continue

        print(f"{filepath} being read")
        with open(filepath, "r", encoding="utf-8") as fread:
            name, ext = os.path.splitext(filepath)
            contents = fread.read()

            for key, val in replaces.items():
                contents = contents.replace(key, val)

            lines = contents.split("\n")

            outpath = filepath.replace(".tab", ".txt")
            with open(outpath, "w", encoding="utf-8") as fwrite:
                for num, line in enumerate(lines[1:], start=1):
                    if not line.strip():
                        continue
                    
                    items = line.split("\t")
                    
                    # print(f"Processing line {num}: {line}")

                    # if len(items) != 2:
                    #     print(f"Line {num} in {filepath} does not have 2 items: {line}")
                    #     continue
                    
                    assert len(items) == 2
                    fwrite.write(f"{items[0]}\t{items[1]}\n")
                    
            print(f"\t{outpath} written")

if __name__ == "__main__":
    main()
