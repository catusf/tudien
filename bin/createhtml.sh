#!/bin/bash
# Example: ./bin/createhtml.sh Tu-dien-Tong-hop-Phat-hoc.tab NoInflections.txt
# Run in root directory

echo "Current directory: " + $pwd
echo $1
echo $2

extension="${1##*.}"
BASE="${1%.*}"

echo $BASE

cd "/workspaces/tudien/"

python ./bin/tab2opf.py -s vi -t vi ./dict/$1 -i ./dict/$2

mkdir ./dict/$BASE
mv -f *.html ./dict/$BASE/
mv -f *.opf ./dict/$BASE/
