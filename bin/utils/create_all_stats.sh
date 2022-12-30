#!/bin/bash

for filepath in $(ls ./ext-dict/*.tab)
do
  echo $filepath
  python ./bin/tab_stats.py -i $filepath
done
