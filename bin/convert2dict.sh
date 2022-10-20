#!/bin/bash

pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Ngữ vựng Danh từ Thiền học" ./dict/Ngu-vung-Danh-tu-Thien-hoc.tab ./output/stardict/Ngu-vung-Danh-tu-Thien-hoc.ifo
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=zh --name="Phật Quang Đại từ điển Hán ngữ" ./dict/Phat-Quang-Dai-tu-dien-Han-ngu.tab ./output/stardict/Phat-Quang-Dai-tu-dien-Han-ngu.ifo
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Rộng mở tâm hồn" ./dict/Rong-mo-tam-hon.tab ./output/stardict/Rong-mo-tam-hon.ifo
pyglossary --read-format=Tabfile --source-lang=en --target-lang=vi --name="Từ điển Anh Việt β" ./dict/TudienAnhVietBeta.tab ./output/stardict/TudienAnhVietBeta.ifo
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Phật Quang" ./dict/Tu-dien-Phat-Quang.tab ./output/stardict/Tu-dien-Phat-Quang.ifo
pyglossary --read-format=Tabfile --source-lang=en --target-lang=vi --name="Từ điển Phật học Anh-Hán-Việt" ./dict/Tu-dien-Phat-hoc-Anh-Han-Viet.tab ./output/stardict/Tu-dien-Phat-hoc-Anh-Han-Viet.ifo
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Phật học Tinh tuyển" ./dict/Tu-dien-Phat-hoc-Tinh-tuyen.tab ./output/stardict/Tu-dien-Phat-hoc-Tinh-tuyen.ifo
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=en --name="Từ điển Phật học Việt Anh - Minh Thông" ./dict/Tu-dien-Phat-hoc-Viet-Anh-Minh-Thong.tab ./output/stardict/Tu-dien-Phat-hoc-Viet-Anh-Minh-Thong.ifo
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=en --name="Từ điển Phật học Việt Anh - Thiện Phúc" ./dict/Tu-dien-Phat-hoc-Viet-Anh-Thien-Phuc.tab ./output/stardict/Tu-dien-Phat-hoc-Viet-Anh-Thien-Phuc.ifo
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=en --name="Từ điển Phật học Việt Anh - Đồng Loại" ./dict/Tu-dien-Phat-hoc-Viet-Anh-Dong-Loai.tab ./output/stardict/Tu-dien-Phat-hoc-Viet-Anh-Dong-Loai.ifo
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Thiền Chửu" ./dict/TudienThienChuu.tab ./output/stardict/TudienThienChuu.ifo
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Tổng hợp Phật học" ./dict/Tu-dien-Tong-hop-Phat-hoc.tab ./output/stardict/Tu-dien-Tong-hop-Phat-hoc.ifo
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Đạo Uyển" ./dict/Tu-dien-Dao-Uyen.tab ./output/stardict/Tu-dien-Dao-Uyen.ifo

rm -f ./output/stardict.zip
zip -9 -j ./output/stardict.zip ./output/stardict/*.*
