# bohcom-kw-tool — KW Tool (Bộ lọc Keyword)

Web tool **tĩnh, zero-build**: nạp file keyword (`.xlsx` / `.xls` / `.csv`), tự quét pool để gợi ý **KW Map**, rồi **chạy phân loại** keyword vào các nhóm theo thứ tự ưu tiên và xuất Excel nhiều sheet.

Toàn bộ ứng dụng nằm trong **một file [`index.html`](index.html)** — HTML + CSS (Tailwind CDN) + JS, dùng [SheetJS](https://sheetjs.com/) và [PapaParse](https://www.papaparse.com/) qua CDN. Không cần Node, không cần build.

## Cách phân loại

1. **Root KW ưu tiên** — lọc TRƯỚC tất cả; mỗi root gán vào 1 nhóm.
2. **Seasonal → Product → Function → Đối tượng** — 4 nhóm theo thứ tự ưu tiên.

Mỗi giá trị KW Map tạo ra một sheet riêng khi xuất Excel; phần chưa khớp giữ lại ở sheet `KW Raw`.

## Chạy local

Mở thẳng `index.html` bằng trình duyệt là dùng được (cần internet cho CDN). Hoặc chạy một static server bất kỳ, ví dụ:

```bash
python -m http.server 8000
# rồi mở http://localhost:8000
```

## Deploy (Vercel)

Project là static thuần (Framework = **Other**, không có build step). Trên Vercel:

- Import repo `bohcom-kw-tool` → Framework Preset = **Other** → Build Command để trống → Output Directory để trống (root) → **Deploy**.
- Sau khi liên kết, **mỗi commit push lên `main` sẽ tự động deploy** (auto-deploy theo Git).

## Quy trình update

```bash
# sửa index.html, rồi:
./push.sh "mô tả thay đổi"
```

`push.sh` chạy `git add . && git commit && git push`; Vercel tự deploy bản mới.
