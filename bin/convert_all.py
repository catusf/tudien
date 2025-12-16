#!/usr/bin/env python3
"""Script to build all dictionaries with all formats

Usage:
./bin/convert_all.py --input_folder=./dict --output_folder=./output --extension=tab
"""

import argparse
import glob
import os
import re
import shlex
import shutil
import subprocess
from fileinput import filename
from pathlib import Path

from dict_summary import parse_toml_file
from iso_language_codes import language_name

# List of dictionary formats to generate using pyglossary
DICT_FORMATS = [
    # DictType, foldername, file ending, need zip
    ("Yomichan", "yomitan", "yomitan.zip", False),
    ("Epub2", "epub", "epub", False),
    ("Kobo", "kobo", "kobo.zip", False),
    ("Stardict", "stardict", "ifo", True),
    ("DictOrg", "dictd", "index", True),
    ("Aard2Slob", "aard", "slob", False),
]

# List of directory formats and their file patterns
DIR_FORMATS = [
    # (Dir, File pattern)
    ("stardict", "*.stardict.zip"),
    ("epub", "*.epub"),
    ("kobo", "*.kobo.zip"),
    ("lingvo", "*.dsl.dz"),
    ("kindle", "*.mobi"),
    ("dictd", "*.dictd.zip"),
    ("yomitan", "*.yomitan.zip"),
    ("mdict", "*.mdx"),
    ("pleco", "*.pleco.zip"),
    ("aard", "*.slob"),
]

def execute_shell(cmd_line, message="", printout=True):
    """
    Executes a shell command and handles any errors that occur during execution.

    Parameters:
    cmd_line (str): The command line string to be executed.
    message (str): An optional message to include in error output if the command fails.
    printout (bool): If True, prints the command line before execution.

    Returns:
    bool: True if the command executes successfully, False if an error occurs.
    """  # noqa: D401
    try:
        if printout:
            print(cmd_line)

        # subprocess.run(shlex.split(cmd_line), check=True)
        subprocess.call(cmd_line, shell=True)
        return True
    except subprocess.CalledProcessError as e:
        if message:
            print(f"Error {message}: {e}")
        else:
            print(f"Error executing shell: {e}")

        return False


DEBUG_FLAG = False

def escape_forbidden_chars(text, forbidden_chars=r" (){}[]$*?^|<>\\"):
    """
    Escapes forbidden characters in a given text.

    Args:
        text (str): The input string to process.
        forbidden_chars (str): A string containing characters to escape (default: common special chars).

    Returns:
        str: The text with forbidden characters escaped.
    """
    # Create a regex pattern to match any of the forbidden characters
    pattern = f"[{re.escape(forbidden_chars)}]"

    # Escape each match by prefixing it with a backslash
    escaped_text = re.sub(pattern, r"\\\g<0>", text)

    return escaped_text


# Example usage

