
file_names = ['ext-dict/star_anhvietanh.tab', 'ext-dict/SPDict-Anh-Viet-Anh.tab']
word_sets = []

print(f'Set A: {file_names[0]} - Set B: {file_names[1]}')
for filename in file_names:
    with open(filename, 'r', encoding='utf-8') as f:
        lines = f.read().split('\n')
        f.close()

        words = []

        for l in lines:
            items = l.split('\t')
#            if items[0].isalpha():
            words.append(items[0])
                
        word_sets.append(set(words))

print(f'No. words: set A: {len(word_sets[0])} set B: {len(word_sets[1])}')

print(f'No. intersected words: {len(word_sets[0].intersection(word_sets[1]))}')

print(f'No. different words in A not in B: {len(word_sets[0].difference(word_sets[1]))}') # \n{word_sets[0].difference(word_sets[1])}

print(f'No. different words in B not in A: {len(word_sets[1].difference(word_sets[0]))}')

print(f'No. symmetricly different words in B not in A: {len(word_sets[1].symmetric_difference(word_sets[0]))}')

#print(f'No. different words in B not in A: {word_sets[1].difference(word_sets[0])}')
