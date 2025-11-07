setup:
	pip install uv
	uv sync

sample:
	cp dict/*.* ext-dict
	ls ext-dict
	mkdir ext-output
	ls -l | wc -l

	uv run python ./bin/convert_all.py --input_folder=ext-dict --output_folder=ext-output --extension=tab --filter=Hanzi
	uv run python ./bin/dict_summary.py --dict_dir=ext-dict --output_dir=ext-output --read_only=no
	echo "Released sample dictionaries"

all:
	cp dict/*.* ext-dict
	ls ext-dict
	mkdir ext-output
	ls -l | wc -l

	uv run python ./bin/convert_all.py --input_folder=ext-dict --output_folder=ext-output --extension=tab
	uv run python ./bin/dict_summary.py --dict_dir=ext-dict --output_dir=ext-output --read_only=no
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
	git clean -fdx