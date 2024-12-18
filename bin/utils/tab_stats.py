"""Statistics for the dictionary data file"""

import argparse
import pathlib
import collections
import string


def frequency(l):
    cp = []
    maxl = []
    minl = []

    ctr = collections.Counter(l)

    print(ctr.most_common())
    for i in ctr:
        r = ctr[i]
        cp.append(r)
    p = max(cp)
    q = min(cp)
    # print(cp)
    for i in ctr:
        if ctr[i] == p:
            maxl.append(i)
        if ctr[i] == q:
            minl.append(i)

    return (sorted(minl), sorted(maxl))


COUNT = 10
DEF_LEN_DIV = 100
MAX_LINE = 1000  # Run multitple round to avoid loading a huge file


def list_words(text):
    return [word.strip(string.punctuation + "\n") for word in text.split()]


def writeStats(file, contents):
    print(str(contents))
    file.write(f"{str(contents)}\n")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert all dictionaries in a folder", usage="Usage: python tab_stats.py --input data.tab --output data.stats"
    )

    parser.add_argument("-i", "--input", required=True, help="Input folder containing .tsv and .dfo files")
    parser.add_argument("-o", "--output", help="Output folder containing dictionary files")

    args, array = parser.parse_known_args()
    inputfile = args.input
    ouputfile = args.output

    mainCharCounter = collections.Counter()
    mainWordCounter = collections.Counter()
    mainHeadwordCounter = collections.Counter()
    mainDefinitionCounter = collections.Counter()

    # Stats về chiều dài headword, definition
    # Tách lượt để thống kê không thì hết bộ nhớ

    inputpath = pathlib.Path(inputfile)

    if not ouputfile:
        ouputpath = inputpath.with_suffix(".stats")
    else:
        ouputpath = pathlib.Path(ouputfile)

    try:
        infile = open(inputpath, encoding="utf-8", errors="strict")

        outfile = open(ouputpath, "w", encoding="utf-8")

        line = infile.readline()

        line_count = 1
        issue_count = 0
        lines = []
        text = ""
        words = []

        writeStats(outfile, "# File Checks")

        while line:
            # print(f'Line {line_count}')

            #            lines.append(line)

            mainCharCounter = mainCharCounter + collections.Counter(line)
            # mainWordCounter = mainWordCounter + collections.Counter(list_words(line))

            items = line.strip().split("\t")
            no_items = len(items)

            if no_items != 2:
                writeStats(outfile, f"### Error on line {line_count}: Wrong number of items ({no_items})> {line.strip()}")
                issue_count += 1

            else:
                mainHeadwordCounter.update([len(items[0])])
                mainDefinitionCounter.update([len(items[1]) // DEF_LEN_DIV * DEF_LEN_DIV])
                pass

            line_count += 1
            line = infile.readline()

            if not line or ((line_count % MAX_LINE) == 0):  # Every MAX_LINE lines, accomulate stats
                print(f"Line {line_count}")
                # mainCharCounter = mainCharCounter + collections.Counter(text)
                # mainWordCounter = mainWordCounter + collections.Counter(words)
                # text = ''
                # lines = []
                # words = []
                outfile.flush()

        writeStats(outfile, "# Line stats")
        writeStats(outfile, f"## Line count: {line_count}")
        writeStats(outfile, f"## Issue count: {issue_count}")

        writeStats(outfile, "# Character frequency")
        writeStats(outfile, str(mainCharCounter.most_common(COUNT)))
        writeStats(outfile, str(mainCharCounter.most_common()[: -COUNT - 1 : -1]))

        # writeStats(outfile, '# Word frequency')
        # writeStats(outfile, str(mainWordCounter.most_common(COUNT)))
        # writeStats(outfile, str(mainWordCounter.most_common()[:-COUNT-1:-1]))

        writeStats(outfile, "# Headword len frequency")
        writeStats(outfile, str(mainHeadwordCounter.most_common(COUNT)))
        writeStats(outfile, str(mainHeadwordCounter.most_common()[: -COUNT - 1 : -1]))

        writeStats(outfile, "# Definition len frequency")
        writeStats(outfile, str(mainDefinitionCounter.most_common(COUNT)))
        writeStats(outfile, str(mainDefinitionCounter.most_common()[: -COUNT - 1 : -1]))

    except IOError as err:
        print(f"Error reading file: {err}")

    except UnicodeDecodeError as err:
        print(f"Error decoding file: {err}")

        # try:
        # print('Write file to compare')
        # infile = open(inputpath, encoding='utf-8', errors='replace')
        # lines = infile.readlines()
        # infile.close()

        # outfile = open(str(inputpath) + '.txt', 'w', encoding='utf-8')
        # outfile.writelines(lines)
        # outfile.close()

        # except IOError as err1:
        # print(f'Error reading file: {err1}')
        # exit(1)


if __name__ == "__main__":
    main()