def gen_mdict_target(filepath, filebase, output_folder, dataName, dataDescription):
    """
    Generate MDict source files (*.title.html, *.description.html, *.txt) and build an MDX dictionary.

    This function creates the necessary metadata and definition files for building an MDict (.mdx) file
    from a tab-separated input text file. Each valid line in the input must contain exactly one tab: 
    `<headword>\t<definition>`. The function then calls the `mdict` command-line tool to produce the MDX file.

    Parameters:
        filepath (str): Path to the input text file containing dictionary entries. 
                        Each line must have one headword and one definition separated by a tab.
        filebase (str): Base filename (without extension) used for generated output files.
        output_folder (str): Directory where all output files will be created.
        dataName (str): Title of the dictionary, written to `<filebase>.title.html`.
        dataDescription (str): Description of the dictionary, written to `<filebase>.description.html`.

    Output Files Generated (in output_folder):
        <filebase>.title.html         Contains the dictionary title.
        <filebase>.description.html   Contains the dictionary description.
        <filebase>.txt                Contains formatted entries for MDict (headword + definition).
        <filebase>.mdx                Final MDict dictionary output (built by `mdict` CLI).

    Behavior:
        • Skips empty lines.
        • Skips lines without exactly one tab, printing a warning for each skipped line.
        • Writes entries to the .txt file in the MDict expected format:
              headword
              definition
              </>
        • Executes the `mdict` tool to build the `.mdx` file.

    Returns:
        Result of the `execute_shell()` call that runs the MDX generation command.
    """
    title_filepath = os.path.join(output_folder, filebase + ".title.html")
    with open(title_filepath, "w", encoding="utf-8") as file:
        file.write(dataName)

    desc_filepath = os.path.join(output_folder, filebase + ".description.html")
    with open(desc_filepath, "w", encoding="utf-8") as file:
        file.write(dataDescription)

    def_filepath = os.path.join(output_folder, filebase + ".txt")
    dict_filepath = os.path.join(output_folder, filebase + ".mdx")

    print(f"{filepath} - {output_folder} - {dict_filepath}")

    with open(def_filepath, "w", encoding="utf-8") as outfile:
        with open(filepath, "r", encoding="utf-8") as file:
            for line in file:
                line = line.strip()        # remove trailing newline

                if not line:
                    continue
                
                if line.count("\t") != 1:
                    print(f"Warning: line in {filepath} has no tab or multiple tabs, skipping: {line!r}")
                    continue
                # assert(line.count("\t") == 1)
                
                headword, definition = line.split("\t")   # split by tab

                outfile.write(f"{headword}\n{definition}\n</>\n")

    cmd_line = (
        f"mdict --title {title_filepath} --description {desc_filepath} -a {def_filepath} {dict_filepath}"  # noqa: E501
    )
    
    return execute_shell(cmd_line=cmd_line, message=f"generating MDict MDX")
    

