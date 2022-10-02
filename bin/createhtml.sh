#!/bin/bash
# Example: ./bin/createhtml.sh NoInflections.txt TudienAnhVietBeta
# Run in root directory

echo "Current directory: " + $pwd
echo $1
echo $2

BASE="${2%.*}"

echo $BASE
echo "./dict/$BASE.opf.patch"

cd "/workspaces/tudien/"

# Generates html and opf files
python ./bin/tab2opf.py -s vi -t vi ./dict/$2 -i ./dict/$1

# Move files to final directory
mkdir ./dict/$BASE
mv -f *.html ./dict/$BASE/
mv -f *.opf ./dict/$BASE/

# Apply patch to fix resultant .opf file
git apply "./dict/$BASE.opf.patch"

zip -r ./output/kindle/$BASE.epub ./dict/$BASE
