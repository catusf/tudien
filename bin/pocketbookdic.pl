#!/bin/perl
use strict;
# use autodie; # Does not get along with pragma 'open'.
use Term::ANSIColor;    #Color display on terminal
use Encode;
use utf8;
use open IO => ':utf8';
use open ':std', ':utf8';
use feature 'unicode_strings'; # You get funky results with the sub convertNumberedSequencesToChar without this.
use feature 'say';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Storable;
use Time::HiRes qw/ time /;

###########################################
### Beginning of manual control input   ###
###########################################

# $BaseDir is the directory where converter.exe and the language folders reside.
# Typically the language folders are named by two letters, e.g. english is named 'en'.
# In each folder should be a collates.txt, keyboard.txt and morphems.txt file.
my $BaseDir="/home/mark/Downloads/PocketbookDic";

# $KindleUnpackLibFolder is the folder in which kindleunpack.py resides.
# You can download KindleUnpack using http with: git clone https://github.com/kevinhendricks/KindleUnpack
# or using ssh with: git clone git@github.com:kevinhendricks/KindleUnpack.git
# Use absolute path beginning with either '/' (root) or '~'(home) on Linux. On Windows use whatever works.
my $KindleUnpackLibFolder="/home/mark/git/KindleUnpack/lib";

# Last filename will be used.
# Give the filename relative to the base directory defined in $BaseDir.
# However, when an argument is given, it will supercede the last filename
my $FileName;
# Examples given:
$FileName = "dict/Oxford English Dictionary 2nd Ed/Oxford English Dictionary 2nd Ed.xdxf";
$FileName = "dict/stardict-Webster_s_Unabridged_3-2.4.2/Webster_s_Unabridged_3.ifo";

my $DumperSuffix = ".Dumper.txt"; # Has to be declared before any call to storeHash or retrieveHash. Otherwise it is undefined, although no error is given.

my $isRealDead=1; # Some errors should kill the program. However, somtimes you just want to convert.

# Controls manual input: 0 disables.
my ( $lang_from, $lang_to, $format ) = ( "eng", "eng" ,"" ); # Default settings for manual input of xdxf tag.
my $reformat_full_name = 1 ; # Value 1 demands user input for full_name tag.
my $reformat_xdxf = 1 ; # Value 1 demands user input for xdxf tag.

# Deliminator for CSV files, usually ",",";" or "\t"(tab).
my $CVSDeliminator = ",";

# Controls for debugging.
my $isDebug = 1; # Toggles all debug messages
my $isDebugVerbose = 0; # Toggles all verbose debug messages
my $isDebugVeryVerbose = 0; # Toggles all verbose debug messages
my ( $isInfo, $isInfoVerbose, $isInfoVeryVerbose ) = ( 1, 0 ,0 );  # Toggles info messages
my ( $isgenerateXDXFTagBasedVerbose, $isgatherSetsVerbose ) = ( 0, 0 ); # Controls verbosity of tag functions
my $DebugKeyWordConvertHTML2XDXF = "Gewirr"; # In convertHTML2XDXF only debug messages from this entry are shown. E.g. "Gewirr"
my $DebugKeyWordCleanseAr = '<k>φλέως</k>'; # In cleanseAr only extensive debug messages for this entry are shown. E.g. '<k>φλέως</k>'
my $NumberofCharactersShownFailedRawML = 4500;

my $isTestingOn = 0; # Toggles intermediary output of xdxf-array.
if ( $isTestingOn ){ use warnings; }
my $no_test = 0; # Testing singles out a single ar and generates a xdxf-file containing only that ar.
my $ar_chosen = 410; # Ar singled out when no_test = 0;
my ($cycle_dotprinter, $cycles_per_dot) = (0 , 300); # A green dot is printed achter $cycles_per_dot ar's have been processed.
my $i_limit = 27000000000000000000; # Hard limit to the number of lines that are processed.

# Controls for Stardict dictionary creation and Koreader stardict compatabiltiy
my $isCreateStardictDictionary = 0; # Turns on Stardict text and binary dictionary creation.
# Same Type Seqence is the initial value of the Stardict variable set in the ifo-file.
# "h" means html-dictionary. "m" means text.
# The xdxf-file will be filtered for &#xDDDD; values and converted to unicode if set at "m"
my $SameTypeSequence = "h"; # Either "h" or "m" or "x".
my $updateSameTypeSequence = 1; # If the Stardict files give a sametypesequence value, update the initial value.
my $isConvertColorNamestoHexCodePoints = 1; # Converting takes time.
my $isConvertMobiAltCodes = 1; # Apparently, characters in the range of 1-31 are displayed as alt-codes in mobireader.
my $isMakeKoreaderReady = 1; # Sometimes koreader want something extra. E.g. create css- and/or lua-file, convert <c color="red"> tags to <span style="color:red;">

# Controls for Pocketbook conversion
my $isCreatePocketbookDictionary = 1; # Controls conversion to Pocketbook Dictionary dic-format
my $remove_color_tags = 0; # Not all viewers can handle color/grayscale. Removing them reduces the article size considerably. Relevant for pocketbook dictionary.
# This controls the maximum article length.
# If set too large, the old converter will crash and the new will truncate the entry.
# Force conversion of numbered sequences to characters.
my $ForceConvertNumberedSequencesToChar = 1;
my $max_article_length = 64000;
# This controls the maximum line length.
# If set too large, the converter wil complain about bad XML syntax and exit.
my $max_line_length = 4000; # In bytes as generated by: length( encode('UTF-8', $line) )

# Nouveau Littré uses doctype symbols, which should be converted before further processing.
my $DoNotFilterDocType = 1;

# Controls for Mobi dictionary handling
my $isHandleMobiDictionary = 1 ;
my $isExcludeImgTags    = 1 ; # <img.../>-tags are removed if toggle is positive.
my $isSkipKnownStylingTags = 1 ; # <b>-, <i>-tags and such are usually not relevant for structuring lemma/definition pairs. However, <font...>-tags sometimes are. So check.
my $HigherFrequencyTags = 10 ; # Tags below this frequency, e.g. 10 times, are considered lower frequency.
my $isDeleteLowerFrequencyTagsinFilterTagsHash = 0 ; # And the consequeces of that can be toggled, too.
my $isRemoveMpbAndBodyTags = 1 ; # <mbp...> and <body>-tags are removed if toggle is positive.
my $MinimumSetPercentage = 80 ; # A tag-set should be at least this percentage to be considered the outer tags for an article.

# Create mdict dictionary
my $isCreateMDict = 0;

# Controls for recoding or deleting images and sounds.
my $isRemoveWaveReferences           = 1; # Removes all the references to wav-files Could be encoded in Base64 now.
my $isConvertImagesUsingOCR          = 1; # Try to identify images as symbols whenever possible.
my $isCodeImageBase64                = 0; # Some dictionaries contain images. Encoding them as Base64 allows coding them inline. Only implemented with convertHTML2XDXF.
my $isConvertGIF2PNG                 = 0; # Creates a dependency on Imagemagick "convert".
my $isRemoveUnSubstitutedImageString = 1;
my $isRemoveUnSourcedImageStrings    = 1;
my $unEscapeHTML                     = 0;
my $EscapeHTMLCharacters             = 0;
my $ForceConvertBlockquote2Div       = 0;
my $isConvertDiv2SpaninHTML2DXDF     = 0;
my $UseXMLTidy                       = 0; # Enables or disables the use of the subroutine tidyXMLArray. Still experimental, so disable.
my $isCutDoneWithTidyXML             = 0; # Enables or disables the cutting of a line for the pocketbook dictionary in cleanseAr. Still experimental, so disable.


# Shortcuts to Collection of settings.
# If you select both settings, they will be ignored.
my $Just4Koreader     = 1;
my $Just4PocketBook = 0;

if( $Just4Koreader and !$Just4PocketBook){
    # Controls for Stardict dictionary creation and Koreader stardict compatabiltiy
    $isCreateStardictDictionary = 1; # Turns on Stardict text and binary dictionary creation.
    $SameTypeSequence = "h"; # Either "h" or "m" or "x".
    $updateSameTypeSequence = 1; # If the Stardict files give a sametypesequence value, update the initial value.
    $isConvertColorNamestoHexCodePoints = 1; # Converting takes time.
    $isMakeKoreaderReady = 1; # Sometimes koreader want something extra. E.g. create css- and/or lua-file, convert <c color="red"> tags to <span style="color:red;">

    # Controls for Pocketbook conversion
    $isCreatePocketbookDictionary = 0; # Controls conversion to Pocketbook Dictionary dic-format
    $remove_color_tags = 0; # Not all viewers can handle color/grayscale. Removing them reduces the article size considerably. Relevant for pocketbook dictionary.
    $max_article_length = 640000;
    $max_line_length = 8000;

    # Controls for recoding or deleting images and sounds.
    $isRemoveWaveReferences = 1; # Removes all the references to wav-files Could be encoded in Base64 now.
    $isCodeImageBase64 = 0; # Some dictionaries contain images. Encoding them as Base64 allows coding them inline. Only implemented with convertHTML2XDXF.
    $isConvertGIF2PNG = 0; # Creates a dependency on Imagemagick "convert".

    $unEscapeHTML = 0;
    $ForceConvertNumberedSequencesToChar = 1;
    $ForceConvertBlockquote2Div = 0;
    $EscapeHTMLCharacters = 0;
}
if( $Just4PocketBook and !$Just4Koreader){
    # Controls for Stardict dictionary creation and Koreader stardict compatabiltiy
    $isCreateStardictDictionary = 0; # Turns on Stardict text and binary dictionary creation.
    $SameTypeSequence = "h"; # Either "h" or "m" or "x".
    $updateSameTypeSequence = 1; # If the Stardict files give a sametypesequence value, update the initial value.
    $isConvertColorNamestoHexCodePoints = 0; # Converting takes time and space
    $isMakeKoreaderReady = 0; # Sometimes koreader want something extra. E.g. create css- and/or lua-file, convert <c color="red"> tags to <span style="color:red;">

    # Controls for Pocketbook conversion
    $isCreatePocketbookDictionary = 1; # Controls conversion to Pocketbook Dictionary dic-format
    $remove_color_tags = 1; # Not all viewers can handle color/grayscale. Removing them reduces the article size considerably. Relevant for pocketbook dictionary.
    $max_article_length = 64000;
    $max_line_length = 4000;
    
    # Controls for recoding or deleting images and sounds.
    $isRemoveWaveReferences = 1; # Removes all the references to wav-files Could be encoded in Base64 now.
    $isCodeImageBase64 = 1; # Some dictionaries contain images. Encoding them as Base64 allows coding them inline. Only implemented with convertHTML2XDXF.
    $isConvertGIF2PNG = 0; # Creates a dependency on Imagemagick "convert".

    $unEscapeHTML = 1;
    $ForceConvertNumberedSequencesToChar = 1;
    $ForceConvertBlockquote2Div = 1;
    $EscapeHTMLCharacters = 0;
}
#########################################################
###  End of manual control input                     ####
###  (Excluding doctype html entities. See below. )  ####
#########################################################

# However, when an argument is given, it will supercede the last filename
# Command line argument handling
if( defined($ARGV[0]) ){
    printYellow("Command line arguments provided:\n");
    @ARGV = map { decode_utf8($_, 1) } @ARGV; # Decode terminal input to utf8.
    foreach(@ARGV){ printYellow("\'$_\'\n"); }
    printYellow("Found command line argument: $ARGV[0].\nAssuming it is meant as the dictionary file name.\n");
    $FileName = $ARGV[0];
}
else{
    printYellow("No commandline arguments provided. Remember to either use those or define \$FileName in the script.\n");
    printYellow("First argument is the dictionary name to be converted. E.g dict/dictionary.ifo (Remember to slash forward!)\n");
    printYellow("Second is the language directory name or the CSV deliminator. E.g. eng\nThird is the CVS deliminator. E.g \",\", \";\", \"\\t\"(for tab)\n");
}
my $language_dir = "";
if( defined($ARGV[1]) and $ARGV[1] !~ m~^.$~ and $ARGV[1] !~ m~^\\t$~ ){
    printYellow("Found command line argument: $ARGV[1].\nAssuming it is meant as language directory.\n");
    $language_dir = $ARGV[1];
}
if ( defined($ARGV[1]) and ($ARGV[1] =~ m~^(\\t)$~ or $ARGV[1] =~ m~^(.)$~ )){
    debugFindings();
    printYellow("Found a command line argument consisting of one character.\n Assuming \"$1\" is the CVS deliminator.\n");
    $CVSDeliminator = $ARGV[1];
}

if( defined($ARGV[2]) and ($ARGV[2] =~ m~^(.t)$~ or $ARGV[2] =~ m~^(.)$~) ){
    printYellow("Found a command line argument consisting of one character.\n Assuming \"$1\" is the CVS deliminator.\n");
    $CVSDeliminator = $ARGV[2];
}
elsif( defined($ARGV[2]) and $FileName =~ m~\.csv$~i ){ 
    printYellow("Found a command line argument consisting of multiple characters and a cvs-extension in the filename.\n Assuming \"$ARGV[2]\" is the CVS deliminator.\n");
    $CVSDeliminator = $ARGV[2];
}

# Determine operating system.
my $OperatingSystem = "$^O";
if ($OperatingSystem eq "linux"){ print "Operating system is $OperatingSystem: All good to go!\n";}
else{ print "Operating system is $OperatingSystem: Not linux, so I am assuming Windows!\n";}

# Checks for inline base64 coding.
# Image inline coding won't work for pocketbook dictionary.
if ($isCreatePocketbookDictionary and $isCodeImageBase64){
    debug("Images won't be encoded in reconstructed dictionary, if Pocketbook dictionary creation is enabled.");
    debug("The definition would become too long and crash 'converter.exe'.");
    debug("Set \"\$isCreatePocketbookDictionary = 0;\" if you want imaged encoded inline for Stardict- and XDXF-format.");
}
# Load pragmas for image coding.
# To store/load the hash %ReplacementImageStrings or %ValidatedOCRedImages.

my (%ReplacementImageStrings, $ReplacementImageStringsHashFileName);
if( $isCodeImageBase64 ){
    use MIME::Base64;    # To encode into Bas64
    $ReplacementImageStringsHashFileName = join('', $FileName=~m~^(.+?\.)[^.]+$~)."replacement.hash";
    if( -e $ReplacementImageStringsHashFileName ){ %ReplacementImageStrings = %{ retrieveHash($ReplacementImageStringsHashFileName)}; }
    storeHash(\%ReplacementImageStrings, $ReplacementImageStringsHashFileName); # To check whether filename is storable.
    if( scalar keys %ReplacementImageStrings == 0 ){ unlink $ReplacementImageStringsHashFileName; }
}

my (%OCRedImages, %ValidatedOCRedImages, $ValidatedOCRedImagesHashFileName);
my $isManualValidation = 1;
if( $isConvertImagesUsingOCR ){
    use Image::OCR::Tesseract 'get_ocr';
    $Image::OCR::Tesseract::DEBUG = 0;
    $ValidatedOCRedImagesHashFileName = join('', $FileName=~m~^(.+?\.)[^.]+$~)."validation.hash";
    if( -e $ValidatedOCRedImagesHashFileName ){ %ValidatedOCRedImages = %{ retrieveHash($ValidatedOCRedImagesHashFileName)}; }
    %OCRedImages = %ValidatedOCRedImages;
    info("Number of imagestrings OCRed is ".scalar keys %ValidatedOCRedImages);
    unless( storeHash(\%ValidatedOCRedImages, $ValidatedOCRedImagesHashFileName) ){ warn "Cannot store hash ValidatedOCRedImages."; Die();} # To check whether filename is storable.
    if( scalar keys %ValidatedOCRedImages == 0 ){ unlink $ValidatedOCRedImagesHashFileName; }
    else{ info("Mistakes in the validated values can be manually corrected by editing '$ValidatedOCRedImagesHashFileName'"); }
}

# Path checking and cleaning
$BaseDir=~s~/$~~; # Remove trailing slashforward '/'.
if( -e "$BaseDir/converter.exe"){
    debugV("Found converter.exe in the base directory $BaseDir.");
}
elsif( $isCreatePocketbookDictionary ){
    debug("Can't find converter.exe in the base directory $BaseDir. Cannot convert to Pocketbook.");
    $isCreatePocketbookDictionary = 0;
}
else{ debugV("Base directory not containing \'converter.exe\' for PocketBook dictionary creation.");}
# Pocketbook converter.exe is dependent on a language directory in which has 3 txt-files: keyboard, morphems and collates.
# Default language directory is English, "en".

$KindleUnpackLibFolder=~s~/$~~; # Remove trailing slashforward '/'.
if( -e "$KindleUnpackLibFolder/kindleunpack.py"){
    debugV("Found \'kindleunpack.py\' in $KindleUnpackLibFolder.");
}
elsif( $isHandleMobiDictionary ){
    debug("Can't find \'kindleunpack.py\' in $KindleUnpackLibFolder. Cannot handle mobi dictionaries.");
    $isHandleMobiDictionary = 0;
}
else{ debugV("$KindleUnpackLibFolder doesn't contain \'kindleunpack.py\' for mobi-format handling.");}
chdir $BaseDir || warn "Cannot change to $BaseDir: $!\n";
my $LocalPath = join('', $FileName=~ m~^(.+?)/[^/]+$~);
my $FullPath = "$BaseDir/$LocalPath";
debug("Local path is $LocalPath.");
debug("Full path is $FullPath");

# As NouveauLittre showed a rather big problem with named entities, I decided to write a special filter
# Here is the place to insert your DOCTYPE string.
# Remember to place it between quotes '..' and finish the line with a semicolon ;
# Last Doctype will be used.
# To omit the filter place an empty DocType string at the end:
# $DocType = '';
my ($DocType,%EntityConversion);
$DocType = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"[<!ENTITY ns "&#9830;"><!ENTITY os "&#8226;"><!ENTITY oo "&#8250;"><!ENTITY co "&#8249;"><!ENTITY a  "&#x0061;"><!ENTITY â  "&#x0251;"><!ENTITY an "&#x0251;&#x303;"><!ENTITY b  "&#x0062;"><!ENTITY d  "&#x0257;"><!ENTITY e  "&#x0259;"><!ENTITY é  "&#x0065;"><!ENTITY è  "&#x025B;"><!ENTITY in "&#x025B;&#x303;"><!ENTITY f  "&#x066;"><!ENTITY g  "&#x0261;"><!ENTITY h  "&#x0068;"><!ENTITY h2 "&#x0027;"><!ENTITY i  "&#x0069;"><!ENTITY j  "&#x004A;"><!ENTITY k  "&#x006B;"><!ENTITY l  "&#x006C;"><!ENTITY m  "&#x006D;"><!ENTITY n  "&#x006E;"><!ENTITY gn "&#x0272;"><!ENTITY ing "&#x0273;"><!ENTITY o  "&#x006F;"><!ENTITY o2 "&#x0254;"><!ENTITY oe "&#x0276;"><!ENTITY on "&#x0254;&#x303;"><!ENTITY eu "&#x0278;"><!ENTITY un "&#x0276;&#x303;"><!ENTITY p  "&#x0070;"><!ENTITY r  "&#x0280;"><!ENTITY s  "&#x0073;"><!ENTITY ch "&#x0283;"><!ENTITY t  "&#x0074;"><!ENTITY u  "&#x0265;"><!ENTITY ou "&#x0075;"><!ENTITY v  "&#x0076;"><!ENTITY w  "&#x0077;"><!ENTITY x  "&#x0078;"><!ENTITY y  "&#x0079;"><!ENTITY z  "&#x007A;"><!ENTITY Z  "&#x0292;">]><html xml:lang="fr" xmlns="http://www.w3.org/1999/xhtml"><head><title></title></head><body>';
if( $DoNotFilterDocType ){ $DocType = ''; }
my @CleanHTMLTags = ( "<!--...-->", "<!DOCTYPE>", "<a>", "<abbr>", "<acronym>", "<address>", "<applet>", "<area>", "<aside>", "<audio>", "<b>", "<base>", "<basefont>", "<bdi>", "<bdo>", "<big>", "<blockquote>", "<body>", "<br>", "<button>", "<canvas>", "<caption>", "<center>", "<cite>", "<code>", "<col>", "<colgroup>", "<data>", "<datalist>", "<dd>", "<del>", "<details>", "<dfn>", "<dialog>", "<dir>", "<div>", "<dl>", "<dt>", "<em>", "<embed>", "<fieldset>", "<figcaption>", "<figure>", "<font>", "<footer>", "<form>", "<frame>", "<frameset>", "<h1>", "<header>", "<hr>", "<html>", "<i>", "<iframe>", "<img>", "<input>", "<ins>", "<kbd>", "<label>", "<legend>", "<li>", "<link>", "<main>", "<map>", "<mark>", "<meta>", "<meter>", "<nav>", "<noframes>", "<noscript>", "<object>", "<ol>", "<optgroup>", "<option>", "<output>", "<p>", "<param>", "<picture>", "<pre>", "<progress>", "<q>", "<rp>", "<rt>", "<ruby>", "<s>", "<samp>", "<script>", "<section>", "<select>", "<small>", "<source>", "<span>", "<strike>", "<strong>", "<style>", "<sub>", "<summary>", "<sup>", "<svg>", "<table>", "<tbody>", "<td>", "<template>", "<textarea>", "<tfoot>", "<th>", "<thead>", "<time>", "<title>", "<tr>", "<track>", "<tt>", "<u>", "<ul>", "<var>", "<video>", "<wbr>" );
my @ExcludedHTMLTags = ( "<head>", "<article>", );

my @xdxf_start = (     '<?xml version="1.0" encoding="UTF-8" ?>'."\n",
                '<xdxf lang_from="" lang_to="" format="visual">'."\n",
                '<full_name></full_name>'."\n",
                '<description>'."\n",
                '<date></date>'."\n",
                'Created with pocketbookdic.pl'."\n",
                '</description>'."\n");
