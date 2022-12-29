# Generate metadata for dictionaries
print_to_file() {
    printf "Name = $2 v$6\nDescription = $3\nSource = $4\nTarget = $5\nVersion = $6\nOwner/Editor = $7\nURL = $8\nInflections = $9" > $1
}

# From OVDP Project
print_to_file "star_phapviet.dfo" "Từ điển Pháp - Việt" "Pháp - Việt" "fr" "vi" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_viethan.dfo" "Từ điển Việt - Hàn" "Việt - Hàn" "vi" "ko" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_vietanh.dfo" "Từ điển Việt - Anh" "Việt - Anh" "vi" "en" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_ngaviet.dfo" "Từ điển Nga - Việt" "Nga - Việt" "ru" "vi" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_vietphap.dfo" "Từ điển Việt - Pháp" "Việt - Pháp" "vi" "fr" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_tbnviet.dfo" "Từ điển Tây Ban Nha - Việt" "Tây Ban Nha - Việt" "es" "vi" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_viettbn.dfo" "Từ điển Việt - Tây Ban Nha" "Việt - Tây Ban Nha" "vi" "es" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_nauyviet.dfo" "Từ điển Na Uy - Việt" "Na Uy - Việt" "no" "vi" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_vietduc.dfo" "Từ điển Việt - Đức" "Việt - Đức" "vi" "de" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_trungviet.dfo" "Từ điển Trung - Việt" "Trung - Việt" "zh" "vi" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_bdnviet.dfo" "Từ điển Bồ Đào Nha - Việt" "Bồ Đào Nha - Việt" "pt" "vi" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_nhatviet.dfo" "Từ điển Nhật - Việt" "Nhật - Việt" "ja" "vi" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_ducviet.dfo" "Từ điển Đức - Việt" "Đức - Việt" "de" "vi" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_vietnga.dfo" "Từ điển Việt - Nga" "Việt - Nga" "vi" "ru" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_secviet.dfo" "Từ điển Séc - Việt" "Séc - Việt" "cs" "vi" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_vietnhat.dfo" "Từ điển Việt - Nhật" "Việt - Nhật" "vi" "ja" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_hanviet.dfo" "Từ điển Hàn - Việt" "Hàn - Việt" "ko" "vi" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_yviet.dfo" "Từ điển Ý - Việt" "Ý - Việt" "it" "vi" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""
print_to_file "star_anhviet.dfo" "Từ điển Anh - Việt" "Anh - Việt" "en" "vi" "1.0" "OVDP" "https://github.com/catusphan/dictionary" ""

# From SuperDict (SPDict)
print_to_file "SPDict-Anh-Viet-Anh.dfo" "Từ diển Anh-Việt-Anh SPDict" "Từ diển Anh-Việt-Anh SPDict với các dạng từ tiếng Anh" "en" "vi" "1.0" "SPDict" "https://github.com/catusphan/dictionary" "english_inflections.txt"
print_to_file "SPDict-Anh-Viet.dfo" "Từ diển Anh-Việt SPDict" "Từ diển Anh-Việt SPDict với các dạng từ tiếng Anh" "en" "vi" "1.0" "SPDict" "https://github.com/catusphan/dictionary" "english_inflections.txt"
print_to_file "SPDict-Viet-Anh.dfo" "Từ diển Việt-Anh SPDict" "Từ diển Việt-Anh SPDict" "vi" "en" "1.0" "SPDict" "https://github.com/catusphan/dictionary" ""
print_to_file "SPDict-Irregular-Verbs.dfo" "English Irregular Verbs SPDict" "English Irregular Verbs SPDict" "en" "en" "1.0" "SPDict" "https://github.com/catusphan/dictionary" "english_inflections.txt"

# # From Prodict
print_to_file "Prodict_EV_Tech.dfo" "Từ điển Anh-Việt Kỹ thuật Prodict" "Từ điển Anh-Việt Kỹ thuật Prodict" "en" "vi" "1.0" "Prodict" "https://github.com/catusphan/dictionary" "english_inflections.txt"
print_to_file "Prodict_EV_business.dfo" "Từ điển Anh-Việt Kinh doanh Prodict" "Từ điển Anh-Việt Kinh doanh Prodict" "en" "vi" "1.0" "Prodict" "https://github.com/catusphan/dictionary" "english_inflections.txt"
print_to_file "Prodict_VE_Tech.dfo" "Từ điển Việt-Anh Kỹ thuật Prodict" "Từ điển Việt-Anh Kỹ thuật Prodict" "vi" "en" "1.0" "Prodict" "https://github.com/catusphan/dictionary" ""
print_to_file "Prodict_VE_business.dfo" "Từ điển Việt-Anh Kỹ thuật Prodict" "Từ điển Việt-Anh Kỹ thuật Prodict" "vi" "en" "1.0" "Prodict" "https://github.com/catusphan/dictionary" ""
print_to_file "Prodict_4in1_all.dfo" "Từ điển Anh-Việt Kỹ thuật & Kinh doanh Prodict" "Từ điểnt Anh-Việt Kỹ thuật & Kinh doanh Prodict" "en" "en" "1.0" "Prodict" "https://github.com/catusphan/dictionary" "english_inflections.txt"

# Others
print_to_file "Bach_khoa_toan_thu.dfo" "Bách khoa toàn thư" "Bách khoa toàn thư tiếng Việt" "vi" "vi" "1.0" "" "https://github.com/catusphan/dictionary" ""
print_to_file "Tu_dien_Han_ngu.dfo" "Từ điển Hán ngữ" "Từ điển Hán ngữ" "vi" "vi" "1.0" "" "https://github.com/catusphan/dictionary" ""
print_to_file "Viet-Nhat_NXBVHTT.dfo" "Từ điển Việt - Nhật" "Anh - Việt" "ja" "vi" "1.0" "" "https://github.com/catusphan/dictionary" ""
print_to_file "Wikipedia.dfo" "Từ điển Wikipedia tiếng Việt" "Từ điển Wikipedia tiếng Việt" "vi" "vi" "1.0" "Wikipedia" "https://github.com/catusphan/dictionary" ""
print_to_file "WordNet2.0.dfo" "Từ điển WordNet" "Từ điển WordNet" "en" "en" "1.0" "Wikipedia" "https://github.com/catusphan/dictionary" ""
