#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Script for conversion of Stardict tabfile (<header>\t<definition>
# per line) into the OPF file for MobiPocket Dictionary
#
# For usage of dictionary convert it by:
# (wine) mobigen.exe DICTIONARY.opf
# or now...
# kindlegen DICTIONARY.opf
#
# MobiPocket Reader at: www.mobipocket.com for platforms:
#   PalmOs, Windows Mobile, Symbian (Series 60, Series 80, 90, UIQ), Psion, Blackberry, Franklin, iLiad (by iRex), BenQ-Siemens, Pepper Pad..
#   http://www.mobipocket.com/en/DownloadSoft/DownloadManualInstall.asp
# mobigen.exe available at:
#   http://www.mobipocket.com/soft/prcgen/mobigen.zip
#
# Copyright (C) 2007 - Klokan Petr Přidal (www.klokan.cz)
# Copyright (C) 2015 - Alexander Peyser (github.com/apeyser)
#
#
# Version history:
# 0.1 (19.7.2007) Initial version
# 0.2 (2/2015) Rework removing encoding, runs on python3
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

# VERSION
VERSION = "0.2"

import sys
import os
import argparse
from itertools import islice, count, groupby
from contextlib import contextmanager
import importlib


# Hand-made table from PloneTool.py
mapping_custom_1 =  {
138: 's', 142: 'z', 154: 's', 158: 'z', 159: 'Y' }

# UnicodeData.txt does not contain normalization of Greek letters.
mapping_greek = {
912: 'i', 913: 'A', 914: 'B', 915: 'G', 916: 'D', 917: 'E', 918: 'Z',
919: 'I', 920: 'TH', 921: 'I', 922: 'K', 923: 'L', 924: 'M', 925: 'N',
926: 'KS', 927: 'O', 928: 'P', 929: 'R', 931: 'S', 932: 'T', 933: 'Y',
934: 'F', 936: 'PS', 937: 'O', 938: 'I', 939: 'Y', 940: 'a', 941: 'e',
943: 'i', 944: 'y', 945: 'a', 946: 'b', 947: 'g', 948: 'd', 949: 'e',
950: 'z', 951: 'i', 952: 'th', 953: 'i', 954: 'k', 955: 'l', 956: 'm',
957: 'n', 958: 'ks', 959: 'o', 960: 'p', 961: 'r', 962: 's', 963: 's',
964: 't', 965: 'y', 966: 'f', 968: 'ps', 969: 'o', 970: 'i', 971: 'y',
972: 'o', 973: 'y' }

# This may be specific to German...
mapping_two_chars = {
140 : 'O', 156: 'o', 196: 'A', 246: 'o', 252: 'u', 214: 'O',
228 : 'a', 220: 'U', 223: 's', 230: 'e', 198: 'E' }

mapping_latin_chars = {
192 : 'A', 193 : 'A', 194 : 'A', 195 : 'a', 197 : 'A', 199 : 'C', 200 : 'E',
201 : 'E', 202 : 'E', 203 : 'E', 204 : 'I', 205 : 'I', 206 : 'I', 207 : 'I',
208 : 'D', 209 : 'N', 210 : 'O', 211 : 'O', 212 : 'O', 213 : 'O', 215 : 'x',
216 : 'O', 217 : 'U', 218 : 'U', 219 : 'U', 221 : 'Y', 224 : 'a', 225 : 'a',
226 : 'a', 227 : 'a', 229 : 'a', 231 : 'c', 232 : 'e', 233 : 'e', 234 : 'e',
235 : 'e', 236 : 'i', 237 : 'i', 238 : 'i', 239 : 'i', 240 : 'd', 241 : 'n',
242 : 'o', 243 : 'o', 244 : 'o', 245 : 'o', 248 : 'o', 249 : 'u', 250 : 'u',
251 : 'u', 253 : 'y', 255 : 'y' }

# Feel free to add new user-defined mapping. Don't forget to update mapping dict
# with your dict.

mapping = {}
mapping.update(mapping_custom_1)
mapping.update(mapping_greek)
mapping.update(mapping_two_chars)
mapping.update(mapping_latin_chars)

inflections = {}

# Stop with the encoding -- it's broken anyhow
# in the kindles and undefined.
def normalizeLetter(ch):
    try: ch = mapping[ch]
    except KeyError: pass
    return ch

def normalizeUnicode(text):
    """
    Reduce some characters to something else
    """
    return ''.join(normalizeLetter(c) for c in text)

# Args:
#  --verbose
#  --module: module to load and attempt to extract getdef, getkey & mapping
#  --source: source language code (en by default)
#  --target: target language code (en by default)
#  file: the tab delimited file to read

