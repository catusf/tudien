#!/usr/bin/env python3

import re
import pinyin

def collect_compound_words():

    DEFINITION_FILE = './dict/Tu-dien-ThienChuu-TranVanChanh.tab'
    PLECO_FLASH_FILE = './dict/Tu-dien-ThienChuu-TranVanChanh.pleco'
    with open(DEFINITION_FILE, 'r', encoding='utf-8') as f:
        lines=f.readlines()
    
    if not lines:
        exit('Emply text files')

    
    CHINESE_PATTERN = r'([一-龥]+)'
    CIRCLED_NUMBERS = r'[①-⑳]'
    SQUARE_BRACKETS = '[\[\]]'

    new_words = []

    for i, line in enumerate(lines):
        items = line.split('\t')
        new_items = []

        if (len(items) != 2):
            exit(f'Line {i+1} has wrong number of tabs: {line}')

        headword = items[0]
        definition = items[1]
        new_items.append(headword)

        viet_pronound = re.split(SQUARE_BRACKETS, definition)

        assert len(viet_pronound), 1

        new_items.append(viet_pronound[0])

        definitions = re.split(CIRCLED_NUMBERS, viet_pronound[2].strip())

        new_defs = [x.strip() for x in definitions if x.strip()]
        
        new_words.append(f'{headword}\t{pinyin.get(headword)}\t{definition}')

        for item in new_defs:
            matches = re.findall(CHINESE_PATTERN, item)

            if not matches:
                continue

            for match in matches:

                if match != headword:
                    new_words.append(f'{match}\t{pinyin.get(match)}\t{item} Mục từ chính {headword} ({viet_pronound[1]}).\n')
        
        pass
    print(f'Original words: {len(lines)}\nNew words: {len(new_words)}')

    with open(PLECO_FLASH_FILE, 'w', encoding='utf-8') as f:
        f.writelines(new_words)

collect_compound_words()
