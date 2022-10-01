import os
import json

filepath = './dict/cactudienphathoc.json'
fileout = './dict/cactudienphathoc.txt'

dictdata = json.load(open(filepath, 'rb'))

print(dictdata.keys())

entries = dictdata['WordRaw']
print('Num of entries: {}'.format(len(entries)))

with open(fileout, 'w', encoding='utf-8') as f:
    for i in entries:
        f.write('%s\t%s\n' % (i['Word'], i['Mean']) )

print('Done')