def main() -> None:
    """Main entry point for converting dictionary files into multiple formats.

    This function processes dictionary files and their metadata to convert them into various
    dictionary formats including StarDict, EPUB, Kobo, Lingvo, Kindle, DictD, Yomitan, and MDict.

    Args:
        None, but accepts command line arguments:
            -i, --input_folder: Input folder containing dictionary files (default: 'dict')
            -o, --output_folder: Output folder for converted dictionaries (default: 'output')
            -e, --extension: File extension for input dictionary files (default: 'tab')
            -m, --metadata: File extension for input metadata files (default: 'toml')
            -f, --filter: Optional comma-separated list of dictionary keys to filter

    Returns:
        None

    The function performs the following operations:
    1. Parses command line arguments
    2. Searches for dictionary and metadata files
    3. Creates necessary output directories
    4. Converts dictionaries to multiple formats:
       - Kindle (MOBI)
       - Pleco (TXT)
       - Lingvo (DSL)
       - MDict (MDX)
       - Other formats specified in DICT_FORMATS
    5. Creates ZIP archives of converted dictionaries

    Note:
        Requires various external dependencies and shell commands for dictionary conversion.
        Temporary files are cleaned up during processing to save space.
    """
    parser = argparse.ArgumentParser(description="Convert all dictionaries in a folder")
    parser.add_argument("-i", "--input_folder", default="dict", help="Input folder containing .tsv and .dfo files")
    parser.add_argument("-o", "--output_folder", default="output", help="Output folder containing dictionary files")
    parser.add_argument("-e", "--extension", default="tab", help="Filename extention for input dictionary files. Default is .tab")
    parser.add_argument("-m", "--metadata", default="toml", help="Filename extention for input metadata for dictionary. Default is .dfo")
    parser.add_argument("-f", "--filter", help="Filter only dictionary entries with matching keys (seperated by comma)")

    args = parser.parse_args()

    input_folder = Path(escape_forbidden_chars(args.input_folder))
    output_folder = Path(escape_forbidden_chars(args.output_folder))
    extension = args.extension
    metadata = args.metadata
    dict_filters = args.filter.split(",") if args.filter is not None else []

    print(f"Arguments: {args}")

    metafilelist = []
    datafilelist = []

    metafilelist, datafilelist = search_data_files(input_folder, extension, metadata, dict_filters)

    # dirs = ["stardict", "epub", "kobo", "lingvo", "kindle", "dictd", "yomitan", "mdict"]

    output_kindle = output_folder / "kindle"
    output_mdict = output_folder / "mdict"
    dict_kindle = input_folder / "kindle"

    # cmd_line = f"mkdir -p {input_folder}/kindle"
    # execute_shell(cmd_line=cmd_line, message="Creating directory")
    # subprocess.call(f'rm -r {output_folder}/*', shell=True)
    dict_kindle.mkdir(parents=True, exist_ok=True)

    # cmd_line = f"rm -r {output_folder}/*"
    # execute_shell(cmd_line=cmd_line, message="Remove existing file in {output_folder}")
    shutil.rmtree(output_folder, ignore_errors=True)

    # cmd_line = f"rm -r {input_folder}/kindle/*"
    # execute_shell(cmd_line=cmd_line, message="Remove existing file in kindle {input_folder}/kindle")
    shutil.rmtree(output_kindle, ignore_errors=True)

    for dir, _ in DIR_FORMATS:
        sub_path = Path(output_folder / dir)
        sub_path.mkdir(parents=True, exist_ok=True)
        # cmd_line = f"mkdir -p {output_folder}/{dir}"
        # execute_shell(cmd_line=cmd_line, message="Creating directory")
        # subprocess.call(f'mkdir -p {output_folder}/{dir}', shell=True)


    # use_only_these = {'Tu-dien-ThienChuu-TranVanChanh'}
    for filepath, datafile in zip(metafilelist, datafilelist):
        _, filename = os.path.split(filepath)
        filebase, fileext = os.path.splitext(filename)

        data = parse_toml_file(filepath)

        if not data:
            continue

        # Add quote to wrap long filename/path
        #datafile = datafile.replace(" ", "\\ ") # safe = shlex.quote(str(datafile))
        dataCreator = data["Owner_Editor"].replace(" ", "\\ ")
        if not dataCreator:
            dataCreator = "Panthera Tigris".replace(" ", "\\ ")

        dataTarget = data["Target"]
        dataSource = data["Source"]
        dataDescription = data["Description"]
        dataFullSource = language_name(data["Source"])
        dataFullTarget = language_name(data["Target"])
        dataName = escape_forbidden_chars(data["Name"])

        INFLECTION_DIR = "./bin/inflections"
        INFLECTION_NONE = "inflections-none.tab"

        # Generare HTML file for Kindle dictionary
        if "Inflections" in data and data["Inflections"]:
            inflections = f'"{INFLECTION_DIR}/{data["Inflections"]}"'
        else:
            inflections = f"{INFLECTION_DIR}/{INFLECTION_NONE}"

        # Generate other dictionary formats using PyGlossary
        for write_format, folder, ext, needzip in DICT_FORMATS:
            _, filename = os.path.split(filepath)
            filebase, _ = os.path.splitext(filename)

            build_dict_many(output_folder, ext, datafile, filebase, dataTarget, dataSource, dataName, write_format, folder, needzip)
        
        # Must run after dictd was created
        build_dict_pocketbook(output_folder, filebase)

        build_dict_mobi(input_folder, output_folder, datafile, filebase, inflections, dataCreator, dataTarget, dataSource, dataName)

        build_dict_pleco_txt(input_folder, output_folder, filebase)

        build_dict_lingvo(input_folder, output_folder, datafile, filebase, dataCreator, dataFullTarget, dataFullSource, dataName)

        build_dict_mdict(output_folder, datafile, filebase, dataDescription, dataName)

        # if DEBUG_FLAG:
        #     continue

        # Deletes src data file to save space
        delete_file(f"{filebase}.txt", input_folder)
        delete_file(f"{filebase}.{extension}", input_folder)

        # cmd_line = f"rm {input_folder}/{filebase}.txt" # Still keeps .tab file for counting lines later
        # execute_shell(cmd_line=cmd_line, message=f"Removes {filebase} input files to save space")

    for dir, format in DIR_FORMATS:
        cmd_line = f"zip -9 -j {output_folder}/all-{dir}.zip {output_folder}/{format}"
        execute_shell(cmd_line=cmd_line, message=f"Zipping all {dir}-format dicts in {output_folder}")

