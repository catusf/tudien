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
import shutil
from iso_language_codes import language_name
from multiprocessing import Pool, cpu_count
import time

class Timer:
    """
    A Timer class to measure elapsed time with start, stop, and display functionalities.
    """
    def __init__(self):
        self.start_time = None
        self.end_time = None

    def start(self):
        """Start the timer."""
        self.start_time = time.time()
        self.end_time = None
        print("Timer started.")

    def stop(self):
        """Stop the timer."""
        if self.start_time is None:
            raise ValueError("Timer has not been started.")
        self.end_time = time.time()
        print("Timer stopped.")

    def elapsed_time(self):
        """Calculate and return the elapsed time in minutes, seconds, and milliseconds."""
        if self.start_time is None:
            raise ValueError("Timer has not been started.")
        if self.end_time is None:
            raise ValueError("Timer has not been stopped.")

        elapsed_time = self.end_time - self.start_time
        minutes = int(elapsed_time // 60)
        seconds = int(elapsed_time % 60)
        milliseconds = int((elapsed_time * 1000) % 1000)

        return {
            'minutes': minutes,
            'seconds': seconds,
            'milliseconds': milliseconds
        }

    def display_elapsed(self, label=""):
        """Display the elapsed time."""
        elapsed = self.elapsed_time()
        print(f"Label: {label}\nElapsed time: {elapsed['minutes']}:{elapsed['seconds']}.{elapsed['milliseconds']}s")


INFLECTION_DIR = './bin/inflections'
INFLECTION_NONE = 'inflections-none.tab'

RUN_ON_WINDOWS = False

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


def process_dictionary(data_tuple):
    ''' Process a dictionary by converting it to multiple formats (e.g., Kindle, StarDict, etc.) '''
    data = data_tuple[0]
    # Access data directly from the dictionary passed by pool.map
    filepath = data["filepath"]
    datafile = data["datafile"]
    output_folder = data["output_folder"]
    # input_folder = data["input_folder"]
    data_source = data["data_source"]
    data_target = data["data_target"]
    data_name = data["data_name"]
    data_full_source = data["data_full_source"]
    data_full_target = data["data_full_target"]
    html = data["html_out_dir"]
    inflections = data["inflections"]
    data_creator = data["data_creator"]
    
    cmd_line = f"python bin/tab2opf.py --title={data_name} --source={data_source} --target={data_target} " \
               f"--inflection={inflections} --outdir={html} --creator={data_creator} --publisher={data_creator} {datafile}"
    # cmd_line = cmd_line.replace("\\", "/")
    print(cmd_line)
    try:
        subprocess.run(shlex.split(cmd_line), check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error generating HTML for Kindle dictionary: {e}")

    # Generate .mobi dictionary from opf+html file
    out_path = os.path.join(html, f'{os.path.splitext(os.path.basename(filepath))[0]}.opf')
    
    if RUN_ON_WINDOWS:
        cmd_line = f"./bin/mobigen/mobigen.exe -unicode -s0 {shlex.quote(out_path)}"
    else:
        cmd_line = f"wine ./bin/mobigen/mobigen.exe -unicode -s0 {shlex.quote(out_path)}"

    # cmd_line = cmd_line.replace("\\", "/")
    print(cmd_line)
    try:
        subprocess.run(shlex.split(cmd_line), check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error generating .mobi dictionary: {e}")

    # Move generated .mobi file to final destination
    if RUN_ON_WINDOWS:
        cmd_line = f'mv {html}/*.mobi {output_folder}/kindle/'
    else:
        cmd_line = f'mv {html}/*.mobi {output_folder}/kindle/'
    try:
        subprocess.run(cmd_line, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error moving .mobi file: {e}")

    # Generate other dictionary formats using PyGlossary
    pyglossary = 'pyglossary'
    formats = [
        ('Yomichan', 'yomitan', 'yomitan.zip'),
        ('Stardict', 'stardict', 'ifo'),
        ('DictOrg', 'dictd', 'index'),
        ('Epub2', 'epub', 'epub'),
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

DEBUG_FLAG = False

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
    
    args_list = []

    for filepath, datafile in zip(metafilelist, datafilelist):
        folder, filename = os.path.split(filepath)
        filebase, fileext = os.path.splitext(filename)

        # if filebase not in use_only_these:
        #     continue

        data = read_dic_info(filepath)

        # Add quote to wrap long filename/path
        datafile = datafile.replace(' ', '\\ ')
        dataCreator = data['Owner/Editor'].replace(' ', '\\ ')
        if not dataCreator:
            dataCreator = 'Panthera Tigris'.replace(' ', '\\ ')
            
        if not data:
            continue

        INFLECTION_DIR = './bin/inflections'
        INFLECTION_NONE = 'inflections-none.tab'

        # Generare HTML file for Kindle dictionary
        if 'Inflections' in data and data['Inflections']:
            inflections = f'\"{INFLECTION_DIR}/{data["Inflections"]}\"'
        else:
            inflections = f'{INFLECTION_DIR}/{INFLECTION_NONE}'

        item = {
                "filepath": filepath,
                "datafile": datafile,
                "data_creator": data["Owner/Editor"],
                "output_folder": output_folder,
                "input_folder": input_folder,
                "inflections": inflections,
                "data_source": data['Source'],
                "data_target": data['Target'],
                "data_name": data["Name"].replace(' ', '\\ '), # Prvents console space issues
                "data_full_source": data['FullSource'],
                "data_full_target": data['FullTarget'],
                "html_out_dir": f'{input_folder}/kindle',
            }
        args_list.append((item, 1))
        pass
    # Prepare output directories
    # Need to consider the case with bz2 compressed files
    subprocess.call(f'mkdir -p {input_folder}/kindle', shell=True)

    subprocess.call(f'rm -r {output_folder}/*', shell=True)

    dirs = ['stardict', 'epub', 'kobo', 'lingvo', 'kindle', 'dictd', 'yomitan']

    for dir in dirs:
        subprocess.call(f'mkdir -p {output_folder}/{dir}', shell=True)


    dirs = [output_folder, os.path.join(input_folder, "kindle"), 'stardict', 'epub', 'kobo', 'lingvo', 'kindle', 'dictd', 'yomitan']
    for dir in dirs:
        os.makedirs(os.path.join(output_folder, dir), exist_ok=True)
    
    # Use multiprocessing to process dictionaries
    # with Pool(cpu_count()) as pool:
    # print(args_list[:3])

    # process_dictionary(args_list[0])
    with Pool(cpu_count()) as pool:
        pool.map(process_dictionary, args_list[:4])
    #     # pool.map(lambda Dict: process_dictionary(**Dict), args_list)

if __name__ == "__main__":
    timer = Timer()
    timer.start()
    main()
    timer.stop()
    timer.display_elapsed("2 cores")
