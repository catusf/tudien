#!/bin/bash

# Generate .mobi ebooks
input_dir=$1
output_dir=$2
kindle_dir=kindle
output_kindle_dir=$output_dir/$kindle_dir

for fullpath in "*.opf"
do
  echo "Input $fullpath"
  filename="${fullpath##*/}"                      # Strip longest match of */ from start
  dir="${fullpath:0:${#fullpath} - ${#filename}}" # Substring from 0 thru pos of filename
  base="${filename%.[^.]*}"                       # Strip shortest match of . plus at least one non-dot char from end
  ext="${filename:${#base} + 1}" 
  
  echo "dir $dir"
  echo "base $base"
  echo "filename $filename"

  wine ./bin/mobigen/mobigen.exe -unicode -s0 $fullpath

  outfilename="$dir$base.mobi"
  echo "outfilename: + $outfilename"
  mv $outfilename $output_kindle_dir
done

#zip -9 -j $output_dir/all-kindle.zip $output_kindle_dir/*.mobi


