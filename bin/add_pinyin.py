"""
Verify tab file


"""

import argparse
import pinyin


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Add Pinyin for Chinese characters",
        usage="Usage: python add_pinyin.py --input data.tab --output data.tab.new",
    )

    parser.add_argument("-i", "--input", required=True, help="Input file ")
    parser.add_argument("-o", "--output", help="Output file")
    args, array = parser.parse_known_args()
    inputfile = args.input
    outputfile = args.output

    if not outputfile:
        outputfile = inputfile + ".new"

    outfile = open(outputfile, "w", encoding="utf-8")

    if not outfile:
        print(f"Couldnot open output file {outputfile}")

    with open(
        inputfile, "r", encoding="utf-8", errors="replace"
    ) as infile:  # , errors='replace'
        count = 0
        count_issues = 0

        while True:
            count += 1
            # print(f'Reading line {count}')
            line = infile.readline().strip()

            if not line:
                break

            tabs = line.count("\t")

            if tabs == 0 or tabs > 1:
                print(f"Line {count} has {tabs} tabs")
                count_issues += 1
            else:
                items = line.split("\t")

                headword = items[0].strip()
                definition = items[1].strip()

                if not headword or not definition:
                    print(f"Line {count} has empty headword or definition")

                    continue

                pinyin_text = pinyin.get(headword)

                outfile.write(f"{headword}\t[{pinyin_text}] {definition}\n")
                # print(f'{headword}\t{definition}')
                outfile.flush()

    outfile.close()


if __name__ == "__main__":
    main()
