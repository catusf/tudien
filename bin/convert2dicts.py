import sys
import pyglossary
from pyglossary import Glossary

# Glossary.init() should be called only once, so make sure you put it
# in the right place
Glossary.init()

glos = Glossary()
glos.convert(
	inputFilename=sys.argv[1],
	outputFilename=sys.argv[2],
	# although it can detect format for *.txt, you can still pass outputFormat
	# outputFormat="Tabfile",
	# you can pass readOptions or writeOptions as a dict
	# writeOptions={"encoding": "utf-8"},
)