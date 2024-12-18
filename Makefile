setup:
	pip install uv
	uv sync

sample:
	uv run python ./bin/convert_all.py --input_folder=dict --output_folder=output --extension=tab --filter=C
	echo "Release sample"

all:
	cp -r dict/* ext-dict/
	uv run python ./bin/convert_all.py --input_folder=ext-dict --output_folder=ext-output --extension=tab
	echo "Release all"

test:
	echo "Run test the venv"
	uv run python ./bin/test.py

dict_new_stats:
	uv run python ./bin/dict_summary.py --dict_dir=dict --read_only=no

dict_stats:
	uv run python ./bin/dict_summary.py --dict_dir=dict --read_only=yes

dict_ext_stats:
	uv run python ./bin/dict_summary.py --dict_dir=ext-dict --read_only=yes
