#!/bin/bash

pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Ngữ vựng Danh từ Thiền học" ./dict/Ngu-vung-Danh-tu-Thien-hoc.tab ./output/epub/Ngu-vung-Danh-tu-Thien-hoc.epub
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=zh --name="Phật Quang Đại từ điển Hán ngữ" ./dict/Phat-Quang-Dai-tu-dien-Han-ngu.tab ./output/epub/Phat-Quang-Dai-tu-dien-Han-ngu.epub
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Rộng mở tâm hồn" ./dict/Rong-mo-tam-hon.tab ./output/epub/Rong-mo-tam-hon.epub
pyglossary --read-format=Tabfile --source-lang=en --target-lang=vi --name="Từ điển Anh Việt β" ./dict/TudienAnhVietBeta.tab ./output/epub/TudienAnhVietBeta.epub
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Phật Quang" ./dict/Tu-dien-Phat-Quang.tab ./output/epub/Tu-dien-Phat-Quang.epub
pyglossary --read-format=Tabfile --source-lang=en --target-lang=vi --name="Từ điển Phật học Anh-Hán-Việt" ./dict/Tu-dien-Phat-hoc-Anh-Han-Viet.tab ./output/epub/Tu-dien-Phat-hoc-Anh-Han-Viet.epub
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Phật học Tinh tuyển" ./dict/Tu-dien-Phat-hoc-Tinh-tuyen.tab ./output/epub/Tu-dien-Phat-hoc-Tinh-tuyen.epub
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=en --name="Từ điển Phật học Việt Anh - Minh Thông" ./dict/Tu-dien-Phat-hoc-Viet-Anh-Minh-Thong.tab ./output/epub/Tu-dien-Phat-hoc-Viet-Anh-Minh-Thong.epub
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=en --name="Từ điển Phật học Việt Anh - Thiện Phúc" ./dict/Tu-dien-Phat-hoc-Viet-Anh-Thien-Phuc.tab ./output/epub/Tu-dien-Phat-hoc-Viet-Anh-Thien-Phuc.epub
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=en --name="Từ điển Phật học Việt Anh - Đồng Loại" ./dict/Tu-dien-Phat-hoc-Viet-Anh-Dong-Loai.tab ./output/epub/Tu-dien-Phat-hoc-Viet-Anh-Dong-Loai.epub
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Thiền Chửu" ./dict/TudienThienChuu.tab ./output/epub/TudienThienChuu.epub
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Tổng hợp Phật học" ./dict/Tu-dien-Tong-hop-Phat-hoc.tab ./output/epub/Tu-dien-Tong-hop-Phat-hoc.epub
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Đạo Uyển" ./dict/Tu-dien-Dao-Uyen.tab ./output/epub/Tu-dien-Dao-Uyen.epub

rm -f ./output/epub.zip
zip -9 -j ./output/epub.zip ./output/epub/*.*
