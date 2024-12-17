sample:
    python ./bin/convert_all.py --input_folder=dict --output_folder=output --extension=tab --filter=Hero

all:
    cp dict/*.* ext-dict/
    python ./bin/convert_all.py --input_folder=ext-dict --output_folder=ext-output --extension=tab --filter=Hero
