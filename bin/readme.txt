# Create new environment in Python 3
python -m venv c:\path\to\myenv

# Activate
c:\path\to\myenv\Scripts\activate.bat

# Create list of packages
pip freeze > requirements.txt

# Install list of packages
pip install -r requirements.txt

# Create executable
pyinstaller -F python_main.py 

Need to download nltk data

