#!/usr/bin/env python3

import os
import json

filepath = './dict/TudienTonghopPhathoc.json'
fileout = './dict/TudienTonghopPhathoc.tab'

dictdata = json.load(open(filepath, 'rb'))

print(dictdata.keys())

entries = dictdata['WordRaw']
print('Num of entries: {}'.format(len(entries)))

dict_names = {
    1: {'Name':'Từ điển Phật Quang', 'File':'Tu-dien-Phat-Quang'},
    2: {'Name':'Từ điển Phật học Việt Anh - Thiện Phúc', 'File':'Tu-dien-Phat-hoc-Viet-Anh-Thien-Phuc'},
    3: {'Name':'Từ điển Phật học Anh-Hán-Việt', 'File':'Tu-dien-Phat-hoc-Anh-Han-Viet'},
    4: {'Name':'Ngữ vựng Danh từ Thiền học', 'File':'Ngu-vung-Danh-tu-Thien-hoc'},
    5: {'Name':'Từ điển Đạo Uyển', 'File':'Tu-dien-Dao-Uyen'},
    6: {'Name':'Từ điển Phật học Việt Anh - Đồng Loại', 'File':'Tu-dien-Phat-hoc-Viet-Anh-Dong-Loai'},
    7: {'Name':'Từ điển Phật học Việt Anh - Minh Thông', 'File':'Tu-dien-Phat-hoc-Viet-Anh-Minh-Thong'},
    8: {'Name':'Phật Quang Đại từ điển Hán ngữ', 'File':'Phat-Quang-Dai-tu-dien-Han-ngu'},
    9: {'Name':'Rộng mở tâm hồn', 'File':'Rong-mo-tam-hon'},
    10: {'Name':'Từ điển Phật học Tinh tuyển', 'File':'Tu-dien-Phat-hoc-Tinh-tuyen'},
}

dictionaries = {}

use_dicts = {1, 2, 4, 5, 9, 10, } #3, 6, 7, 8}

count = 0
with open(fileout, 'w', encoding='utf-8') as f:
    for i in entries:
        key = i['Word'].strip()
        meaning = i['Mean'].strip()

        if key.find('\n') >= 0:
            key = key.replace('\r\n', '|')

        if meaning.find('\n') >= 0:
            meaning = meaning.replace('\r\n', '|')
        
        dk = i['Dict']

        if dk not in dictionaries:
            dictionaries[dk] = []
        
        dictionaries[dk].append({'Word': key, 'Mean': meaning})

        if len(meaning) and dk in use_dicts:
            f.write('%s\t%s\n' % (key, meaning))

            count = count + 1

print(dictionaries.keys())

for key in dictionaries:
    print('%i\t%i\t%s' % (len(dictionaries[key]), key, dict_names[key]['Name']))

    filename = f"./dict/{dict_names[key]['File']}.tab"

    with open(filename, 'w', encoding='utf-8') as f:
        for e in dictionaries[key]:
            f.write('%s\t%s\n' % (e['Word'], e['Mean']))

print(f'{count} words processed')