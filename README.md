# bohcom-kw-tool — KW Tool (Bộ lọc Keyword)

Web tool **tĩnh, 1 file, zero-build**: nạp file keyword (`.xlsx` / `.xls` / `.csv`), tự quét pool để gợi ý **KW Map**, **chạy phân loại** keyword vào từng nhóm theo thứ tự ưu tiên, rồi **xuất Excel** nhiều sheet.

Toàn bộ ứng dụng nằm trong **một file [`index.html`](index.html)** — HTML + CSS (Tailwind CDN) + JS thuần, dùng [SheetJS](https://sheetjs.com/) (xlsx 0.18.5) và [PapaParse](https://www.papaparse.com/) (5.4.1) qua CDN. **Không cần Node, không cần build, không backend.** Mở thẳng bằng trình duyệt là chạy (cần internet để tải CDN).

> File này là **nguồn chân lý** của project. Mọi thay đổi phải tuân thủ. Khi làm việc với tool (kể cả Claude Code), hãy đọc và bám theo file này trước khi sửa bất cứ thứ gì.

---

## ⚠️ 1. Nguyên tắc bất biến (KHÔNG ĐƯỢC VI PHẠM)

Phần **logic lõi** đã đúng và là final. **KHÔNG** refactor, viết lại, "tối ưu", đổi tên biến/hàm, hay đổi hành vi của:

- Engine khớp chữ: `canon()`, `stem()`, `SYN`, `phraseIn()`.
- Thuật toán phân loại `classifyKW()` và thứ tự ưu tiên.
- Bộ từ điển auto-suggest `LEX` (Seasonal / Product / Function / Đối tượng).
- Thanh **Root KW ưu tiên** + dropdown gán nhóm.
- Cách tách tab/sheet, xử lý leftover, bản sao gốc, và logic **Xuất Excel**.

Nếu buộc phải đụng vào code logic: chỉ được giữ **hành vi 100% như cũ**. Mọi tính năng mới phải **cộng thêm**, không thay đổi luồng cũ. Khi nghi ngờ → **DỪNG và hỏi**.

Giữ kiến trúc **1 file `index.html` static, không build, không thêm framework**.

---

## 2. Quy trình 7 bước (luồng nghiệp vụ)

1. **Nạp file** `.xlsx` / `.xls` / `.csv` (ưu tiên đọc sheet tên `KW Raw`). Tự tạo **bản sao gốc** `KW Raw (Bản sao)` 🔒 — giữ nguyên, không bị chỉnh.
2. **Tạo tab KW Map** gồm 4 nhóm cột: Seasonal · Product · Function · Đối tượng.
3. **Tự quét pool** (cột `Keyword Phrase`) và **điền sẵn** giá trị nhóm vào KW Map (kèm số KW khớp). Người dùng xem lại / sửa / thêm.
4. **Chạy phân loại:** đọc từng `Keyword Phrase`, gán mỗi KW vào **đúng 1 nhóm** theo thứ tự ưu tiên (mục 3).
5. **Tách tab:** mỗi giá trị (ô) trong KW Map → **1 tab/sheet riêng**, tên = giá trị root (phần trước dấu `/`). Ô 0 KW vẫn tạo tab.
6. **Chuyển dữ liệu:** copy nguyên dòng (đủ mọi cột) của KW khớp sang tab nhóm tương ứng, đồng thời **gỡ khỏi KW Raw**. KW không khớp → **giữ nguyên** trong KW Raw (leftover).
7. **Phân loại cấp 2 (trong từng tab):** coi mỗi tab giá trị là pool mới, rút gọn mỗi KW thành **root con**:
   - Root con = **chỉ 1 TỪ**. Cách chọn: bỏ **term chính của tab** (tên tab, vd `card`) + *stopword* (for/the/with…) + *từ generic* (gift/idea/present), **giữ** từ Đối tượng. Trong các từ còn lại: **ưu tiên từ có trong KW Map** (tier cao nhất: Seasonal>Product>Function>Đối tượng; hoà → từ xuất hiện nhiều nhất trong tab → A→Z). Không có từ KW Map: nếu có **số** (2 pack, set of 3…) → `number`; còn lại lấy **từ phổ biến nhất**. KW = đúng term tab → `(không có root phụ)`.
   - VD tab `Calendar`: `desk small flip`, `daily 2026 desk`, `humor desk`… đều chứa `desk` (Product) → gom hết vào root **`desk`**; tab `Card`: `funny card` → `funny`. (Muốn tách theme riêng như `affirmation` → thêm từ đó vào KW Map.)
   - Mỗi root con **gán 1 trong 4 nhóm bằng KW Map hiện có**; root không khớp xếp **cuối** (không gắn nhãn). Root con **xếp theo thứ tự 4 nhóm**, trong nhóm **volume giảm dần** (tự dò cột `Volume/Volumes/Search Volume/Search Volumes`; không có thì theo số KW), hoà thì A→Z. KW bên trong mỗi root con cũng **volume giảm dần**.
   - Hiển thị dạng **gập** (mặc định gập sẵn), bấm root con → xổ ra KW. Có **toggle bật/tắt cấp 2** (tắt → xem phẳng như cũ). **Không tạo tab mới, không thêm cột.**

---

## 3. Thứ tự ưu tiên phân loại (BẮT BUỘC)

```
0. Root KW ưu tiên   (cao nhất — người dùng tự thêm)
1. Seasonal
2. Product
3. Function
4. Đối tượng
```

- Mỗi KW chỉ vào **1 nhóm duy nhất** = nhóm ưu tiên cao nhất mà nó khớp; khớp xong **dừng**, không xét nhóm dưới.
- Trong **cùng 1 nhóm**, ô **cụ thể hơn** (nhiều chữ hơn / dài hơn) được xét **trước** ô chung (vd `unborn baby` xét trước `baby`).

---

## 4. Cơ chế khớp chữ (matching engine)

- **Chuẩn hoá (`canon`):** lowercase → bỏ dấu nháy `'` → tách từ `[a-z0-9]+` → **stem** từng từ → áp **từ đồng nghĩa `SYN`**.
- **Stem (số nhiều/biến thể):** `ies→y` (babies→baby); `es` (cắt `es` sau s/x/z/ch/sh, còn lại cắt `s`: valentines→valentine); `s` cuối (trừ `ss`). Từ ≤3 ký tự giữ nguyên.
- **`SYN` (đồng nghĩa, mở rộng biến thể):** mom/mommy/mama/mum/mothers→mother; woman→women; xmas→christmas; bday→birthday; congrats/congratulations→congratulation; pregnancy/pregnancies→pregnant; expecting/expectant/expected→expect.
- **Khớp (`phraseIn`):** so theo **chuỗi từ nguyên vẹn liên tiếp** (whole-word, đúng thứ tự). Cách này tránh bắt nhầm giữa từ (vd `son` KHÔNG dính `season`).
- **Dấu `/`** trong 1 ô = **HOẶC** (gộp nhiều biến thể vào cùng nhóm). Vd `mom / mother / mommy`.
- **Tự mở rộng biến thể:** nhờ stem + SYN, gõ 1 kiểu vẫn bắt được số nhiều / cách viết gần giống (pregnant↔pregnancy, mothers day↔mother day…).

---

## 5. KW Map & Auto-suggest

- Tool có **bộ từ điển `LEX`** cho 4 nhóm (occasion cho Seasonal, item Amazon cho Product ~90+ loại, thuộc tính/sự kiện cho Function, người nhận cho Đối tượng).
- Khi nạp file: chỉ điền vào KW Map những term **thực sự xuất hiện trong pool**, sắp theo tần suất giảm dần. Nút **🔄 Quét thêm gợi ý** = merge thêm, giữ nguyên phần đã sửa tay.
- Số bên phải mỗi term = số KW chứa term đó (raw match). Số thực vào tab có thể nhỏ hơn do ưu tiên (nhóm trên ăn trước).

---

## 6. Root KW ưu tiên (tính năng đặc biệt)

- Thanh riêng (màu hồng ★) **luôn hiện** trên cùng, ở mọi tab.
- Mỗi root = `{ term, group }` — có **dropdown chọn nhóm** (Seasonal/Product/Function/Đối tượng).
- KW khớp root → **lọc trước tất cả**, nhưng **gom kết quả vào nhóm đã chọn**: tab mang **màu nhóm đó + dấu ★**, đếm cộng vào nhóm đó, đứng đầu hàng tab.
- Root ưu tiên **cũng được thêm vào KW Map** (hiện ★ ở cột nhóm đã chọn, cả trong giao diện lẫn file Excel xuất ra).

---

## 7. Đầu ra & Xuất Excel

File Excel xuất ra gồm:

- `KW Raw` — chỉ còn KW **leftover** (chưa khớp).
- `KW Raw (Bản sao)` — **đủ toàn bộ** KW gốc, không đụng.
- `KW Map` — 4 cột nhóm (kèm root ưu tiên ★ ở đúng cột).
- **1 sheet cho mỗi giá trị** trong KW Map (giữ nguyên cột gốc, **không thêm cột**). Khi bật cấp 2, các KW được **gom theo root con** giống giao diện: mỗi root con là 1 hàng tiêu đề (`▸ root · nhóm · n KW · vol`), KW nằm bên dưới, **gom dòng (+/-) và gập sẵn** trong Excel, **cách 1 dòng** giữa các nhóm; xếp theo 4 nhóm, volume giảm dần. (Tắt cấp 2 → xuất phẳng như cũ.)

**Bất biến đã kiểm chứng (phải luôn đúng):** `matched + leftover = tổng KW`; **không dòng nào ở 2 tab**; mỗi KW matched nằm **đúng 1 tab**.

---

## 8. Cấu trúc project

```
bohcom-kw-tool/
├── index.html      # toàn bộ tool (static, zero-build) — KHÔNG tách file
├── README.md       # file này — mô tả + luật + đặc tả
├── .gitignore      # node_modules/ .DS_Store .vercel *.log
└── push.sh         # git add + commit + push (1 lệnh)
```

---

## 9. Chạy local

Mở thẳng `index.html` bằng trình duyệt là dùng được (cần internet cho CDN). Hoặc chạy static server bất kỳ:

```bash
python -m http.server 8000
# rồi mở http://localhost:8000
```

---

## 10. Deploy (GitHub + Vercel)

- **GitHub:** repo `bohcom-kw-tool`. Source = file tĩnh.
- **Vercel:** Import repo → Framework Preset = **Other** → **không** Build Command / Output Directory → Deploy. Bật **auto-deploy theo repo** → mỗi commit lên GitHub là Vercel tự deploy.
- Nếu bước nào cần đăng nhập (gh / vercel / token) → **DỪNG và yêu cầu người dùng đăng nhập**, không tự bịa token.

---

## 11. Quy trình update

```bash
# sau khi sửa index.html:
./push.sh "mô tả thay đổi"
# = git add . && git commit && git push  →  Vercel tự deploy ~30s
```

> `push.sh` chạy bằng **Git Bash**. Nếu dùng PowerShell: `bash push.sh "mô tả thay đổi"`.

Mọi tính năng mới: **cộng thêm**, không phá luồng/logic cũ ở mục 1–7.
