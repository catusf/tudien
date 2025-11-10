setup:
	pip install uv
	uv sync

.PHONY: sample
sample:
# 	mv dict/*.* dict/
	ls dict
	mkdir -p output
	ls -l | wc -l

	uv run python ./bin/convert_all.py --input_folder=dict --output_folder=output --extension=tab --filter=Tu_dien_Han_ngu
	uv run python ./bin/dict_summary.py --dict_dir=dict --output_dir=output --read_only=no
	echo "Released sample dictionaries"

all:
# 	mv dict/*.* dict/
	ls dict
	mkdir -p output
	ls -l | wc -l

	uv run python ./bin/convert_all.py --input_folder=dict --output_folder=output --extension=tab
	uv run python ./bin/dict_summary.py --dict_dir=dict --output_dir=output --read_only=no
	echo "Released all dictionaries"

test:
	echo "Run test the venv"
	uv run python ./bin/test.py

dict_stats_new:
	uv run python ./bin/dict_summary.py --dict_dir=dict --output_dir=output --read_only=no

dict_stats_old:
	uv run python ./bin/dict_summary.py --dict_dir=dict --output_dir=output --read_only=yes

dict_ext_stats_new:
	uv run python ./bin/dict_summary.py --dict_dir=ext-dict --output_dir=ext-output --read_only=no

dict_ext_stats_old:
	uv run python ./bin/dict_summary.py --dict_dir=ext-dict --output_dir=ext-output --read_only=yes

clean:
# 	git reset --hard
	git clean -fdx

ruff:
	uv run ruff check ./bin/convert_all.py --fix
	uv run ruff check ./bin/dict_summary.py --fix