def delete_file(filename, input_folder=""):
    """
    Delete a single file if it exists.

    Parameters
    ----------
    filename : str
        Name of the file to delete.
    input_folder : str, optional
        Path to the folder containing the file (default is current directory).

    Notes
    -----
    If the file does not exist, the function does nothing.
    """
    file_path = Path(input_folder) / filename
    if file_path.exists():
        file_path.unlink()

def delete_file_pattern(filename, pattern, dir_path=""):
    """
    Delete all files in a directory that match a filename pattern.

    Parameters
    ----------
    filename : str
        Base name of the files to match.
    pattern : str
        Pattern appended to filename (e.g., "*.txt" or "_backup.*").
    dir_path : str, optional
        Directory to search for matching files (default is current directory).

    Notes
    -----
    Only files are deleted. Subdirectories are ignored.
    """
    dir = Path(dir_path)
    for f in dir.glob(f"{filename}{pattern}"):
        if f.is_file():
            f.unlink()

def build_dict_many(output_folder, extension, datafile, filebase, dataTarget, dataSource, dataName, write_format, folder, needzip):
    """
    Generate a dictionary file from a tab-delimited data source using pyglossary,
    optionally compress the result into a ZIP archive, and move or clean up
    intermediate files.

    This function builds command lines for pyglossary and common shell utilities
    (zip, rm, mv) and delegates execution to `execute_shell`. It is intended to
    create a converted dictionary file at:
        <output_folder>/<folder>/<filebase>.<extension>
    or, when `needzip` is True, to create a ZIP at:
        <output_folder>/<filebase>.<folder>.zip

    Parameters
    ----------
    output_folder : str
        Path to the base output directory where resulting files or ZIPs will be
        placed.
    extension : str
        File extension for the generated file (used in the output filename).
    datafile : str
        Path to the input data file (expected Tabfile format) to be converted.
    filebase : str
        Base name (without extension) for the generated file or ZIP.
    dataTarget : str
        Target language code passed to pyglossary via --target-lang.
    dataSource : str
        Source language code passed to pyglossary via --source-lang.
    dataName : str
        Dictionary name passed to pyglossary via --name.
    pyglossary : str
        Path to the pyglossary executable or a placeholder parameter. Note:
        the current implementation does not use this parameter directly when
        building the command line (pyglossary is invoked by literal name).
    write_format : str
        Output format name passed to pyglossary via --write-format.
    folder : str
        Subfolder inside `output_folder` where the non-zipped output is placed.
    needzip : bool
        If True, compress the generated output files into a ZIP and remove the
        temporary generated files; if False, move the generated file(s) into
        `output_folder`.

    Returns
    -------
    None

    Side effects
    ------------
    - Executes shell commands via `execute_shell`:
      - Runs pyglossary to convert the input file to the requested format.
      - If `needzip` is True:
          * Creates a ZIP containing the generated files and deletes the
            temporary files produced in the subfolder.
        Otherwise:
          * Moves the produced file(s) from the subfolder into `output_folder`.
    - Creates, moves, and deletes files on the filesystem.

    Errors and exceptions
    ---------------------
    - Any exception or error produced by `execute_shell` (or underlying shell
      commands) will propagate to the caller.
    - The function currently interpolates many values directly into shell
      command strings. For safety, ensure that inputs are trusted or properly
      sanitized to avoid shell injection vulnerabilities. Only `out_path` is
      quoted with `shlex.quote` in the current implementation.

    Notes
    -----
    - The function assumes `pyglossary` and standard Unix utilities (`zip`, `rm`,
      `mv`) are available in PATH, or that `execute_shell` knows how to locate them.
    - `pyglossary` parameter is accepted but not inserted into constructed
      command lines in the current implementation; update the command
      construction if you need to use a non-default pyglossary executable.
    """
    out_path = os.path.join(output_folder, folder, f"{filebase}.{extension}")
    cmd_line = (
                f"pyglossary --ui=none --read-format=Tabfile --write-format={write_format} "
                f"--source-lang={dataSource} --target-lang={dataTarget} --name={dataName} {datafile} {shlex.quote(out_path)}"
            )

    execute_shell(cmd_line=cmd_line, message=f"generating {write_format}")

    if needzip:
        out_path = os.path.join(output_folder, f"{folder}/{filebase}.*")
        zip_path = os.path.join(output_folder, f"{filebase}.{folder}.zip")
        cmd_line = f"zip -j {zip_path} {out_path}"
        execute_shell(cmd_line=cmd_line, message=f"creating zip file for {write_format} in {output_folder}")

        if folder not in ("dictd"): # keep dictd files for Pocketbook conversion
            out_dir = Path(output_folder) / folder

            for f in out_dir.glob(f"{filebase}.*"):
                if f.is_file():
                    f.unlink()

        # cmd_line = f"rm {out_path}"
        # execute_shell(cmd_line=cmd_line, message=f"Remove temp file for {filebase} in {output_folder}")
    else:
        # cmd_line = f"mv {out_path} {output_folder}"
        # execute_shell(cmd_line=cmd_line, message=f"moving output {out_path} to output folder {output_folder}")
        Path(out_path).replace(Path(output_folder) / f"{filebase}.{extension}")

