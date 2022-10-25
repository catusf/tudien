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


import codecs
try:
    f = codecs.open(r'./ext-stardict-vi/ko-vi/star_hanviet.ifo', encoding='utf-8', errors='strict')
    for line in f:
        pass
    print("Valid utf-8")
except UnicodeDecodeError:
    print("*** Invalid utf-8")        