#!/bin/bash

ruby ./bin/tab2dsl/tab2dsl.rb --from-lang vi --to-lang vi --dict-name "Ngữ vựng Danh từ Thiền học" ./dict/Ngu-vung-Danh-tu-Thien-hoc.tab
ruby ./bin/tab2dsl/tab2dsl.rb --from-lang vi --to-lang zh --dict-name "Phật Quang Đại từ điển Hán ngữ" ./dict/Phat-Quang-Dai-tu-dien-Han-ngu.tab
ruby ./bin/tab2dsl/tab2dsl.rb --from-lang vi --to-lang vi --dict-name "Rộng mở tâm hồn" ./dict/Rong-mo-tam-hon.tab
ruby ./bin/tab2dsl/tab2dsl.rb --from-lang en --to-lang vi --dict-name "Từ điển Anh Việt β" ./dict/TudienAnhVietBeta.tab
ruby ./bin/tab2dsl/tab2dsl.rb --from-lang vi --to-lang vi --dict-name "Từ điển Phật Quang" ./dict/Tu-dien-Phat-Quang.tab
ruby ./bin/tab2dsl/tab2dsl.rb --from-lang en --to-lang vi --dict-name "Từ điển Phật học Anh-Hán-Việt" ./dict/Tu-dien-Phat-hoc-Anh-Han-Viet.tab
ruby ./bin/tab2dsl/tab2dsl.rb --from-lang vi --to-lang vi --dict-name "Từ điển Phật học Tinh tuyển" ./dict/Tu-dien-Phat-hoc-Tinh-tuyen.tab
ruby ./bin/tab2dsl/tab2dsl.rb --from-lang vi --to-lang en --dict-name "Từ điển Phật học Việt Anh - Minh Thông" ./dict/Tu-dien-Phat-hoc-Viet-Anh-Minh-Thong.tab
ruby ./bin/tab2dsl/tab2dsl.rb --from-lang vi --to-lang en --dict-name "Từ điển Phật học Việt Anh - Thiện Phúc" ./dict/Tu-dien-Phat-hoc-Viet-Anh-Thien-Phuc.tab
ruby ./bin/tab2dsl/tab2dsl.rb --from-lang vi --to-lang en --dict-name "Từ điển Phật học Việt Anh - Đồng Loại" ./dict/Tu-dien-Phat-hoc-Viet-Anh-Dong-Loai.tab
ruby ./bin/tab2dsl/tab2dsl.rb --from-lang vi --to-lang vi --dict-name "Từ điển Thiền Chửu" ./dict/TudienThienChuu.tab
ruby ./bin/tab2dsl/tab2dsl.rb --from-lang vi --to-lang vi --dict-name "Từ điển Tổng hợp Phật học" ./dict/Tu-dien-Tong-hop-Phat-hoc.tab
ruby ./bin/tab2dsl/tab2dsl.rb --from-lang vi --to-lang vi --dict-name "Từ điển Đạo Uyển" ./dict/Tu-dien-Dao-Uyen.tab

mv *.dsl.dz ./output/dsl/