def build_dict_mobi(input_folder, output_folder, datafile, filebase, inflections, dataCreator, dataTarget, dataSource, dataName):
    """
    Build a Kindle-compatible .mobi dictionary from intermediate data files.

    This function orchestrates the creation of a Kindle dictionary by:
    1. Running a conversion script (tab2opf.py) to produce an OPF+HTML set in a temporary
        "kindle" subdirectory under the provided input folder.
    2. Invoking the mobigen.exe tool (via wine) to generate a .mobi file from the
        generated OPF file.
    3. Moving the resulting .mobi file to the specified output folder.
    4. Cleaning up generated HTML files for the processed file base.

    Note: this function executes external commands and relies on several external
    binaries and scripts being present and executable (python ./bin/tab2opf.py,
    wine, ./bin/mobigen/mobigen.exe). It prints command lines it runs and uses
    subprocess and an execute_shell helper for execution.

    Args:
         input_folder (str): Path to the input folder containing source materials.
              A "kindle" subdirectory under this folder will be used as the temporary
              output directory for OPF/HTML files.
         output_folder (str): Destination directory where the final .mobi file will
              be moved.
         datafile (str): Path to the source data file passed as the final argument to
              tab2opf.py.
         filebase (str): Base filename (without extension) used to name the generated
              OPF/HTML/mobi artefacts.
         inflections (str): Value passed to tab2opf.py's --inflection option that
              controls whether/which inflections to include.
         dataCreator (str): Creator/author name passed to tab2opf.py (also used as
              publisher in the current command).
         dataTarget (str): Target language/code passed to tab2opf.py’s --target option.
         dataSource (str): Source language/code passed to tab2opf.py’s --source option.
         dataName (str): Title/name passed to tab2opf.py’s --title option and used as
              metadata in the generated OPF.

    Returns:
         None

    Side effects:
         - Creates (and later removes) HTML files in {input_folder}/kindle.
         - Creates an OPF file and a .mobi file for the given filebase.
         - Moves the .mobi file into the provided output_folder.
         - Prints executed command lines to stdout.

    Errors and exceptions:
         - External command failures may raise subprocess exceptions or fail silently
            depending on how subprocess.run/subprocess.call are invoked. The function
            also depends on the behavior of execute_shell for cleanup; any errors
            raised by that helper will propagate.
         - Because command lines are assembled from input parameters, passing
            untrusted input may lead to shell injection risks (note that some calls
            use shlex.split while others invoke a shell). Sanitize or validate inputs
            before calling this function in untrusted contexts.

    Example:
         build_dict_mobi(
              input_folder="/path/to/workspace",
              output_folder="/path/to/output",
              datafile="/path/to/data.tsv",
              filebase="my_dictionary",
              inflections="yes",
              dataCreator="Example Author",
              dataTarget="en",
              dataSource="la",
              dataName="Latin–English Dictionary"
         )
    """
    html_dir = f"kindle"
    html_out_dir = f"{input_folder}/{html_dir}"

    cmd_line = f"python ./bin/tab2opf.py --title={dataName} --source={dataSource} --target={dataTarget} --inflection={inflections} --outdir={html_out_dir} --creator={dataCreator} --publisher={dataCreator} {datafile}"  # noqa: E501
    print(cmd_line)
    subprocess.run(shlex.split(cmd_line))

        # Generate .mobi dictionary from opf+html file
    out_path = f"{html_out_dir}/{filebase}.opf".replace(" ", "\\ ")
    cmd_line = f"wine ./bin/mobigen/mobigen.exe -unicode -s0 {out_path}"
    print(cmd_line)
    subprocess.run(shlex.split(cmd_line))

    cmd_line = f"mv {html_out_dir}/{filebase}.mobi {output_folder}/"
    print(cmd_line)
    subprocess.call(cmd_line, shell=True)

    # cmd_line = f"rm {htmlOutDir}/{filebase}*.html"
    # execute_shell(cmd_line=cmd_line, message=f"Removes html files for {filebase}")

    delete_file_pattern(filebase, "*.html", html_out_dir)

