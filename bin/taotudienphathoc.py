import os
import json

filepath = './dict/cactudienphathoc.json'
fileout = './dict/cactudienphathoc.tab'

dictdata = json.load(open(filepath, 'rb'))

print(dictdata.keys())

entries = dictdata['WordRaw']
print('Num of entries: {}'.format(len(entries)))

dictionaries = {}

use_dicts = {3, 7, 2, 1, 9, 6, 10, 5, 4}
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

        if len(meaning) and dk in use_dicts:
            f.write('%s\t%s\n' % (key, meaning))

            if dk not in dictionaries:
                dictionaries[dk] = []
            else:
                dictionaries[dk].append(i)

            count = count + 1

print(dictionaries.keys())
print(f'{count} words processed')