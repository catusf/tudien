sample:
	uv run python ./bin/convert_all.py --input_folder=dict --output_folder=output --extension=tab --filter=Hero
	echo "Release sample"

all:
	cp dict/* ext-dict/
	uv run python ./bin/convert_all.py --input_folder=ext-dict --output_folder=ext-output --extension=tab
	echo "Release all"