def build_dict_pocketbook(output_folder, filebase):
    """
    Builds an Pocketbook from dictd file. This MUST RUN AFTER dictd was created

    Args:
        output_folder (str): Directory path where the output dictionary will be saved
        datafile (str): Path to input data file
        filebase (str): Base filename to use for generated dictionary
        dataDescription (str): Description of the dictionary data
        dataName (str): Name of the dictionary

    The function:
    1. Generates an XDXF datafile using makedict tool
    2. Use Pocketbook LanguageFilesPocketbookConverter to convert XDXF to Pocketbook .dic format
    3. Renames output file

    Requires:
        - gen_mdict_target() function to generate the dictionary
        - execute_shell() function to run shell commands
    """
    # Generare Pocketbook dictionary

    cmd_line = f"mkdir {output_folder}/xdxf"
    print(cmd_line)
    subprocess.run(shlex.split(cmd_line))

    # Generare xdxf intermediate dictionary format
    out_dictdir = os.path.join(output_folder, "xdxf")
    cmd_line = f"makedict -i dictd -o xdxf {output_folder}/dictd/{filebase}.index --work-dir {out_dictdir}"
    print(cmd_line)
    subprocess.run(shlex.split(cmd_line))

    converter = "wine LanguageFilesPocketbookConverter/converter.exe"
    lang_data = "./LanguageFilesPocketbookConverter/en/"

    cmd_line = f"{converter} /workspaces/tudien/{output_folder}/xdxf/{filebase}/dict.xdxf {lang_data}"
    print(cmd_line)
    subprocess.run(shlex.split(cmd_line))

    cmd_line = f"mv {out_dictdir}/{filebase}/dict.dic {output_folder}/{filebase}.dic"
    print(cmd_line)
    subprocess.run(shlex.split(cmd_line))

    # cmd_line = f"rm {output_folder}/mdict/{filebase}*"
    # execute_shell(cmd_line=cmd_line, message=f"Removes temp mdict files in {output_folder}/mdict")
    # delete_file_pattern(filebase, "*", f"{output_folder}/mdict/")

def build_dict_mdict(output_folder, datafile, filebase, dataDescription, dataName):
    """
    Builds an MDict from a data file.

    Args:
        output_folder (str): Directory path where the output dictionary will be saved
        datafile (str): Path to input data file
        filebase (str): Base filename to use for generated dictionary
        dataDescription (str): Description of the dictionary data
        dataName (str): Name of the dictionary

    The function:
    1. Generates an MDict in a temporary folder
    2. Moves .mdx files to the output folder 
    3. Cleans up temporary files

    Requires:
        - gen_mdict_target() function to generate the dictionary
        - execute_shell() function to run shell commands
    """
    # Generare Mdict dictionary
    out_dictdir = os.path.join(output_folder, "mdict")
    gen_mdict_target(datafile, filebase, out_dictdir, dataName, dataDescription)
    cmd_line = f"mv {out_dictdir}/*.mdx {output_folder}/"
    execute_shell(cmd_line=cmd_line, message=f"moving output {output_folder} to output folder {output_folder}")

    # cmd_line = f"rm {output_folder}/mdict/{filebase}*"
    # execute_shell(cmd_line=cmd_line, message=f"Removes temp mdict files in {output_folder}/mdict")
    delete_file_pattern(filebase, "*", f"{output_folder}/mdict/")

