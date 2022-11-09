#!/bin/bash

for filepath in $(ls ./ext-dict/*.tab)
do
  echo $filepath
  python ./bin/tab_stats.py -i $filepath
done

for filepath in $(ls ./ext-dict/*.bz2)
do
  echo $filepath
  bzip2 -dk $filepath
done
