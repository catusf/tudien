import os
import json

filepath = './dict/cactudienphathoc.json'
fileout = './dict/cactudienphathoc.txt'

dictdata = json.load(open(filepath, 'rb'))

print(dictdata.keys())

with open(fileout, 'w', encoding='utf-8') as f:
    for i in dictdata['WordRaw']:
        f.write('%s\t%s\n' % (i['Word'], i['Mean']) )

pass