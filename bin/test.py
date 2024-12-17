from iso_language_codes import language_name
import langcodes

import pinyin_jyutping_sentence
import os
import pypinyin

from pinyin import get as getpinyin

from dragonmapper import hanzi

print(language_name("vi"))
print(language_name("zh"))

print(langcodes.Language.get("vi").display_name("vi"))
print(langcodes.Language.get("zh").display_name("vi"))


s="我们还可以再见面吗?"
print(s)

#rint(f"pinyin_jyutping_sentence.pinyin: {pinyin_jyutping_sentence.pinyin(s)}")
ss = " ".join([item[0] for item in pypinyin.pinyin(s, heteronym=True)])
print(f"pypinyin.pinyin: {ss}")

print(f"pinyin.get: {getpinyin(s)}")

