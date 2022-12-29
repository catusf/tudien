import os
import unimorph


def split_inflections(results):
    if not results.strip():
        return []

    lines = results.strip().split('\n')
    items = []
    for l in lines:
        items.append(l.split('\t'))

    return items


def split_inflection_words(results):
    if not results.strip():
        return []

    items = split_inflections(results)
    words = set()
    skips = set(['uncountable', 'countable', items[0][0]])

    for i in items:
        if len(i) > 1 and i[1].isalpha() and not i[1] in skips:
            words.add(i[1])

    return words

# lang = 'deu'

# unimorph.download_unimorph(lang)
# unimorph.load_dataset(lang)
# #print(unimorph.get_list_of_datasets())
# #words = ['think', 'sing', 'flower', 'man', 'smart', 'beautiful']
# words = ['recken', ]

# for w in words:
#     l = unimorph.inflect_word(w, lang=lang)

#     print(f'Word: {w}: {split_inflection_words(l)}')


language_files = {
    # 'ita': 'star_yviet.tab',
    # 'ces': 'star_secviet.tab',
    # 'spa': 'star_tbnviet.tab',
    # 'rus': 'star_ngaviet.tab',
    # 'nno': 'star_nauyviet.tab',
    'por': 'star_bdnviet.tab',
    # 'deu': 'star_ducviet.tab',
    # 'fra': 'star_phapviet.tab',
    # 'eng': 'star_anhviet.tab',
}

print(f'Getting inflections for {len(language_files)} languages')

for lang in language_files:
    print(f'----- Getting inflections for {lang} -----')
    unimorph.download_unimorph(lang)
    unimorph.load_dataset(lang)

    filename = language_files[lang]
    filepath = os.path.join('./ext-dict/', filename)
    outfilepath = os.path.join('./bin/inflections/', f'inflection-{lang}.tab')

    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.read().split('\n')
        f.close()

        words = []

        for l in lines:
            items = l.split('\t')
            if items[0].isalpha():
                words.append(items[0])
        num_words = len(words)
        print(f'Number of words: {num_words}')
        inflections = 0

        with open(outfilepath, 'w', encoding='utf-8') as o:
            for i, w in enumerate(words):
                results = unimorph.inflect_word(w, lang=lang)
                items = split_inflection_words(results)

                inflections += len(items)

                # if inflections > 100:
                #     break

                print(
                    f"{i}/{num_words} (#infl: {inflections}) {w}\t{'|'.join(items)}")
                if l:
                    o.write(f"{w}\t{'|'.join(items)}\n")

        print(f'===== Number of inflections: {inflections} ======')
