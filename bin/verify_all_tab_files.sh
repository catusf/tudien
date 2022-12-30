#!/bin/bash

for filepath in $(ls ./dict/*.tab)
do
  echo $filepath
  python ./bin/verify_tab_file.py --input $filepath
done