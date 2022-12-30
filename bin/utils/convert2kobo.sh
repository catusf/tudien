#!/bin/bash

pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Ngữ vựng Danh từ Thiền học" ./dict/Ngu-vung-Danh-tu-Thien-hoc.tab ./output/kobo/Ngu-vung-Danh-tu-Thien-hoc.kobo.zip &&
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=zh --name="Phật Quang Đại từ điển Hán ngữ" ./dict/Phat-Quang-Dai-tu-dien-Han-ngu.tab ./output/kobo/Phat-Quang-Dai-tu-dien-Han-ngu.kobo.zip &&
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Rộng mở tâm hồn" ./dict/Rong-mo-tam-hon.tab ./output/kobo/Rong-mo-tam-hon.kobo.zip &&
pyglossary --read-format=Tabfile --source-lang=en --target-lang=vi --name="Từ điển Anh Việt β" ./dict/TudienAnhVietBeta.tab ./output/kobo/TudienAnhVietBeta.kobo.zip &&
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Phật Quang" ./dict/Tu-dien-Phat-Quang.tab ./output/kobo/Tu-dien-Phat-Quang.kobo.zip &&
pyglossary --read-format=Tabfile --source-lang=en --target-lang=vi --name="Từ điển Phật học Anh-Hán-Việt" ./dict/Tu-dien-Phat-hoc-Anh-Han-Viet.tab ./output/kobo/Tu-dien-Phat-hoc-Anh-Han-Viet.kobo.zip &&
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Phật học Tinh tuyển" ./dict/Tu-dien-Phat-hoc-Tinh-tuyen.tab ./output/kobo/Tu-dien-Phat-hoc-Tinh-tuyen.kobo.zip &&
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=en --name="Từ điển Phật học Việt Anh - Minh Thông" ./dict/Tu-dien-Phat-hoc-Viet-Anh-Minh-Thong.tab ./output/kobo/Tu-dien-Phat-hoc-Viet-Anh-Minh-Thong.kobo.zip &&
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=en --name="Từ điển Phật học Việt Anh - Thiện Phúc" ./dict/Tu-dien-Phat-hoc-Viet-Anh-Thien-Phuc.tab ./output/kobo/Tu-dien-Phat-hoc-Viet-Anh-Thien-Phuc.kobo.zip &&
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=en --name="Từ điển Phật học Việt Anh - Đồng Loại" ./dict/Tu-dien-Phat-hoc-Viet-Anh-Dong-Loai.tab ./output/kobo/Tu-dien-Phat-hoc-Viet-Anh-Dong-Loai.kobo.zip &&
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Thiền Chửu" ./dict/TudienThienChuu.tab ./output/kobo/TudienThienChuu.kobo.zip &&
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Tổng hợp Phật học" ./dict/Tu-dien-Tong-hop-Phat-hoc.tab ./output/kobo/Tu-dien-Tong-hop-Phat-hoc.kobo.zip &&
pyglossary --read-format=Tabfile --source-lang=vi --target-lang=vi --name="Từ điển Đạo Uyển" ./dict/Tu-dien-Dao-Uyen.tab ./output/kobo/Tu-dien-Dao-Uyen.kobo.zip

rm -f ./output/all-kobo.zip &&
zip -9 -j ./output/all-kobo.zip ./output/kobo/*.*