def parseargs():
    if len(sys.argv) < 1:
        print("tab2opf (Stardict->MobiPocket)")
        print("------------------------------")
        print("Version: %s" % VERSION)
        print("Copyright (C) 2007 - Klokan Petr Pridal")
        print()
        print("Usage: python tab2opf.py [-utf] DICTIONARY.tab")
        print()
        print("ERROR: You have to specify a .tab file")
        sys.exit(1)

    parser = argparse.ArgumentParser("tab2opf")
    parser.add_argument("-v", "--verbose", help="make verbose", 
                        action="store_true")
    parser.add_argument("-m", "--module", 
                        help="Import module for mapping, getkey, getdef")
    parser.add_argument("-i", "--inflection", help="Path to inflection file")
    parser.add_argument("-l", "--title", help="Title of dictionary")
    parser.add_argument("-o", "--outdir", help="Output dir", default='')
    parser.add_argument("-s", "--source", default="en", help="Source language")
    parser.add_argument("-t", "--target", default="en", help="Target language")
    parser.add_argument("-c", "--creator", default="en", help="Creator of this dictionary")
    parser.add_argument("-p", "--publisher", default="en", help="Publisher of this dictionary")
    parser.add_argument("file", help="tab file to input")   
    return parser.parse_args()

def loadmember(mod, attr, dfault):
    if hasattr(mod, attr):
        print("Loading {} from {}".format(attr, mod.__name__))
        globals()[attr] = getattr(mod, attr)
    else: globals()[attr] = dfault

def importmod():
    global MODULE
    if MODULE is None: mod = None
    else:
        mod = importlib.import_module(MODULE)
        print("Loading methods from: {}".format(mod.__file__))

    loadmember(mod, 'getkey', lambda key: key)
    loadmember(mod, 'getdef', lambda dfn: dfn)
    loadmember(mod, 'mapping', {})
#    loadmember(mod, 'getInflections', lambda key: key) # Get inflections

args = parseargs()
VERBOSE  = args.verbose
FILENAME = args.file
MODULE   = args.module
INFLECT  = args.inflection
INLANG   = args.source
OUTLANG  = args.target
TITLE  = args.title
OUTDIR  = args.outdir
CREATOR = args.creator
PUBLISHER = args.publisher

importmod()

# add a single [term, definition]
# to defs[key]
# r is a tab split line
def readkey(r, defs):
    try: term, defn =  r.split('\t',1)
    except ValueError:
        print("Bad line: '{}'".format(r))
        raise

    term = term.strip()
    defn = getdef(defn)
    # defn = defn.replace("\\\\","\\").\
        # replace(">", "\\>").\
        # replace("<", "\\<").\
        # replace("\\n","<br/>\n").\
        # strip()

    nkey = normalizeUnicode(term)
    key = getkey(nkey)
    key = key.\
        replace('"', "'").\
        replace('<', '\\<').\
        replace('>', '\\>').\
        lower().strip()

    nkey = nkey.\
        replace('"', "'").\
        replace('<', '\\<').\
        replace('>', '\\>').\
        lower().strip()

    if key == '':
        raise Exception("Missing key {}".format(term))
    if defn == '':
        raise Exception("Missing definition {}".format(term))

    if VERBOSE: print(key, ":", term)

    ndef = [term, defn, key == nkey]
    if key in defs: defs[key].append(ndef)
    else:           defs[key] = [ndef]

# Skip empty lines and lines that only have a comment
def inclline(s):
    s = s.lstrip()
    return len(s) != 0 and s[0] != '#'

# Open file containing reflections
# with format: key  \t  inflections (seperated by '|' character)
# for instance: 
# sorrow	sorrowed|sorrows|sorrowing
#
def readinflections():
    if VERBOSE: print("Reading {}".format(INFLECT))
    
    if not INFLECT:
        print('No inflection file.')
        return None
        
    with open(INFLECT,'r', encoding='utf-8', errors='replace') as fr:
        inflections = {}
        for l in fr.readlines():
            [key, text] = l.strip().split('\t')
            items = text.split('|')
            
            inflections[key] = items
            
        print('**** No of inflections: %i' % len(inflections))
        
        return inflections
        
# Iterate over FILENAME, reading lines of
# term {tab} definition
# skips empty lines and commented out lines
#
def readkeys():
    if VERBOSE: print("Reading {}".format(FILENAME))
    with open(FILENAME,'r', encoding='utf-8', errors='replace') as fr:
        defns = {}
        for r in filter(inclline, fr):
            readkey(r, defns)
        return defns

# Write to key file {name}{n}.html
# put the body inside the context manager
# The onclick here gives a kindlegen warning
# but appears to be necessary to actually
# have a lookup dictionary
@contextmanager
def writekeyfile(name, i):
    fname = "{}{}.html".format(name, i)
    if VERBOSE: print("Key file: {}".format(fname))
    with open(fname, 'w', encoding='utf-8') as to:
        to.write("""<?xml version="1.0" encoding="utf-8"?>
<html xmlns:idx="www.mobipocket.com" xmlns:mbp="www.mobipocket.com" xmlns:xlink="http://www.w3.org/1999/xlink">
  <body>
    <mbp:pagebreak/>
    <mbp:frameset>
      <mbp:slave-frame display="bottom" device="all" breadth="auto" leftmargin="0" rightmargin="0" bottommargin="0" topmargin="0">
        <div align="center" bgcolor="yellow"/>
        <a onclick="index_search()">Dictionary Search</a>
        </div>
      </mbp:slave-frame>
      <mbp:pagebreak/>
""")
        try: yield to
        finally:
            to.write("""
    </mbp:frameset>
  </body>
</html>
        """)

