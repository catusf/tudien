python tab2opf.py -s vi -t vi ../dict/TudienThienChuu.tab -i ../dict/TudienThienChuu-Inflections.txt 
python tab2opf.py -s en -t vi ../dict/TudienAnhVietBeta.tab -i ../dict/TudienAnhVietBeta-Inflections.txt

move /Y *.html ../dict
move /Y *.opf ../dict
