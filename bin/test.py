import pinyin_jyutping_sentence
import os
import pypinyin

from pinyin import get as getpinyin

from dragonmapper import hanzi

s="我们还可以再见面吗?"
print(s)

#rint(f"pinyin_jyutping_sentence.pinyin: {pinyin_jyutping_sentence.pinyin(s)}")
ss = " ".join([item[0] for item in pypinyin.pinyin(s, heteronym=True)])
print(f"pypinyin.pinyin: {ss}")

print(f"pinyin.get: {getpinyin(s)}")

import jieba

from pypinyin_dict.phrase_pinyin_data import cc_cedict
cc_cedict.load()

# 使用 pinyin-data 项目中 kXHC1983.txt 文件中的拼音数据优化结果
from pypinyin_dict.pinyin_data import kxhc1983
kxhc1983.load()

def get_word_pinyin(sentences):

    words = list(jieba.cut(sentences))
    
    pinyins = [pypinyin.pinyin(word, heteronym=True) for word in words]
    
    pinyintext = " ".join(["".join([item[0] for item in pinyin]) for pinyin in pinyins])
    return pinyintext

def get_word_pinyin_dragon(sentences):
   
    return hanzi.to_pinyin(' '.join(list(jieba.cut(sentences))))

print(f"get_word_pinyin: {get_word_pinyin(s)}")

import jieba

print(f"jieba")

seg_list = jieba.cut_for_search(s) # 搜索引擎模式
print(", ".join(seg_list))

print(f"get_word_pinyin_dragon: {get_word_pinyin_dragon(s)}")
