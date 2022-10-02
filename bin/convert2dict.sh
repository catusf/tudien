#!/bin/bash
echo $cwd
for input in $(ls /workspaces/tudien/dict/*.tab)
do
    output = BASE="${input%.*}.ilo"
    pyglossary input output --read-format=Tabfile
done