import os
import json

filepath = './dict/cactudienphathoc.json'
fileout = './dict/cactudienphathoc.tab'

dictdata = json.load(open(filepath, 'rb'))

print(dictdata.keys())

entries = dictdata['WordRaw']
print('Num of entries: {}'.format(len(entries)))

count = 0
with open(fileout, 'w', encoding='utf-8') as f:
    for i in entries:
        key = i['Word'].strip()
        meaning = i['Mean'].strip()

        if key.find('\n') >= 0:
            key = key.replace('\r\n', '|')

        if meaning.find('\n') >= 0:
            meaning = meaning.replace('\r\n', '|')

        if len(meaning):
            f.write('%s\t%s\n' % (i['Word'], meaning) )
            count = count+1

print(f'{count} words processed')