#!/bin/bash

python ./bin/tab2opf.py --title=CharDict --source=zh --target=en --inflection=./bin/inflections/inflections-none.tab --outdir=./dict//kindle --creator=Panthera\ Tigris --publisher=Panthera\ Tigris ./dict/char_dict_pleco.tab
./bin/mobigen/mobigen.exe -unicode -s0 ./dict/kindle/char_dict_pleco.opf

python ./bin/tab2opf.py --title=RadicalLookup --source=zh --target=en --inflection=./bin/inflections/inflections-none.tab --outdir=./dict//kindle --creator=Panthera\ Tigris --publisher=Panthera\ Tigris ./dict/radical_lookup_pleco.tab
./bin/mobigen/mobigen.exe -unicode -s0 ./dict/kindle/radical_lookup_pleco.opf

python ./bin/tab2opf.py --title=RadicalNames --source=zh --target=en --inflection=./bin/inflections/inflections-none.tab --outdir=./dict//kindle --creator=Panthera\ Tigris --publisher=Panthera\ Tigris ./dict/radical_name_pleco.tab
./bin/mobigen/mobigen.exe -unicode -s0 ./dict/kindle/radical_name_pleco.opf

python ./bin/tab2opf.py --title=TrungVietBeta --source=zh --target=en --inflection=./bin/inflections/inflections-none.tab --outdir=./dict//kindle --creator=Panthera\ Tigris --publisher=Panthera\ Tigris ./dict/tvb_pleco.tab
./bin/mobigen/mobigen.exe -unicode -s0 ./dict/kindle/tvb_pleco.opf



