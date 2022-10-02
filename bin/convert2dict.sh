#!/bin/bash
echo $cwd
for input in $(ls /workspaces/tudien/dict/*.tab)
do
    echo $input

    base=$(basename -s .tab "$input")
    outdir="./output/stardict/base/"
    output="$outdir$base.ifo"

    echo $output
   pyglossary $input $output --read-format=Tabfile
done