def build_dict_pleco_txt(input_folder, output_folder,  filebase):
    """
    Create a Pleco-compatible zipped dictionary file (.pleco.zip) from a plaintext
    dictionary file located in input_folder.

    This function looks for a file named "{filebase}.txt" in input_folder. If that
    file exists, it runs a shell zip command to create a zip archive named
    "{filebase}.pleco.zip" in output_folder containing the original .txt file.
    The zip is created with the -j option (junk the path) so the archive contains
    only the .txt file, not its parent directories.

    Parameters
    ----------
    input_folder : str
        Path to the folder that contains the source "{filebase}.txt" file.
    output_folder : str
        Path to the folder where the resulting "{filebase}.pleco.zip" archive
        should be written.
    filebase : str
        Base filename (without extension) used to compose the source ".txt" and
        destination ".pleco.zip" filenames.

    Returns
    -------
    None

    Side effects
    ------------
    - If "{input_folder}/{filebase}.txt" exists, a shell command is executed via
      execute_shell to create the zip archive at "{output_folder}/{filebase}.pleco.zip".
    - If the source .txt file does not exist, the function does nothing.

    Exceptions
    ----------
    Any exceptions raised by execute_shell or underlying system calls (e.g.,
    permission errors, missing external zip utility) will propagate to the caller.

    Example
    -------
    build_dict_pleco_txt("/path/to/input", "/path/to/output", "mydict")
    # If "/path/to/input/mydict.txt" exists, creates "/path/to/output/mydict.pleco.zip"
    """
    # Zip to create Pleco dictionary
    pleco_dict_file = f"{input_folder}/{filebase}.txt"
    if os.path.exists(pleco_dict_file):
        cmd_line = f"zip -j {output_folder}/{filebase}.pleco.zip {input_folder}/{filebase}.txt"
        execute_shell(cmd_line=cmd_line, message=f"Making Pleco dict file for {pleco_dict_file}")

def build_dict_lingvo(input_folder, output_folder, datafile, filebase, dataCreator, dataFullTarget, dataFullSource, dataName):
    """
    Generate a Lingvo (.dsl) dictionary by invoking an external tab2dsl Ruby tool and move the generated archive to the output folder.

    This function constructs and runs shell commands to:
    1. Call the Ruby script ./dsl-tools/tab2dsl/tab2dsl.rb to convert a tabular dictionary file into a Lingvo DSL file.
    2. Move the resulting compressed output (.dz) from the temporary output location into the provided output folder.

    Notes:
    - The temporary DSL output path is constructed as "<output_folder>/lingvo/<filebase>.dsl" with spaces escaped.
    - The function relies on an available `execute_shell` helper to run shell commands; any exceptions raised by that helper will propagate.
    - The Ruby script must exist at ./dsl-tools/tab2dsl/tab2dsl.rb and be executable in the running environment.
    - The parameter `dataCreator` is accepted but not used by this function.

    Parameters
    ----------
    input_folder : str
        Path to the folder containing input resources (not directly used by the current implementation but kept for API consistency).
    output_folder : str
        Destination folder where the final .dz archive will be moved.
    datafile : str
        Path to the tab-separated dictionary file that will be converted by the tab2dsl tool.
    filebase : str
        Base name used for the generated DSL file (the function creates "lingvo/{filebase}.dsl" under output_folder).
    dataCreator : str
        Metadata field intended to represent the creator of the data. Note: currently not used by the function.
    dataFullTarget : str
        Target language code/name passed to the tab2dsl tool via --to-lang.
    dataFullSource : str
        Source language code/name passed to the tab2dsl tool via --from-lang.
    dataName : str
        Dictionary name passed to the tab2dsl tool via --dict-name.

    Returns
    -------
    None
        The function performs side effects (file creation and movement) and does not return a value.

    Raises
    ------
    Exception
        Propagates any exception raised by the underlying `execute_shell` calls (e.g., subprocess errors, OSError),
        indicating failure of the external tool invocation or filesystem operations.

    Examples
    --------
    # Typical usage
    build_dict_lingvo(
        input_folder="/path/to/input",
        output_folder="/path/to/output",
        datafile="/path/to/input/data.tsv",
        filebase="my_dictionary",
        dataCreator="Example Creator",
        dataFullTarget="ru",
        dataFullSource="en",
        dataName="My Dictionary"
    """
    # Generare Lingvo dictionary
    out_path = os.path.join(output_folder, f"lingvo/{filebase}.dsl").replace(" ", "\\ ")
    cmd_line = (
        f"ruby ./dsl-tools/tab2dsl/tab2dsl.rb --from-lang {dataFullSource} --to-lang {dataFullTarget} --dict-name {dataName} --output {out_path} {datafile}"  # noqa: E501
    )
    execute_shell(cmd_line=cmd_line, message=f"generating DSL/Longvo")

    cmd_line = f"mv {out_path}.dz {output_folder}"
    execute_shell(cmd_line=cmd_line, message=f"moving output {out_path} to output folder {output_folder}")


