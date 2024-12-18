"""Merges two English inflection files"""

file_names = ["./bin/inflections/english_inflections.tab", "./bin/inflections/inflection-eng.tab"]
word_dicts = []

print(f"Set A: {file_names[0]} - Set B: {file_names[1]}")
for filename in file_names:
    with open(filename, "r", encoding="utf-8") as f:
        lines = f.read().split("\n")
        f.close()

        words = {}

        for c, l in enumerate(lines):
            l = l.strip()
            if not l:
                continue

            items = l.split("\t")
            if len(items) != 2:
                print(f"Issue at line {c}: {l}")
                continue

            #            if items[0].isalpha():
            headword = items[0]
            inflections = set(items[1].split("|"))

            words[headword] = inflections

        word_dicts.append(words)

print(f"No. words: set A: {len(word_dicts[0])} set B: {len(word_dicts[1])}")

print(f"No. intersected words: {len(set(word_dicts[0].keys()).intersection(set(word_dicts[1].keys())))}")

print(
    f"No. different words in A not in B: {len(set(word_dicts[0].keys()).difference(set(word_dicts[1].keys())))}"
)  # \n{word_dicts[0].difference(word_dicts[1])}

print(f"No. different words in B not in A: {len(set(word_dicts[1].keys()).difference(set(word_dicts[0].keys())))}")

print(f"No. symmetricly different words in B not in A: {len(set(word_dicts[1].keys()).symmetric_difference(set(word_dicts[0].keys())))}")

# print(f'No. different words in B not in A: {word_dicts[1].difference(word_dicts[0])}')

merged_filename = "./bin/inflections/merged_english_inflections.tab"

with open(merged_filename, "w", encoding="utf-8") as f:
    for key in word_dicts[0]:
        if not key in word_dicts[1]:
            word_dicts[1][key] = word_dicts[0][key]
        else:
            union = word_dicts[1][key].union(word_dicts[0][key])

            word_dicts[1][key] = word_dicts[1][key].union(word_dicts[0][key])

    for key in word_dicts[1]:
        f.write(f'{key}\t{"|".join(list(word_dicts[1][key]))}\n')
