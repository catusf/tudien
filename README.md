# Từ điển tiếng Việt dành cho Kindle

Mã nguồn cho từ điển dành cho máy đọc sách Kindle. Để sử dụng download tại đây http://catusf.github.io/.

### Hướng dẫn cách tạo ra file từ điển .mobi
1. Cài Python 3.x
2. Tạo mới hay sửa file định nghĩa từ điển (như dict/TudienAnhVietBeta.txt)
3. Chạy dòng lệnh `createhtml.bat` để tạo ra các file `.html` (có format OPFcho ebook ebook) dùng chương trình Python `tab2opf.py`
4. Sửa file .opf nếu cần (tham khảo các file *-org.opf)
5. Chạy `createmobi.bat` để tạo từ điển Kindle sử dụng công cụ `mobigen.exe` của Amazon. Các từ điển nằm trong thư mục `../dict`

Việc còn lại là copy file .mobi vừa được tạo ra bằng dây cáp USB vào thư mục `documents` trên Kindle để bắt đầu sử dụng.

### TODO
- [X] Copy dữ liệu Từ điển Thiền Chửu lên repo
- [ ] Sử dụng Action để build và release tự động từ điển
- [X] Khái quát hoá tool để có thể build được các file dữ liệu từ điển khác


### Chat với tác giả

[![Join the chat at https://gitter.im/catusf/tudienanhviet](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/catusf/tudienanhviet?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
 
