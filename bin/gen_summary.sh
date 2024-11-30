for file in dict/*.bz2; do
    echo "Decompressing $file..."
    bzip2 -dkf "$file"
    echo "done."
done

echo "Generating report..."
python bin/dict_summary.py
echo "Report generated at dict/dict_summary.md"