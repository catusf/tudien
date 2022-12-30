#!/bin/bash
outfile="wordcount.txt"
echo "Word count" > $outfile

for file in *.tab
do
  wc -l $file >> $outfile
done