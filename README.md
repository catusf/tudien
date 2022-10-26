# Từ điển tiếng Việt dành cho máy đọc sách Kindle, Kobo, Pocketbook v.v.

Mã nguồn cho từ điển dành cho máy đọc sách Kindle. Để sử dụng download tại đây http://catusf.github.io/.

## Tại sao?
- Do tôi thấy cần:
    - Có các từ điển có chất lượng để giúp việc học hỏi của bản thân và mọi người
    - Lập trình viên bất kỳ có thể dùng dữ liệu đầu vào ở đây để tạo output khác
    - Có thể dễ dàng bổ sung từ điển - chỉ cần tạo 1 file văn bản phân cách bằng dấu \t (.tab) và 1 file mô tả .dfo

- Các từ điển cần: 

    - Chính xác và dễ tra cứu
    - Dùng được trên nhiều thiết bị (Kindle, Kobo, Onyx, mobile và PC apps)

## Hướng dẫn cách tạo ra file từ điển .mobi
1. Cài Python 3.x
2. Tạo mới hay sửa file định nghĩa từ điển (như `../dict/TudienAnhVietBeta.tab`)
3. Chạy dòng lệnh `createhtml.bat` để tạo ra các file `.html` (có format OPFcho ebook ebook) dùng chương trình Python `tab2opf.py`
4. Sửa file .opf nếu cần (tham khảo các file *-org.opf)
5. Chạy `createmobi.bat` để tạo từ điển Kindle sử dụng công cụ `mobigen.exe` của Amazon. Các từ điển nằm trong thư mục `../dict`

Việc còn lại là copy file .mobi vừa được tạo ra bằng dây cáp USB vào thư mục `documents` trên Kindle để bắt đầu sử dụng.


## Danh sách các từ điển và số từ hiện có

1. Từ điển Hán Việt Thiền Chửu (9'897)
2. Từ điển Anh Việt Beta (106'059 với 28'400 dạng từ thay thế - inflection)
3. Từ điển phật học tổng hợp (49'569)
4. Từ điển Phật Quang (16'973)
5. Từ điển Phật học Việt Anh - Thiện Phúc (24'767)
6. Từ điển Phật học Anh-Hán-Việt (3'914)
7. Ngữ vựng Danh từ Thiền học (302)
8. Từ điển Đạo Uyển (3'262)
9. Từ điển Phật học Việt Anh - Đồng Loại (7'847)
10. Từ điển Phật học Việt Anh - Minh Thông (9'113)
11. Phật Quang Đại từ điển (Hán ngữ) (22'900)
12. Rộng mở tâm hồn (1'347)
13. Từ điển Phật học Tinh tuyển (2'918)

### Chat với tác giả

[![Join the chat at https://gitter.im/catusf/tudienanhviet](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/catusf/tudienanhviet?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
 
[![Release all dictionaries](https://github.com/catusf/tudien/actions/workflows/release_all.yml/badge.svg)](https://github.com/catusf/tudien/actions/workflows/release_all.yml)