# Order definitions by keys, then by whether the key
# matches the original term, then by length of term
# then alphabetically
def keyf(defn):
    term = defn[0]
    if defn[2]: l = 0
    else: l = len(term)
    return l, term


# Write into to the key, definition pairs
# key -> [[term, defn, key==term]]
def writekey(to, key, defn):
    terms = iter(sorted(defn, key=keyf))
        
    for term, g in groupby(terms, key=lambda d: d[0]):
        
        # Build string for inflections, if any
        infs = inflections.get(term, None)
        
        if not infs:
            infstring = ''
        else:
            itemstext = ''
            for item in infs:
                itemstext += r'              <idx:iform value="{item}" />'.format(item = item) + '\n'

            infstring = '''
            <idx:infl>
{itemstext}            </idx:infl>'''.format(itemstext = itemstext)

        to.write(
"""
      <idx:entry name="word" scriptable="yes">
        <h2>
          <idx:orth value="{key}">{term}{infstring}
          </idx:orth>
        </h2>
""".format(term=term, key=key, infstring=infstring))

        to.write('; '.join(ndefn for _, ndefn, _ in g))
        to.write(
"""
      </idx:entry>
"""
)

    if VERBOSE: print(key)

# Write all the keys, where defns is a map of
# key --> [[term, defn, key==term]...]
# and name is the basename
# The files are split so that there are no more than
# 10,000 keys written to each file (why?? I dunno)
#
# Returns the number of files.
def writekeys(defns, name):
    keyit = iter(sorted(defns))
    for j in count():
        with writekeyfile(name, j) as to:
            keys = list(islice(keyit, 10000))
            if len(keys) == 0: break
            for key in keys:
                writekey(to, key, defns[key])
    return j+1

# After writing keys, the opf that references all the key files
# is constructed.
# openopf wraps the contents of writeopf
#
@contextmanager
def openopf(ndicts, name):
    fname = "%s.opf" % name
    if VERBOSE: print("Opf: {}".format(fname))
    with open(fname, 'w', encoding='utf-8') as to:
        to.write("""<?xml version="1.0"?><!DOCTYPE package SYSTEM "oeb1.ent">

<!-- the command line instruction 'prcgen dictionary.opf' will produce the dictionary.prc file in the same folder-->
<!-- the command line instruction 'mobigen dictionary.opf' will produce the dictionary.mobi file in the same folder-->

<package unique-identifier="uid" xmlns:dc="Dublin Core">

<metadata>
	<dc-metadata>
		<dc:Identifier id="uid">{title}</dc:Identifier>
		<!-- Title of the document -->
		<dc:Title><h2>{title}</h2></dc:Title>
		<dc:Language>{target}</dc:Language>
		<dc:Creator>{creator}</dc:Creator>
		<dc:Publisher>{publisher}</dc:Publisher>
	</dc-metadata>
	<x-metadata>
	    <output encoding="utf-8" flatten-dynamic-dir="yes"/>
		<DictionaryInLanguage>{source}</DictionaryInLanguage>
		<DictionaryOutLanguage>{target}</DictionaryOutLanguage>
	</x-metadata>
</metadata>

<!-- list of all the files needed to produce the .prc file -->
<manifest>
""".format(title=TITLE, source=INLANG, target=OUTLANG, creator=CREATOR, publisher=PUBLISHER))

        yield to

        to.write("""
<tours/>
<guide> <reference type="search" title="Dictionary Search" onclick= "index_search()"/> </guide>
</package>
"""
)

# Write the opf that describes all the key files
def writeopf(ndicts, name):
    # As name is full path, need to extract just the tail of the path

    dir, filename = os.path.split(name)

    with openopf(ndicts, name) as to:
        for i in range(ndicts):
            to.write(
"""     <item id="dictionary{ndict}" href="{filename}{ndict}.html" media-type="text/x-oeb1-document"/>
""".format(ndict=i, filename=filename, name=name))

        to.write("""
</manifest>
<!-- list of the html files in the correct order  -->
<spine>
"""
)
        for i in range(ndicts):
            to.write("""
	<itemref idref="dictionary{ndict}"/>
""".format(ndict=i))

        to.write("""
</spine>
""")

######################################################
# main
######################################################

print("Reading keys")
defns = readkeys()
inflections = readinflections()
name = os.path.splitext(os.path.basename(FILENAME))[0]
print(f'Prev: {name}')

if OUTDIR:
    path, filename = os.path.split(name)
    name = os.path.join(OUTDIR, filename)
print(f'New : {name}')

print("Writing keys")
ndicts = writekeys(defns, name)
keys = defns.keys()


print("Writing opf")
writeopf(ndicts, name)
