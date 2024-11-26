#!/usr/bin/env python3
''' Script to build all dictionaries with all formats
    Usage:
    ./bin/convert_all.py --input_folder=./ext-dict --output_folder=./ext-output --extension=tab
'''

import argparse
import glob
import os
import subprocess
import shlex
from iso_language_codes import language_name
from multiprocessing import Pool, cpu_count


INFLECTION_DIR = './bin/inflections'
INFLECTION_NONE = 'inflections-none.tab'


def read_dic_info(filepath):
    ''' Read metadata of dictionary with the following format

        Name = Dictionary of xyz
        Description = Description of this dictionary
        Source = en
        Target = vi
        Inflections = "NoInflections.txt"
        Version = 1.1

        Target and Source are the ISO 2-character codes of the language.
        Name, Source, and Target are mandatory fields.
    '''

    valuemap = {}
    
    try:
        with open(filepath, encoding='utf-8') as file:
            lines = file.readlines()
            for line in lines:
                line = line.strip()
                if not line:
                    continue
                key, value = line.split('=', 1)  # Limit split to 1 to avoid issues with '=' in value
                valuemap[key.strip()] = value.strip()

        valuemap['FullSource'] = language_name(valuemap['Source'])
        valuemap['FullTarget'] = language_name(valuemap['Target'])

        # Check mandatory fields
        keys = ['Name', 'Source', 'Target']
        for k in keys:
            if k not in valuemap:
                print(f'Missing key: \"{k}\"')
                return None

    except IOError as err:
        print(f"Error reading file {filepath}: {err}")
        return None

    return valuemap


def process_dictionary(args):
    filepath, datafile, output_folder, input_folder = args
    data = read_dic_info(filepath)
    if not data:
        return

    # Prepare data for conversion
    datafile = shlex.quote(datafile)
    data_creator = shlex.quote(data.get('Owner/Editor', 'Panthera Tigris'))
    data_name = shlex.quote(data['Name'])
    data_target = data['Target']
    data_source = data['Source']
    data_full_source = data['FullSource']
    data_full_target = data['FullTarget']
    html_out_dir = os.path.join(input_folder, 'kindle')

    # Generate HTML file for Kindle dictionary
    inflections = f'{INFLECTION_DIR}/{data.get("Inflections", INFLECTION_NONE)}'
    
    cmd_line = f"python ./bin/tab2opf.py --title={data_name} --source={data_source} --target={data_target} " \
               f"--inflection={inflections} --outdir={html_out_dir} --creator={data_creator} --publisher={data_creator} {datafile}"
    cmd_line = cmd_line.replace("\\", "/")
    print(cmd_line)
    try:
        subprocess.run(shlex.split(cmd_line), check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error generating HTML for Kindle dictionary: {e}")

    # Generate .mobi dictionary from opf+html file
    out_path = os.path.join(html_out_dir, f'{os.path.splitext(os.path.basename(filepath))[0]}.opf')
    cmd_line = f"wine ./bin/mobigen/mobigen.exe -unicode -s0 {shlex.quote(out_path)}"
    # cmd_line = f"./bin/mobigen/mobigen.exe -unicode -s0 {shlex.quote(out_path)}"
    cmd_line = cmd_line.replace("\\", "/")
    print(cmd_line)
    try:
        subprocess.run(shlex.split(cmd_line), check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error generating .mobi dictionary: {e}")

    # Move generated .mobi file to final destination
    cmd_line = f'mv {shlex.quote(html_out_dir)}/*.mobi {shlex.quote(os.path.join(output_folder, "kindle"))}/'
    try:
        subprocess.run(cmd_line, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error moving .mobi file: {e}")

    # Generate other dictionary formats using PyGlossary
    pyglossary = 'pyglossary'
    formats = [
        ('Yomichan', 'yomitan', 'yomitan.zip'),
        ('StarDict', 'stardict', 'ifo'),
        ('Dictd', 'dictd', 'index'),
        ('Epub', 'epub', 'epub'),
        ('Kobo', 'kobo', 'kobo.zip'),
    ]
    for write_format, folder, extension in formats:
        out_path = os.path.join(output_folder, folder, f'{os.path.splitext(os.path.basename(filepath))[0]}.{extension}')
        cmd_line = f"{pyglossary} --ui=none --read-format=Tabfile --write-format={write_format} " \
                   f"--source-lang={data_source} --target-lang={data_target} --name={data_name} {datafile} {shlex.quote(out_path)}"
        print(cmd_line)
        try:
            subprocess.run(shlex.split(cmd_line), check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error generating {write_format} dictionary: {e}")

    # Generate Lingvo dictionary
    out_path = os.path.join(output_folder, 'lingvo', f'{os.path.splitext(os.path.basename(filepath))[0]}.dsl')
    cmd_line = f"ruby ./dsl-tools/tab2dsl/tab2dsl.rb --from-lang {shlex.quote(data_full_source)} --to-lang {shlex.quote(data_full_target)} " \
               f"--dict-name {data_name} --output {shlex.quote(out_path)} {datafile}"
    print(cmd_line)
    try:
        subprocess.run(shlex.split(cmd_line), check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error generating Lingvo dictionary: {e}")


def main() -> None:
    parser = argparse.ArgumentParser(description='Convert all dictionaries in a folder')
    parser.add_argument('-i', '--input_folder', required=True, help='Input folder containing .tsv and .dfo files')
    parser.add_argument('-o', '--output_folder', required=True, help='Output folder containing dictionary files')
    parser.add_argument('-e', '--extension', default='tab', help='Filename extension for input dictionary files. Default is .tab')
    parser.add_argument('-m', '--metadata', default='dfo', help='Filename extension for input metadata for dictionary. Default is .dfo')

    args = parser.parse_args()

    input_folder = args.input_folder
    output_folder = args.output_folder
    extension = args.extension
    metadata = args.metadata

    # Gather metadata and data files
    metafilelist = sorted(glob.glob(os.path.join(input_folder, f'*.{metadata}')), reverse=True)
    datafilelist = sorted(glob.glob(os.path.join(input_folder, f'*.{extension}')), reverse=True)
    zippdatafilelist = sorted(glob.glob(os.path.join(input_folder, '*.bz2')), reverse=True)

    meta_dict = {os.path.splitext(os.path.basename(filepath))[0]: filepath for filepath in metafilelist}
    data_dict = {os.path.splitext(os.path.basename(filepath))[0]: filepath for filepath in datafilelist + zippdatafilelist}

    common_keys = sorted(list(meta_dict.keys() & data_dict.keys()))
    
    metafilelist = [meta_dict[key] for key in common_keys]
    datafilelist = [data_dict[key].replace('.bz2', '') for key in common_keys]

    # Prepare output directories
    os.makedirs(output_folder, exist_ok=True)
    dirs = ['stardict', 'epub', 'kobo', 'lingvo', 'kindle', 'dictd', 'yomitan']
    for dir in dirs:
        os.makedirs(os.path.join(output_folder, dir), exist_ok=True)

    # Use multiprocessing to process dictionaries
    args_list = [(filepath, datafile, output_folder, input_folder) for filepath, datafile in zip(metafilelist, datafilelist)]
    # process_dictionary(args_list[0])
    with Pool(cpu_count()) as pool:
        pool.map(process_dictionary, args_list)

if __name__ == "__main__":
    main()
