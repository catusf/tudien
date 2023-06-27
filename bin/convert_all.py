#!/usr/bin/env python3
''' Script to build all dictionaries with all formats
    Usage:
    ./bin/convert_all.py --input_folder=./ext-dict --output_folder=./ext-output --extension=tab
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

DEBUG_FLAG = False

def main() -> None:
    parser = argparse.ArgumentParser(description='Convert all dictionaries in a folder',
        usage='Usage: python convert_all.py --input-folder=./mydictdata --output-folder=./myoutputdict --extension=tsv')
    parser.add_argument('-i', '--input_folder', required=True, help='Input folder containing .tsv and .dfo files')
    parser.add_argument('-o', '--output_folder', required=True, help='Output folder containing dictionary files')
    parser.add_argument('-e', '--extension', default='tsv', help='Filename extention for input dictionary files. Default is .tsv')
    parser.add_argument('-m', '--metadata', default='dfo', help='Filename extention for input metadata for dictionary. Default is .dfo')

    args, array = parser.parse_known_args()

    input_folder = args.input_folder.replace(' ', '\\ ')
    output_folder = args.output_folder.replace(' ', '\\ ')
    extension = args.extension
    metadata = args.metadata

    if input_folder:
        metafilelist = sorted(glob.glob(input_folder + f'/*.{metadata}'), reverse=True)
        datafilelist = sorted(glob.glob(input_folder + f'/*.{extension}'), reverse=True)
        zippdatafilelist = sorted(glob.glob(input_folder + f'/*.bz2'), reverse=True)

        meta_dict = {}
        data_dict = {}
        print(f'Len of metafilelist: {len(metafilelist)}')
        print(f'Len of datafilelist: {len(datafilelist)}')
        print(f'Len of compressed datafilelist: {len(zippdatafilelist)}')

        # Keep only pairs of metadata and dict data files
        for filepath in metafilelist:
            folder, filename = os.path.split(filepath)
            filebase = filename.split('.')[0]

            meta_dict[filebase] = filepath
        
        bothdatalist = datafilelist+zippdatafilelist

        for filepath in bothdatalist:
            folder, filename = os.path.split(filepath)
            filebase = filename.split('.')[0]

            data_dict[filebase] = filepath

        common_keys = sorted(list(meta_dict.keys() & data_dict.keys()))

        print(common_keys)
        
        metafilelist.clear()
        datafilelist.clear()

        for key in common_keys:
            metafilelist.append(meta_dict[key])

            datafile = data_dict[key]

            # If datafile is a .bz2
            if datafile.find('.bz2') >= 0:
                
                cmd_line = f'bzip2 -kd \"{datafile}\"'
                print(cmd_line)

                if not DEBUG_FLAG:
                    subprocess.call(cmd_line, shell=True)

            datafilelist.append(datafile.replace('.bz2', ''))


        print(f'Len of checked datafilelist: {len(datafilelist)}')
        
    # Need to consider the case with bz2 compressed files
    subprocess.call(f'mkdir -p {input_folder}/kindle', shell=True)

    subprocess.call(f'rm -r {output_folder}/*', shell=True)

    dirs = ['stardict', 'epub', 'kobo', 'lingvo', 'kindle', 'dictd']

    for dir in dirs:
        subprocess.call(f'mkdir -p {output_folder}/{dir}', shell=True)

    # use_only_these = {'Tu-dien-ThienChuu-TranVanChanh'}
    for filepath, datafile in zip(metafilelist, datafilelist):
        folder, filename = os.path.split(filepath)
        filebase, fileext = os.path.splitext(filename)

        # if filebase not in use_only_these:
        #     continue

        data = readDicInfo(filepath)

        # Add quote to wrap long filename/path
        datafile = datafile.replace(' ', '\\ ')
        dataCreator = data['Owner/Editor'].replace(' ', '\\ ')
        if not dataCreator:
            dataCreator = 'Panthera Tigris'.replace(' ', '\\ ')
            
        dataTarget = data['Target']
        dataSource = data['Source']
        dataFullSource = data['FullSource']
        dataFullTarget = data['FullTarget']
        dataName = data["Name"].replace(' ', '\\ ')
        htmlDir = f'kindle'
        htmlOutDir = f'{input_folder}/{htmlDir}'

        if not data:
            continue

        INFLECTION_DIR = './bin/inflections'
        INFLECTION_NONE = 'inflections-none.tab'

        # Generare HTML file for Kindle dictionary
        if 'Inflections' in data and data['Inflections']:
            inflections = f'\"{INFLECTION_DIR}/{data["Inflections"]}\"'
        else:
            inflections = f'{INFLECTION_DIR}/{INFLECTION_NONE}'

        cmd_line = f"python ./bin/tab2opf.py --title={dataName} --source={dataSource} --target={dataTarget} --inflection={inflections} --outdir={htmlOutDir} --creator={dataCreator} --publisher={dataCreator} {datafile}"
        print(cmd_line)
        subprocess.run(shlex.split(cmd_line))

        # Generate .mobi dictionary from opf+html file
        out_path = f'{htmlOutDir}/{filebase}.opf'.replace(' ', '\\ ')
        cmd_line = f"wine ./bin/mobigen/mobigen.exe -unicode -s0 {out_path}"
        print(cmd_line)
        subprocess.run(shlex.split(cmd_line))

        if DEBUG_FLAG:
            continue

        # Move input file to final destinations. Using subprocess.call
        # cmd_line = f'rm *.html *.opf'
        # print(cmd_line)
        # subprocess.call(cmd_line, shell=True)

        cmd_line = f'mv {htmlOutDir}/*.mobi {output_folder}/kindle/'
        print(cmd_line)
        subprocess.call(cmd_line, shell=True)

        pyglossary = './pyglossary/main.py'

        # Generare StarDict dictionary
        out_path = os.path.join(output_folder, f'stardict/{filebase}.ifo').replace(' ', '\\ ')
        cmd_line = f"{pyglossary} --ui=none --read-format=Tabfile --source-lang={dataSource} --target-lang={dataTarget} --name={dataName} {datafile} {out_path}"
        print(cmd_line)
        subprocess.run(shlex.split(cmd_line))

        # Compress to make one zip file for one startdict
        out_path = os.path.join(output_folder, f'stardict/{filebase}.*')
        zip_path = os.path.join(output_folder, f'{filebase}.stardict.zip')
        cmd_line = f"zip -j {zip_path} {out_path}"
        print(cmd_line)
        subprocess.call(cmd_line, shell=True)

        # Generare dictd dictionary
        out_path = os.path.join(output_folder, f'dictd/{filebase}.index').replace(' ', '\\ ')
        cmd_line = f"{pyglossary} --ui=none --read-format=Tabfile --source-lang={dataSource} --target-lang={dataTarget} --name={dataName} {datafile} {out_path}"
        print(cmd_line)
        subprocess.run(shlex.split(cmd_line))

        # Compress to make one zip file for one dictd
        out_path = os.path.join(output_folder, f'dictd/{filebase}.*')
        zip_path = os.path.join(output_folder, f'{filebase}.dictd.zip')
        cmd_line = f"zip -j {zip_path} {out_path}"
        print(cmd_line)
        subprocess.call(cmd_line, shell=True)

        # Generare Epub dictionary
        out_path = os.path.join(output_folder, f'epub/{filebase}.epub').replace(' ', '\\ ')
        cmd_line = f"{pyglossary} --ui=none --read-format=Tabfile --source-lang={dataSource} --target-lang={dataTarget} --name={dataName} {datafile} {out_path}"
        print(cmd_line)
        subprocess.run(shlex.split(cmd_line))

        # Generare Kobo dictionary
        out_path = os.path.join(output_folder, f'kobo/{filebase}.kobo.zip').replace(' ', '\\ ')
        cmd_line = f"{pyglossary} --ui=none --read-format=Tabfile --source-lang={dataSource} --target-lang={dataTarget} --name={dataName} {datafile} {out_path}"
        print(cmd_line)
        subprocess.run(shlex.split(cmd_line))

        # Generare Lingvo dictionary
        out_path = os.path.join(output_folder, f'lingvo/{filebase}.dsl').replace(' ', '\\ ') 
        cmd_line = f"ruby ./dsl-tools/tab2dsl/tab2dsl.rb --from-lang {dataFullSource} --to-lang {dataFullTarget} --dict-name {dataName} --output {out_path} {datafile}"
        print(cmd_line)
        subprocess.run(shlex.split(cmd_line))
        pass

if __name__ == "__main__":
    main()
