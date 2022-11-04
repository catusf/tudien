#!/usr/bin/env python3
''' Script to build all dictionaries with all formats
'''
import argparse
from fileinput import filename
import glob
import os.path
import os
import subprocess
from iso_language_codes import language_name
import shlex

def readDicInfo(filepath):
    ''' Read metadata of dictionary with the following format

            Name = Dictionary of xyz
            Description = Description of this dictionary
            Source = en
            Target = vi
            Inflections = "NoInflections.txt"
            Version = 1.1

        Target and Source are the ISO 2-character codes of the language.
        Name, Source and Target are mandatory fields.
    '''

    valuemap = {}

    try:
        file = open(filepath, encoding='utf-8')

        lines = file.readlines()

        for line in lines:
            line = line.strip()

            if not line:
                continue
         
            key, value = line.split('=')

            valuemap[key.strip()] = value.strip()

        valuemap['FullSource'] = language_name(valuemap['Source'])
        valuemap['FullTarget'] = language_name(valuemap['Target'])

        keys = ['Name', 'Source', 'Target'] # Mandatory keys

        for i, k in enumerate(keys):
            if not k in valuemap:
                print(f'Missing key: "{keys[i]}"')

                return None
            
    except IOError as err:
        print(err)
        return None

#    print(valuemap)

    return valuemap


def main() -> None:
    parser = argparse.ArgumentParser(description='Convert all dictionaries in a folder',
        usage='Usage: python convert_all.py --input-folder ./mydictdata --output-folder ./myoutputdict --extension tsv')
    parser.add_argument('-i', '--input_folder', help='Input folder containing .tsv and .dfo files')
    parser.add_argument('-o', '--output_folder', help='Output folder containing dictionary files')
    parser.add_argument('-e', '--extension', default='tsv', help='Filename extention for input dictionary files. Default is .tsv')
    parser.add_argument('-m', '--metadata', default='dfo', help='Filename extention for input metadata for dictionary. Default is .dfo')

    args, array = parser.parse_known_args()

    input_folder = args.input_folder
    output_folder = args.output_folder
    extension = args.extension
    metadata = args.metadata

    if input_folder:
        glob1 = input_folder + f'/*.{metadata}'
        metafilelist = sorted(glob.glob(input_folder + f'/*.{metadata}'), reverse=True)
        datafilelist = sorted(glob.glob(input_folder + f'/*.{extension}'), reverse=True)

        ## Need to verify two list ate of the same file

    subprocess.run(shlex.split(f'mkdir -p {output_folder}/stardict'))
    subprocess.run(shlex.split(f'mkdir -p {output_folder}/epub'))
    subprocess.run(shlex.split(f'mkdir -p {output_folder}/kobo'))
    subprocess.run(shlex.split(f'mkdir -p {output_folder}/lingvo'))
    subprocess.run(shlex.split(f'mkdir -p {output_folder}/kindle'))

    subprocess.run(shlex.split(f'mkdir -p {input_folder}/kindle'))

    for filepath, datafile in zip(metafilelist, datafilelist):
        folder, filename = os.path.split(filepath)
        filebase, fileext = os.path.splitext(filename)

        data = readDicInfo(filepath)

        if not data:
            continue

        # Generare HTML file for Kindle dictionary
        if 'Inflections' in data:
            inflections = {data['Inflections']}
        else:
            inflections = './ext-dict/NoInflections.txt'

        cmd_line = f"python ./bin/tab2opf.py --title \"{data['Name']}\" --source {data['Source']} --target {data['Target']} {datafile} --inflection {inflections}"
        print(cmd_line)
        subprocess.run(shlex.split(cmd_line))

        # Generate .mobi dictionary from opf+html file
        cmd_line = f"wine ./bin/mobigen/mobigen.exe -unicode -s0 {filebase}.opf"
        print(cmd_line)
        subprocess.run(shlex.split(cmd_line))

        # Move input file to final destinations. Using subprocess.call
        cmd_line = f'mv *.html *.opf {input_folder}/kindle/'
        print(cmd_line)
        subprocess.call(cmd_line, shell=True)
        
        cmd_line = f'mv {filebase}.mobi {output_folder}/kindle/'
        print(cmd_line)
        subprocess.call(cmd_line, shell=True)
         

        # # Generare StarDict dictionary
        # out_path = os.path.join(output_folder, f'stardict/{filebase}.ifo')
        # cmd_line = f"pyglossary --read-format=Tabfile --source-lang={data['Source']} --target-lang={data['Target']} --name=\"{data['Name']}\" {datafile} {out_path}"
        # print(cmd_line)
        # subprocess.run(shlex.split(cmd_line))

        # # Generare Epub dictionary
        # out_path = os.path.join(output_folder, f'epub/{filebase}.epub')
        # cmd_line = f"pyglossary --read-format=Tabfile --source-lang={data['Source']} --target-lang={data['Target']} --name=\"{data['Name']}\" {datafile} {out_path}"
        # print(cmd_line)
        # subprocess.run(shlex.split(cmd_line))

        # # Generare Kobo dictionary
        # out_path = os.path.join(output_folder, f'kobo/{filebase}.kobo.zip')
        # cmd_line = f"pyglossary --read-format=Tabfile --source-lang={data['Source']} --target-lang={data['Target']} --name=\"{data['Name']}\" {datafile} {out_path}"
        # print(cmd_line)
        # subprocess.run(shlex.split(cmd_line))

        # # Generare Lingvo dictionary
        # out_path = os.path.join(output_folder, f'lingvo/{filebase}.dsl')
        # cmd_line = f"ruby ./dsl-tools/tab2dsl/tab2dsl.rb --from-lang {data['FullSource']} --to-lang {data['FullTarget']} --dict-name \"{data['Name']}\" --output {out_path} {datafile}"
        # print(cmd_line)
        # subprocess.run(shlex.split(cmd_line))
        # pass


if __name__ == "__main__":
    main()
