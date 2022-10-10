tab2dsl - a very basic script to convert tab-separated files into DSL-format dictionaries.

For a similar program written in Python see [tsv2dsl](https://github.com/fastrizwaan/tsv2dsl). I wrote this script because tsv2dsl can't handle a tab separated file with only 2 columns. Right now tab2dsl has the opposite situation - it only handles files with two columns of tab-separated text. Configurable number of columns and different parameters (e.g. parts of speech, location of the headword, fancy formatting) may be added later.

# Requirements

The script requires that the dictzip program is installed in order to compress the final dictionary (dsl.dz files are a small fraction of the size of the uncompressed originals and are supported by most dictionary programs).

# Usage

If run without command-line arguments, the script will ask for the name of a source file to process:

    ruby tab2dsl.rb

Alternatively, the location of the source file can be specified as an argument:

    ruby tab2dsl.rb /path/to/mydictionary.txt

In either case, you will then be prompted to supply basic information about the dictionary (dictionary name, index language, and contents language). These are required by the DSL format and will be used to construct the dictionary header information.

This works fine for one-off dictionary conversions. For batch processing, some options for providing the header information on the command-line or from a separate file should eventually be added.

# Source format

tab2dsl expects a source file containing two tab-separated columns in which the first column is the headword, and the second column is the body of the entry or definition, e.g.:

    Headword	Entry

These will converted into DSL-format entries with minimal formatting (italicized headwords and indented definitions).

# License

MIT -- see LICENSE file for details.
