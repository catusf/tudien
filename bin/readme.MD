# Introduction

These tools convert text files in the format word<tab>definitions into .mobi dictionaries for Amazon Kindle with a focus for Vietnamese dictionaries.

## Steps
1. Install Python 3.x
2. Create/update definition file (like dict/TudienAnhVietBeta.txt) 
3. Run createhtml.bat to create .html files (actually OPF format for ebook) using Python program tab2opf.py
4. Run createmobi.bat to create Kindle dictionary files using Amazon tools mobigen.exe. Output files are in ../dict folder above


## For programmers
### Create new environment in Python 3
python -m venv c:\path\to\myenv

### Activate
c:\path\to\myenv\Scripts\activate.bat

### Create list of packages
pip freeze > requirements.txt

### Install list of packages
pip install -r requirements.txt

### Create executable
pyinstaller -F python_main.py 

### Inorder to generate inflections (words form for plurals, verb tenses, etc.) for English, you need to run Python program create_english_inflections.py. That needs [pattern](https://pypi.org/project/Pattern/) library
