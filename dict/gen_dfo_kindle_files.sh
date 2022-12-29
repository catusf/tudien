# Generate metadata for dictionaries
print_to_file() {
    printf "Name = $2 v$6\nDescription = $3\nSource = $4\nTarget = $5\nVersion = $6\nOwner/Editor = $7\nURL = $8\nInflections = $9" > $1
}

print_to_file "Ngu-vung-Danh-tu-Thien-hoc.dfo" "Ngữ vựng danh từ thiền học" "Ngữ vựng danh từ thiền học" "vi" "vi" "1.0" "" "https://github.com/catusphan/dictionary" ""
print_to_file "Rong-mo-tam-hon.dfo" "Rộng mở tâm hồn" "Rộng mở tâm hồn" "vi" "vi" "1.0" "" "https://github.com/catusphan/dictionary" ""
print_to_file "Phat-Quang-Dai-tu-dien-Han-ngu.dfo" "Phật quang Đại từ điển Hán ngữ" "Phật quang Đại từ điển Hán ngữ" "zh" "zh" "1.0" "" "https://github.com/catusphan/dictionary" ""
print_to_file "Tu-dien-Dao-Uyen.dfo" "Từ điển Đạo Uyển" "Từ điển Đạo Uyển" "vi" "vi" "1.0" "" "https://github.com/catusphan/dictionary"  ""
print_to_file "Tu-dien-Phat-Quang.dfo" "Từ điển Phật Quang" "Từ điển Phật Quang" "vi" "vi" "1.0" "" "https://github.com/catusphan/dictionary" ""
print_to_file "Tu-dien-Phat-hoc-Anh-Han-Viet.dfo" "Từ điển Phật học Anh-Hán-Việt" "Từ điển Phật học Anh-Hán-Việt" "en" "vi" "1.0" "" "https://github.com/catusphan/dictionary" "english_inflections.txt"
print_to_file "Tu-dien-Phat-hoc-Tinh-tuyen.dfo" "Từ điển Phật học Tinh tuyển" "Từ điển Phật học Tinh tuyển" "vi" "vi" "1.0" "" "https://github.com/catusphan/dictionary" ""
print_to_file "Tu-dien-Phat-hoc-Viet-Anh-Dong-Loai.dfo" "Từ điển Phật học Việt Anh - Đồng Loại" "Từ điển Phật học Việt Anh - Đồng Loại" "vi" "en" "1.0" "" "https://github.com/catusphan/dictionary" ""
print_to_file "Tu-dien-Phat-hoc-Viet-Anh-Minh-Thong.dfo" "Từ điển Phật học Việt Anh - Minh Thông" "Từ điển Phật học Việt Anh - Minh Thông" "vi" "en" "1.0" "" "https://github.com/catusphan/dictionary" ""
print_to_file "Tu-dien-Phat-hoc-Viet-Anh-Thien-Phuc.dfo" "Từ điển Phật học Việt Anh - Thiện Phúc" "Từ điển Phật học Việt Anh - Thiện Phúc" "vi" "en" "1.0" "" "https://github.com/catusphan/dictionary" ""
print_to_file "Tu-dien-Tong-hop-Phat-hoc.dfo" "Từ điển tổng hợp Phật học" "Từ điển tổng hợp Phật học" "vi" "vi" "1.0" "" "https://github.com/catusphan/dictionary" ""
print_to_file "TudienThienChuu.dfo" "Từ điển từ Hán Việt Thiền Chửu" "Từ điển từ Hán Việt Thiền Chửu" "vi" "vi" "1.0" "" "https://github.com/catusphan/dictionary" ""

print_to_file "TudienAnhVietAnh.dfo" "Từ điển Anh-Việt-Anh" "Từ điển Anh-Việt-Anh với các dạng từ tiếng Anh" "en" "vi" "1.0" "" "https://github.com/catusphan/dictionary" "english_inflections.txt"
print_to_file "TudienAnhVietBeta.dfo" "Từ điển Anh-Việt β" "Từ điển Anh-Việt β với các dạng từ tiếng Anh" "en" "vi" "1.3.1" "" "https://github.com/catusphan/dictionary" "english_inflections.txt"
