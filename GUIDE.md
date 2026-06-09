# NamkhaZoe — Hướng dẫn toàn diện

> Tài liệu này giải thích **cách hệ thống hoạt động** và **cách quản lý data** cho app NamkhaZoe.  
> Đọc từ đầu đến cuối 1 lần là hiểu toàn bộ.

---

## MỤC LỤC

1. [Hệ thống hoạt động như thế nào](#1-hệ-thống-hoạt-động-như-thế-nào)
2. [Cấu trúc data thực tế](#2-cấu-trúc-data-thực-tế)
3. [Cách Flutter app load data](#3-cách-flutter-app-load-data)
4. [Setup tools lần đầu](#4-setup-tools-lần-đầu)
5. [Hướng dẫn upload data mới](#5-hướng-dẫn-upload-data-mới)
6. [Hướng dẫn chỉnh sửa data](#6-hướng-dẫn-chỉnh-sửa-data)
7. [Hướng dẫn xóa data](#7-hướng-dẫn-xóa-data)
8. [Quản lý file trên R2](#8-quản-lý-file-trên-r2)
9. [Backup và đồng bộ B2](#9-backup-và-đồng-bộ-b2)
10. [Bảng tham chiếu nhanh](#10-bảng-tham-chiếu-nhanh)

---

## 1. Hệ thống hoạt động như thế nào

### Sơ đồ tổng quan

```
┌─────────────────────────────────────────────────────────┐
│                  Flutter App (iOS + Android)             │
└──────────────┬──────────────────────────┬───────────────┘
               │                          │
        API calls                    Load files
        (metadata)                  (PDF, MP3, ảnh)
               │                          │
               ▼                          ▼
    ┌──────────────────┐      ┌───────────────────────┐
    │   SUPABASE       │      │   CLOUDFLARE R2        │
    │   PostgreSQL DB  │      │   Object Storage       │
    │                  │      │                        │
    │  "Cái tủ danh    │      │  "Kho chứa file thật"  │
    │   mục / index"   │      │  PDF, MP3, ảnh, ...    │
    │                  │      │                        │
    │  Miễn phí        │      │  ~$0.50/tháng          │
    └──────────────────┘      └───────────┬────────────┘
                                          │
                                   rclone sync
                                   (thủ công)
                                          │
                              ┌───────────▼────────────┐
                              │   BACKBLAZE B2          │
                              │   "Bản backup dự phòng" │
                              │   App KHÔNG đọc từ đây  │
                              │   ~$0.19/tháng          │
                              └────────────────────────┘
```

### Nguyên tắc cốt lõi — quan trọng nhất

> **Supabase chỉ lưu metadata (tên, mô tả, tên file...).**  
> **Cloudflare R2 lưu file thật (PDF, MP3, ảnh).**  
> **App ghép 2 cái lại để hiển thị.**

**Ví dụ minh hoạ:**

Trong DB có:
```
posts.title    = "Dudjom Lingpa Sungbum Vol.1"
files.file_name = "1623067538.pdf"
```

App lấy `file_name` từ DB → ghép URL → load file:
```
https://pub-xxx.r2.dev/pdf/1623067538.pdf
```

Đây là lý do file_name chỉ là một cái **timestamp** (`1623067538`) — tên thật đã có trong DB rồi, không cần tên file phải đẹp.

---

### Tại sao chọn kiến trúc này?

| Vấn đề | Giải pháp |
|--------|-----------|
| AWS S3 + CloudFront cũ **$50–80/tháng** | Cloudflare R2 **zero egress** → ~$0.50/tháng |
| Muốn có DB quan hệ đầy đủ | Supabase PostgreSQL free tier |
| Cần backup dự phòng | Backblaze B2 $0.006/GB — rẻ nhất thị trường |
| App cross-platform iOS + Android | Flutter với Riverpod state management |

---

## 2. Cấu trúc data thực tế

### Số liệu hiện tại

```
Posts (bài đăng)    :  3,857
Files đính kèm      :  5,275
  ├── PDF           :  4,925  (sách Phật giáo Tây Tạng)
  ├── MP3 audio     :    263  (giảng pháp)
  └── Ảnh           :     79
Categories          :     10
Sub-categories      :    197
Announcements       :     24
Gallery (thangka)   :     19
```

### Cấu trúc phân cấp nội dung

```
Category (10 danh mục lớn)
│
├── [2]  ༈ གསུང་འབུམ། Sungbum      — 117 sub-cats, 1,121 posts  ← NHIỀU NHẤT
├── [13] ༈ དེབ་གཟུགས། Books         —  13 sub-cats, 2,173 posts
├── [3]  ༈ དབང་ཙག Wangtsak         —   9 sub-cats,   389 posts
├── [4]  MP3 Teaching               —  18 sub-cats,    68 posts
├── [6]  ༈ དཀྱིལ་འཁོར། Mandala      —  13 sub-cats,    33 posts
├── [1]  Photo                      —   4 sub-cats,    42 posts
├── [5]  Video                      —   1 sub-cat,     10 posts
├── [7]  ༈ གཏོར་དཔེ། Tor-pe          —  14 sub-cats,    12 posts
├── [12] ༈ ལྷ་ཚོགས། Thangka Gallery  —   3 sub-cats,     8 posts
└── [14] ༈ དཀར་ཆག་ཁག Contents       —   5 sub-cats,     1 post
        │
        ▼
    Sub-category (197 danh mục con)
    Ví dụ: "Dudjom lingpa Sungbum" (id=7)
        │
        ▼
    Posts (3,857 bài đăng)
    Ví dụ: "Ga", "Ka", "Kha", ...
        │
        ▼
    Files (5,275 files)
    Ví dụ: 1623067538.pdf  ← tên file timestamp
```

### Cấu trúc thư mục trên Cloudflare R2

```
tersarzoe/                 ← bucket gốc
│
├── pdf/                   ← PDF sách (4,925 files)
│   ├── 1609669272.pdf
│   └── 1623067538.pdf
│
├── posts/
│   ├── mp3/               ← Audio giảng pháp (263 files)
│   │   ├── 1608121700.mp3
│   │   └── 1623154115.mp3
│   ├── thumbnail/         ← Ảnh bìa của post
│   │   └── 1620918632.jpg
│   ├── JPG/               ← Ảnh đính kèm post (JPG)
│   ├── jpeg/              ← Ảnh đính kèm post (JPEG)
│   └── png/               ← Ảnh đính kèm post (PNG)
│
├── categories/            ← Banner ảnh danh mục
├── sub_categories/        ← Banner ảnh danh mục con
├── announcements/         ← Ảnh thông báo
└── thumbnails/            ← Thumbnail cũ (legacy)
```

### Bảng URL — từ file_name → URL đầy đủ

| Loại file | Field trong DB | URL |
|-----------|---------------|-----|
| PDF sách | `files.file_name` | `{R2_BASE}/pdf/{file_name}` |
| MP3 audio | `files.file_name` | `{R2_BASE}/posts/mp3/{file_name}` |
| Ảnh bìa post | `posts.thumbnail` | `{R2_BASE}/posts/thumbnail/{thumbnail}` |
| Ảnh đính kèm | `files.file_name` | `{R2_BASE}/posts/JPG/{file_name}` |
| Category banner | `categories.banner_image` | `{R2_BASE}/categories/{banner_image}` |
| Sub-cat banner | `sub_categories.banner_image` | `{R2_BASE}/sub_categories/{banner_image}` |
| Ảnh thông báo | `announcements.thumbnail` | `{R2_BASE}/announcements/{thumbnail}` |

> `{R2_BASE}` = giá trị `AppConstants.r2BaseUrl` trong Flutter  
> Ví dụ: `https://pub-xxxxxxxx.r2.dev`

---

## 3. Cách Flutter app load data

### Màn Home Screen

```
App khởi động
    │
    ├── Provider: featuredPostsProvider
    │   └── Supabase query:
    │       SELECT * FROM posts
    │       WHERE is_featured=true AND content_type IN ('book','pdf')
    │       ORDER BY featured_order LIMIT 10
    │       → hiển thị "Featured Books" (horizontal scroll)
    │
    └── Provider: featuredAudioProvider
        └── Supabase query:
            SELECT * FROM posts
            WHERE content_type='audio'
            ORDER BY created_at DESC LIMIT 8
            → hiển thị "Featured Audio" (danh sách)
```

### Màn Books — Duyệt sách

```
[1] Load categories
    Supabase: SELECT * FROM categories WHERE status=true
    → Hiển thị 10 pills ngang (filter)

[2] User chọn category → load sub-categories
    Supabase: SELECT * FROM sub_categories WHERE category_id=?
    → Hiển thị tabs ngang

[3] User chọn sub-category → load posts (phân trang 20/trang)
    Supabase: SELECT * FROM posts WHERE sub_category_id=? LIMIT 20
    → Hiển thị grid 3 cột

[4] Mỗi post hiển thị ảnh bìa:
    URL = R2_BASE + "/posts/thumbnail/" + posts.thumbnail
    Dùng CachedNetworkImage (tự cache trên thiết bị)
```

### Màn Book Detail → Đọc PDF

```
User bấm vào 1 cuốn sách
    │
    [1] Supabase: SELECT * FROM files WHERE post_id=?
        → Lấy danh sách files
    │
    [2] Tìm file có file_type='pdf'
        → Lấy file_name (ví dụ: "1623067538.pdf")
    │
    [3] Ghép URL: R2_BASE + "/pdf/" + file_name
        = "https://pub-xxx.r2.dev/pdf/1623067538.pdf"
    │
    [4] SfPdfViewer.network(url)
        → Stream PDF trực tiếp từ R2, không tải về
        → Tự động track % đọc vào Riverpod state
```

### Màn Audio Player

```
User bấm play 1 track
    │
    [1] Kiểm tra posts.audio_url
        → Nếu có: dùng URL đó luôn
        → Nếu không: Supabase query files WHERE file_type='audio'
    │
    [2] Ghép URL: R2_BASE + "/posts/mp3/" + file_name
        = "https://pub-xxx.r2.dev/posts/mp3/1623154115.mp3"
    │
    [3] just_audio: AudioPlayer().setUrl(url) → play()
        audio_service: chạy nền, hiện controls màn khoá
```

### Search

```
User gõ từ khoá
    │
    Supabase: SELECT * FROM posts
    WHERE title ILIKE '%keyword%'
       OR tibetan_title ILIKE '%keyword%'
       OR description ILIKE '%keyword%'
    LIMIT 40
    → Trả kết quả real-time (debounce 300ms)
```

---

## 4. Setup tools lần đầu

### Yêu cầu

```bash
# Python 3.8+
python3 --version

# Cài 2 thư viện
pip3 install boto3 psycopg2-binary
```

### Kiểm tra hoạt động

```bash
cd tersarzoe_app/tools

# Xem thống kê — nếu hiện ra số liệu là OK
python3 nz_manage.py --stats
```

Kết quả mong đợi:
```
📊 NamkhaZoe — Database Stats
  Posts (active)     :  3,857
  Files (active)     :  5,275
  ...
```

> **Credentials** được đọc tự động từ `~/.tersarzoe-credentials`  
> File đó đã có sẵn, không cần làm gì thêm.

---

## 5. Hướng dẫn upload data mới

### Trường hợp 1: Upload 1 file PDF sách mới

**Bước 1** — Xem danh sách sub-categories để chọn ID phù hợp:
```bash
python3 nz_upload.py --list-subcats
```

Output:
```
📂 SUB-CATEGORIES:
  ID     Sub-category name                    Parent category
  ---------------------------------------------------------------
  7      Dudjom lingpa Sungbum                ༈ གསུང་འབུམ། Sungbum
  8      Chokling Tesrar Sungbum              ༈ གསུང་འབུམ། Sungbum
  20     Sera khando                          ༈ གསུང་འབུམ། Sungbum
  ...
```

**Bước 2** — Upload:
```bash
python3 nz_upload.py \
  --file "/path/to/DudjomLingpa_Vol2.pdf" \
  --title "Dudjom Lingpa Sungbum Vol.2" \
  --tib "བདུད་འཇོམས་གླིང་པ་གསུང་འབུམ།" \
  --sub-cat 7 \
  --type pdf
```

Output:
```
🔷 NamkhaZoe Upload Tool
   File    : DudjomLingpa_Vol2.pdf
   Type    : pdf
   Title   : Dudjom Lingpa Sungbum Vol.2

Step 1/2 — Upload lên Cloudflare R2...
  📤 Uploading: DudjomLingpa_Vol2.pdf
     → R2 key : pdf/1749123456.pdf
     → Size   : 12.30 MB
  ✅ Upload thành công!

Step 2/2 — Cập nhật Supabase DB...
  ✅ Tạo post mới thành công! post_id = 4056

✨ Done!
   R2 key  : pdf/1749123456.pdf
   Filename: 1749123456.pdf
```

---

### Trường hợp 2: Upload file MP3 audio

```bash
python3 nz_upload.py \
  --file "/path/to/teaching_emptiness.mp3" \
  --title "Teaching on Emptiness — Session 1" \
  --tib "སྟོང་པ་ཉིད་ཀྱི་གདམས་ངག།" \
  --sub-cat 20 \
  --type audio \
  --artist "Namkha Rinpoche" \
  --duration 3600
```

> `--duration` tính bằng **giây** (3600 = 1 giờ, 1800 = 30 phút)

---

### Trường hợp 3: Upload nhiều file cùng lúc (bulk)

**Bước 1** — Tạo template CSV từ folder:
```bash
python3 nz_bulk_upload.py --template /path/to/folder_pdfs --out upload_list.csv
```

Template CSV được tạo ra trông như này:
```csv
file_path,title,tibetan_title,sub_category_id,type,artist,duration_seconds,accent_color,description
/folder/book1.pdf,book1,,,,,,#6B1414,
/folder/book2.pdf,book2,,,,,,#6B1414,
/folder/teaching1.mp3,teaching1,,,,,,#6B1414,
```

**Bước 2** — Mở CSV, điền thông tin:

| Cột | Bắt buộc? | Ghi chú |
|-----|-----------|---------|
| `file_path` | ✅ | Tự điền |
| `title` | ✅ | Tên tiếng Anh |
| `tibetan_title` | ❌ | Tên Tây Tạng |
| `sub_category_id` | ✅ | Lấy từ `--list-subcats` |
| `type` | ✅ | `pdf` / `audio` / `image` |
| `artist` | ❌ | Tên giảng sư |
| `duration_seconds` | ❌ | Với audio |
| `accent_color` | ❌ | Màu hex (mặc định `#6B1414`) |

**Bước 3** — Preview trước (không upload thật):
```bash
python3 nz_bulk_upload.py --csv upload_list.csv --dry-run
```

**Bước 4** — Upload thật (8 luồng song song):
```bash
python3 nz_bulk_upload.py --csv upload_list.csv --workers 8
```

Output:
```
🔷 Bulk Upload — 25 files
   Workers : 8 parallel uploads

Step 1/2 — Upload lên R2...
  [1/25] ✅ DudjomLingpa_Vol1.pdf
  [2/25] ✅ DudjomLingpa_Vol2.pdf
  ...
  [25/25] ✅ Teaching_Session5.mp3

Step 2/2 — Insert 25 records vào DB...
══════════════════════════════════════
✅ Upload thành công  : 25/25
```

---

### Trường hợp 4: Upload ảnh bìa cho post đã có

```bash
python3 nz_upload.py \
  --file "/path/to/cover.jpg" \
  --type thumbnail \
  --post-id 7
```

Tự động upload lên `posts/thumbnail/` trên R2 và cập nhật `posts.thumbnail` trong DB.

---

### Trường hợp 5: Upload ảnh banner category / sub-category

```bash
# Upload banner cho category (chỉ upload R2, sửa DB thủ công)
python3 nz_upload.py --file banner.jpg --type category

# Output sẽ cho biết tên file để điền vào DB:
# File name để dùng: 1749123456.jpg
```

Sau đó update DB:
```bash
python3 nz_manage.py --update-post 0 ...
# Hoặc dùng Supabase Dashboard tại: https://supabase.com/dashboard
```

---

### Trường hợp 6: Upload thư mục không cần CSV

Khi muốn nhanh, không cần điền metadata chi tiết:
```bash
python3 nz_bulk_upload.py \
  --folder /path/to/pdfs \
  --sub-cat 7 \
  --type pdf
```
Title tự lấy từ tên file, có thể sửa sau bằng `--update-post`.

---

## 6. Hướng dẫn chỉnh sửa data

### Xem thống kê tổng quan

```bash
python3 nz_manage.py --stats
```

### Tìm bài đăng cần sửa

```bash
# Tìm theo từ khoá tiếng Anh hoặc Tây Tạng
python3 nz_manage.py --search "dudjom lingpa"
python3 nz_manage.py --search "བདུད་འཇོམས"

# Xem 20 bài mới nhất
python3 nz_manage.py --recent 20

# Xem chi tiết 1 bài (kèm danh sách files)
python3 nz_manage.py --post 7
```

### Sửa thông tin bài đăng

```bash
# Sửa tiêu đề
python3 nz_manage.py --update-post 7 --title "Dudjom Lingpa Sungbum — Volume Ga"

# Thêm tiêu đề Tây Tạng
python3 nz_manage.py --update-post 7 --tib "བདུད་འཇོམས་གླིང་པ་གསུང་འབུམ།"

# Thêm tên tác giả
python3 nz_manage.py --update-post 7 --artist "Dudjom Lingpa"

# Đổi màu accent (màu nền book cover khi không có thumbnail)
python3 nz_manage.py --update-post 7 --accent "#1A3A6B"

# Ẩn bài (vẫn còn trong DB, không hiện app)
python3 nz_manage.py --update-post 7 --status hide

# Hiện lại
python3 nz_manage.py --update-post 7 --status show
```

### Quản lý "Featured" — Nội dung nổi bật trên Home screen

```bash
# Đánh dấu nổi bật (hiển thị trên Home screen)
python3 nz_manage.py --set-featured 7,8,9,18,19,20

# Bỏ nổi bật
python3 nz_manage.py --unset-featured 18,19

# Đánh dấu 1 bài và set thứ tự hiển thị
python3 nz_manage.py --update-post 7 --featured
```

> Nếu `is_featured = false` với tất cả posts → Home screen sẽ trống phần "Featured Books".  
> Cần đánh dấu ít nhất 3–5 posts là featured.

---

## 7. Hướng dẫn xóa data

### ⚠️ Lưu ý quan trọng

Xóa post sẽ:
1. Xóa record trong bảng `posts` và `files` trên Supabase
2. Xóa file thật trên Cloudflare R2

**Không thể hoàn tác.** B2 vẫn còn backup nhưng phải restore thủ công.

### Xem trước trước khi xóa

```bash
# Xem post sẽ bị xóa gì (KHÔNG xóa thật)
python3 nz_manage.py --delete-post 7
```

Output:
```
  Deleting post #7: Ga
  Files sẽ bị xóa khỏi R2: 1
  (Thêm --confirm để thực hiện)
```

### Xóa thật

```bash
python3 nz_manage.py --delete-post 7 --confirm
```

### Ẩn thay vì xóa (khuyến nghị)

Thay vì xóa hẳn, nên ẩn post — vẫn giữ file nhưng không hiện trên app:
```bash
python3 nz_manage.py --update-post 7 --status hide
```

---

## 8. Quản lý file trên R2

### Xem files trong 1 folder

```bash
python3 nz_manage.py --r2-ls pdf
python3 nz_manage.py --r2-ls posts/mp3
python3 nz_manage.py --r2-ls posts/thumbnail
python3 nz_manage.py --r2-ls categories

# Hiện nhiều hơn (default 20)
python3 nz_manage.py --r2-ls pdf --limit 100
```

### Xóa file R2 (cẩn thận)

```bash
# Xem trước
python3 nz_manage.py --r2-delete pdf/1623067538.pdf

# Xóa thật
python3 nz_manage.py --r2-delete pdf/1623067538.pdf --confirm
```

---

## 9. Backup và đồng bộ B2

Khi thêm file mới lên R2, cần **sync sang B2** để giữ backup đồng bộ.

### Sync R2 → B2

```bash
# Sync toàn bộ (thường mất 5–30 phút tuỳ số file mới)
rclone sync r2-tersarzoe:tersarzoe b2-tersarzoe:tersarzoe-backup \
  --progress --transfers 8

# Kiểm tra đồng bộ (không copy, chỉ báo chênh lệch)
rclone check r2-tersarzoe:tersarzoe b2-tersarzoe:tersarzoe-backup
```

### Khuyến nghị: Chạy sync sau mỗi đợt upload lớn

```bash
# Chạy nền (khoảng 10–15 phút với vài GB mới)
nohup rclone sync r2-tersarzoe:tersarzoe b2-tersarzoe:tersarzoe-backup \
  --progress --transfers 8 \
  > /tmp/b2-sync.log 2>&1 &

# Theo dõi tiến trình
tail -f /tmp/b2-sync.log
```

---

## 10. Bảng tham chiếu nhanh

### Các lệnh dùng nhiều nhất

```bash
# ── XEM ──────────────────────────────────────────────
python3 nz_manage.py --stats                      # Thống kê tổng quan
python3 nz_manage.py --recent 20                  # 20 posts mới nhất
python3 nz_manage.py --search "từ khoá"           # Tìm kiếm
python3 nz_manage.py --post 7                     # Chi tiết post #7

# ── UPLOAD ───────────────────────────────────────────
python3 nz_upload.py --list-subcats               # Xem sub-category IDs
python3 nz_upload.py --file f.pdf --title "..." --sub-cat 7 --type pdf
python3 nz_upload.py --file f.mp3 --title "..." --sub-cat 20 --type audio
python3 nz_upload.py --file cover.jpg --type thumbnail --post-id 7

# ── BULK UPLOAD ──────────────────────────────────────
python3 nz_bulk_upload.py --template /folder --out list.csv
python3 nz_bulk_upload.py --csv list.csv --dry-run
python3 nz_bulk_upload.py --csv list.csv --workers 8

# ── SỬA ─────────────────────────────────────────────
python3 nz_manage.py --update-post 7 --title "..." --tib "..."
python3 nz_manage.py --update-post 7 --artist "..." --accent "#1A3A6B"
python3 nz_manage.py --update-post 7 --status hide
python3 nz_manage.py --set-featured 7,8,9,18,19   # Hiển thị Home screen

# ── XÓA ─────────────────────────────────────────────
python3 nz_manage.py --delete-post 7 --confirm     # Xóa thật

# ── R2 ──────────────────────────────────────────────
python3 nz_manage.py --r2-ls pdf                   # Xem files trong /pdf/
python3 nz_manage.py --r2-ls posts/mp3

# ── BACKUP ───────────────────────────────────────────
rclone sync r2-tersarzoe:tersarzoe b2-tersarzoe:tersarzoe-backup --progress
```

---

### Màu accent gợi ý

| Màu | Hex | Dùng cho |
|-----|-----|---------|
| Temple Maroon | `#6B1414` | Mặc định, sách Mật Tông |
| Midnight Blue | `#1A3A6B` | Heart Sutra, Prajnaparamita |
| Forest Green | `#1B5E3A` | Tara, Medicine Buddha |
| Deep Purple | `#4A1A6B` | Vajrayana, tantra |
| Teal | `#2A7A7A` | Marpa, Milarepa |
| Dark Gold | `#8B6914` | Guru Yoga, empowerments |
| Saffron | `#C8700A` | Mañjuśrī, wisdom texts |
| Slate | `#3A3A4A` | Lojong, mind training |

---

### Tốc độ upload tham khảo

| Số file | Kích thước trung bình | Thời gian (workers=8) |
|---------|----------------------|----------------------|
| 10 file | 5 MB/file | ~1 phút |
| 50 file | 5 MB/file | ~4 phút |
| 100 file | 5 MB/file | ~8 phút |
| 200 file | 5 MB/file | ~15 phút |
| 500 file | 5 MB/file | ~35 phút |

---

### Lỗi thường gặp

| Lỗi | Nguyên nhân | Cách xử lý |
|-----|------------|------------|
| `FileNotFoundError` | Đường dẫn file sai | Kiểm tra lại `--file` |
| `sub_category_id không hợp lệ` | ID không tồn tại | Chạy `--list-subcats` |
| `Connection refused` | Mất internet | Kiểm tra kết nối |
| `Access Denied (R2)` | Credentials sai | Kiểm tra `~/.tersarzoe-credentials` |
| File upload nhưng app không thấy | R2 Public URL chưa enable | Bật trong Cloudflare Dashboard |

---

### Cần làm gì nếu app không hiện ảnh/PDF?

**Nguyên nhân 99%:** `r2BaseUrl` trong Flutter chưa được set.

```dart
// lib/core/constants/app_constants.dart
static const r2BaseUrl = 'REPLACE_WITH_R2_PUBLIC_URL';  // ← chưa set
```

**Cách fix:**
1. Vào `https://dash.cloudflare.com` → R2 → bucket `tersarzoe` → Settings
2. Bật **"Public Development URL"**
3. Copy URL dạng `https://pub-xxxxxxxxxxxxxxxx.r2.dev`
4. Cập nhật trong Flutter:
```dart
static const r2BaseUrl = 'https://pub-xxxxxxxxxxxxxxxx.r2.dev';
```
5. Build lại app

---

*Tài liệu này cùng với `DATA_ARCHITECTURE.md` là tài liệu kỹ thuật đầy đủ của dự án NamkhaZoe.*