def search_data_files(input_folder, extension, metadata, dict_filters):
    """
    Search for matching metadata and data files in a specified directory.

    This function looks for pairs of metadata and dictionary data files in the input folder,
    optionally filtering the results based on specified dictionary names.

    Args:
        input_folder (str): Path to the directory containing the data files
        extension (str): File extension for the dictionary data files
        metadata (str): File extension for the metadata files
        dict_filters (list): Optional list of strings to filter dictionary names. Only dictionaries
                            containing any of these strings in their names will be included.

    Returns:
        tuple: A pair of lists (metafilelist, datafilelist) containing paths to matching
               metadata and data files. For compressed files (.bz2), they will be decompressed
               and the path to the decompressed file will be returned.

    Notes:
        - The function handles both regular and bzip2 compressed (.bz2) data files
        - Files are matched based on their base names (without extensions)
        - When dict_filters is provided, only dictionaries with names containing any
          of the filter strings will be included
        - Compressed files are automatically decompressed during processing
    """
    if input_folder:
        metafilelist =      sorted(input_folder.glob(f"*.{metadata}"), reverse=True)
        datafilelist =      sorted(input_folder.glob(f"*.{extension}"), reverse=True)
        zippdatafilelist =  sorted(input_folder.glob(f"*.bz2"), reverse=True)

        meta_dict = {}
        data_dict = {}
        print(f"Len of metafilelist: {len(metafilelist)}")
        print(f"Len of datafilelist: {len(datafilelist)}")
        print(f"Len of compressed datafilelist: {len(zippdatafilelist)}")

        bothdatalist = datafilelist + zippdatafilelist # Lists of data files including compressed ones

        # Keep only pairs of metadata and dict data files
        meta_dict = {full_stem(filepath): filepath for filepath in metafilelist}

        data_dict = {full_stem(filepath): filepath for filepath in bothdatalist}

        common_keys = sorted(list(meta_dict.keys() & data_dict.keys()))

        print(common_keys)

        metafilelist.clear()
        datafilelist.clear()

        for key in common_keys:
            include_dict = False

            if dict_filters:
                for filter in dict_filters:
                    if filter in key:
                        include_dict = True

                        break

                if not include_dict:
                    print(f"Excluding this dictionary: {key}")
                    continue

            metafilelist.append(meta_dict[key])

            datafile = data_dict[key]

            # If datafile is a .bz2
            if datafile.suffix == ".bz2":
                cmd_line = f'bzip2 -d "{str(datafile)}"' # Add -k to keep the original file

                execute_shell(cmd_line=cmd_line, message=f"bunzip data file")

                datafilelist.append(datafile.with_suffix("")) # Remove .bz2 suffix
            else:
                datafilelist.append(datafile)

        print(f"Len of checked datafilelist: {len(datafilelist)}")

    return metafilelist,datafilelist

def full_stem(path):
    """
    Return the filename without any extensions for files with multiple suffixes (e.g., .tar.gz).
    Files with a single suffix behave as path.stem
    
    Parameters
    ----------
    path : str or Path
        The path to the file.
        
    Returns
    -------
    str
        The filename with all suffixes removed.
    """
    p = Path(path)
    name = p.name
    for _ in p.suffixes:
        name = Path(name).with_suffix("")
    return str(name)


if __name__ == "__main__":
    """"
    Main entry point
    """

    main()
