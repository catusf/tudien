import codecs
import sys

if __name__ == "__main__":
    if len(sys.argv) < 1:
        print("usage: check-valid-utf8 filemame")
        exit(1)

    f = open(sys.argv[1], encoding="utf-8", errors="strict")
    for i, line in enumerate(f):
        print(f"{i}: {line}")

    print("Valid utf-8")
