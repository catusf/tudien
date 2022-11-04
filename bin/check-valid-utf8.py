
import codecs

def try_utf8(data):
    "Returns a Unicode object on success, or None on failure"
    try:
       return data.decode('utf-8')
    except UnicodeDecodeError:
       return None


# with open(r'./ext-stardict-vi/ja-vi/star_nhatviet.dict', 'rb') as f:
#     data = f.read()
#     udata = try_utf8(data)
#     if udata is None:
#         # Not UTF-8.  Do something else
#         print('Error')
#     else:
#         print('ok')
#         # Handle unicode data

#'./ext-dict/star_hanviet.tab'

f = open(r'./bin/test.txt', encoding='utf-8', errors='strict')
for i, line in enumerate(f):
    print(f'{i}: {line}')
print("Valid utf-8")

# import codecs
# try:
#     f = codecs.open(r'./ext-dict/star_hanviet.tab', encoding='utf-8', errors='strict')
#     for i, line in enumerate(f):
#         print(f'{i}: {line}')
#     print("Valid utf-8")
# except UnicodeDecodeError as err:
#     print("*** Invalid utf-8", err)        