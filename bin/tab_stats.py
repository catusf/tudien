''' Statistics for the dictionary data file
'''
import argparse
import pathlib
import collections
import string

def frequency(l):
    cp=[]
    maxl=[]
    minl=[]

    ctr = collections.Counter(l)

    print(ctr.most_common())
    for i in ctr:
        r=ctr[i]
        cp.append(r)
    p=max(cp)
    q=min(cp)
    #print(cp)
    for i in ctr:
        if ctr[i]==p:
            maxl.append(i)
        if ctr[i]==q:
            minl.append(i)
    
    return (sorted(minl),sorted(maxl))

COUNT = 10

def main() -> None:
    parser = argparse.ArgumentParser(description='Convert all dictionaries in a folder',
        usage='Usage: python tab_stats.py --input data.tab --output data.stats')
    parser.add_argument('-i', '--input', help='Input folder containing .tsv and .dfo files')
    parser.add_argument('-o', '--output', help='Output folder containing dictionary files')

    args, array = parser.parse_known_args()
    inputfile = args.input
    ouputfile = args.output

    inputpath = pathlib.Path(inputfile)

    if not ouputfile:
        ouputpath = inputpath.with_suffix('.stats')
    else:
        ouputpath = pathlib.Path(ouputfile)

    with open(inputpath, encoding='utf-8', errors='replace') as infile:
        lines = infile.readlines()
        text = '\n'.join(lines).replace('\\n', '\n')

        print('# Character frequency')
        counterchar = collections.Counter(text)

        print(counterchar.most_common(COUNT))
        print(counterchar.most_common()[:-COUNT-1:-1])

        print('# Word frequency')
        words  = [word.strip(string.punctuation + '\n') for word in text.split()]
        
        counterword = collections.Counter(words)

        print(counterword.most_common(COUNT))
        print(counterword.most_common()[:-COUNT-1:-1])

        print(f'Number of line: {len(lines)}')
        for i, line in enumerate(lines):
            items = line.split('\t')
            no_items = len(items)

            if no_items != 2:
                print(f'### Error on line {i}: Wrong number of items ({len(items)})')
                for i in items:
                    print(f'{len(i)}: {i}')

            if no_items == 0:
                print(f'### Error on line {i}: No items')
            elif no_items > 0:
                head = items[0]
                if not head.strip():
                    print(f'### Error on line {i}: Empty headword')
            elif no_items > 1:
                define = items[1]
                if not define.strip():
                    print(f'### Error on line {i}: Empty definition')

        # with open(ouputpath, encoding='utf0-8') as outfile:

if __name__ == "__main__":
    main()
