# PocketBookDic
Script that originated to convert dictionaries to pocketbook dictionary dic-format. 
However, since I moved away from Pocketbook devices, I am more focussed on converting to the intermediary xdxf-format and Stardict-format. Both formats are easily converted with other tools to custom formats. Only this script incorporates the Pocketbook dic-format. For other formats I can recommend pyGlossary. 

**pocketbookdic.pl** \
Script to convert from csv-, Stardict dict-, Stardict dictdz-, Textual Stardict xml-, mobi- (via html- with KindleUnpack) and xdxf-format to pocketbook dic-, Stardict dict/idx/ifo-, xdxf- and Stardict xml-format. (The csv-file should be comma separated or the delimiter should be given at the command line.) \
The conversion to Pocketbook dic-format needs files that can be found in the repository [LanguageFilesPocketbookConverter](https://github.com/Markismus/LanguageFilesPocketbookConverter).
Currently starting to convert epub-dictionaries and rawml-files. (Rawml-files are unpacked mobi-files that KindleUnpack can't process further.) \

_Dependencies:_
- Perl - It's a Perl script: Install Perl to run it! 
- Perl modules - Term::ANSIColor and Encode are used. They might be installed with Perl or will have to be installed separately. They can be installed from cpan. E.g. In Arch Linux the first module is installed by `cpanp i Term::ANSIColor`. On Windows 10 I only installed 'Strawberry Perl' and no modules and it still ran, so go figure!
- converter.exe - Pocketbook's converter. Look on the mobileread site in the pocketbook subforum for the newest version. (Currently it is converter3.exe posted by ezdiy. Please rename it to converter.exe.)
- language folders - converter.exe depends on the presence of a language folder in which the files collates.txt, keyboard.txt and  morphems.txt are located. The name of the language folder should be the same as the language_from which your dictionary translates. There are a lot of preformed language folders floating around the mobileread site in the pocketbook subforum.
- Wine - Converter.exe is a windows binary, which can be runned with Wine. (If your running windows, you of course do not need wine.
- stardict-bin2text - The script uses a binary from the stardict-tools package to convert a triplet of ifo-, -idx and -dict (or -dict.dz) Stardict files to one xml-file. (That xml-file will then be converted to a xdxf-file, which will be reconstructed to fit through converter.exe. 
    - If you run Windows you should _manually_ generate the xml- or csv-file. E.g. You can use stardict-editor (included with the windows Stardict installation) and decompile a dictionary to Textual Stardict dictionary. This generates a xml-file that you can use as filename at the start of the script.
- stardict-text2bin - The script has been expanded to generate Stardict binary files. 
- KindleUnpack - If you want to convert mobi-dictionaries, you'll first have to convert it to html-format using [KindleUnpack](https://github.com/kevinhendricks/KindleUnpack). Under Linux it is enough to point the script to the installation directory and the script will handle it for you.
- dictzip for zipping the stardict dict-file generated with startdict-text2bin.
- 7z CLI utility for unzipping epub-files. 
- I've probably forgotten something. If you run into it, please open an issue.

_Preparation:_
- Install the dependencies
- Move the script `pocketbook.pl`, the language maps, e.g. `eng`, `converter.exe` into the same map.
- Change the control variables in the beginning of the script to your liking. The most important one will be:
  - BaseDir = "absolute_path_to_your_map"; (In Windows remember to write your path with slashes, e.g. "C:/Users/DefaultUser/Downloads/PocketbookDic/".
  - FileName = "relative_to_your_$Basedir_path/name_of_your_dictionary", e.g. "dict/Latin-English\ dictionary.ifo".
  - isCreateStardictDictionary = 1; # Turns on Stardict text and binary dictionary creation.
  - isCreatePocketbookDictionary = 1; # Turns on Pocketbook Dictionary dic-format creation. (Stardict xml- and xdxf-format are created as intermediaries.) 

  
  
_Usage:_
- To run: `perl pocketbookdic.pl`
- Using arguments: 
    - `perl pocketbookdic.pl path_to_and_filename_of_your_dictionary_with_extention`
    - `perl pocketbookdic.pl path_to_and_filename_of_your_dictionary_with_extention language_folder_name`
    - `perl pocketbookdic.ok path_to_and_filename_of_your_dictionary_with_extention language_folder_name cvs-delimiter`
- All command line variables are optional. However, you can't specify the next one without the previous one.\
    - E.g. `perl pocketbookdic.pl dict/myDictionary.cvs eng "|--|"`
    - E.g. `perl pocketbookdic.pl dict/myDictionary.ifo`
