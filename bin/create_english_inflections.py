#!/usr/bin/env python3

# from nltk.corpus import words
from pattern.en import lexeme #conjugate, lemma, 
from pattern.en import pluralize

# List of common English words
wordlist = set(open("../misc/354984si.ngl").read().split())

keys = set(open("english_keys.txt", encoding='utf-8').read().split())

def getInflections(key):

    inflections=set()
    # print('"%s"' % key)
    
    if key.isalpha():
    
        try:
            try:
                lexeme(key)
            except:
                pass
                
            inflections.add(lexeme(key)) # get all lexem inflections of words
            inflections.add(pluralize(key)) # add plural inflections
            
            inflections.intersection_update(wordlist)
                
            print(inflections)

        except:
            pass
            # print("Unexpected error")

    return inflections
    
keyfile = open("english_inflections.txt", "w", encoding='utf-8')

try:
    print(lexeme('be'))
except:
    pass
    
print(lexeme('be'))
print(lexeme('conclusion'))
print(lexeme('harlot'))


print(pluralize('be'))
print(pluralize('conclusion'))
print(pluralize('harlot'))

for k in keys:
    # print(lexeme(k))
    # print(pluralize(k))
    
    inflections=set()
    # print('"%s"' % key)

    inflections.update(lexeme(k)) # get all lexem inflections of words
    inflections.add(pluralize(k)) # add plural inflections
    if k in inflections:
        inflections.remove(k)
    
    inflections.intersection_update(wordlist)
        
    # print(inflections)
    
    if len(inflections):
        keyfile.write('%s\t%s\n' % (k, '|'.join(inflections)))
        
keyfile.close()