my $lastline_xdxf = "</xdxf>\n";
my @xml_start = (     '<?xml version="1.0" encoding="UTF-8" ?>'."\n",
                    '<stardict xmlns:xi="http://www.w3.org/2003/XInclude">'."\n",
                    '<info>'."\n",
                    '<version>2.4.2</version>'."\n",
                    '<bookname></bookname>'."\n",
                    '<author>pocketbookdic.pl</author>'."\n",
                    '<email>rather_open_issue@github.com</email>'."\n",
                    '<website>https://github.com/Markismus/PocketBookDic</website>'."\n",
                    '<description></description>'."\n",
                    '<date>'.gmtime().'</date>'."\n",
                    # '<dicttype></dicttype>'."\n",
                    '</info>'."\n");
my $lastline_xml = "</stardict>\n";

# Localized Roman Package, because LCL uses lxxxx, which is strictly speaking not a roman number.
#Begin
my %roman2arabic = qw(I 1 V 5 X 10 L 50 C 100 D 500 M 1000);
my %roman_digit = qw(1 IV 10 XL 100 CD 1000 MMMMMM);
my @figure = reverse sort keys %roman_digit;
$roman_digit{$_} = [split(//, $roman_digit{$_}, 2)] foreach @figure;

sub isroman{
    my $String= shift;

    if(    defined $String and $String=~m/^[ivxlcm]+$/    ){    return(1);    }
    else{    return(0);    }
}
sub arabic{
    my $arg = shift;
    isroman $arg or return undef;
    my($last_digit) = 1000;
    my($arabic);
    foreach (split(//, uc $arg)) {
        my($digit) = $roman2arabic{$_};
        $arabic -= 2 * $last_digit if $last_digit < $digit;
        $arabic += ($last_digit = $digit);
    }
    $arabic;
}
sub Roman{
    my $arg = shift;
    0 < $arg and $arg < 4000 or return undef;
    my($x, $roman);
    foreach (@figure) {
        my($digit, $i, $v) = (int($arg / $_), @{$roman_digit{$_}});
        if (1 <= $digit and $digit <= 3) {
            $roman .= $i x $digit;
        } elsif ($digit == 4) {
            $roman .= "$i$v";
        } elsif ($digit == 5) {
            $roman .= $v;
        } elsif (6 <= $digit and $digit <= 8) {
            $roman .= $v . $i x ($digit - 5);
        } elsif ($digit == 9) {
            $roman .= "$i$x";
        }
        $arg -= $digit * $_;
        $x = $i;
    }
    $roman;
}
sub roman{
    lc Roman shift;
}
sub sortroman{
    return ( sort {arabic($a) <=> arabic($b)} @_ );
}
#End Localized Roman Package

sub array2File {
    my ( $FileName, @Array ) = @_;
    if( $FileName =~ m~(?<dir>.*)/(?<file>[^/]+)~ ){
        my $dir = $+{dir};
        my $file = $+{file};
        unless( -r $dir){
            warn "Can't read '$dir'";
            $dir =~ s~ ~\\ ~g;
            unless( -r $dir ){ warn "Can't read '$dir' with escaped spaces."; }
        }
        unless( -w $dir){ warn "Can't write '$dir'"; }


    }
    debugV("Array to be written:\n",@Array);
    if( -e $FileName){ warn "$FileName already exist" if $isDebugVerbose; };
    unless( open( FILE, ">:encoding(utf8)", $FileName ) ){
      warn "Cannot open $FileName: $!\n";
      Die() ;
    }
    print FILE @Array;
    close(FILE);
    $FileName =~ s/.+\/(.+)/$1/;
    printGreen("Written $FileName. Exiting sub array2File\n") if $isDebugVerbose;
    return ("File written");}
sub debug { $isDebug and printRed( @_, "\n" ); return(1);}
sub debug_t { $isDebug and $isTestingOn and printRed( @_, "\n" ); return(1);}
sub debugV { $isDebugVerbose and printBlue( @_, "\n" ); return(1);}
sub debugVV { $isDebugVeryVerbose and printBlue( @_, "\n" ); return(1);}
sub debugFindings {
    debugV();
    if ( defined $1 )  { debugV("\$1 is: \"$1\"\n"); }
    if ( defined $2 )  { debugV("\$2 is: \"$2\"\n"); }
    if ( defined $3 )  { debugV("\$3 is: \"$3\"\n"); }
    if ( defined $4 )  { debugV("\$4 is:\n $4\n"); }
    if ( defined $5 )  { debugV("5 is:\n $5\n"); }
    if ( defined $6 )  { debugV("6 is:\n $6\n"); }
    if ( defined $7 )  { debugV("7 is:\n $7\n"); }
    if ( defined $8 )  { debugV("8 is:\n $8\n"); }
    if ( defined $9 )  { debugV("9 is:\n $9\n"); }
    if ( defined $10 ) { debugV("10 is:\n $10\n"); }
    if ( defined $11 ) { debugV("11 is:\n $11\n"); }
    if ( defined $12 ) { debugV("12 is:\n $12\n"); }
    if ( defined $13 ) { debugV("13 is:\n $13\n"); }
    if ( defined $14 ) { debugV("14 is:\n $14\n"); }
    if ( defined $15 ) { debugV("15 is:\n $15\n"); }
    if ( defined $16 ) { debugV("16 is:\n $16\n"); }
    if ( defined $17 ) { debugV("17 is:\n $17\n"); }
    if ( defined $18 ) { debugV("18 is:\n $18\n"); }}
sub Die{
    sub showCallStack {
      my ( $path, $line, $subr );
      my $max_depth = 30;
      my $i = 1;
        debug("--- Begin stack trace ---");
        while ( ( my @call_details = (caller($i++)) ) && ($i<$max_depth) ) {
        debug("$call_details[1] line $call_details[2] in function $call_details[3]");
        }
        debug("--- End stack trace ---");
    }

    showCallStack();
    die;}
sub checkSameTypeSequence{
    my $FileName = $_[0];
    if(! $updateSameTypeSequence ){return;}
    elsif( -e substr($FileName, 0, (length($FileName)-4)).".ifo"){
        my $ifo = join( '',  file2Array(substr($FileName, 0, (length($FileName)-4)).".ifo") ) ;
        if($ifo =~ m~sametypesequence=(?<sametypesequence>\w)~s){
            printGreen("Initial sametypesequence was \"$SameTypeSequence\".");
            $SameTypeSequence = $+{sametypesequence};
            printGreen(" Updated to \"$SameTypeSequence\".\n");
        }
    }
    elsif( -e substr($FileName, 0, (length($FileName)-4)).".xml"){
        my $xml = join( '',  file2Array(substr($FileName, 0, (length($FileName)-4)).".xml") );
        # Extract sametypesequence from Stardict XML
        if( $xml =~ m~<definition type="(?<sametypesequence>\w)">~s){
            printGreen("Initial sametypesequence was \"$SameTypeSequence\".");
            $SameTypeSequence = $+{sametypesequence};
            printGreen(" Updated to \"$SameTypeSequence\".\n");
        }
    }
    return;}
my %AlreadyMentionedStylingHTMLTags;
sub cleanOuterTags{
    my $block = shift;
    $block =~ s~^\s+~~s;
    $block =~ s~\s+$~~s;
    if( $block !~ m~^<~ ){ infoV("No outer tag"); return $block; }
    my $Start = startTag( $block );
    foreach( @CleanHTMLTags ){
        if( $Start =~ m~$_~i ){
            info("Styling HTML tag '$_' found as outer start tag.") unless $AlreadyMentionedStylingHTMLTags{ $_ };
            $AlreadyMentionedStylingHTMLTags{ $_ } = 1;
            return( $block);
        }
    }
    my $Stop = stopFromStart( $Start );
    unless( $block =~ s~^$Start~~s ){ warn "Regex for removal of block start-tag doesn't match."; Die(); }
    unless( $block =~ s~$Stop$~~s ){ warn "Regex for removal of block stop-tag doesn't match."; Die(); }
    return $block;}
sub cleanseAr{
    my @Content = @_;
    my $Content = join('',@Content) ;
    
    # Special characters in $head and $def should be converted to
    #  &lt; (<), &amp; (&), &gt; (>), &quot; ("), and &apos; (')
    my $PossibleTags = qr~/?(def|mbp|c>|c c="|abr>|ex>|kref>|k>|key|rref|f>|!--|!doctype|a|abbr|acronym|address|applet|area|article|aside|audio|b>|base|basefont|bb|bdo|big|blockquote|body|/?br|button|canvas|caption|center|cite|code|col|colgroup|command|datagrid|datalist|dd|del|details|dfn|dialog|dir|div|dl|dt|em|embed|eventsource|fieldset|figcaption|figure|font|footer|form|frame|frameset|h[1-6]|head|header|hgroup|hr/|html|i>|i |iframe|img|input|ins|isindex|kbd|keygen|label|legend|li|link|map|mark|menu|meta|meter|nav|noframes|noscript|object|ol|optgroup|option|output|p|param|pre|progress|q>|rp|rt|ruby|s>|samp|script|section|select|small|source|span|strike|strong|style|sub|sup|table|tbody|td|textarea|tfoot|th|thead|time|title|tr|track|tt|u>|ul|var|video|wbr)~;
    my $HTMLcodes = qr~(lt;|amp;|gt;|quot;|apos;|\#x?[0-9A-Fa-f]{1,6})~;
        
    $Content =~ s~(?<lt><)(?!$PossibleTags)~&lt;~gs if $EscapeHTMLCharacters;
    $Content =~ s~(?<amp>&)(?!$HTMLcodes)~&amp;~gs if $EscapeHTMLCharacters;
    
    # Remove preceding and trailing empty lines.
    $Content =~ s~^\n~~gs;
    $Content =~ s~\n$~~gs;

    if( $Content =~ m~^<head>(?<head>(?:(?!</head).)+)</head><def>(?<def>(?:(?!</def).)+)</def>~s){
        # debugFindings();
        # debug("Well formed ar content entry");
        my $head = $+{head};
        my $def_old = $+{def};
        my $def = $def_old;
        $def =~ s~</?mbp[^>]*>~~sg;

        my $ExtraDebugging = 0;
        if( $head eq $DebugKeyWordCleanseAr ){ debug("Found debug keyword in cleanseAr. Extra debugging on for this article."); $ExtraDebugging = 1; }
        if( $ExtraDebugging ){ debug("\$max_line_length\t=\t$max_line_length"); }

        if( $isCreatePocketbookDictionary){
            # Splits complex blockquote blocks from each other. Small impact on layout.
            $def =~ s~</blockquote><blockquote>~</blockquote>\n<blockquote>~gs;
            # Splits blockquote from next heading </blockquote><b><c c=
            $def =~ s~</blockquote><b><c c=~</blockquote>\n<b><c c=~gs;
            # Remove base64 encoded content: $replacement = '<img src="data:image/'.$imageformat.';base64,'.$encoded.'" alt="'.$imageName.'"/>';
            $def =~ s~<img src="data:[^/]+/[^;]+;base64[^>]+>~~g;
            # Splits the too long lines.
            if( length($def) > 2000){ $def = join('', tidyXMLArray( $def ) );}
            my @def = split(/\n/,$def);
            my $def_line_counter = 0;
            foreach my $line (@def){
                 $def_line_counter++;
                 if( $ExtraDebugging ){ debug("'$line'");}
                
                my $lengthLineUTF8 = length(encode('UTF-8', $line));
                my $lengthLine = length($line);
                if( $lengthLine == 0){ next; }
                my $RatioLenghtUTF = $lengthLineUTF8 / $lengthLine;

                if( $ExtraDebugging ){ debug("\$lengthLineUTF8\t=\t$lengthLineUTF8 (bytes)"); debug("\$lengthLine\t=\t$lengthLine (chars)"); debug("\$RatioLenghtUTF = $RatioLenghtUTF"); }
                 # Finetuning of cut location
                 if ( $lengthLineUTF8 > $max_line_length){
                    if ( $isCutDoneWithTidyXML ){ $line = join('', tidyXMLArray( $line ) ); next; }
                     if( $ExtraDebugging ){ debug("\$lengthLineUTF8 > $max_line_length"); }
                     # So I would like to cut the line at say 3500 chars not in the middle of a tag, so before a tag.
                     # index STR,SUBSTR,POSITION
                     sub cutsize{
                         # Usage: $cutsize = cutsize( $line, $cut_location);
                         my ($line, $cut_location) = @_;
                         my $bytesize = length(encode('UTF-8', substr($line, 0, $cut_location) ) );
                         return $bytesize;
                     }
                     my $cut_location = rindex $line, "<", int($max_line_length * 0.85 / $RatioLenghtUTF );
                     if($cut_location < 1 ){
                         # No "<" found.
                         if( $ExtraDebugging ){ debug("No '<' found."); }
                         $cut_location = (rindex $line, " ", int($max_line_length * 0.85 / $RatioLenghtUTF)) + 1 ;
                         if($cut_location < 1){
                             debug("No Space found in substring. Quitting"); die;
                         }
                     }
                     elsif(cutsize( $line, $cut_location) > $max_line_length){
                         debug("Don't know what happend, yet." );
                         debug("Line");
                         debug($line);
                         debug("\$lengthLineUTF8\t=\t$lengthLineUTF8 (bytes)"); debug("\$lengthLine\t=\t$lengthLine (chars)"); debug("\$RatioLenghtUTF = $RatioLenghtUTF");
                         debug("\$max_line_length\t=\t$max_line_length");
                         debug("\$cut_location\t=\t$cut_location");
                         debug("int($max_line_length * 0.85 / $RatioLenghtUTF )\t=\t",int($max_line_length * 0.85 / $RatioLenghtUTF ));
                         debug("index \$line, \"<\", int(\$max_line_length * 0.85 / \$RatioLenghtUTF )\t=\t", index $line, "<", int($max_line_length * 0.85 / $RatioLenghtUTF ));
                         debug("rindex \$line, \"<\", int(\$max_line_length * 0.85 / \$RatioLenghtUTF )\t=\t", rindex $line, "<", int($max_line_length * 0.85 / $RatioLenghtUTF ));
                         debug("rindex \$line, \"<\", int(\$max_line_length * 0.85 / \$RatioLenghtUTF )\t=\t", rindex substr($line, 0, int($max_line_length * 0.85 / $RatioLenghtUTF )), "<");
                         debug("cutsize is too big: ",cutsize( $line, $cut_location));
                         debug("First piece");
                         debug(substr($line, 0, $cut_location));
                         debug("Second piece");
                         debug(substr($line, $cut_location));
                         die;


                     }
                     debugV("Definition line $def_line_counter of lemma $head is ",length($line)," characters and ",length(encode('UTF-8', $line))," bytes. Cut location is $cut_location.");
                     my $cutline_begin = substr($line, 0, $cut_location)."\n";
                     if( $ExtraDebugging ){ debug("cutline_begin is ",length(encode('UTF-8', $cutline_begin))," bytes"); }
                     my $cutline_end = substr($line, $cut_location);
                     if( $ExtraDebugging){ debug("Line taken to be cut:") and printYellow("$line\n") and
                     debug("First part of the cut line is:") and printYellow("$cutline_begin\n") and
                     debug("Last part of the cut line is:") and printYellow("$cutline_end\n"); }

                     die if ($cut_location > $max_line_length) and $isRealDead;
                     # splice array, offset, length, list
                     splice @def, $def_line_counter, 0, ($cutline_end);
                     $line = $cutline_begin;
                 }
            }
            $def = join("\n",@def);
            # debug($def);
            # Creates multiple articles if the article is too long.

            my $def_bytes = length(encode('UTF-8', $def));
            if( $def_bytes > $max_article_length ){
                debugV("The length of the definition of \"$head\" is $def_bytes bytes.");
                #It should be split in chunks < $max_article_length , e.g. 64kB
                my @def=split("\n", $def);
                my @definitions=();
                my $counter = 0;
                my $loops = 0;
                my $concatenation = "";
                # Split the lines of the definition in separate chunks smaller than 90kB
                foreach my $line(@def){
                    $loops++;
                    # debug("\$loops is $loops. \$counter at $counter" );
                    $concatenation = $definitions[$counter]."\n".$line;
                    if( length(encode('UTF-8', $concatenation)) > $max_article_length ){
                        debugV("Chunk is larger than ",$max_article_length,". Creating another chunk.");
                        chomp $definitions[$counter];
                        $counter++;

                    }
                    $definitions[$counter] .= "\n".$line;
                }
                chomp $definitions[$counter];
                # Join the chunks with the relevant extra tags to form multiple ar entries.
                # $Content is between <ar> and </ar> tags. It consists of <head>$head</head><def>$def_old</def>
                # So if $def is going to replace $def_old in the later substitution: $Content =~ s~\Q$def_old\E~$def~s; ,
                # how should the chunks be assembled?
                # $defs[0]."</def></ar><ar><head>$head</head><def>".$defs[1]."...".$def[2]
                my $newhead = $head;
                $newhead =~ s~</k>~~;
                # my @Symbols = (".",":","⁝","⁞");
                # my @Symbols = ("a","aa","aaa","aaaa");
                my @Symbols = ("","","","");
                # debug("Counter reached $counter.");
                $def="";
                for(my $a = 0; $a < $counter; $a = $a + 1 ){
                        # debug("\$a is $a");
                        $def.=$definitions[$a]."</def>\n</ar>\n<ar>\n<head>$newhead$Symbols[$a]</k></head><def>\n";
                        debugV("Added chunk ",($a+1)," to \$def together with \"</def></ar>\n<ar><head>$newhead$Symbols[$a]</k></head><def>\".");
                }
                $def .= $definitions[$counter];

            }

        }



        if($remove_color_tags){
            # Removes all color from lemma description.
            # <c c="darkslategray"><c>Derived:</c></c> <c c="darkmagenta">
            # Does not remove for example <span style="color:#472565;"> and corresponding </span>!!!
            # Does not remove for example <font color="#007000">noun</font>!!!
            $def =~ s~<\?c>~~gs;
            $def =~ s~<c c=[^>]+>~~gs;
            # Does not remove span-blocks with nested html-blocks.
            $def =~ s~<span style="color:#\d+;">(?<colored_text>[^<]*)</span>~$+{colored_text}~gs;
            # Does not remove font-blocks with nested html-blocks.
            $def =~ s~<font color="#\d+">(?<colored_text>[^<]*)</font>~$+{colored_text}~gs;
        }

        $Content =~ s~\Q$def_old\E~$def~s;
    }
    else{debug("Not well formed ar content!!\n\"$Content\"");}

    if ($isRemoveWaveReferences){
        # remove wav-files displaying
        # Example:
        # <rref>
        #z_epee_1_gb_2.wav</rref>
        #<rref>z_a__gb_2.wav</rref>
        # <c c="blue"><b>ac</b>‧<b>quaint</b></c> /əˈkweɪnt/ <abr>BrE</abr> <rref>bre_ld41acquaint.wav</rref> <abr>AmE</abr> <rref>ame_acquaint.wav</rref><i><c> verb</c></i><c c="green"> [transitive]</c><i><c c="maroon"> formal</c></i>
        $Content =~ s~(<abr>(AmE|BrE)</abr>)? *<rref>((?!\.wav</rref>).)+\.wav</rref>~~gs;
    }

    return( $Content );}
sub convertBlockquote2Div{
    # return (@_);
    waitForIt('Converting <blockquote-tags to <div style:"margin 0 0 0 1em;">-tags.');
    my $html = join('', @_);

    $html =~ s~</blockquote>~</div>~sg;

    while( $html =~ m~(?<starttag><blockquote(?<styling>[^>]*)>)~s ){
        my $StartTag    = $+{starttag};
        my $Styling     = $+{styling};
        my $Div;
        if( $Styling =~ s~(?<style>style=")~$+{style}margin: 0 0 0 1em; ~){ $Div = '<div'.$Styling.'>';}
        else{ $Div = '<div'.$Styling.' style="margin: 0 0 0 1em;">'; }
        $html =~ s~\Q$StartTag\E~$Div~sg;
    }
    $html =~ s~(<div[^>]*>)\n~$1~sg;
    if( scalar @_ > 1 ){ return split(/^/, $html) ; }
    else{ return $html; }}
sub convertColorName2HexValue{
    my $html = join( '', @_);
    my %ColorCoding = qw( aliceblue #F0F8FF  antiquewhite #FAEBD7  aqua #00FFFF  aquamarine #7FFFD4  azure #F0FFFF  beige #F5F5DC  bisque #FFE4C4  black #000000  blanchedalmond #FFEBCD  blue #0000FF  blueviolet #8A2BE2  brown #A52A2A  burlywood #DEB887  cadetblue #5F9EA0  chartreuse #7FFF00  chocolate #D2691E  coral #FF7F50  cornflowerblue #6495ED  cornsilk #FFF8DC  crimson #DC143C  cyan #00FFFF  darkblue #00008B  darkcyan #008B8B  darkgoldenrod #B8860B  darkgray #A9A9A9  darkgrey #A9A9A9  darkgreen #006400  darkkhaki #BDB76B  darkmagenta #8B008B  darkolivegreen #556B2F  darkorange #FF8C00  darkorchid #9932CC  darkred #8B0000  darksalmon #E9967A  darkseagreen #8FBC8F  darkslateblue #483D8B  darkslategray #2F4F4F  darkslategrey #2F4F4F  darkturquoise #00CED1  darkviolet #9400D3  deeppink #FF1493  deepskyblue #00BFFF  dimgray #696969  dimgrey #696969  dodgerblue #1E90FF  firebrick #B22222  floralwhite #FFFAF0  forestgreen #228B22  fuchsia #FF00FF  gainsboro #DCDCDC  ghostwhite #F8F8FF  gold #FFD700  goldenrod #DAA520  gray #808080  grey #808080  green #008000  greenyellow #ADFF2F  honeydew #F0FFF0  hotpink #FF69B4  indianred  #CD5C5C  indigo  #4B0082  ivory #FFFFF0  khaki #F0E68C  lavender #E6E6FA  lavenderblush #FFF0F5  lawngreen #7CFC00  lemonchiffon #FFFACD  lightblue #ADD8E6  lightcoral #F08080  lightcyan #E0FFFF  lightgoldenrodyellow #FAFAD2  lightgray #D3D3D3  lightgrey #D3D3D3  lightgreen #90EE90  lightpink #FFB6C1  lightsalmon #FFA07A  lightseagreen #20B2AA  lightskyblue #87CEFA  lightslategray #778899  lightslategrey #778899  lightsteelblue #B0C4DE  lightyellow #FFFFE0  lime #00FF00  limegreen #32CD32  linen #FAF0E6  magenta #FF00FF  maroon #800000  mediumaquamarine #66CDAA  mediumblue #0000CD  mediumorchid #BA55D3  mediumpurple #9370DB  mediumseagreen #3CB371  mediumslateblue #7B68EE  mediumspringgreen #00FA9A  mediumturquoise #48D1CC  mediumvioletred #C71585  midnightblue #191970  mintcream #F5FFFA  mistyrose #FFE4E1  moccasin #FFE4B5  navajowhite #FFDEAD  navy #000080  oldlace #FDF5E6  olive #808000  olivedrab #6B8E23  orange #FFA500  orangered #FF4500  orchid #DA70D6  palegoldenrod #EEE8AA  palegreen #98FB98  paleturquoise #AFEEEE  palevioletred #DB7093  papayawhip #FFEFD5  peachpuff #FFDAB9  peru #CD853F  pink #FFC0CB  plum #DDA0DD  powderblue #B0E0E6  purple #800080  rebeccapurple #663399  red #FF0000  rosybrown #BC8F8F  royalblue #41690  saddlebrown #8B4513  salmon #FA8072  sandybrown #F4A460  seagreen #2E8B57  seashell #FFF5EE  sienna #A0522D  silver #C0C0C0  skyblue #87CEEB  slateblue #6A5ACD  slategray #708090  slategrey #708090  snow #FFFAFA  springgreen #00FF7F  steelblue #4682B4  tan #D2B48C  teal #008080  thistle #D8BFD8  tomato #FF6347  turquoise #40E0D0  violet #EE82EE  wheat #F5DEB3  white #FFFFFF  whitesmoke #F5F5F5  yellow #FFFF00  yellowgreen #9ACD32 );
    
    waitForIt("Converting all color names to hex values.");
    # This loop takes 1m26s for a dictionary with 132k entries and no color tags.
    # foreach my $Color(keys %ColorCoding){
    #     $html =~ s~c="$Color">~c="$ColorCoding{$Color}">~isg;
    #     $html =~ s~color:$Color>~c:$ColorCoding{$Color}>~isg;
    # }

    # This takes 1s for a dictionary with 132k entries and no color tags
    # Not tested with Oxford 2nd Ed. yet!!
    $html =~ s~c="(\w+)">~c="$ColorCoding{lc($1)}">~isg;
    # $html =~ s~color:(\w+)>~c:$ColorCoding{lc($1)}>~isg;
    # <span style="color:orchid">▪</span> <i><span style="color:sienna">I stepped back to let them pass.</span>
    # $html =~ s~<span style="color:(?<color>\w+)">(?<colored>(?!</span>).*?)</span>~<span style="color:$ColorCoding{lc($+{color})}">$+{colored}</span>~isg;
    $html =~ s~color:(?<color>\w+)~color:$ColorCoding{lc($+{color})}~isg;
    doneWaiting();
    return( split(/^/,$html) );}
sub convertCVStoXDXF{
    my @cvs = @_;
    my @xdxf = @xdxf_start;
    my $number= 0;
    info("\$CVSDeliminator is \'$CVSDeliminator\'.") if $number<10;
    foreach(@cvs){
        $number++;
        info("CVS line is: $_") if $number<10;
        m~\Q$CVSDeliminator\E~;
        my $key = $`; # Special variable $PREMATCH
        my $def = $'; # Special variable $POSTMATCH
        info("key found: '$key'") if $number<10;
        info("def found: '$def'") if $number<10;
        unless( defined $key and defined $def ){
            warn "key and/or definition are undefined.";
            debug("CVSDeliminator is '$CVSDeliminator'");
            debug("CVS line is '$_'");
            debug("Array index is $number");
            Die();
        }
        # Remove whitespaces at the beginning of the definition and EOL at the end.
        $def =~ s~^\s+~~;
        $def =~ s~\s+$~~;
        push @xdxf, "<ar><head><k>$key</k></head><def>$def</def></ar>\n";
        debug("Pushed <ar><head><k>$key</k></head><def>$def</def></ar>") if $number<10;
    }
    push @xdxf, $lastline_xdxf;
    return(@xdxf);}
sub convertImage2Base64{
    $_ =  shift;
    my @imagestrings = m~(<img[^>]+>)~sg;
    debug("Number of imagestrings found is ", scalar @imagestrings) if m~<idx:orth value="$DebugKeyWordConvertHTML2XDXF"~;
    my $replacement;
    foreach my $imagestring(@imagestrings){
        # debug('$ReplacementImageStrings{$imagestring}: ',$ReplacementImageStrings{$imagestring});
        if ( exists $ReplacementImageStrings{$imagestring} ){
            $replacement = $ReplacementImageStrings{$imagestring}
        }
        else{
            # <img hspace="0" align="middle" hisrc="Images/image15907.gif"/>
            $imagestring =~ m~hisrc="(?<image>[^"]*?\.(?<ext>gif|jpg|png|bmp))"~si;
            debug("Found image named $+{image} with extension $+{ext}.") if m~<idx:orth value="$DebugKeyWordConvertHTML2XDXF"~;
            my $imageName = $+{image};
            my $imageformat = $+{ext};
            if( -e "$FullPath/$imageName"){
                if ( $isConvertGIF2PNG and $imageformat =~ m~gif~i){
                    # Convert gif to png
                    my $Command="convert \"$FullPath/$imageName\" \"$FullPath/$imageName.png\"";
                    debug("Executing command: $Command") if m~<idx:orth value="$DebugKeyWordConvertHTML2XDXF"~;
                    `$Command`;
                    $imageName = "$imageName.png";
                    $imageformat = "png";
                }
                my $image = join('', file2Array("$FullPath/$imageName", "raw", "quiet") );
                my $encoded = encode_base64($image);
                $encoded =~ s~\n~~sg;
                $replacement = '<img src="data:image/'.$imageformat.';base64,'.$encoded.'" alt="'.$imageName.'"/>';
                $replacement =~ s~\\\"~"~sg;
                debug($replacement) if m~<idx:orth value="$DebugKeyWordConvertHTML2XDXF"~;
                $ReplacementImageStrings{$imagestring} = $replacement;
            }
            else{
                if( $isRealDead ){ debug("Can't find $FullPath/$imageName. Quitting."); die; }
                else{ $replacement = ""; }
            }
        }
        s~\Q$imagestring\E~$replacement~;
    }
    return $_;}
sub convertIMG2Text{
    my $String = shift;
    info_t("Entering convertIMG2Text");
    debugVV( $String."\n");

    # Get absolute ImagePath
    my $CurrentDir = `pwd`; chomp $CurrentDir;
    unless( $CurrentDir eq $BaseDir){ warn "'$CurrentDir' is another than '$BaseDir'"; }
    else{ infoV("Working from '$BaseDir'"); }
    infoV("$FileName");
    unless( $FileName =~ m~(?<localpath>.+?)[^/]+$~ ){ warn "Regex didn't match for local path"; Die(); }
    my $ImagePath = $CurrentDir . "/" . $+{localpath};
    debugV( "Imagepath is '$ImagePath'");

    # Collect ImageStrings;
    my @ImageStrings = $String =~ m~(<img[^>]+>)~sg;
    unless( scalar @ImageStrings ){ warn "No imagestrings found in convertIMG2Text. Why is the sub called?"; return $String; }

    my $counter = 0;
    my %ImageStringsHandled;
    IMAGESTRING: foreach my $ImageString( @ImageStrings){
        # Deal with already handled imagestrings in $String.
        if( $ImageStringsHandled{ $ImageString } ){ next; }
        # Unhandled imagestring.
        $counter++;
        if( $ImageString =~ m~alt="x([0-9A-Fa-f]+)"~ ){
            infoV("Alternative expression for image is U+$1.");
            # my $smiley_from_code_point = "\N{U+263a}";
            my $Alt = chr( hex($1) );
            if( $String =~ s~\Q$ImageString\E~$Alt~sg ){
                infoV("Substituted imagestring '$ImageString' with '$Alt'");
                $ImageStringsHandled{ $ImageString } = 1;
                next IMAGESTRING;
            }
            else{ warn "Regex substitution alternative expression doesn't work."; Die(); }
        }
        my @Sources = $ImageString =~ m~(\w*src="[^"]+")~sg;
        unless( scalar @Sources ){
            warn "No sources found in imagestring:\n'$ImageString'";
            $ImageStringsHandled{ $ImageString } = 1;
            if( $isRemoveUnSourcedImageStrings ){
                unless( $String =~ s~\Q$ImageString\E~~sg){ warn "Couldn't remove unsourced imagestring"; Die(); }
                next IMAGESTRING;
            }
        }

        my %Sources;
        foreach( @Sources ){
            unless( m~(?<type>\w*src)="(?<imagename>[^"]+)"~s ){ warn "Regex sources doesn't work."; Die(); }
            $Sources{ $+{"imagename"} } = $+{"type"};
        }
        my %SourceQuality = { "src" => 1, "hisrc" => 2, "lowsrc" => 0 };
        sub sourceQuality{
            # Filename to src/hisrc/losrc to 1/2/0
            # Descending sort so $a and $b are swapped.
            $SourceQuality{ $Sources{ $b } } <=> $SourceQuality { $Sources { $a } }
        }
        SOURCE: foreach my $Source ( sort sourceQuality keys %Sources ){
            # Change to absolute path
            my $SourceInfo = "Quality of '$Source' is '$Sources{ $Source }'";
            $Source = $ImagePath . $Source;
            # If the source has been validated, act upon it.
            if( exists $ValidatedOCRedImages{ $Source } ){
                if( defined $ValidatedOCRedImages{ $Source } and $ValidatedOCRedImages{ $Source } ne "VALIDATED AS INCORRECT" ){
                    unless ( $String =~ s~\Q$ImageString\E~$ValidatedOCRedImages{ $Source }~sg ){
                        warn "ImageString '$ImageString' not matched for substitution with '$ValidatedOCRedImages{ $Source }'."; Die();
                    }
                    else{
                        infoV("ImageString '$ImageString' substituted with '$ValidatedOCRedImages{ $Source }'.");
                    }
                    $ImageStringsHandled{ $ImageString } = 1;
                    next IMAGESTRING;
                }
                else{ next SOURCE; }
            }
            # No validated recognition of source image available.
            elsif( $isManualValidation ){
                unless( -e $Source ){ warn "Image file '$Source' not found."; next SOURCE; }
                # No use in running the OCR twice.
                unless( exists $OCRedImages{ $Source } ){
                    my $text = get_ocr( $Source, undef, "eng+equ --psm 10" );
                    chomp $text;
                    info_t( "Imagestring =\n'".$ImageString."'");
                    info_t( $SourceInfo );
                    info( "Tesseract identified image '$Source' as '$text'");
                    $OCRedImages{ $Source } = $text;
                }
                if( $OCRedImages{ $Source } eq '' ){ debug("No result from OCR."); }

                # Validate OCRedImages manually and store them or quit.
                my $substitution = 0;
                system("feh --borderless --auto-zoom --image-bg white --geometry 300x300 \"$Source\"&");
                printGreen("\n\n--------->Is the image '$Source' correctly recognized as '".$OCRedImages{$Source}."'?\nPress enter to keep or provide a correction or quit manual validation [Enter|Provide correction|No|quit]");
                my $input = <STDIN>;
                system( "killall feh 2>/dev/null");
                chomp $input;
                if( $input =~ m~quit~i ){
                    $isManualValidation = 0;
                    next SOURCE;
                }
                elsif( $input eq ''){
                    $ValidatedOCRedImages{ $Source } = $OCRedImages{ $Source };
                    $substitution = 1;
                }
                elsif( $input =~ m~no~i ){
                    $ValidatedOCRedImages{ $Source } = "VALIDATED AS INCORRECT";
                    $substitution = 0;
                }
                else{
                    $ValidatedOCRedImages{ $Source } = $input;
                    $substitution = 1;
                }
                storeHash(\%ValidatedOCRedImages, $ValidatedOCRedImagesHashFileName);
               
                if( $substitution ){
                    unless ( $String =~ s~\Q$ImageString\E~$ValidatedOCRedImages{ $Source }~sg ){
                        warn "ImageString '$ImageString' not matched for substitution with '$ValidatedOCRedImages{ $Source }'";
                        Die();
                    }
                    $ImageStringsHandled{ $ImageString } = 1;
                    next IMAGESTRING;
                }
            }
        }
        # End SOURCE-loop. If the code is here, than no substitution has been made for the imagestring.
        if( $isRemoveUnSubstitutedImageString ){
            unless( $String =~ s~\Q$ImageString\E~~sg ){ warn "Image-tag '$ImageString' could not be removed"; Die(); }
            $ImageStringsHandled{ $ImageString } = 1;
        }
    }
    infoV("Leaving convertIMG2Text");
    return $String;
}
sub convertHTML2XDXF{
    # Converts html generated by KindleUnpack to xdxf
    my $encoding = shift @_;
    my $html = join('',@_);
    my @xdxf = @xdxf_start;
    # Content excerpt Duden 7. Auflage 2011:
        # <idx:entry scriptable="yes"><idx:orth value="a"></idx:orth><div height="4"><a id="filepos242708" /><a id="filepos242708" /><a id="filepos242708" /><div><sub> </sub><sup> </sup><b>a, </b><b>A </b><img hspace="0" align="middle" hisrc="Images/image15902.gif"/>das; - (UGS.: -s), - (UGS.: -s) [mhd., ahd. a]: <b>1.</b> erster Buchstabe des Alphabets: <i>ein kleines a, ein gro\xDFes A; </i> <i>eine Brosch\xFCre mit praktischen Hinweisen von A bis Z (unter alphabetisch angeordneten Stichw\xF6rtern); </i> <b>R </b>wer A sagt, muss auch B sagen (wer etwas beginnt, muss es fortsetzen u. auch unangenehme Folgen auf sich nehmen); <sup>*</sup><b>das A und O, </b>(SELTENER:) <b>das A und das O </b>(die Hauptsache, Quintessenz, das Wesentliche, Wichtigste, der Kernpunkt; urspr. = der Anfang und das Ende, nach dem ersten [Alpha] und dem letzten [Omega] Buchstaben des griech. Alphabets); <sup>*</sup><b>von A bis Z </b>(UGS.; von Anfang bis Ende, ganz und gar, ohne Ausnahme; nach dem ersten u. dem letzten Buchstaben des dt. Alphabets). <b>2.</b> &#139;das; -, -&#155; (MUSIK) sechster Ton der C-Dur-Tonleiter: <i>der Kammerton a, A.</i> </div></div></idx:entry><div height="10" align="center"><img hspace="0" vspace="0" align="middle" losrc="Images/image15903.gif" hisrc="Images/image15904.gif" src="Images/image15905.gif"/></div> <idx:entry scriptable="yes"><idx:orth value="\xE4"></idx:orth><div height="4"><div><b>\xE4, </b><b>\xC4 </b><img hspace="0" align="middle" hisrc="Images/image15906.gif"/>das; - (ugs.: -s), - (ugs.: -s) [mhd. \xE6]: Buchstabe, der f\xFCr den Umlaut aus a steht.</div></div></idx:entry><div height="10" align="center"><img hspace="0" vspace="0" align="middle" losrc="Images/image15903.gif" hisrc="Images/image15904.gif" src="Images/image15905.gif"/></div> <idx:entry scriptable="yes"><idx:orth value="a"></idx:orth><div height="4"><div><sup><font size="2">1&#8204;</font></sup><b>a</b><b> </b>= a-Moll; Ar.</div></div></idx:entry><div height="10" align="center"><img hspace="0" vspace="0" align="middle" losrc="Images/image15903.gif" hisrc="Images/image15904.gif" src="Images/image15905.gif"/></div>
    # (The /xE6 was due to Perl output encoding set to UTF-8.)
    # Prettified:
        # <idx:entry scriptable="yes">
        #     <idx:orth value="a"></idx:orth>
        #     <div height="4"><a id="filepos242708" /><a id="filepos242708" /><a id="filepos242708" />
        #         <div><sub> </sub><sup> </sup><b>a, </b><b>A </b><img hspace="0" align="middle" hisrc="Images/image15902.gif" />das; - (UGS.: -s), - (UGS.: -s) [mhd., ahd. a]: <b>1.</b> erster Buchstabe des Alphabets: <i>ein kleines a, ein gro\xDFes A; </i> <i>eine Brosch\xFCre mit praktischen Hinweisen von A bis Z (unter alphabetisch angeordneten Stichw\xF6rtern); </i> <b>R </b>wer A sagt, muss auch B sagen (wer etwas beginnt, muss es fortsetzen u. auch unangenehme Folgen auf sich nehmen); <sup>*</sup><b>das A und O, </b>(SELTENER:) <b>das A und das O </b>(die Hauptsache, Quintessenz, das Wesentliche, Wichtigste, der Kernpunkt; urspr. = der Anfang und das Ende, nach dem ersten [Alpha] und dem letzten [Omega] Buchstaben des griech. Alphabets); <sup>*</sup><b>von A bis Z </b>(UGS.; von Anfang bis Ende, ganz und gar, ohne Ausnahme; nach dem ersten u. dem letzten Buchstaben des dt. Alphabets). <b>2.</b> &#139;das; -, -&#155; (MUSIK) sechster Ton der C-Dur-Tonleiter: <i>der Kammerton a, A.</i> </div>
        #     </div>
        # </idx:entry>
        # <div height="10" align="center"><img hspace="0" vspace="0" align="middle" losrc="Images/image15903.gif" hisrc="Images/image15904.gif" src="Images/image15905.gif" /></div>
        # <idx:entry scriptable="yes">
        #     <idx:orth value="\xE4"></idx:orth>
        #     <div height="4">
        #         <div><b>\xE4, </b><b>\xC4 </b><img hspace="0" align="middle" hisrc="Images/image15906.gif" />das; - (ugs.: -s), - (ugs.: -s) [mhd. \xE6]: Buchstabe, der f\xFCr den Umlaut aus a steht.</div>
        #     </div>
        # </idx:entry>
        # <div height="10" align="center"><img hspace="0" vspace="0" align="middle" losrc="Images/image15903.gif" hisrc="Images/image15904.gif" src="Images/image15905.gif" /></div>
        # <idx:entry scriptable="yes">
        #     <idx:orth value="a"></idx:orth>
        #     <div height="4">
        #         <div><sup>
        #                 <font size="2">1&#8204;</font>
        #             </sup><b>a</b><b> </b>= a-Moll; Ar.</div>
        #     </div>
        # </idx:entry>
        # <div height="10" align="center"><img hspace="0" vspace="0" align="middle" losrc="Images/image15903.gif" hisrc="Images/image15904.gif" src="Images/image15905.gif" /></div>
    # Content excerpt Prettified:
        # <idx:entry>
        #     <idx:orth value="A">
        # </idx:entry>
        # <b>A N M</b>
        # <blockquote>Aulus (Roman praenomen); (abb. A./Au.); [Absolvo, Antiquo => free, reject];</blockquote>
        # <hr />
        # <idx:entry>
        #     <idx:orth value="Abba">
        # </idx:entry>
        # <b>Abba, undeclined N M</b>
        # <blockquote>Father; (Aramaic); bishop of Syriac/Coptic church; (false read obba/decanter);</blockquote>
        # <hr />
        # <idx:entry>
        #     <idx:orth value="Academia">
        #         <idx:infl>
        #             <idx:iform name="" value="Academia" />
        #             <idx:iform name="" value="Academiabus" />
        #             <idx:iform name="" value="Academiad" />
        #             <idx:iform name="" value="Academiae" />
        #             <idx:iform name="" value="Academiai" />
        #             <idx:iform name="" value="Academiam" />
        #             <idx:iform name="" value="Academiarum" />
        #             <idx:iform name="" value="Academias" />
        #             <idx:iform name="" value="Academiis" />
        #             <idx:iform name="" value="Academium" />
        #         </idx:infl>
        #         <idx:infl>
        #             <idx:iform name="" value="Academiaque" />
        #             <idx:iform name="" value="Academiabusque" />
        #             <idx:iform name="" value="Academiadque" />
        #             <idx:iform name="" value="Academiaeque" />
        #             <idx:iform name="" value="Academiaique" />
        #             <idx:iform name="" value="Academiamque" />
        #             <idx:iform name="" value="Academiarumque" />
        #             <idx:iform name="" value="Academiasque" />
        #             <idx:iform name="" value="Academiisque" />
        #             <idx:iform name="" value="Academiumque" />
        #         </idx:infl>
        # </idx:entry>
        # <b>Academia, Academiae N F</b>
        # <blockquote>academy, university; gymnasium where Plato taught; school built by Cicero;</blockquote>
        # <hr />
        # <idx:entry>
    # Duden entry around "früh"
        # <idx:entry scriptable="yes">
        #     <idx:orth value="früh"></idx:orth>
        #     <div height="4"><a id="filepos17894522" /><a id="filepos17894522" />
        #         <div><sub> </sub><sup> </sup><sup>
        #                 <font size="2">1&#8204;</font>
        #             </sup><b>fr</b><u><b><b>ü</b></b></u><b>h</b><b> </b>
        #             <mmc:no-fulltext>&#139;Adj.&#155; [mhd. vrüe(je), ahd. fruoji, zu: fruo, </mmc:no-fulltext>
        #             <mmc:fulltext-word value="‹Adj.› mhd. vrüeje, ahd. fruoji, zu: fruo, " /><a href="#filepos17896263">
        #                 <font size="+1"><b><img hspace="0" align="middle" hisrc="Images/image15907.gif" /></b></font> <sup>
        #                     <font size="-1">2</font>
        #                 </sup>früh
        #             </a>]: <b>1.</b> in der Zeit noch nicht weit fortgeschritten, am Anfang liegend, zeitig: <i>am -en Morgen; </i> <i>
        #                 <mmc:no-fulltext>in -er, -[e]ster Kindheit; </mmc:no-fulltext>
        #                 <mmc:fulltext-word value="in -er, -ester Kindheit; " />
        #             </i> <i>es ist noch f. am Tage; </i> <i>f. blühende Tulpen; </i> Ü <i>der -e (junge) Nietzsche; </i> Ü <i>die -esten (ältesten) Kulturen; </i> <sup>*</sup><b>von f. auf </b>(von früher Kindheit, Jugend an: <i>sie ist von f. auf an Selbstständigkeit gewöhnt). </i> <b>2.</b> früher als erwartet, als normalerweise geschehend, eintretend; frühzeitig, vorzeitig: <i>ein -er Winter; </i> <i>ein -er Tod; </i> <i>eine -e (früh reifende) Sorte Äpfel; </i> <i>wir nehmen einen -eren Zug; </i> <i>Ostern ist, fällt dieses Jahr f.; </i> <i>er kam -er als erwartet; </i> <i>sie ist zu f., noch f. genug gekommen; </i> <i>ihre f. (in jungen Jahren) verstorbene Mutter; </i> <i>ein f. vollendeter (in seiner Kunst schon in jungen Jahren zu absoluter Meisterschaft gelangter [u. jung verstorbener]) Maler; </i> <i>sie hat f. geheiratet; </i> <i>-er oder später (zwangsläufig irgendwann einmal) wird sie doch umziehen müssen.</i>
        #         </div>
        #     </div>
        # </idx:entry>
        # <div height="10" align="center"><img hspace="0" vspace="0" align="middle" losrc="Images/image15903.gif" hisrc="Images/image15904.gif" src="Images/image15905.gif" /><br /></div>
        # <idx:entry scriptable="yes">
        #     <idx:orth value="früh"></idx:orth>
        #     <div height="4"><a id="filepos17896263" />
        #         <div><sup>
        #                 <font size="2">2&#8204;</font>
        #             </sup><b>fr</b><u><b><b>ü</b></b></u><b>h</b><b> </b>&#139;Adv.&#155; [mhd. vruo, ahd. fruo, eigtl. = (zeitlich) vorn, voran]: morgens, am Morgen: <i>heute f., [am] Dienstag f.; </i> <i>kommst du morgen f.?; </i> <i>er arbeitet von f. bis spät [in die Nacht] (den ganzen Tag).</i> </div>
        #     </div>
        # </idx:entry>
        # <div height="10" align="center"><img hspace="0" vspace="0" align="middle" losrc="Images/image15903.gif" hisrc="Images/image15904.gif" src="Images/image15905.gif" /><br /></div>
    # Clean images out of the html
    if( $html =~ m~<img[^>]+>~s and $isConvertImagesUsingOCR ){ 
        $html = convertIMG2Text( $html ); 
        if( $isTestingOn ){ 
            my $ConvertedIMG2TextHTML = $FileName;
            debug_t( $FileName );
            unless( $ConvertedIMG2TextHTML =~ s~html$~test.html~ ){ warn "Regex for filename for test.html does not match."; Die(); }
            string2File( $ConvertedIMG2TextHTML, $html );
        }
    }

    # my @indexentries = $html=~m~<idx:entry scriptable="yes">((?:(?!</idx:entry>).)+)</idx:entry>~gs; # Only works for Duden
    my @indexentries = $html=~m~<idx:entry[^>]*>((?:(?!<idx:entry).)+)~gs; # Collect from the start until the next starts.
    if($isTestingOn){ array2File("test_html_indexentries.html",map(qq/$_\n/,@indexentries)  ) ; }
    my $number = 0;
    my $lastkey = "";
    my $lastInflectionEntries="";
    my %ConversionDebugStrings;
    waitForIt("Converting indexentries from HTML to XDXF.");
    my ($TotalRemovalTime,$TotalImageConversion,$TotalEncodingConversionTime,$TotalConversion2SpanTime,$TotalArticleExtraction) = (0,0,0,0,0);
    foreach (@indexentries){
        my $TotalTime = 0;
        $number++;
        my $isLoopDebugging = 0;
        if(m~<idx:orth value="\Q$DebugKeyWordConvertHTML2XDXF\E"~ and $isTestingOn){ $isLoopDebugging = 1; }
        debug($_) if $isLoopDebugging;
        # Removal of tags
        my $start = time;
        # Remove <a />, </a>, </idx:entry>, <br/>, <hr />, <betonung/>, <mmc:fulltext-word ../> tags
        s~</?a[^>]*>|<betonung\s*/>|</idx:entry>|<br\s*/>|<hr\s*/>|<mmc:fulltext-word[^>]+>~~sg;
        # Remove empty sup and sub-blocks
        s~<sub>[\s]*</sub>|<sup>[\s]*</sup>|<b>[\s]*</b>~~sg;
        $TotalRemovalTime += time - $start;
        # Convert or remove <img...>, e.g. <img hspace="0" align="middle" hisrc="Images/image15907.gif" />
        $start = time;
        if( $isConvertImagesUsingOCR and m~<img[^>]+>~s ){ $_ = convertIMG2Text( $_ ); }
        if( $isCodeImageBase64       and m~<img[^>]+>~s ){ $_ = convertImage2Base64( $_ ); }
        else{  s~<img[^>]+>~~sg; } # No images-resources are used in xdxf.
        $TotalImageConversion += time - $start;

        # Include encoding conversion
        $start = time;
        while( $encoding eq "cp1252" and m~\&\#(\d+);~s ){
            my $encoded = $1;
            my $decoded = decode( $encoding, pack("N", $encoded) );
            # The decode step generates four hex values: a triplet of <0x00> followed by the one that's wanted. This goes awry if there are multiple non-zero octets.
            while( ord( substr( $decoded, 0, 1) ) == 0 ){
                $decoded = substr( $decoded, 1 );
            }
            # Skip character because it cannot be handled by code and is most probably the same in cp1252 and unicode.
            if( length($decoded)>1 ){
                # Convert to hexadecimal value so that the while-loop doesn't become endless.
                my $hex = sprintf("%X", $encoded);
                $decoded = "&#x$hex;";
            }
            # If character is NL, than replacement should be \n
            elsif( ord($decoded) == 12 ){ $decoded = "\n";}
            my $DebugString = "Encoding is $encoding. Encoded is $encoded. Decoded is \'$decoded\' of length ".length($decoded).", numbered ".ord($decoded);
            $ConversionDebugStrings{$encoded} = $DebugString;
            s~\&\#$encoded;~$decoded~sg;                
        }
        $TotalEncodingConversionTime += time - $start;
        # Change div-blocks to spans
        if( $isConvertDiv2SpaninHTML2DXDF ){ s~(</?)div[^>]*>~$1span>~sg; }
        my $round = 0;
        # Change font- to spanblocks
        $start = time;
        while( s~<font size="(?:2|-1)">((?:(?!</font).)+)</font>~<small>$1</small>~sg ){
            $round++;
            debug("font-blocks substituted with small-blocks in round $round.") if m~<idx:orth value="$DebugKeyWordConvertHTML2XDXF"~;
        }
        $round = 0;
        while( s~<font(?<fontstyling>[^>]*)>(?<content>(?:(?!</font).)*)</font>~<span$+{"fontstyling"}>$+{"content"}</span>~sg ){
            $round++;
            debug("font-blocks substituted with span-blocks in round $round.") if m~<idx:orth value="$DebugKeyWordConvertHTML2XDXF"~;
        }
        # Change <mmc:no-fulltext> to <span>
        $round = 0;
        while( s~<mmc:no-fulltext>((?:(?!</mmc:no-fulltext).)+)</mmc:no-fulltext>~<span> $1</span>~sg ){
            $round++;
            debug("<mmc:no-fulltext>-blocks substituted with spans in round $round.") if $number<3;
        }
        $TotalConversion2SpanTime = time - $start;
        # Create key&definition strings.
        $start = time;
        # m~^<idx:orth value="(?<key>[^"]+)"></idx:orth>(?<def>.+)$~s; # Works only for Duden
        s~<idx:orth value="(?<key>[^"]+)">~~s; # Remove idx-orth value.
        my $key = $+{key};
        if( defined $key and $key ne "" ){    debug("Found \$key $key.") if $isLoopDebugging; }
        else{ debug("No key found! Dumping and Quitting:\n\n$_"); die;}
        s~</idx:orth>~~sg; # Remove closing tag if present.

        #Handle inflections block
        # Remove inflections category tags
        s~</?idx:infl>~~sg;
        # <idx:iform name="" value="Academia" />
        my @inflections = m~<idx:iform name="" value="(\w*)"/>~sg;
        s~<idx:iform[^>]*>~~sg;
        my $InflectionEntries="";
        foreach my $inflection(@inflections){
            # Create string to append after main definition.
            if( defined $inflection and $inflection ne $key and $inflection ne "" ){
                my $ExtraEntry = "<ar><head><k>$inflection</k></head><def><blockquote>↑".pack("U", 0x2009)."<i>$key</i></blockquote></def></ar>\n";
                $InflectionEntries = $InflectionEntries.$ExtraEntry;
            }
        }
        
        # Remove leftover empty lines.
        s~  ~ ~sg;
        s~\t\t~\t~sg;
        s~\n\n~\n~sg;
        # Remove trailing and leading spaces and line endings
        s~^\s+~~sg;
        s~\s+$~~sg;

        # Assign remaining entry to $def.
        my $def = "<blockquote>".$_."</blockquote>";
        debugV("key found: $key") if $number<5;
        debugV("def found: $def") if $number<5;
        # Remove whitespaces at the beginning of the definition and EOL at the end.
        $def =~ s~^\s+~~;
        $def =~ s~\n$~~;
        # Switch position sup/span/small blocks
        # <sup><small>1&#8204;</small></sup>
        # $html =~ s~<sup><small>([^<]*)</small>~<sup>$1~sg;
        $def =~ s~<sup><small>([^<]*)</small></sup>~<small><sup>$1</sup></small>~sg;
        # $html =~ s~<sup><span>([^<]*)</span>~<sup>$1~sg;
        $def =~ s~<sup><span>([^<]*)</span></sup>~<span><sup>$1</sup></span>~sg;
        $def =~ s~<sub><small>([^<]*)</small></sub>~<small><sub>$1</sub></small>~sg;
        $def =~ s~<sub><span>([^<]*)</span></sub>~<span><sub>$1</sub></span>~sg;
        # Put space in front of ‹, e.g. ‹Adj.›, if it's lacking
        $def =~ s~([^\s])‹~$1 ‹~sg;
        if( $key eq $lastkey){
            # Change the last entry to append current definition
            $xdxf[-1] =~ s~</def></ar>\n~\n$def</def></ar>\n~s;
            debug("Added to the last definition. It's now:\n$xdxf[-1]") if $isLoopDebugging;
        }
        else{
            # Because I want the inflections to follow in the index on the full definition.
            if( $lastInflectionEntries ne "" ){
                $xdxf[-1] =~ s~\n$~\n$lastInflectionEntries~s;
                $lastInflectionEntries = "";
            }
            push @xdxf, "<ar><head><k>$key</k></head><def>$def</def></ar>\n";
            debug("Pushed <ar><head><k>$key</k></head><def>$def</def></ar>") if $isLoopDebugging;
        }
        # To allow appending definitions of identical keys
        $lastkey = $key;
        # To allow inflection entries after the main entry
        $lastInflectionEntries = $lastInflectionEntries.$InflectionEntries;
        $TotalArticleExtraction += time - $start;
        my @Names = ("TotalRemovalTime","TotalImageConversion","TotalEncodingConversionTime","TotalConversion2SpanTime","TotalArticleExtraction");
        foreach($TotalRemovalTime,$TotalImageConversion,$TotalEncodingConversionTime,$TotalConversion2SpanTime,$TotalArticleExtraction){
            my $Name = shift @Names;
            infoVV("$Name: $_");
            $TotalTime += $_;
        }
        infoVV("Total time in loop: $TotalTime");
    }
   
    foreach( sort keys %ConversionDebugStrings){ debug($ConversionDebugStrings{$_}); }
    doneWaiting();
    push @xdxf, $lastline_xdxf;
    return(@xdxf);}
sub convertRAWML2XDXF{
    # Converts html generated by KindleUnpack to xdxf
    my $rawml = join('',@_);
    my $xdxf_try =  generateXDXFTagBased( $rawml );
    if( $xdxf_try ){ return (@{ $xdxf_try }); }
    my @xdxf = @xdxf_start;
    # Snippet Rawml
    #<html><head><guide><reference title="Dictionary Search" type="search" onclick="index_search()"/></guide></head><body><mbp:pagebreak/><p>Otwarty słownik hiszpańsko-polski</p> <p>Baza tłumaczeń: 2010 Jerzy Kazojć – CC-BY-SA</p> <p>Baza odmian: Athame – GPL3</p> <mbp:pagebreak/><mbp:frameset> <mbp:pagebreak/><h3> a </h3> ku, na, nad, o, po, przy, u, w, za <hr/> <h3> abacero </h3> sklepikarz <hr/> <h3> ábaco </h3> abakus, liczydło <hr/> <h3> abad </h3> opat <hr/> <h3> abadejo </h3> dorsz <hr/> <h3> abadía </h3> opactwo <hr/> <h3> abajo </h3> dolny <hr/> <h3> abalanzar </h3> równoważyć <hr/> <h3> abalanzarse </h3> rzucać, rzucić <hr/> <h3> abalear </h3> przesiewać, wiać <hr/> <h3> abanar </h3> chwiać, potrząsać, trząść, wstrząsać <hr/> <h3> abanderado </h3> chorąży, lider <hr/> <h3> abandonado </h3> opuszczony, porzucony <hr/> <h3> abandonar </h3> opuścić, opuszczać, porzucać, porzucić, pozostawiać, zaniechać, zostawiać, zrezygnować <hr/>

    # Prettified rawml
    # <html>

    # <head>
    #     <guide>
    #         <reference title="Dictionary Search" type="search" onclick="index_search()" />
    #     </guide>
    # </head>

    # <body>
        # <mbp:pagebreak />
        # <p>Otwarty słownik hiszpańsko-polski</p>
        # <p>Baza tłumaczeń: 2010 Jerzy Kazojć – CC-BY-SA</p>
        # <p>Baza odmian: Athame – GPL3</p>
        # <mbp:pagebreak />
        # <mbp:frameset>
            # <mbp:pagebreak />
            # <h3> a </h3> ku, na, nad, o, po, przy, u, w, za
            # <hr />
            # <h3> abacero </h3> sklepikarz
            # <hr />
            # <h3> ábaco </h3> abakus, liczydło
            # <hr />
            # <h3> abad </h3> opat
            # <hr />
            # <h3> abadejo </h3> dorsz
            # <hr />
            # ...
            # ...
            # ...
            # <h3> zurriago </h3> bat, batog, bicz, bykowiec, knut, pejcz, szpicruta
            # <hr />
        #     <h3> zurrir </h3> śmiać
        # </mbp:frameset>
        # <mbp:pagebreak />
    # </body>

    # </html>

    # <body topmargin="0" leftmargin="0" rightmargin="0" bottommargin="0">
    #     <div align="center" bgcolor="yellow">
    #         <p>Dictionary Search</p>
    #     </div>
    # </body>

    my (@indexentries, $headervalue);
    for( $headervalue = 3; $headervalue > 0; $headervalue--){
        debug( "headervalue = $headervalue.   scalar \@indexentries = ".scalar @indexentries);
        @indexentries = $rawml=~m~(<h(?:$headervalue)>(?:(?!<hr|<mbp).)+)<hr ?/>~gs; # Collect from the start until the next starts.
        if( @indexentries > 10 ){ last; }
    }
    unless( @indexentries ){ debug("No indexentries found in rawml-string."); debug(substr($rawml, 0, $NumberofCharactersShownFailedRawML)); goto DONE;}
    else{ info("Found ".scalar @indexentries." indexentries.\n"); }
    waitForIt("Converting indexentries from RAWML to XDXF.");
    my $isLoopDebugging = 1;
    my $lastkey = "";
    my $number = 0;
    foreach (@indexentries){
        $number++;
        # Create key&definition strings.
        # <h3> zurrir </h3> śmiać
        debug( "headervalue = $headervalue") if $number < 5;
        s~<h(?:$headervalue)> ?(?<key>[^<]+)</h(?:$headervalue)>~~s; # Remove h3-block value.
        my $key = $+{key};
        if( defined $key and $key ne "" ){  debug("Found \$key $key.") if $isLoopDebugging; $isLoopDebugging++ if $isLoopDebugging; $isLoopDebugging = 0 if $isLoopDebugging == 10; }
        else{ debug("No key found! Dumping and Quitting:\n\n$_"); die;}
        # Remove leftover empty lines.
        s~  ~ ~sg;
        s~\t\t~\t~sg;
        s~\n\n~\n~sg;
        # Remove trailing and leading spaces and line endings
        s~^\s+~~sg;
        s~\s+$~~sg;

        # Assign remaining entry to $def.
        my $def = "<blockquote>".$_."</blockquote>";
        # Remove trailing space from key.
        $key =~ s~\s+$~~sg;
        debugV("key found: $key") if $number<5;
        debugV("def found: $def") if $number<5;
        # Remove whitespaces at the beginning of the definition and EOL at the end.
        $def =~ s~^\s+~~;
        $def =~ s~\n$~~;
        # $html =~ s~<sup><span>([^<]*)</span>~<sup>$1~sg;
        $def =~ s~<sup><span>([^<]*)</span></sup>~<span><sup>$1</sup></span>~sg;
        $def =~ s~<sub><small>([^<]*)</small></sub>~<small><sub>$1</sub></small>~sg;
        $def =~ s~<sub><span>([^<]*)</span></sub>~<span><sub>$1</sub></span>~sg;
        # Put space in front of ‹, e.g. ‹Adj.›, if it's lacking
        $def =~ s~([^\s])‹~$1 ‹~sg;
        if( $key eq $lastkey){
            # Change the last entry to append current definition
            $xdxf[-1] =~ s~</def></ar>\n~\n$def</def></ar>\n~s;
            debug("Added to the last definition. It's now:\n$xdxf[-1]") if $isLoopDebugging;
        }
        else{
            push @xdxf, "<ar><head><k>$key</k></head><def>$def</def></ar>\n";
            debug("Pushed <ar><head><k>$key</k></head><def>$def</def></ar>") if $isLoopDebugging;
        }
        # To allow appending definitions of identical keys
        $lastkey = $key;
    }
    DONE:
    doneWaiting();
    push @xdxf, $lastline_xdxf;
    return(@xdxf);}
sub convertMobiAltCodes{
    # my %MobiAltCodes = {
    #     1 => '☺',
    #     2 => '☻',
    #     3 => '♥',
    #     4 => '♦',
    #     5 => '♣',
    #     6 => '♠',
    #     7 => '•',
    #     8 => '◘',
    #     9 => '○',
    #     10 => '◙',
    #     11 => '♂',
    #     12 => '♀',
    #     13 => '♪',
    #     14 => '♫',
    #     15 => '☼',
    #     16 => '►',
    #     17 => '◄',
    #     18 => '↕',
    #     19 => '‼',
    #     20 => '¶',
    #     21 => '§',
    #     22 => '&',
    #     23 => '↨',
    #     24 => '↑',
    #     25 => '↓',
    #     26 => '→',
    #     27 => '←',
    #     28 => '∟',
    #     29 => '↔',
    #     30 => '▲',
    #     31 => '▼'
    # };

    my $xdxf = $_[0]; # Only a string or first entry of array is checked and returned.
    waitForIt("Converting Mobi alt-codes, because isConvertMobiAltCodes = $isConvertMobiAltCodes.");
    if( $xdxf =~ s~\x01~☺~g ){ info("Converted mobi alt-code to '☺'");}
    if( $xdxf =~ s~\x02~☻~g ){ info("Converted mobi alt-code to '☻'");}
    if( $xdxf =~ s~\x03~♥~g ){ info("Converted mobi alt-code to '♥'");}
    if( $xdxf =~ s~\x04~♦~g ){ info("Converted mobi alt-code to '♦'");}
    if( $xdxf =~ s~\x05~♣~g ){ info("Converted mobi alt-code to '♣'");}
    if( $xdxf =~ s~\x06~♠~g ){ info("Converted mobi alt-code to '♠'");}
    if( $xdxf =~ s~\x07~•~g ){ info("Converted mobi alt-code to '•'");}
    if( $xdxf =~ s~\x08~◘~g ){ info("Converted mobi alt-code to '◘'");}
    if( $xdxf =~ s~\x09~○~g ){ info("Converted mobi alt-code to '○'");}
    if( $xdxf =~ s~\x0A~◙~g ){ info("Converted mobi alt-code to '◙'");}
    if( $xdxf =~ s~\x0B~♂~g ){ info("Converted mobi alt-code to '♂'");}
    if( $xdxf =~ s~\x0C~♀~g ){ info("Converted mobi alt-code to '♀'");}
    if( $xdxf =~ s~\x0D~♪~g ){ info("Converted mobi alt-code to '♪'");}
    if( $xdxf =~ s~\x0E~♫~g ){ info("Converted mobi alt-code to '♫'");}
    if( $xdxf =~ s~\x0F~☼~g ){ info("Converted mobi alt-code to '☼'");}
    if( $xdxf =~ s~\x10~►~g ){ info("Converted mobi alt-code to '►'");}
    if( $xdxf =~ s~\x11~◄~g ){ info("Converted mobi alt-code to '◄'");}
    if( $xdxf =~ s~\x12~↕~g ){ info("Converted mobi alt-code to '↕'");}
    if( $xdxf =~ s~\x13~‼~g ){ info("Converted mobi alt-code to '‼'");}
    if( $xdxf =~ s~\x14~¶~g ){ info("Converted mobi alt-code to '¶'");}
    if( $xdxf =~ s~\x15~§~g ){ info("Converted mobi alt-code to '§'");}
    if( $xdxf =~ s~\x16~&~g ){ info("Converted mobi alt-code to '&'");}
    if( $xdxf =~ s~\x17~↨~g ){ info("Converted mobi alt-code to '↨'");}
    if( $xdxf =~ s~\x18~↑~g ){ info("Converted mobi alt-code to '↑'");}
    if( $xdxf =~ s~\x19~↓~g ){ info("Converted mobi alt-code to '↓'");}
    if( $xdxf =~ s~\x1A~→~g ){ info("Converted mobi alt-code to '→'");}
    if( $xdxf =~ s~\x1B~←~g ){ info("Converted mobi alt-code to '←'");}
    if( $xdxf =~ s~\x1C~∟~g ){ info("Converted mobi alt-code to '∟'");}
    if( $xdxf =~ s~\x1D~↔~g ){ info("Converted mobi alt-code to '↔'");}
    if( $xdxf =~ s~\x1E~▲~g ){ info("Converted mobi alt-code to '▲'");}
    if( $xdxf =~ s~\x1F~▼~g ){ info("Converted mobi alt-code to '▼'");}
    doneWaiting();
    return($xdxf); }
sub convertNonBreakableSpacetoNumberedSequence{
    my $UnConverted = join('',@_);
    waitForIt("Removing '&nbsp;'.");
    my @results = $UnConverted =~ s~(&nbsp;)~&#160;~sg ;
    shift @results;
    if( scalar @results > 0 ){
        # Make unique results;
        my %unique_results;
        foreach(@results){ $unique_results{$_} = 1; }
        debug("Number of characters removed in convertNonBreakableSpacetoNumberedSequence: ",scalar @results);
        debug( map qq/"$_", /, keys %unique_results );
    }
    my @UnConverted = split(/^/, $UnConverted);
    if( $UnConverted =~ m~\&nbsp;~ ){ debug("Still found '&nbsp;' in array! Quitting"); Debug(@UnConverted); Die(); }
    return( @UnConverted );}
sub convertNumberedSequencesToChar{
    my $UnConverted = join('',@_);
    debug("Entered sub convertNumberedSequencesToChar") if $isTestingOn;
    while( $UnConverted =~ m~\&\#x([0-9A-Fa-f]{1,6});~s ){
        my $HexCodePoint = $1;
        $UnConverted =~ s~\&\#x$HexCodePoint;~chr(hex($HexCodePoint))~seg ;
        debug("Result convertNumberedSequencesToChar: $HexCodePoint"."-> '".chr(hex($HexCodePoint))."'" ) if $isTestingOn;
    }
    while( $UnConverted =~ m~\&\#([0-9]{1,6});~s  ){
        my $Number = $1;
        if( $Number >= 128 and $Number <=159 ){
            # However, for the characters in the range of 128-159 in Windows-1252, these are the wrong values. For example the Euro (€) is at code point 0x80 in Windows-1252, but in Unicode it is U+20AC. &#x80; is the NCR for a control code and will not display as the Euro. The correct NCR is &#x20AC;.

            $UnConverted =~ s~\&\#$Number;~decode('cp1252', chr(int($Number)))~seg;
            debug("Result convertNumberedSequencesToChar: $Number"."-> '".decode('cp1252', chr(int($Number)))."'" ) if $isTestingOn;
        }
        else{
            $UnConverted =~ s~\&\#$Number;~chr(int($Number))~seg ;
            debug("Result convertNumberedSequencesToChar: $Number"."-> '".chr(int($Number))."'" ) if $isTestingOn;
        }
    }

    $UnConverted = removeInvalidChars( $UnConverted );

    return( split(/(\n)/, $UnConverted) );}
sub convertStardictXMLtoXDXF{
    my $StardictXML = join('',@_);
    my @xdxf = @xdxf_start;
    # Extract bookname from Stardict XML
    if( $StardictXML =~ m~<bookname>(?<bookname>((?!</book).)+)</bookname>~s ){
        my $bookname = $+{bookname};
        # xml special symbols are not recognized by converter in the dictionary title.
        $bookname = unEscapeHTMLString( $bookname);
        substr($xdxf[2], 11, 0) = $bookname;
    }
    # Extract date if present from Stardict XML
    if( $StardictXML =~ m~<date>(?<date>((?!</date>).)+)</date>~s ){
        substr($xdxf[4], 6, 0) = $+{date};
    }
    # Extract sametypesequence from Stardict XML
    if( $updateSameTypeSequence and $StardictXML =~ m~<definition type="(?<sametypesequence>\w)">~s){
        $SameTypeSequence = $+{sametypesequence};
    }

    waitForIt("Converting stardict xml to xdxf xml.");
    # Initialize variables for collection
    my ($key, $def, $article, $definition) = ("","", 0, 0);
    # Initialize variables for testing
    my ($test_loop, $counter,$max_counter) = (0,0,40) ;
    foreach(@_){
        $counter++;
        # Change state to article
        if(m~<article>~){ $article = 1; debug("Article start tag found at line $counter.") if $test_loop;}

        # Match key within article outside of definition
        if($article and !$definition and m~<key>(?<key>((?!</key>).)+)</key>~){
            $key = $+{key};
            debug("Key \"$key\" found at line $counter.") if $test_loop;
        }
        # change state to definition
        if(m~<definition type="\w">~){ $definition = 1; debug("Definition start tag found at line $counter.") if $test_loop;}
        # Fails for multiline definitions such as:
            # <definition type="x">
            # <![CDATA[<k>&apos;Arry</k>
            # <b>&apos;Arry</b>
            # <blockquote><blockquote>(<c c="darkslategray">ˈærɪ</c>)</blockquote></blockquote>
            # <blockquote><blockquote><c c="gray">[The common Christian name <i>Harry</i> vulgarly pronounced without the aspirate.]</c></blockquote></blockquote>
            # <blockquote><blockquote>Used humorously for: A low-bred fellow (who ‘drops his <i>h&apos;</i>s’) of lively temper and manners. Hence <b>&apos;Arryish</b> <i>a.</i>, vulgarly jovial.</blockquote></blockquote>
            # <blockquote><blockquote><blockquote><blockquote><blockquote><blockquote><ex><b>1874</b> <i>Punch&apos;s Almanac</i>, <c c="darkmagenta">&apos;Arry on &apos;Orseback.</c> <b>1881</b> <i><abr>Sat.</abr> <abr>Rev.</abr></i> <abr>No.</abr> 1318. 148 <c c="darkmagenta">The local &apos;Arry has torn down the famous tapestries of the great hall.</c> <b>1880</b> W. Wallace in <i>Academy</i> 28 Feb. 156/1 <c c="darkmagenta">He has a fair stock of somewhat &apos;Arryish animal spirits, but no real humour.</c></ex></blockquote></blockquote></blockquote></blockquote></blockquote></blockquote>]]>
            # </definition>
        s~<definition type="\w">~~;
        s~<\!\[CDATA\[~~;
        s~<k>\Q$key\E</k>~~;
        s~<b>\Q$key\E</b>~~;
        s~^[\n\s]+$~~;
        if($definition and m~(?<def>((?!\]\]>).)+)(\]\]>)?~s){
            my $fund = $+{def};
            $fund =~ s~</definition>\n?~~;
            $def .= $fund if $fund!~m~^[\n\s]+$~;
            debug("Added definition \"$fund\" at line $counter.") if $test_loop and $fund ne "" and $fund!~m~^[\n\s]+$~;
        }
        if(  m~</definition>~ ){
            $definition = 0;
            debug("Definition stop tag found at line $counter.") if $test_loop;
        }
        if(  !$definition and $key ne "" and $def ne ""){
            debug("Found key \'$key\' and definition \'$def\'") if $test_loop;
            push @xdxf, "<ar><head><k>$key</k></head><def>$def</def></ar>\n";
            ($key, $def, $definition) = ("","",0);
        }
        # reset on end of article
        if(m~</article>~ ){
            ($key, $def, $article) = ("","",0);
            debug("Article stop tag found at line $counter.\n") if $test_loop;
        }
        die if $counter==$max_counter and $test_loop and $isRealDead;
    }
    doneWaiting();
    push @xdxf, $lastline_xdxf;
    return(@xdxf);}
sub convertXDXFtoStardictXML{
    my $xdxf = join('',@_);
    $xdxf = removeInvalidChars( $xdxf );
    my @xml = @xml_start;
    if( $xdxf =~ m~<full_name>(?<bookname>((?!</full_name).)+)</full_name>~s ){
        my $bookname = $+{bookname};
        # xml special symbols are not recognized by converter in the dictionary title.
        $bookname = unEscapeHTMLString( $bookname );
        substr($xml[4], 10, 0) = $bookname;
    }
    if( $xdxf =~ m~<date>(?<date>((?!</date>).)+)</date>~s ){
        substr($xml[9], 6, 0) = $+{date};
    }
    if( $xdxf =~ m~<xdxf (?<description>((?!>).)+)>~s ){
        substr($xml[8], 13, 0) = $+{description};
    }
    waitForIt("Converting xdxf-xml to Stardict-xml." );
    my @articles = $xdxf =~ m~<ar>((?:(?!</ar).)+)</ar>~sg ;
    printCyan("Finished getting articles at ", getLoggingTime(),"\n" );
    $cycle_dotprinter = 0;
    my $PreviousKey = "";
    foreach my $article ( @articles){
        $cycle_dotprinter++; if( $cycle_dotprinter == $cycles_per_dot){ printGreen("."); $cycle_dotprinter=0;}
        # <head><k>a</k></head>
        $article =~ m~<head><k>(?<key>((?!</k).)+)</k>~s;
        my $CurrentKey = escapeHTMLString($+{key});
        $article =~ m~<def>(?<definition>((?!</def).)+)</def>~s;
        my $CurrentDefinition = $+{definition};
        # Append the current definition to the previous one
        if( $CurrentKey ne $PreviousKey){
            push @xml, "<article>\n";
            push @xml, "<key>".$CurrentKey."</key>\n\n";
            push @xml, '<definition type="'.$SameTypeSequence.'">'."\n";
            push @xml, '<![CDATA['.$CurrentDefinition.']]>'."\n";
            push @xml, "</definition>\n";
            push @xml, "</article>\n\n";
            $PreviousKey = $CurrentKey;
        }
        else{
            my $PreviousStopArticle = pop @xml;
            my $PreviousStopDefinition = pop @xml;
            my $PreviousCDATA = pop @xml;
            if ( '<![CDATA['.$CurrentDefinition.']]>'."\n" eq "$PreviousCDATA" ){ debug("Double entry found. Skipping!"); next;}
            debugV("\n\$CurrentKey:\n\"", $CurrentKey, "\"");
            debugV("\$CurrentDefinition:\n\"", $CurrentDefinition, "\"");
            debugV("\$PreviousStopArticle:\n\"", $PreviousStopArticle, "\"");
            debugV("\$PreviousStopDefinition:\n\"", $PreviousStopDefinition, "\"");
            debugV("\$PreviousCDATA:\n\"", $PreviousCDATA, "\"");
            debugV("Quitting before anything is tested. If testing is OK: remove next 'die'-statement");
            my $PreviousDefinition = $PreviousCDATA;
            $PreviousDefinition =~ s~^<!\[CDATA\[(?<definition>.+?)\]\]>\n$~$+{definition}~s;
            debugV("\$PreviousDefinition:\n\"", $PreviousDefinition, "\"");
            my $UpdatedCDATA = '<![CDATA[' . fixPrefixes($PreviousDefinition,$CurrentDefinition) . "]]>\n";
            debugV("\$UpdatedCDATA:\n\"",$UpdatedCDATA, "\"");
            push @xml, $UpdatedCDATA, $PreviousStopDefinition, $PreviousStopArticle;
        }
    }
    push @xml, "\n";
    push @xml, $lastline_xml;
    push @xml, "\n";
    doneWaiting();
    return(@xml);}
sub doneWaiting{ printCyan("Done at ",getLoggingTime(),"\n");}
sub escapeHTMLString{
    my $String = shift;
    $String =~ s~<~\&lt;~sg;
    $String =~ s~>~\&gt;~sg;
    $String =~ s~'\&apos;~~sg;
    $String =~ s~&~\&amp;~sg;
    $String =~ s~"~\&quot;~sg;
    return $String;}
sub file2ArrayOld {

    #This subroutine expects a path-and-filename in one and returns an array
    my $FileName = $_[0];
    my $encoding = $_[1];
    my $verbosity = $_[2];
    my $isBinMode = 0;
    if(defined $encoding and $encoding eq "raw"){
        undef $encoding;
        $isBinMode = 1;
    }
    if(!defined $FileName){debug("File name in file2Array is not defined. Quitting!");Die() if $isRealDead;}
    if( defined $encoding){ open( FILE, "<:encoding($encoding)", $FileName )
      || (warn "Cannot open $FileName: $!\n" and Die());}
    else{    open( FILE, "$FileName" )
      || (warn "Cannot open $FileName: $!\n" and Die());
  }
      if( $isBinMode ){
          binmode FILE;
      }
    my @ArrayLines = <FILE>;
    close(FILE);
    printBlue("Read $FileName, returning array. Exiting file2Array\n") if (defined $verbosity and $verbosity ne "quiet");
    return (@ArrayLines);}
sub file2Array{
    #This subroutine expects a path-and-filename in one and returns an array
    my $FileName = $_[0];
    my $encoding = $_[1];
    my $verbosity = $_[2];
    # Read the raw bytes
    local $/;
    unless( -e $FileName ){
        warn "'$FileName' doesn't exist.";
        if( $FileName =~ m~(?<dir>.*)/(?<file>[^/]+)~ ){
            my $dir = $+{dir};
            my $file = $+{file};
            if( -e $dir ){
                unless( -r $dir){
                    warn "Can't read '$dir'";
                    $dir =~ s~ ~\\ ~g;
                    unless( -r $dir ){ warn "Can't read '$dir' with escaped spaces."; }
                }
                unless( -w $dir){ warn "Can't write '$dir'"; }
            }
            elsif( $dir =~ s~ ~\\ ~g and -e $dir){
                warn "Found '$dir' after escaping spaces";
            }
            elsif( -e "$BaseDir/$dir"){
                warn "Found $BaseDir/$dir. Prefixing '$BaseDir'.";
                $dir = "$BaseDir/$dir";
            }
            else{
                warn "'$dir' doesn't exist";
                my @commands = (
                    "pwd",
                    "ls -larth $dir",
                    "ls -larth $BaseDir/$dir");
                foreach(@commands){
                    print "\$ $_\n";
                    system("$_");
                }
                Die();
            }
        }

        if( -e "BaseDir/$FileName"){
            warn "Changing it to BaseDir/$FileName";
            $FileName = "BaseDir/$FileName";
        }
        elsif( $FileName =~ s~ ~\\ ~g and -e $FileName ){
            warn "Escaped spaces to find filename";
        }
    }
    else{ debugVV( "$FileName exists."); }
    open (my $fh, '<:raw', "$FileName") or (warn "Couldn't open $FileName: $!" and Die() and return undef() );
    my $raw = <$fh>;
    close($fh);
    if($encoding eq "raw"){
        printBlue("Read $FileName (raw), returning array. Exiting file2Array\n") if (defined $verbosity and $verbosity ne "quiet");
        return( split(/^/, $raw) );
    }
    elsif( defined $encoding ){
        printBlue("Read $FileName ($encoding), returning array. Exiting file2Array\n") if (defined $verbosity and $verbosity ne "quiet");
        return(split(/^/, decode( $encoding, $raw ) ) );
    }

    my $content;
    # Try to interpret the content as UTF-8
    eval { my $text = decode('utf-8', $raw, Encode::FB_CROAK); $content = $text };
    # If this failed, interpret as windows-1252 (a superset of iso-8859-1 and ascii)
    if (!$content) {
        eval { my $text = decode('windows-1252', $raw, Encode::FB_CROAK); $content = $text };
    }
    # If this failed, give up and use the raw bytes
    if (!$content) {
        $content = $raw;
    }
    my @ReturnArray = split(/^/, $content);
    printBlue("Read $FileName, returning array of size ".@ReturnArray.". Exiting file2Array\n") if (defined $verbosity and $verbosity ne "quiet");

    return @ReturnArray;}
sub filterXDXFforEntitites{
    my( @xdxf ) = @_;
    my @Filteredxdxf;
    if( scalar keys %EntityConversion == 0 ){
        debugV("No \%EntityConversion hash defined");
        return(@xdxf);
    }
    else{debug("These are the keys:", keys %EntityConversion);}
    $cycle_dotprinter = 0 ;
    waitForIt("Filtering entities based on DOCTYPE.");
    foreach my $line (@xdxf){
        $cycle_dotprinter++; if( $cycle_dotprinter == $cycles_per_dot){ printGreen("."); $cycle_dotprinter=0;}
        foreach my $EntityName(keys %EntityConversion){
            $line =~ s~(\&$EntityName;)~$EntityConversion{$EntityName}~g;
        }
        push @Filteredxdxf, $line;
    }
    doneWaiting();
    return (@Filteredxdxf);}
sub fixPrefixes{
                my( $PreviousDefinition, $CurrentDefinition ) = @_;
                debugV("\$CurrentDefinition:\n\"", $CurrentDefinition,"\"");
                debugV("\$PreviousDefinition:\n\"", $PreviousDefinition,"\"");
            
                my( $CurrentDefinitionPrefix, $PreviousDefinitionPrefix) = ( "", "");
                
                my @PossiblePrefixes = $PreviousDefinition =~ m~<sup>[ivx]+\.</sup>~gs;
                if( scalar @PossiblePrefixes > 0 ){
                    debugV("\@PossiblePrefixes\t=\t@PossiblePrefixes");
                    debugV("Multiple entries found.");
                    my $LastPrefix = $PossiblePrefixes[-1];
                    $LastPrefix =~ s~<sup>|</sup>|\.~~sg;
                    debugV("\$LastPrefix:\t=\t$LastPrefix");
                    my $LastPrefixArabic = arabic($LastPrefix);
                    $LastPrefixArabic++;
                    $CurrentDefinitionPrefix = "<sup>".roman($LastPrefixArabic).".</sup>";
                    debugV("\$CurrentDefinitionPrefix\t=\t$CurrentDefinitionPrefix");
                }
                else{
                    $PreviousDefinitionPrefix = '<sup>i.</sup>';
                    $CurrentDefinitionPrefix = '<sup>ii.</sup>';
                }
                
                $PreviousDefinition = $PreviousDefinitionPrefix.$PreviousDefinition;
                $CurrentDefinition  = $CurrentDefinitionPrefix.$CurrentDefinition;
                
                my $UpdatedDefinition = $PreviousDefinition."\n".$CurrentDefinition;
                debugV("\$UpdatedDefinition:\n\"", $UpdatedDefinition, "\"");
                return( $UpdatedDefinition);}
sub generateEntityHashFromDocType{
    my $String = $_[0]; # MultiLine DocType string. Not Array!!!
    my %EntityConversion=( );
    while($String =~ s~<!ENTITY\s+(?<name>[^\s]+)\s+"(?<meaning>.+?)">~~s){
        debugV("$+{name} --> $+{meaning}");
        $EntityConversion{$+{name}} = $+{meaning};
    }
    return(%EntityConversion);}
sub generateXDXFTagBased{
    info("\nEntering generateXDXFTagBased");
    my $rawml = join('', @_);
    my %Info;
    $rawml = removeEmptyTagPairs( $rawml );
   
    $Info{ "isExcludeImgTags" }     = $isExcludeImgTags;
    $Info{ "isSkipKnownStylingTags" } = $isSkipKnownStylingTags;
    $Info{ "HigherFrequencyTags"}   = $HigherFrequencyTags;
    $Info{ "isDeleteLowerFrequencyTagsinFilterTagsHash" } = $isDeleteLowerFrequencyTagsinFilterTagsHash;
    $Info{ "isRemoveMpbAndBodyTags"} = $isRemoveMpbAndBodyTags;
    $Info{ "minimum set percentage"}= $MinimumSetPercentage;
    $Info{ "rawml" }                = \$rawml;
    sub countTagsAndLowerCase{
        # Generates 2 hash references in %Info named "lowered stop-tags" and "counted tags hash".
        # Usage: countTagsAndLowerCase( \%Info );
        my $Info = shift;
        my (%tags, %LoweredStopTags);
        my $rawml = ${ $$Info{ "rawml" } };
        foreach(@{ $$Info{ "tags" } } ){
            if( m~^</[A-Z0-9]+>$~ ){
                my $lc = lc($_);
                unless( $LoweredStopTags{$_} ){
                    debug("Upper case stop tag '$_'. Lowering it.");
                    $rawml =~ s~\Q$_\E~$lc~g;
                }
                $LoweredStopTags{$_} = 1;
                $_ = $lc;
            }
            if( $tags{$_} ){ $tags{$_} = 1 + $tags{$_} ; }
            else{ $tags{$_} = 1; }
        }
        $$Info{ "rawml with lowered stop-tags"} = \$rawml;
        $$Info{ "lowered stop-tags"} = \%LoweredStopTags;
        $$Info{ "counted tags hash"} = \%tags;}
    sub filterTagsHash{
        # Usage: filterTagsHash( \%Info );
        # Uses the hash keys "counted tags hash" and "rawml".
        # Generates 4 keys in given hash, resp. "removed tags", "filtered rawml", "filtered tags hash" and "deleted tags".
   
        my $Info = shift;
        my %tags = %{ $$Info{ "counted tags hash" } };
        my $rawml = ${ $$Info{ "rawml with lowered stop-tags"} };
        my (%DeletedTags, %LowerFrequencyTags);
        sub sorttags{
            sub stripped{
                my $c = shift;
                $c =~ s~</?~~;
                return $c;
            }
            $tags{$a} <=> $tags{$b} or
            &stripped($a) cmp &stripped($b) or
            $a cmp $b}
        foreach( sort sorttags keys %tags ){
            if( m~</?a( |>)|</?i( |>)|</?b( |>)|</?font( |>)~i){
                unless( $DeletedTags{ substr($_, 0, 5) } ){ debug("Deleted '$_' from list of tags."); }
                $DeletedTags{ substr($_, 0, 5) } = 1;  # Use of substr to prevent flooding with anchor references.
                delete $tags{$_};     # Skip known styling.
            }
            elsif( m~^<img[^>]+>$~ and $$Info{ "isExcludeImgTags" } ){ delete $tags{$_}; }             # Remove img-tags if they're excluded
            # This also eliminates low  frequency <div .....> even if there are high frequency <div>-tags, leading to different counts for start- and stop-tags.
            elsif ( $tags{$_} > $$Info{ "HigherFrequencyTags"} ){ print "\$tags{$_} = $tags{$_}\n";}  # Keep and print higher frequency tags
            elsif ( $$Info{ "isDeleteLowerFrequencyTagsinFilterTagsHash" } ){
                unless( $LowerFrequencyTags{ $_ } ){ debug("Deleted '$_' from list of tags due to too low frequency ($tags{$_})."); }
                $LowerFrequencyTags{ $_ } = 1;
                delete $tags{$_};
            }
        }

        my %RemovedTags;
        foreach (keys %tags){
            if( $$Info{"isRemoveMpbAndBodyTags"} and
                ( m~</?mbp:~ or m~</?body~ )
                ){
                unless( defined $RemovedTags{$_} ){
                    $rawml =~ s~\Q$_\E~~sg;
                }
                $RemovedTags{ $_ } = 1;
            }
        }
        $$Info{ "removed tags" } = \%RemovedTags;
        $$Info{ "filtered rawml" } = \$rawml;
        $$Info{ "filtered tags hash" } = \%tags;
        $$Info{ "deleted tags"} = \%DeletedTags;}
    sub findArticlesBySets{
        # Structure @{$SetInfo}
        # [
        #   #0
        #   {
        #     'set' => [
        #                #0
        #                '</ar>',
        #                #1
        #                94837,
        #                #2
        #                '<ar>',
        #                #3
        #                94837
        #              ],
        #     'regex' => '<ar>((?!<ar>|</ar>).)+</ar>',
        #     'percentage' => 99,
        #     'disjunction' => '<ar>|</ar>'
        #   },
        #
        # ]
        my $Info = shift;
        my $SetInfo = $$Info{ "SetInfo" };
        my $rawml = ${$$Info{ "filtered rawml" }};
        foreach( sort {-($$a{"percentage"} <=> $$b{"percentage"}) } @$SetInfo ){
            print "\n-----".$$_{"set"}[0]."------\n";
            debug($$_{"percentage"}."%");
            if( $$_{"percentage"} < $$Info{ "minimum set percentage"}){
                debug("Maximum percentage (".$$_{"percentage"}."%)is below minimum (".$$Info{ "minimum set percentage"}."). No use trying for sets.");
                info("You can lower \$MinimumSetPercentage at the start of generateXDXFTagBased to change this behaviour.");
                last;
            }
            my $test = $rawml;
            # # Remove start.
            my $Start = qr~^(?<start>(?:(?!($$_{"disjunction"})).)+)~s;
            $test =~ s~$Start~~;
            # # Remove end.
            # # my $End = qr~(?<endregex>(?:(?<!($$_{"disjunction"})).)+)$~s; # Creates a Variable length negative lookbehind with capturing is experimental in regex;
            my $End = qr~(?<end>(?:(?<!($$_{"set"}[0])).)+)$~s; # Creates a Variable length negative lookbehind with capturing is experimental in regex;
            $test =~ s~$End~~;
            my @articles = $test =~ m~($$_{"regex"})~sg;
            $test =~ s~$$_{"regex"}\s+~~sg;
            debug("length of the remaining test is ". length($test) );
            debug(substr($test,0,2000));
            if( length($test) == 0 ){
                info("Articles identified.");
                info("Number of articles found: ".scalar @articles." with regex '".$$_{"regex"}."'.");
                info("0\n".$articles[0]);
                info("1\n".$articles[1]);
                info("2\n".$articles[2]);
                $$Info{ "articles"} = \@articles;
                $$Info{ "article stop tag"} = $$_{"set"}[0];
                return 1;
            }
            else{ @articles = (); }
        }
        info("No articles found by using sets.");
        return 0;}
    sub gatherSets{
        info("\nEntering gatherSets");
        # Usage: gatherSets( \%Info ); # Uses the hash key "filtered tags hash" and generates the keys "sets" and "SkippedTags", resp. an array- and a hash-reference.
        my $Info = shift;
        my $tags = $$Info{ "filtered tags hash" };
        my $Fails = 0;
        my $LowFrequencyCriterium = 100;
        $$Info{ "LowFrequencyCriterium"} = $LowFrequencyCriterium;

        my @sets; # Used for storing references to arrays of a set. Each set starts with the endtag, followed by a frequency and continuous with start-tags accompagnied by their frequencies.
        # [
        #   #0
        #   [
        #     #0
        #     '</ar>',
        #     #1
        #     94837,
        #     #2
        #     '<ar>',
        #     #3
        #     94837
        #   ],
        #   .....
        # ]

        my %SkippedTags;
        my @GatheredStartTags;
        # Find stop-tags and match them to starting tags
        foreach my $key ( keys %$tags ){
            my $count = 0;
            if( $$Info{ "isSkipKnownStylingTags" } and $key =~ m~</?a( |>)|</?i( |>)|</?b( |>)|</?font( |>)~i){ $SkippedTags{$key} = "known styling"; next; } # Skip known styling.
            if( ($$tags{$key} < $LowFrequencyCriterium ) and ($isgatherSetsVerbose == 0) ){ $SkippedTags{$key} = "too low frequency";  next; }
            unless( $key =~ m~^<\/~ ){  $SkippedTags{$key} = "not a stop tag"; next; }
            info("Reviewing endtag '$key' ($$tags{$key})");
            my @set;
            push @sets, \@set;
            push @set, $key, $$tags{$key};
            $key =~ s~(^<\/)~~;
            my @info;
            foreach ( keys %$tags ){
                s~^<~~;
                if( substr(lc($key), 0, length($key)-1 ) eq substr(lc($_), 0, length($key)-1 ) # To check that the keywords start the same
                    ){
                    if( substr($_, length($key)-1, 1 ) eq " " or substr($_, length($key)-1, 1 ) eq ">" ){ # end the same
                        push @info, "<$_ (".$$tags{"<".$_}.")";
                        $count = $count + $$tags{"<".$_};
                        push @set, "<".$_, $$tags{"<".$_};
                        push @GatheredStartTags, "<".$_;
                    }
                    else{ debugV("<$_ has at ". (length($key) - 1 )." the character '".substr($_, length($key)-1, 1 )."'"); }
                }

            }
            if( scalar @info > 5 ){
                info( $info[0]);
                info( $info[1]);
                info( ".. .. "x10 );
                info( ".. .. "x10 );
                info( $info[-2]);
                info( $info[-1]);
            }
            else{ info( join("\n", @info ) ); }
            unless( $$tags{"</".$key} == $count){
                $Fails++;
                debug("The stop- (".$$tags{"</".$key}.") and starttags ($count) have a different count.");
            }
            else{ info("The stop- and starttags have the same count ($count)."); }

        }
        if( $Fails ){ debug( "There were $Fails unequal counts of start- and stoptags."); }
        else{ info("All obvious pairs of start- en stop-tags appear in equal numbers."); }
        $Data::Dumper::Indent = 3;
        infoVV( Dumper( \@sets ));
        foreach( @GatheredStartTags ){ if( exists $SkippedTags{ $_ } ){ delete $SkippedTags{ $_ }; } }
        # printDumperFilered( \%SkippedTags, '<\?a ?' );
        logSets( $FileName, \@sets );
        $Info{ "sets" }              = \@sets;
        $Info{ "SkippedTags" }       = \%SkippedTags;}
    sub logSets{
        my $FileName = shift;
        my $Data = join('', Dumper( shift ));

        $FileName =~ s~.+/([^/]+)~$1~;

        $Data =~ s~\n+\s*(\[|\]\;)~$1~g;
        $Data =~ s~\n+\s*(\d+)~$1~g;

        my $LogDirName = "$BaseDir/dict/logs";
        unless( -e $LogDirName ){
            mkdir $LogDirName || ( Die("Couldn't create directory '$LogDirName'.") );
        }
        my $LogName = "$LogDirName/$FileName.sets.log";
        array2File( $LogName, $Data); }
    sub logTags{
        my $FileName = shift;
        my $Data = join('', Dumper( shift ));

        $FileName =~ s~.+/([^/]+)~$1~;

        # $Data =~ s~\n+\s*(\[|\]\;)~$1~g;
        # $Data =~ s~\n+\s*(\d+)~$1~g;

        my $LogDirName = "$BaseDir/dict/logs";
        unless( -e $LogDirName ){
            mkdir $LogDirName || ( Die("Couldn't create directory '$LogDirName'.") );
        }
        my $LogName = "$LogDirName/$FileName.tags.log";
        array2File( $LogName, $Data); }
    sub sets2Percentages{
        info("\nEntering sets2Percentages");
        # Usage: sets2Percentages( \%Info );
        # Uses the hash keys "sets" and "filtered rawml" to generate the key "SetInfo", an array-reference.
   
        my $Info = shift;
        my @sets = @{ $$Info{ "sets" } };
        my $rawml   =   ${ $$Info{ "filtered rawml"} };

        my %Percentages;

        my @SetInfo;
        # [
        #   #0
        #   {
        #     'set' => [
        #                #0
        #                '</ar>',
        #                #1
        #                94837,
        #                #2
        #                '<ar>',
        #                #3
        #                94837
        #              ],
        #     'regex' => '<ar>((?!<ar>|</ar>).)+</ar>',
        #     'percentage' => 99,
        #     'disjunction' => '<ar>|</ar>'
        #   },
        # .....
        # ]

        for( my $set = 0; $set < scalar @sets; $set++ ){
            my $test = $rawml;
            debugVV( $sets[$set] );
            debugVV( scalar @{ $sets[$set] });
            my $disjunction = $sets[$set][0]; # Set equal to stop-tag
            debugVV("Name:disjunction", $disjunction);
            my $regex;
            debugVV( scalar @{ $sets[$set]});
            for( my $index = 2; $index < scalar @{ $sets[$set] }; $index += 2 ){
                $regex = "$sets[$set][$index](?:(?!DISJUNCTION).)+$sets[$set][0]";
                infoVV("set $set, index $index, regex: '$regex'");
                $disjunction = "$sets[$set][$index]|$disjunction";
                infoVV("set $set, index $index, disjunction: '$disjunction'");
            }
            infoVV("Regex formed: '$regex'");
            $regex =~ s~DISJUNCTION~$disjunction~;
            infoVV("Regex formed: '$regex'");
            $test =~ s~$regex~~gs;
            my $percentage = int( 100 - length($test) / length($rawml) * 100 );
            $SetInfo[$set]{"set"}           = $sets[$set];      # Array of the keywords and their frequencies
            $SetInfo[$set]{"regex"}         = $regex;
            $SetInfo[$set]{"disjunction"}   = $disjunction;
            $SetInfo[$set]{"percentage"}    = $percentage;
            $Percentages{$sets[$set][0]}    = $SetInfo[$set]{"percentage"};
            info("Removed stringlength is $percentage\% for $sets[$set][0] ($sets[$set][1])");
        }
        infoVV( Dumper \@SetInfo );

        $Percentages{ "max_amount" } = 0;
        $Percentages{ "stop-tag" } = "";
        foreach( keys %Percentages ){
            if( m~max_amount|stop-tag|remaining~ ){ next; }
            debugVV( $_);
            if( $Percentages{ $_ } > $Percentages{ "max_amount" } ){
                $Percentages{ "max_amount" }    = $Percentages{ $_ };
                $Percentages{ "stop-tag" }       = $_;
            }
            debugVV( $Percentages{ $_ } );
            debugVV( $Percentages{ "max_amount" } );
            debugVV( "----")
        }
        info("The maximum amount of string is ".$Percentages{ "max_amount" }."% and is removed with blocks that end with ".$Percentages{ "stop-tag" }."." );
        $Info{ "SetInfo"} = \@SetInfo;}
    sub splitArticlesIntoKeyAndDefinition{
        # Usage: splitArticlesIntoKeyAndDefinition(\%Info)
        # returns 1 on success.
        my $Info = shift;
        my $articles = $$Info{ "articles" };
        debugV( Dumper $$Info{ "sets"} );
        my @csv;
        my $OldCVSDeliminator = $CVSDeliminator;
        $CVSDeliminator = "||||";
        unless( @$articles > 0 ){ warn "No articles were given to sub splitArticlesIntoKeyAndDefinition!"; Die(); }
        my $counter = 0;
        foreach my $article( @$articles ){
            $counter++;
            # Check outer article tags and remove them.
            if( defined $$Info{ "article stop tag"} ){
                my $Stoptag = $$Info{ "article stop tag"}; # </ar>
                my $Starttag = startTag( $article );
                debugVV("Start-tag = '$Starttag'");
                unless( $Stoptag eq stopFromStart( $Starttag ) ){ warn "Article stop-tag registered in %Info doesn't match start-tag"; die; }
                $article = cleanOuterTags( $article );
            }
            debug( "'$article'" ) if $counter < 6;

            # Check starting key-tag and check them against high frequency tags.
            my $KeyStartTag = startTag( $article );
            debug( "Key start tag: $KeyStartTag") if $counter < 6;
            my $KeyStopTag = stopFromStart( $KeyStartTag );
            debug( "Key stop tag: $KeyStopTag") if $counter < 6;
            my $HighFrequencyTagRecognized = 0;
            foreach my $Set( @{ $$Info{ "sets" } } ){
                if( $KeyStopTag eq $$Set[0] ){ $HighFrequencyTagRecognized = 1; last; }
                else{ debugVV( "'$KeyStopTag' isn't equal to '$$Set[0]'"); }
            }
            unless( $HighFrequencyTagRecognized ){ warn "Key start tag is not a high frequency tag."; Die(); }
            # Match key and definition. Push cleaned string to csv-array.
            unless( $article =~ m~\Q$KeyStartTag\E(?<key>.+?)\Q$KeyStopTag\E(?<definition>.+)$~s){ warn "Regex for key-block doesn't match."; die;}
            infoV("Found a key and definition in article.");
            my $Key         = cleanOuterTags( $+{ "key" } );
            my $Definition  = cleanOuterTags( $+{ "definition" } );
            infoVV("Key is '$Key'");
            infoVV("Definition is '$Definition'");
            push @csv, $Key.$CVSDeliminator.$Definition;
        }
        # Create xdxf-array and store csv- and xdxf-arrays in info hash.
        $$Info{ "csv" } = \@csv;
        my @xdxf = convertCVStoXDXF( @csv );
        $CVSDeliminator = $OldCVSDeliminator;

        if( scalar @xdxf ){ $$Info{ "xdxf" } = \@xdxf; return 1; }
        else{ return 0; }}
    sub splitRawmlIntoArticles{
        # Usage: splitRawmlIntoArticles( \%Info );
        # Takes the hash keys "SkippedTags" and "filtered rawml" and generates the keys "articles" and "filtered SkippedTags", resp. an array- and a hash-reference.
   
        my $Info = shift;
        my %SkippedTags = %{ $$Info{ "SkippedTags"    } };
        my $rawml       = ${ $$Info{ "filtered rawml" } };

        # Filter SkippedTags
        foreach( sort { $SkippedTags{$a} cmp $SkippedTags{$b} or $a cmp $b }keys %SkippedTags ){
            if( $SkippedTags{$_} =~ m~known styling|too low frequency~ ){ delete $SkippedTags{$_}; infoV("'$_' (".$SkippedTags{$_}.") didn't form a set"); }
            elsif( m~^<img[^>]+>$~ and $isExcludeImgTags ){ delete $SkippedTags{$_}; infoV("'$_' (".$SkippedTags{$_}.") didn't form a set"); }
            else{ info("'$_' (".$SkippedTags{$_}.") didn't form a set");}
        }
        debugV( Dumper \%SkippedTags );
        SKIPPEDTAG: foreach my $SplittingTag( keys %SkippedTags){
            my @chunks = split(/\Q$SplittingTag\E/, $rawml );
            my $FirstArticle = shift @chunks;
            my $LastArticle = pop @chunks;
            $LastArticle =~ s~^\s*~~;
            my $counter = 0;
            # Check that all chuncks start with a tag
            my $StartTag = "unknown";
            foreach my $chunk( @chunks ){
                $counter++;
                $chunk =~ s~^\s+~~;
                debugV( "Chunk is\n'$chunk'") if $counter < 6;
                my $NewStartTag = startTagReturnUndef( $chunk );
                unless( defined $NewStartTag ){
                    info("Chunk doesn't start with a tag. Skipping splitting tag '$SplittingTag'.");
                    next SKIPPEDTAG;
                }
                unless( $NewStartTag eq $StartTag or $StartTag eq "unknown"){
                    info("Start-tags of chunks are different: '$StartTag' vs '$NewStartTag'. Skipping splitting tag '$SplittingTag'.");
                    next SKIPPEDTAG;
                }
                elsif( $StartTag eq "unknown" ){ $StartTag = $NewStartTag; }
            }
            my $StopTag = stopFromStart( $StartTag );
            info("Found that splitting tag '$SplittingTag' results in an uniform key-block surrounded by '$StartTag....$StopTag'.");
            # Fix first and last article
            infoV("First article:\n'$FirstArticle'");
            $FirstArticle =~ m~$StartTag(?:(?!\Q$StartTag\E).)+$~s; # Match the last tag
            $Info{ "start dictionary"} = $`;
            unshift @chunks, $&;
            infoV( "Start dictionary is\n'". $Info{ "start dictionary"} ."'");
            infoV( "First article is \n'". $& ."'");
            infoV("Last article:\n'$LastArticle'");
            my @LastStopTags = $LastArticle =~ m~(</[^>]+>)~sg;
            foreach my $LastStopTag (@LastStopTags){
                my $LastStartTag = startFromStop( $LastStopTag );
                unless( $LastArticle =~ m~^((?!\Q$LastStopTag\E).)*\Q$LastStartTag\E((?!\Q$LastStopTag\E).)*\Q$LastStopTag\E~ ){
                    # No preceding start-tag: Cut at this last stop tag.
                    $LastArticle =~ m~$LastStopTag~;
                    $Info{ "end dictionary" } = $LastStopTag.$';
                    push @chunks, $`;
                    if( $chunks[-1] !~ m~^\Q$StartTag\E~ ){
                        unless( $chunks[-1] =~ m~^\s*$~ ){ debug("Last article is not properly formed:\n'". $chunks[-1]."'"); }
                        pop @chunks;
                    }
                    else{ infoV( "Last article is\n'".$`."'"); }
                    infoV( "End dictionary is\n'". $LastStopTag.$'."'");
                    unless( defined $Info{ "end dictionary" } ){ warn "Didn't separate end of dictionary from last article."; die; }
                    last;
                }
            }
            unless( defined $Info{ "start dictionary" } ){ warn "Didn't separate start of dictionary from first article."; die; }
            unless( defined $Info{ "end dictionary"   } ){ warn "Didn't separate end of dictionary from last article."; die; }
            $$Info{ "filtered SkippedTags" } = \%SkippedTags;
            $$Info{ "articles"} = \@chunks;
            info( "Articles were split.");
            last;
        }}   
   
    # Get all tags
    my @tags = $rawml =~ m~(<[^>]*>)~sg;
    $Info{ "tags" } = \@tags;
    logTags( $FileName, \@tags);

    # Hash all tags with their frequency and filter them
    countTagsAndLowerCase( \%Info ); # Generates 2 hash references in %Info named "lowered stop-tags" and "counted tags hash".
    filterTagsHash( \%Info ); # Uses the hash key { "counted tags hash" }. Generates 4 keys in given hash, resp. "removed tags", "filtered rawml", "filtered tags hash" and "deleted tags".
   
    # Gather the start- and stop tag sets.
    gatherSets( \%Info ); # Uses the hash key "filtered tags hash" and generates the keys "sets" and "SkippedTags", resp. an array- and a hash-reference.

    # Find the percentages that the sets occupy of the rawml.
    sets2Percentages( \%Info ); # Uses the hash keys "sets" and "filtered rawml" to generate the key "SetInfo", an array-reference.

    # Are there high frequency tag-blocks that contain all other high frequency blocks?
    unless( exists $Info{ "articles" } ){ findArticlesBySets( \%Info ); }

    # Is there a high frequency tag that doesn't have a partner, e.g. <hr /> or <hr/>? Splitting at such a tag could give uniform chunks;
    unless( exists $Info{ "articles" } ){ splitRawmlIntoArticles( \%Info ); } # Takes the hash keys "SkippedTags" and "filtered rawml" and generates the keys "articles" and "filtered SkippedTags", resp. an array- and a hash-reference.
   
   
    if( exists $Info{ "articles" } ){
        info( "Articles were found.");
        if( splitArticlesIntoKeyAndDefinition(\%Info) ){
            info("Articles were split into keys and definitions");
        }
    }
    else{ debug( "No articles found with sub generateXDXFTagBased(), yet"); }
    return ( $Info{ "xdxf"} )}
sub getLoggingTime {

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
    my $nice_timestamp = sprintf ( "%04d%02d%02d %02d:%02d:%02d",
                                   $year+1900,$mon+1,$mday,$hour,$min,$sec);
    return $nice_timestamp;}
sub info{   printCyan( join('',@_)."\n" ) if $isInfo;               }
sub info_t{   printCyan( join('',@_)."\n" ) if $isInfo and $isTestingOn;}
sub infoV{  printCyan( join('',@_)."\n" ) if $isInfoVerbose;        }
sub infoVV{ printCyan( join('',@_)."\n" ) if $isInfoVeryVerbose;    }
sub loadXDXF{
    # Create the array @xdxf
    my @xdxf;
    my $PseudoFileName = join('', $FileName=~m~^(.+?\.)[^.]+$~)."xdxf";
    ## Load from xdxffile
    if( $FileName =~ m~\.xdxf$~){
        @xdxf = file2Array($FileName);
        my $xdxf_try =  generateXDXFTagBased( join('', @xdxf ) );
        if( $xdxf_try ){ @xdxf = @{ $xdxf_try }; }
    }
    elsif( -e $PseudoFileName ){
        @xdxf = file2Array($PseudoFileName);
        # Check SameTypeSequence
        checkSameTypeSequence($FileName);
        # Change FileName to xdxf-extension
        $FileName = $PseudoFileName;
    }
    ## Load from ifo-, dict- and idx-files
    elsif( $FileName =~ m~^(?<filename>((?!\.ifo).)+)\.(ifo|xml)$~){
        # Check wheter a converted xml-file already exists or create one.
        if(! -e $+{filename}.".xml"){
            # Convert the ifo/dict using stardict-bin2text $FileName $FileName.".xml";
            if ( $OperatingSystem == "linux"){
                printCyan("Convert the ifo/dict using system command: \"stardict-bin2text $FileName $FileName.xml\"\n");
                system("stardict-bin2text \"$FileName\" \"$+{filename}.xml\"");
            }
            else{ debug("Not linux, so you can't use the script directly on ifo-files, sorry!\n",
                "First decompile your dictionary with stardict-editor to xml-format (Textual Stardict dictionary),\n",
                "than either use the ifo- or xml-file as your dictioanry name for conversion.")}
        }
        # Create an array from the stardict xml-dictionary.
        my @StardictXML = file2Array("$+{filename}.xml");
        @xdxf = convertStardictXMLtoXDXF(@StardictXML);
        # Write it to disk so it hasn't have to be done again.
        array2File($+{filename}.".xdxf", @xdxf);
        # debug(@xdxf); # Check generated @xdxf
        $FileName=$+{filename}.".xdxf";
    }
    ## Load from comma separated values cvs-file.
    ## It is assumed that every line has a key followed by a comma followed by the definition.
    elsif( $FileName =~ m~^(?<filename>((?!\.csv).)+)\.csv$~){
        my @cvs = file2Array($FileName);
        @xdxf = convertCVStoXDXF(@cvs);
        # Write it to disk so it hasn't have to be done again.
        array2File($+{filename}.".xdxf", @xdxf);
        # debug(@xdxf); # Check generated @xdxf
        $FileName=$+{filename}.".xdxf";
    }
    elsif(    $FileName =~ m~^(?<filename>((?!\.mobi).)+)\.mobi$~ or
            $FileName =~ m~^(?<filename>((?!\.azw3?).)+)\.azw3?$~ or
            $FileName =~ m~^(?<filename>((?!\.html).)+)\.html$~    ){
        # Use full path and filename
        my $InputFile = "$BaseDir/$FileName";
        my $OutputFolder = substr($InputFile, 0, length($InputFile)-5);
        unless( $OutputFolder =~ m~([^/]+)$~ ){ warn "Couldn't match dictionary name for '$OutputFolder'" ; Die(); }
        my $DictionaryName = $1;
        my $HTMLConversion = 0;
        my $RAWMLConversion = 0;
        if( $FileName =~ m~^(?<filename>((?!\.mobi).)+)\.mobi$~ or
            $FileName =~ m~^(?<filename>((?!\.azw3?).)+)\.azw3?$~     ){

            # Checklist
            if ($OperatingSystem eq "linux"){ debugV("Converting mobi to html on Linux is possible.") }
            else{ debug("Not Linux, so the script can't convert mobi-format. Quitting!"); die; }
            my $python_version = `python --version`;
            if(  substr($python_version, 0,6) eq "Python"){
                debug("Found python responding as expected.");
            }
            else{ debug("Python binary not working as expected/not installed. Quitting!"); die; }

            # Conversion mobi to html
            if( -e "$OutputFolder/mobi7/$DictionaryName.html" ){
                debug("html-file found. Mobi-file already converted.");
                $HTMLConversion = 1;
                $LocalPath = "$LocalPath/$DictionaryName/mobi7";
                $FullPath = "$FullPath/$DictionaryName/mobi7";
                $FileName = "$LocalPath/$DictionaryName.html";
            }
            elsif( -e "$OutputFolder/mobi7/$DictionaryName.rawml" ){
                debug("rawml-file found. Mobi-file already converted, but KindleUnpack failed to convert it to html.");
                debug("Will try at the rawml-file, but don't get your hopes up!");
                $RAWMLConversion = 1;
                $LocalPath = "$LocalPath/$DictionaryName/mobi7";
                $FullPath = "$FullPath/$DictionaryName/mobi7";
                $FileName = "$LocalPath/$DictionaryName.rawml";
            }
            else{
                chdir $KindleUnpackLibFolder || warn "Cannot change to $KindleUnpackLibFolder: $!\n";
                waitForIt("The script kindelunpack.py is now unpacking the file:\n$InputFile\nto: $OutputFolder.");
                my $returnstring = `python kindleunpack.py -r -s --epub_version=A -i "$InputFile" "$OutputFolder"`;
                if( $returnstring =~ m~Completed\n*$~s ){
                    debug("Succes!");
                    chdir $BaseDir || warn "Cannot change to $BaseDir: $!\n";
                    rename "$OutputFolder/mobi7/book.html", "$OutputFolder/mobi7/$DictionaryName.html";
                    doneWaiting();
                    $HTMLConversion = 1;
                    $LocalPath = "$LocalPath/$DictionaryName/mobi7";
                    $FullPath = "$FullPath/$DictionaryName/mobi7";
                    $FileName = "$LocalPath/$DictionaryName.html";
                }
                else{
                    debug("KindleUnpack failed to convert the mobi-file.");
                    debug($returnstring);
                    if( -e "$OutputFolder/mobi7/$DictionaryName.rawml" ){
                        debug("rawml-file found. Mobi-file already converted, but KindleUnpack failed to convert it to html.");
                        debug("Will try at the rawml-file, but don't get your hopes up!");
                        $RAWMLConversion = 1;
                        $LocalPath = "$LocalPath/$DictionaryName/mobi7";
                        $FullPath = "$FullPath/$DictionaryName/mobi7";
                        $FileName = "$LocalPath/$DictionaryName.rawml";
                        chdir $BaseDir || warn "Cannot change to $BaseDir: $!\n";
                    }
                    else{ Die(); }
                }
            }
            debug("After conversion dictionary name is '$DictionaryName'.");
            debug("Local path for generated html is \'$LocalPath\'.");
            debug("Full path for generated html is \'$FullPath\'.");
            debug("Filename for generated html is \'$FileName\'.");
        }
        elsif( $FileName =~ m~^(?<filename>((?!\.html).)+)\.html$~    ){
            $HTMLConversion = 1;
        }

        # Output of KindleUnpack.pyw
        my $encoding = "UTF-8";
        if( $HTMLConversion ){
            my @html = file2Array($FileName);
            @xdxf = convertHTML2XDXF($encoding,@html);
            array2File("testConvertedHTML.xdxf", @xdxf) if $isTestingOn;
        }
        elsif( $RAWMLConversion ){
            my @rawml = file2Array( $FileName );
            @xdxf = convertRAWML2XDXF( @rawml );
            if( scalar @xdxf == (1+scalar @xdxf_start) ){ debug("Not able to handle the rawml-file. Quitting!"); Die(); }
        }
        # Check whether there is a saved reconstructed xdxf to get the language and name from.
        if(-e  "$LocalPath/$DictionaryName"."_reconstructed.xdxf"){
            my @saved_xdxf = file2Array("$LocalPath/$DictionaryName"."_reconstructed.xdxf");
            if( $saved_xdxf[1] =~ m~<xdxf lang_from="[^"]+" lang_to="[^"]+" format="visual">~ ){
                $xdxf[1] = $saved_xdxf[1];
            }
            if( $saved_xdxf[2] =~ m~<full_name>[^<]+</full_name>~ ){
                @xdxf[2] = @saved_xdxf[2];
            }
        }
        else{debug('No prior dictionary reconstructed.');}
        $FileName="$LocalPath/$DictionaryName".".xdxf";
        # Write it to disk so it hasn't have to be done again.
        array2File($FileName, @xdxf);
        # debug(@xdxf); # Check generated @xdxf


    
    }
    elsif( $FileName =~ m~^(?<filename>((?!\.epub).)+)\.epub$~i ){
        debug("Found an epub-file. Unzipping.");
        unless( $FileName =~ m~([^/]+)$~ ){ warn "Couldn't match dictionary name for '$FileName'" ; Die(); }
        my $DictionaryName = $1;
        debug('$DictionaryName = "', $DictionaryName, '"');
        my $LocalPath = substr($FileName, 0, length($FileName)-length($DictionaryName) );
        chdir $BaseDir."/".$LocalPath;
        my $SubDir = substr($DictionaryName, 0, length($DictionaryName)-5);
        $SubDir =~ s~ ~__~g;
        unless( -e $SubDir){`mkdir "$SubDir"`; debug( "Made directory '$SubDir'"); }
        else{ debug("Directory '$SubDir' already exists. Files will be overwritten if present."); }
        my $UnzipCommand = "7z e -y \"$DictionaryName\" -o\"$SubDir\"";
        debugV("Executing command:\n '$UnzipCommand'");
        system($UnzipCommand);
        debug("\"$SubDir/*.html\"");

        my @html = glob("$SubDir/*.html");
        debugV('@html = ', @html);
        @xdxf = @xdxf_start;
        foreach my $HTMLFile( @html ){
            my $Content = join('', file2Array($HTMLFile) );
            # <style type="text/css">
            # p{text-align:left;text-indent:0;margin-top:0;margin-bottom:0;}
            # .ww{color:#FFFFFF;}
            # .gag{font-weight:bold;}
            # .gc{font-weight:bold;text-decoration:underline;}
            # .g4{color:#115349;}
            # .g5{color:#3B3B3B;}
            # .g6_s{color:#472565;}
            # .gm{font-style:italic;}
            # .gaa_gj{font-weight:bold;}
            # .gh{font-weight:bold;}
            # </style>
            my (@Classes, %Classes);
            if( $Content =~ m~<style type="text/css">(?<styleblock>(?!</style>).+)</style>~s ){
                my $StyleBlock = $+{styleblock};
                debugV("StyleBlock is \n$StyleBlock");
                @Classes = $StyleBlock =~ m~\.([^\{]+)\{(?<style>[^\}]+)\}~sg;
                while( @Classes){
                    my $Class = shift @Classes;
                    my $Style = shift @Classes;
                    $Class = "class=\"$Class\"";
                    $Style = "style=\"$Style\"";
                    debugV("Class '$Class' is style '$Style'");
                    $Classes{$Class} =  $Style;
                }
            }
            else{ debug("No StyleBlock found.");}
            foreach my $Class( keys %Classes){
                $Content =~ s~\Q$Class\E~$Classes{$Class}~sg;
            }
            debugV($Content);
            my @Paragraphs = $Content =~ m~(<p[^>]*>(?:(?!</p>).)+</p>)~sg;
            foreach(@Paragraphs){
                debugV($_);
            }
            debugV("number of paragraphs in '$HTMLFile' is ", scalar @Paragraphs);
            my $isLoopDebugging = 0;
            while(@Paragraphs){
                my $Key = shift @Paragraphs;
                my $Def = shift @Paragraphs;
                # <p style="color:#FFFFFF;"><sub>q  32 chars
                # </sub></p>            10 chars
                $Key = substr( $Key, 32, length($Key) - 42);
                # debug('$Key is ', $Key);
                # debug('$Def is ', $Def);
                push @xdxf, "<ar><head><k>$Key</k></head><def>$Def</def></ar>\n";
                debug("Pushed <ar><head><k>$Key</k></head><def>$Def</def></ar>") if $isLoopDebugging;
            } # Finished all Paragraphs

        } # Finished all HTMLFiles
        push @xdxf, "</xdxf>\n";
        my $XDXFfile = $DictionaryName;
        $XDXFfile =~ s~epub$~xdxf~;
        array2File($XDXFfile, @xdxf);

        $FileName = $LocalPath.$XDXFfile;

        debugV("Current directory was ", `pwd`);
        debugV("Returning to basedir '$BaseDir'.");
        chdir $BaseDir;
    }
    else{debug("Not an extension that the script can handle for the given filename. Quitting!");die;}


    return( @xdxf );}
sub makeKoreaderReady{
    my $html = join('',@_);
    waitForIt("Making the dictionary Koreader ready.");
    # Not moving it to lua, because it also works with Goldendict.
    $html =~ s~<c>~<span>~sg;
    $html =~ s~<c c="~<span style="color:~sg;
    $html =~ s~</c>~</span>~sg;
    # Things done with css-file
    my @css;
    my $FileNameCSS = join('', $FileName=~m~^(.+?)\.[^.]+$~)."_reconstructed.css";
    # Remove large blockquote margins
    push @css, "blockquote { margin: 0 0 0 1em }\n";
    # Remove images
    # $html =~ s~<img[^>]+>~~sg;
    # push @css, "img { display: none; }\n"; # Doesn't work. Placeholder [image] still appears in Koreader.
    if(scalar @css>0){array2File($FileNameCSS,@css);}
    # Things done with lua-file
    my @lua;
    my $FileNameLUA = join('', $FileName=~m~^(.+?)\.[^.]+$~)."_reconstructed.lua";
    # Example
    # return function(html)
    # html = html:gsub('<c c=\"', '<span style="color:')
    # html = html:gsub('</c>', '</span>')
    # html = html:gsub('<c>', '<span>')
    # return html
    # end
    # Example
    # return function(html)
    # -- html = html:gsub(' style=', ' zzztyle=')
    # html = html:gsub(' [Ss][Tt][Yy][Ll][Ee]=', ' zzztyle=')
    # return html
    # end
    my $lua_start = "return function(html)\n";
    my $lua_end = "return html\nend\n";
    # Remove images
    push @lua, "html = html:gsub('<img[^>]+>', '')\n";
    if(scalar @lua>0){
        unshift @lua, $lua_start;
        push @lua, $lua_end;
        array2File($FileNameLUA,@lua);
    }
    doneWaiting();
    
    return(split(/$/, $html));}
sub printBlue    { print color('blue') if $OperatingSystem eq "linux";    print @_; print color('reset') if $OperatingSystem eq "linux"; }
sub printCyan    { print color('cyan') if $OperatingSystem eq "linux";    print @_; print color('reset') if $OperatingSystem eq "linux"; }
sub printGreen   { print color('green') if $OperatingSystem eq "linux";   print @_; print color('reset') if $OperatingSystem eq "linux"; }
sub printMagenta { print color('magenta') if $OperatingSystem eq "linux"; print @_; print color('reset') if $OperatingSystem eq "linux"; }
sub printRed     { print color('red') if $OperatingSystem eq "linux";     print @_; print color('reset') if $OperatingSystem eq "linux"; }
sub printYellow  { print color('yellow') if $OperatingSystem eq "linux";  print @_; print color('reset') if $OperatingSystem eq "linux"; }
sub reconstructXDXF{
    # Construct a new xdxf array to prevent converter.exe from crashing.
    ## Initial values
    my @xdxf = @_;
    my @xdxf_reconstructed = ();
    my $xdxf_closing = "</xdxf>\n";
    
    # Initalizing values based on found values in reconstructed xdxf-file
    my $full_name;
    my $dict_xdxf_reconstructed =  $FileName;
    if( $dict_xdxf_reconstructed !~ s~\.[^\.]+$~_reconstructed\.xdxf~ ){ debug("Filename substitution did not work for : \"$dict_xdxf_reconstructed\""); die if $isRealDead; }
    if( -e $dict_xdxf_reconstructed ){
        my @xdxf_reconstructed = file2Array($dict_xdxf_reconstructed);
        my $xdxf_reconstructed = join('', @xdxf_reconstructed[0..20]);
        debugV("First 20 lines of xdxf_reconstructed:\n", $xdxf_reconstructed);
        #<xdxf lang_from="fr" lang_to="nl" format="visual">
        if( $xdxf_reconstructed =~ m~<xdxf lang_from="(?<lang_from>\w+)" lang_to="(?<lang_to>\w+)" format="visual">~ ){
            $lang_from = $+{lang_from};
            $lang_to = $+{lang_to};
        }
        # <full_name>Van Dale FR-NL 2010</full_name>
        if( $xdxf_reconstructed =~ m~<full_name>(?<full_name>[^<]+)</full_name>~ ){
            $full_name = $+{full_name};
        }
    }

    waitForIt("Reconstructing xdxf array.");
    ## Step through the array line by line until the articles start.
    ## Then push (altered) entry to array.

    foreach my $entry (@xdxf){
        # Handling of xdxf tag
        if ( $entry =~ m~^<xdxf(?<xdxf>.+)>\n$~){
            my $xdxf = $+{xdxf};
            if( $reformat_xdxf and $xdxf =~ m~ lang_from="(.*)" lang_to="(.*)" format="(.*)"~){
                $lang_from = $1 if defined $1 and $1 ne "";
                $lang_to = $2 if defined $2 and $2 ne "";
                $format = $3 if defined $3 and $3 ne "";
                print(" lang_from is \"$1\". Would you like to change it? (press enter to keep default \[$lang_from\] ");
                my $one = <STDIN>; chomp $one; if( $one ne ""){ $lang_from = $one ; }
                print(" lang_to is \"$2\". Would you like to change it? (press enter to keep default \[$lang_to\] ");
                my $two = <STDIN>; chomp $two; if( $two ne ""){ $lang_to = $two ; }
                print(" format is \"$3\". Would you like to change it? (press enter to keep default \[$format\] ");
                my $three = <STDIN>; chomp $three; if( $three ne ""){ $format = $three ; }
                $xdxf= 'lang_from="'.$lang_from.'" lang_to="'.$lang_to.'" format="'.$format.'"';
            }
            $entry = "<xdxf ".$xdxf.">\n";
            printMagenta($entry);
        }
        # Handling of full_name tag
        elsif ( $entry =~ m~^<full_name>~){
            if ( $entry !~ m~^<full_name>.*</full_name>\n$~){ debug("full_name tag is not on one line. Investigate!\n"); die if $isRealDead;}
            elsif( $reformat_full_name and $entry =~ m~^<full_name>(?<fullname>((?!</full).)*)</full_name>\n$~ ){
                my $old_name = $full_name;
                $full_name = $+{fullname};
                if ( $old_name eq ""){ $old_name = $full_name; }
                print("Full_name is \"$full_name\".\nWould you like to change it? (press enter to keep default \[$old_name\] ");
                my $one = <STDIN>; chomp $one;
                if( $one ne ""){ $full_name = $one ; }
                else{ $full_name = $old_name;}
                debug("\$entry was: $entry");
                $entry = "<full_name>$full_name</full_name>\n";
                debug("Fullname tag entry is now: ");
            }
            printMagenta($entry);
        }
        # Handling of Description. Turns one line into multiple.
        elsif( $entry =~ m~^(?<des><description>)(?<cont>((?!</desc).)*)(?<closetag></description>)\n$~ ){
            my $Description_content .= $+{cont} ;
            chomp $Description_content;
            $entry = $+{des}."\n".$Description_content."\n".$+{closetag}."\n";
        }
        # Handling of an ar-tag
        elsif ( $entry =~ m~^<ar>~){last;}  #Start of ar block
        
        push @xdxf_reconstructed, $entry;
    }

    # Push cleaned articles to array
    my $xdxf = join( '', @xdxf);
    my @articles = $xdxf =~ m~<ar>((?:(?!</ar).)+)</ar>~sg ;
    my ($ar, $ar_count) = ( 0, -1);
    my (%KnownKeys,@IndexedDefinitions,@IndexedKeys);
    foreach my $article (@articles){
        $ar_count++; $cycle_dotprinter++; if( $cycle_dotprinter == $cycles_per_dot){ printGreen("."); $cycle_dotprinter=0;}
        $article = cleanseAr($article);
        chomp $article;
        # <head><k>accognoscundis</k></head><def><blockquote>accognosco</blockquote></def>
        $article =~ m~<head><k>(?<key>(?:(?!</k>).)+)</k></head><def>(?<def>(?:(?!</def>).)+)</def>~s;
        if( exists $KnownKeys{$+{key}} ){
            # Append definition to other definition.
            my $CurrentDefinition = $+{def};
            my $PreviousDefinition = $IndexedDefinitions[$KnownKeys{$+{key}}];
            $IndexedDefinitions[$KnownKeys{$+{key}}] = fixPrefixes($PreviousDefinition, $CurrentDefinition);

            $ar_count--;
        }
        else{
            $KnownKeys{$+{key}} = $ar_count;
            $IndexedKeys[$ar_count] = $+{key};
            $IndexedDefinitions[$ar_count] = $+{def};
        }
    }
    # push @xdxf_reconstructed, "<ar>\n$article\n</ar>\n";    
    foreach( @IndexedKeys ){
        push @xdxf_reconstructed, "<ar>\n<head><k>$_</k></head><def>$IndexedDefinitions[$KnownKeys{$_}]</def>\n</ar>\n";    
    }
    push @xdxf_reconstructed, $xdxf_closing;
    printMagenta("\nTotal number of articles processed \$ar = ",scalar @articles,".\n");
    doneWaiting();
    return( @xdxf_reconstructed );}
sub removeBloat{
    my $xdxf = join('',@_);
    debugV("Removing bloat from dictionary...");
    while ( $xdxf =~ s~<blockquote>(?<content><blockquote>(?!<blockquote>).*?</blockquote>)</blockquote>~$+{content}~sg ){ debugV("Another round (removing double nested blockquotes)");}
    while( $xdxf =~ s~<ex>\s*</ex>|<ex></ex>|<blockquote></blockquote>|<blockquote>\s*</blockquote>~~sg ){ debugV("And another (removing empty blockquotes and examples)"); }
    while( $xdxf =~ s~\n\n~\n~sg ){ debugV("Finally then..(removing empty lines)");}
    while( $xdxf =~ s~</blockquote>\s+<blockquote>~</blockquote><blockquote>~sg ){ debugV("...another one (removing EOLs between blockquotes)"); }
    while( $xdxf =~ s~</blockquote>\s+</def>~</blockquote></def>~sg ){ debugV("...and another one (removing EOLs between blockquotes and definition stop tags)"); }
    # This a tricky one.
    # OALD9 has a strange string [s]key.bmp[/s] that keeps repeating. No idea why!
    while( $xdxf =~ s~\[s\].*?\.bmp\[/s\]~~sg ){ debugV("....cleaning house (removing s-blocks with .bmp at the end.)"); }
    debugV("...done!");
    return( split(/^/, $xdxf) );}
sub removeEmptyTagPairs{
    waitForIt("Removing empty tag pairs");
    my $html = shift;
    debug("Length html is ".length($html) );
    # my %matches;
    # while( $html =~ s~<(\S+)[^>]*>\s*</\g1>~~sg ){
    #     if( $isTestingOn ){
    #         info_t($1);
    #         if( exists $matches{ $1 } ){ $matches{ $1 } += 1 ; }
    #         else{
    #             $matches{ $1 } = 1;
    #             info_t("Removed empty <$1>-block.");
    #         }
    #     }
    # }
    foreach( @CleanHTMLTags ){
        s~^<~~;
        s~>$~~;
        if( $html =~ s~<\Q$_\E[^>]*>\s*</\Q$_\E>~~sg ){
            info_t("Removed <$_>..</$_>.");
        }
    }
    # info_t( Dumper( \%matches ) );
    doneWaiting();
    return( $html );
}
sub removeInvalidChars{
    my $xdxf = $_[0]; # Only a string or first entry of array is checked and returned.
    waitForIt("Removing invalid characters.");

    if( $isConvertMobiAltCodes ){ $xdxf = convertMobiAltCodes( $xdxf ); }

    my $check = 0 ;
    # U+0000  0   000     Null character  NUL
    # U+0001  1   001     Start of Heading    SOH / Ctrl-A
    # U+0002  2   002     Start of Text   STX / Ctrl-B
    # U+0003  3   003     End-of-text character   ETX / Ctrl-C1
    # U+0004  4   004     End-of-transmission character   EOT / Ctrl-D2
    # U+0005  5   005     Enquiry character   ENQ / Ctrl-E
    # U+0006  6   006     Acknowledge character   ACK / Ctrl-F
    # U+0007  7   007     Bell character  BEL / Ctrl-G3
    # U+0008  8   010     Backspace   BS / Ctrl-H
    # U+0009  9   011     Horizontal tab  HT / Ctrl-I
    # U+000A  10  012     Line feed   LF / Ctrl-J4
    # U+000B  11  013     Vertical tab    VT / Ctrl-K
    # U+000C  12  014     Form feed   FF / Ctrl-L
    # U+000D  13  015     Carriage return     CR / Ctrl-M5
    # U+000E  14  016     Shift Out   SO / Ctrl-N
    # U+000F  15  017     Shift In    SI / Ctrl-O6
    # U+0010  16  020     Data Link Escape    DLE / Ctrl-P
    # U+0011  17  021     Device Control 1    DC1 / Ctrl-Q7
    # U+0012  18  022     Device Control 2    DC2 / Ctrl-R
    # U+0013  19  023     Device Control 3    DC3 / Ctrl-S8
    # U+0014  20  024     Device Control 4    DC4 / Ctrl-T
    # U+0015  21  025     Negative-acknowledge character  NAK / Ctrl-U9
    # U+0016  22  026     Synchronous Idle    SYN / Ctrl-V
    # U+0017  23  027     End of Transmission Block   ETB / Ctrl-W
    # U+0018  24  030     Cancel character    CAN / Ctrl-X10
    # U+0019  25  031     End of Medium   EM / Ctrl-Y
    # U+001A  26  032     Substitute character    SUB / Ctrl-Z11
    # U+001B  27  033     Escape character    ESC
    # U+001C  28  034     File Separator  FS
    # U+001D  29  035     Group Separator     GS
    # U+001E  30  036     Record Separator    RS
    # U+001F  31  037     Unit Separator  US 
    if( $xdxf =~ s~(\x7f|\x05|\x02|\x01|\x00)~~sg ){ $check++; info( "Removed characters with codes U+007F or between U+0000 and U+001F.");}
    if( $xdxf =~ s~(\x{0080})~Ç~sg ){ $check++; infoV(" Replaced U+0080 with 'Ç'"); }
    if( $xdxf =~ s~(\x{0091})~æ~sg ){ $check++; infoV(" Replaced U+0091 with 'æ'"); }
    if( $xdxf =~ s~(\x{0092})~Æ~sg ){ $check++; infoV(" Replaced U+0092 with 'Æ'"); }
    if( $xdxf =~ s~(\x{0093})~ô~sg ){ $check++; infoV(" Replaced U+0093 with 'ô'"); }
    if( $xdxf =~ s~(\x{0094})~ö~sg ){ $check++; infoV(" Replaced U+0094 with 'ö'"); }
    unless( $check ){ debugV('Nothing removed. If \"parser error : PCDATA invalid Char value...\" remains, look at subroutine removeInvalidChars.');}

    doneWaiting();
    return($xdxf); }
sub retrieveHash{
    info_t("Entering sub retrieveHash.") ;
    foreach( @_ ){ debug_t( $_ ); }
    debug_t( "DumperSuffix is '$DumperSuffix'");
    my $FileName = "$_[0]$DumperSuffix";
    debug_t("Filename in sub storeHash is '$FileName'");
    if( -e $FileName ){
        infoVV("Preferring '$_[0]$DumperSuffix', because it could contain manual edits");
        my @Dumpered = file2Array( "$_[0]$DumperSuffix" );
        my %Dumpered;
        my $index = -1;
        foreach( @Dumpered ){
            $index++;
            # Skip first and last line.
            if( m~\$VAR1 = \\?\{$~ or m~^\s*\};$~ ){ next; }
            debug_t( "[$index] $_" );
            chomp;
            s~^\s*~~;
            my ( $key, $value) = split( / => /, $_ );
            debug_t("key is>$key<");
            debug_t("value is >$value<");
            $key =~ s~^'~~;
            $key =~ s~'$~~;
            $value =~ s~,$~~;
            $value =~ s~^('|")~~;
            $value =~ s~('|")$~~;
            my $check = 0;
            while( $value =~ m~\\x\{([0-9A-Fa-f]+)\}~ ){
                $check++;
                my $oldvalue = $value;
                # $value = $`."\x{$1}".$';
                debug_t("\$` is '$`'");
                debug_t("\$' is '$''");
                debug_t("\$1 is '$1'");
                $value = $`.chr(hex($1)).$';
                debug_t("'$oldvalue' is now '$value'");
            }
            if( $check ){ debug_t("updated value is '$value'") ;}
            $value =~ s~^\\(.)~$1~g; # Remove preceding slashes.
            debug_t("key is>$key<");
            debug_t("value is >$value<");
            unless( $key and $value ){
                warn "Line '$_' in returned array from '$_[0]$DumperSuffix' is not a simple hash structure";
                return( retrieve (@_) );
            }
            else{ $Dumpered{ $key } = $value; }
        }
        if( scalar keys %Dumpered ){ return \%Dumpered; }
        else{ warn "$_[0]$DumperSuffix is not an dumpered HASH"; }
    }
    return( retrieve( @_) );}
sub startFromStop{ return ("<" . substr( $_[0], 2, (length( $_[0] ) - 3) ) . "( [^>]*>|>)"); }
sub startTag{
    $_[0] =~ s~\s+~~s;
    my $StartTag = startTagReturnUndef( $_[0]);
    unless( defined $StartTag ){ warn "Regex for key-start '$StartTag' doesn't match."; Die(); }
    return ( $StartTag );}
sub startTagReturnUndef{
    $_[0] =~ s~\s+~~s;
    unless( $_[0] =~ m~^(?<StartTag><[^>]+>)~s ){ return undef; }
    return ( $+{"StartTag"} );}
sub stopFromStart{
    unless( $_[0] =~ m~<(?<tag>\w+)( |>)~ ){ warn "Regex in stopFromStart doesn't match. Value given is '$_[0]'"; Die(); }
    return( "</" . $+{"tag"}.">" );}
sub storeHash{
    info("Entering sub storeHash.") if $isTestingOn ;
    foreach( @_ ){ debug( $_ ) if $isTestingOn ; }
    if( $_[0] -~ m~^HASH\(0x~ ){
        my $Dump = Dumper( $_[0]);
        debug( "DumperSuffix is '$DumperSuffix'") if $isTestingOn;
        my $FileName = "$_[1]$DumperSuffix";
        debug("Filename in sub storeHash is '$FileName'");
        debugV( $Dump );
        array2File( $FileName, $Dump );
        return 1;
    }
    else{ return( store( @_) ); }}
sub string2File{
    my $FileName = shift;
    my @Array = split(/^/, shift);
    array2File( $FileName, @Array);}
my @XMLTidied;
sub tidyXMLArray{
    my $UseXMLTidyHere = 0;
    my $UseXMLLibXMLPrettyPrint = 0;
    my $UseXMLBlockArray = 0;
    if( $UseXMLTidyHere ){
        use XML::Tidy;
        use warnings;
        array2File("tobetidied.xml", @_) ;

        # create new   XML::Tidy object by loading:  MainFile.xml
        my $tidy_obj = XML::Tidy->new('filename' => 'tobetidied.xml');

        # tidy  up  the  indenting
       $tidy_obj->tidy();

        # write out changes back to MainFile.xml
        $tidy_obj->write();
        my @ReturnedXML = file2Array( "tobetidied.xml" );
        my @TidiedXML;
        foreach( @ReturnedXML){
            if( $_ eq "\n" or $_ eq '<?xml version="1.0" encoding="utf-8"?>'."\n"){ next;}
            push @TidiedXML, $_;
        }
        return( @TidiedXML );    }
    elsif($UseXMLLibXMLPrettyPrint){
        use XML::LibXML;
        array2File("tobetidied.xml", @_);
        my $document = XML::LibXML->new->parse_file('tobetidied.xml');
        my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");
        $pp->pretty_print($document); # modified in-place
        return( split(/^/,$document->toString ) );
    }
    elsif( $UseXMLBlockArray ){
        my $xml = join('', @_);
        $xml =~ s~(?<!\n)(</?blockquote[^>]*>)~$1\n$2~sg;
        $xml =~ s~(</?blockquote[^>]*>)(?>!\n)~$1\n$2~sg;
        $xml =~ s~\n\n~\n~sg;
        if(scalar @_ > 1){ return (split( /^/, $xml) ); }
        else{ return $xml;}
    }
    else{
        my $xml = join('', @_);
        $xml =~ s~(?!\n)(</?blockquote[^>]*>)~$1\n$2~sg;
        $xml =~ s~(</?blockquote[^>]*>)(?!\n)~$1\n$2~sg;
        $xml =~ s~\n\n~\n~sg;
        push @XMLTidied, $xml;
        if(scalar @_ > 1){ return (split( /^/, $xml) ); }
        else{ return $xml;}
    }}
sub unEscapeHTMLArray{
    my $String = unEscapeHTMLString( join('', @_) );
    return( split(/^/, $String) ); }
sub unEscapeHTMLString{
    my $String = shift;
    $String =~ s~\&lt;~<~sg;
    $String =~ s~\&gt;~>~sg;
    $String =~ s~\&apos;~'~sg;
    $String =~ s~\&amp;~&~sg;
    $String =~ s~\&quot;~"~sg;
    return $String;}
sub waitForIt{ printCyan(join('', @_)," This will take some time. ", getLoggingTime(),"\n");}

# Generate entity hash defined in DOCTYPE
%EntityConversion = generateEntityHashFromDocType($DocType);

# Fill array from file.
my @xdxf;
@xdxf = loadXDXF();
array2File("testLoaded_line".__LINE__.".xdxf", @xdxf) if $isTestingOn;
my $SizeOne = scalar @xdxf;
debugV("\$SizeOne\t=\t$SizeOne");
# Remove bloat from xdxf.
if( $FileName !~ m~_unbloated\.xdxf$~ ){
    @xdxf = removeBloat(@xdxf);
    if( $FileName =~ m~xdxf$~ ){
        my $Unbloated = $FileName;
        $Unbloated =~ s~\.xdxf$~_unbloated.xdxf~;
        array2File($Unbloated, @xdxf);
    }
}
my $SizeTwo = scalar @xdxf;
if( $SizeTwo > $SizeOne){ debug("Unbloated \@xdxf ($SizeTwo) has more indices than before ($SizeOne)."); }
else{ debugV("\$SizeTwo\t=\t$SizeTwo");}
array2File("testUnbloated_line".__LINE__.".xdxf", @xdxf) if $isTestingOn;
# filterXDXFforEntitites
@xdxf = filterXDXFforEntitites(@xdxf);
my $SizeThree = scalar @xdxf;
if( $SizeThree > $SizeTwo){ debug("\$SizeThree ($SizeThree) is larger than \$SizeTwo ($SizeTwo"); }
else{ debugV("\$SizeThree\t=\t$SizeThree");}
array2File("testFiltered_line".__LINE__.".xdxf", @xdxf) if $isTestingOn;

my @xdxf_reconstructed = reconstructXDXF( @xdxf );
my $SizeFour = scalar @xdxf;
if( $SizeFour > $SizeThree){ debug("\$SizeFour ($SizeFour) is larger than \$SizeThree ($SizeThree"); }
else{ debugV("\$SizeFour\t=\t$SizeFour");}

array2File("test_Constructed_line".__LINE__.".xdxf", @xdxf_reconstructed) if $isTestingOn;

# If SameTypeSequence is not "h", remove &#xDDDD; sequences and replace them with characters.
if ( $SameTypeSequence ne "h" or $ForceConvertNumberedSequencesToChar ){
    @xdxf_reconstructed = convertNonBreakableSpacetoNumberedSequence( @xdxf_reconstructed );
    array2File("test_convertednbsp_line".__LINE__.".xdxf", @xdxf_reconstructed) if $isTestingOn;
    @xdxf_reconstructed = convertNumberedSequencesToChar( @xdxf_reconstructed );
    array2File("test_converted2char_line".__LINE__.".xdxf", @xdxf_reconstructed) if $isTestingOn;
}
if( $ForceConvertBlockquote2Div or $isCreatePocketbookDictionary ){
    @xdxf_reconstructed = convertBlockquote2Div( @xdxf_reconstructed );
    array2File("test_converted2div_line".__LINE__.".xdxf", @xdxf_reconstructed) if $isTestingOn;
}
if ( $unEscapeHTML ){ @xdxf_reconstructed = unEscapeHTMLArray( @xdxf_reconstructed ); }
array2File("test_unEscapedHTML_line".__LINE__.".xdxf", @xdxf_reconstructed) if $isTestingOn;

if( $UseXMLTidy ){
    @xdxf_reconstructed = tidyXMLArray( @xdxf_reconstructed);
}
# Save reconstructed XDXF-file
my $dict_xdxf=$FileName;
if( $dict_xdxf !~ s~\.xdxf$~_reconstructed\.xdxf~ ){ debug("Filename substitution did not work for : \"$dict_xdxf\""); die if $isRealDead; }
array2File($dict_xdxf, @xdxf_reconstructed);

# Convert colors to hexvalues
if( $isConvertColorNamestoHexCodePoints ){ @xdxf_reconstructed = convertColorName2HexValue(@xdxf_reconstructed); }
# Create Stardict dictionary
if( $isCreateStardictDictionary ){
    if ( $isMakeKoreaderReady ){ @xdxf_reconstructed = makeKoreaderReady(@xdxf_reconstructed); }
    # Save reconstructed XML-file
    my @StardictXMLreconstructed = convertXDXFtoStardictXML(@xdxf_reconstructed);
    my $dict_xml = $FileName;
    if( $dict_xml !~ s~\.xdxf$~_reconstructed\.xml~ ){ debug("Filename substitution did not work for : \"$dict_xml\""); die if $isRealDead; }
    # Remove spaces in filename
    # my @dict_xml = split('/',$dict_xml);
    $dict_xml =~ s~(?<!\\) ~\ ~g;
    # $dict_xml = join('/', @dict_xml);

    array2File($dict_xml, @StardictXMLreconstructed);

    # Convert reconstructed XML-file to binary
    if ( $OperatingSystem eq "linux"){
        my $dict_bin = $dict_xml;
        $dict_bin =~ s~\.xml~\.ifo~;
        my $command = "stardict-text2bin \"$BaseDir/$dict_xml\" \"$BaseDir/$dict_bin\" ";
        printYellow("Running system command:\n$command\n");
        system($command);
        # Workaround for dictzip
        if( $dict_bin =~ m~ |\(|\)~ ){
            debugV("Spaces or braces found, so dictzip will have failed. Running it again while masking the spaces.");
            if( $dict_bin !~ m~(?<filename>[^/]+)$~){ debug("Regex not working for dictzip workaround."); die if $isRealDead; }
            my $SpacedFileName = $+{filename};
            
            my $Path = $dict_bin;
            if( $Path =~ s~\Q$SpacedFileName\E~~ ){ debug("Changing to path $Path"); }
            chdir $Path;        
            
            $SpacedFileName =~ s~ifo$~dict~;
            my $MaskedFileName = $SpacedFileName;
            $MaskedFileName =~ s~ ~__~g;
            $MaskedFileName =~ s~\(~___~g;
            $MaskedFileName =~ s~\)~____~g;
            
            rename "$SpacedFileName", "$MaskedFileName";
            my $command = "dictzip $MaskedFileName";
            printYellow("Running system command:\n$command\n");
            system($command);
            rename "$MaskedFileName.dz", "$SpacedFileName.dz";
        }
        else{ debug("No spaces in filename."); debug("\$dict_bin is \'$dict_bin\'"); }
    }
    else{
        debug("Not linux, so you the script created an xml Stardict dictionary.");
        debug("You'll have to convert it to binary manually using Stardict editor.")
    }
    # Remove oft-file from old dictionary
    unlink join('', $FileName=~m~^(.+?)\.[^.]+$~)."_reconstructed.idx.oft" if $isTestingOn;
}

# Create Pocketbook dictionary
if( $isCreatePocketbookDictionary ){
    my $ConvertCommand;
    if( $language_dir ne "" ){ $lang_from = $language_dir ;}
    if( $OperatingSystem eq "linux"){ $ConvertCommand = "WINEDEBUG=-all wine converter.exe \"$BaseDir/$dict_xdxf\" $lang_from"; }
    else{ $ConvertCommand = "converter.exe \"$dict_xdxf\" $lang_from"; }
    printYellow("Running system command:\"$ConvertCommand\"\n");
    system($ConvertCommand);
}
my $Renamed = join('', $FileName=~m~^(.+?)\.[^.]+$~);
rename $Renamed.".xdxf", $Renamed.".backup.xdxf" if $isTestingOn;

if( $isCreateMDict ){
    my $mdict = join('', @xdxf_reconstructed);
    my $dictdata ;
    # Strip dictionary data
    if( $mdict =~ s~(?<start>(?:(?!<ar>).)+)<ar>~<ar>~s ){$dictdata = $+{start};}
    else{ debug("Regex mdict to strip dictionary data failed. Quitting."); Die();}
    debugV("1st Length \$mdict is ", length($mdict));
    #Strip tags and insert EOLs.
    $mdict =~ s~<ar>\n<head><k>~~gs;
    debugV("2nd Length \$mdict is ", length($mdict));

    $mdict =~ s~</k></head><def>~\n~gs;
    debugV("3rd Length \$mdict is ", length($mdict));

    # Replace endtags
    $mdict =~ s~</def>\n</ar>~\n</>~gs;
    $mdict =~ s~</xdxf>\n~~;
    debug("Length \$mdict is ", length($mdict));

    # Insert keyword at start definition.
    $mdict =~ s~(?<pos_before>(?<key>[^\n]+)\n)~$+{pos_before}<bold>$+{key}</bold> ~s;
    $mdict =~ s~(?<pos_before></>\n(?<key>[^\n]+)\n)~$+{pos_before}<bold>$+{key}</bold> ~sg;
    debug("Length \$mdict is ", length($mdict));
    string2File($Renamed.".mdict.txt", $mdict);
}
chdir $BaseDir;
array2File("XmlTidied_line".__LINE__.".xml", @XMLTidied ) if $UseXMLTidy;
# Save hash for later use.
storeHash(\%ReplacementImageStrings, $ReplacementImageStringsHashFileName) if scalar keys %ReplacementImageStrings;

if( scalar keys %ValidatedOCRedImages ){
    unless( storeHash(\%ValidatedOCRedImages, $ValidatedOCRedImagesHashFileName) ){
        warn "Cannot store hash ValidatedOCRedImages.";
        Die();
    } # To check whether filename is storable.
}