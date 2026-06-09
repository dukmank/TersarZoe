# NamkhaZoe — Data Architecture & Storage Guide

> Tài liệu này mô tả toàn bộ cấu trúc dữ liệu, cách lưu trữ file, và cách Flutter app load data.  
> Cập nhật lần cuối: 2026-06-08

---

## 1. Tổng quan kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────────────┐
│                      Flutter App (iOS + Android)                │
│                                                                 │
│   ┌──────────────────┐          ┌──────────────────────────┐   │
│   │  Supabase Client │          │   CachedNetworkImage /   │   │
│   │  (REST + Auth)   │          │   SfPdfViewer / JustAudio│   │
│   └────────┬─────────┘          └────────────┬─────────────┘   │
└────────────┼───────────────────────────────── ┼────────────────┘
             │ HTTPS API                        │ HTTPS URL
             ▼                                  ▼
┌─────────────────────┐          ┌──────────────────────────────┐
│     SUPABASE        │          │      CLOUDFLARE R2           │
│  PostgreSQL DB      │          │   (Primary File Storage)     │
│                     │          │   ~32 GB — $0.50/tháng       │
│  • posts (3,857)    │          │   Zero egress cost           │
│  • files (5,275)    │          │                              │
│  • categories (10)  │          │  Bucket: tersarzoe           │
│  • sub_cats (197)   │          │  Endpoint: *.r2.cloudflarestorage.com
│  • announcements(24)│          └──────────────┬───────────────┘
│  • gallery (19)     │                         │ rclone sync (manual)
│  Free tier          │          ┌──────────────▼───────────────┐
└─────────────────────┘          │      BACKBLAZE B2            │
                                 │   (Backup / Archive only)    │
                                 │   ~32 GB — $0.19/tháng       │
                                 │   Bucket: tersarzoe-backup   │
                                 └──────────────────────────────┘
```

**Luồng hoạt động:**
1. App gọi **Supabase API** → nhận metadata (title, tibetan title, file_name, v.v.)
2. Dùng `file_name` + biết loại file → **ghép URL** trỏ vào Cloudflare R2
3. App tải file trực tiếp từ R2 (PDF, MP3, ảnh)
4. B2 chỉ là **backup thụ động**, app không bao giờ đọc từ B2

---

## 2. Cloudflare R2 — Cấu trúc thư mục

**Bucket:** `tersarzoe`  
**Endpoint:** `https://5b62040e9b287077ff4cf4a58ec4da0d.r2.cloudflarestorage.com`  
**Public URL base:** `REPLACE_WITH_R2_PUBLIC_URL` ← cần enable trong R2 Dashboard

```
tersarzoe/                          ← root bucket
│
├── pdf/                            ← PDF sách (4,925 files)
│   ├── 1623067538.pdf
│   ├── 1623067373.pdf
│   └── ...  (timestamp.pdf)
│
├── posts/                          ← Media của posts
│   ├── JPG/                        ← Ảnh định dạng JPG
│   │   ├── 1609174758.jpg
│   │   └── ...
│   ├── jpeg/                       ← Ảnh định dạng JPEG
│   │   └── ...
│   ├── png/                        ← Ảnh định dạng PNG
│   │   └── ...
│   ├── mp3/                        ← File âm thanh (263 files)
│   │   ├── 1623154115.mp3
│   │   └── ...
│   ├── pdf/                        ← PDF thêm (một số nằm đây)
│   │   └── ...
│   └── thumbnail/                  ← Thumbnail của post (ảnh bìa)
│       ├── 1620918632.jpg
│       └── ...
│
├── thumbnails/                     ← Thumbnail cũ (legacy, ít dùng)
│   ├── costarica.jpg
│   └── sony.jpg
│
├── categories/                     ← Ảnh banner của categories
│   ├── 1620889293.png
│   └── ...
│
├── sub_categories/                 ← Ảnh banner của sub-categories
│   ├── 1623834036.jpeg
│   └── ...
│
├── announcements/                  ← Ảnh thông báo
│   ├── 1621164313.jpg
│   └── ...
│
└── txt/                            ← File text (ít dùng)
```

### Quy tắc đặt tên file
Tất cả file đều được đặt tên theo **Unix timestamp** tại thời điểm upload:
```
1623067538.pdf   →  upload lúc 2021-06-07 09:12:18 UTC
1623154115.mp3   →  upload lúc 2021-06-08 09:28:35 UTC
```
Không có tên mô tả — tên thật được lưu trong DB (bảng `files.file_name` hoặc `posts.title`).

---

## 3. Supabase PostgreSQL — Cấu trúc Database

**URL:** `https://arbaychxmbbewogyverv.supabase.co`  
**DB Connection:** `postgresql://postgres:***@db.arbaychxmbbewogyverv.supabase.co:5432/postgres`

### 3.1 Sơ đồ quan hệ (ERD)

```
categories (10 rows)
    │ id
    │ 1 ──── nhiều
    ▼
sub_categories (197 rows)
    │ id, category_id → categories.id
    │ 1 ──── nhiều
    ▼
posts (3,857 rows)
    │ id, sub_category_id → sub_categories.id
    │ 1 ──── nhiều
    ▼
files (5,275 rows)
    id, post_id → posts.id
    file_name, file_type (pdf | audio | image | other)

announcements (24 rows)          ← độc lập, không liên kết posts
gallery_items (19 rows)          ← độc lập, ảnh thangka/masters/deities
featured_content (5 rows)        ← shortlist nội dung nổi bật
```

---

### 3.2 Bảng `categories` — 10 danh mục

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| `id` | bigint | Primary key |
| `name` | varchar | Tên tiếng Anh (vd: "Sungbum") |
| `tibetan_name` | text | Tên Tây Tạng (vd: "གསུང་འབུམ།") |
| `banner_image` | varchar | Tên file ảnh banner → R2: `categories/{banner_image}` |
| `content_type` | varchar | `'book'` / `'audio'` / `'image'` |
| `display_order` | integer | Thứ tự hiển thị |
| `icon_name` | varchar | Tên icon (cho UI) |
| `status` | boolean | true = hiển thị |

**10 categories hiện có:**
```
1  → Photo (4 sub-cats)         — Ảnh lễ lạy, thầy
2  → ༈ གསུང་འབུམ། Sungbum (117) — Tuyển tập giáo lý (nhiều nhất)
3  → ༈ དབང་ཙག Wangtsak (9)     — Lễ quán đảnh
4  → MP3 Teaching (18)          — Giảng dạy bằng âm thanh
5  → Video (1)                  — Video giảng pháp
6  → ༈ དཀྱིལ་འཁོར། Mandala (13)  — Mandala
7  → ༈ གཏོར་དཔེ། Tor-pe (14)    — Torma practice
12 → ༈ ལྷ་ཚོགས། Thangka Gallery (3) — Thangka ảnh
13 → ༈ དེབ་གཟུགས། Books (13)   — Sách vật lý
14 → ༈ དཀར་ཆག་ཁག Contents (5)  — Mục lục
```

---

### 3.3 Bảng `sub_categories` — 197 sub-danh mục

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| `id` | bigint | Primary key |
| `name` | varchar | Tên sub-category |
| `tibetan_name` | text | Tên Tây Tạng |
| `category_id` | integer | FK → `categories.id` |
| `banner_image` | varchar | Tên file → R2: `sub_categories/{banner_image}` |
| `status` | boolean | Hiển thị hay ẩn |

*Ví dụ: Sub-cat "Dudjom lingpa Sungbum" thuộc cat "Sungbum", chứa nhiều post PDF.*

---

### 3.4 Bảng `posts` — 3,857 bài đăng (QUAN TRỌNG NHẤT)

| Cột | Kiểu | Ý nghĩa | Ghi chú |
|-----|------|---------|---------|
| `id` | bigint | PK | |
| `title` | varchar | Tiêu đề tiếng Anh | |
| `tibetan_title` | text | Tiêu đề Tây Tạng | *Thêm migration v1* |
| `description` | text | Mô tả / tóm tắt | |
| `sub_category_id` | integer | FK → sub_categories | |
| `content_type` | varchar | `'book'` / `'audio'` / `'video'` | *Thêm v1, default='book'* |
| `thumbnail` | varchar | Tên file ảnh bìa | URL = `posts/thumbnail/{thumbnail}` |
| `is_video` | integer | 1 nếu là video | |
| `is_youtube` | integer | 1 nếu link YouTube | |
| `youtube_url` | varchar | YouTube URL | |
| `artist` | varchar | Tên giảng sư / tác giả | *Thêm v1* |
| `translator` | varchar | Người dịch | *Thêm v1* |
| `duration_seconds` | integer | Thời lượng audio (giây) | *Thêm v1* |
| `cover_image_url` | varchar | URL ảnh bìa đầy đủ (override) | *Thêm v1* |
| `audio_url` | varchar | URL audio đầy đủ (override) | *Thêm v1* |
| `accent_color` | varchar | Màu accent hex (vd: `#6B1414`) | *Thêm v1, default maroon* |
| `pages_count` | integer | Số trang PDF | *Thêm v1* |
| `is_featured` | boolean | Nội dung nổi bật | *Thêm v1* |
| `featured_order` | integer | Thứ tự trong featured | *Thêm v1* |
| `status` | boolean | true = public | |
| `created_at` | timestamptz | Ngày tạo | |

**Phân bố content_type:**
```
book   → 3,790 posts  (chiếm 98.3%) — hầu hết là PDF sách Phật giáo Tây Tạng
audio  →    67 posts  (chiếm 1.7%)  — giảng pháp MP3
```

---

### 3.5 Bảng `files` — 5,275 files

Mỗi `post` có thể có **nhiều files** đính kèm.

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| `id` | bigint | PK |
| `file_name` | varchar | Tên file (timestamp-based, vd: `1623067538.pdf`) |
| `file_extension` | varchar | `pdf` / `mp3` / `jpeg` / `jpg` / `png` |
| `file_type` | varchar | `pdf` / `audio` / `image` / `other` |
| `file_size` | varchar | Kích thước (string) |
| `file_mime` | varchar | MIME type |
| `post_id` | integer | FK → `posts.id` |
| `status` | boolean | Có active không |

**Phân bố file_type:**
```
pdf    → 4,925 files  — Sách PDF Phật giáo Tây Tạng
audio  →   263 files  — File MP3 giảng pháp
image  →    79 files  — Ảnh
other  →     8 files  — Khác
```

---

### 3.6 Bảng `announcements` — 24 thông báo

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| `id` | bigint | PK |
| `title` | varchar | Tiêu đề thông báo |
| `description` | text | Nội dung |
| `thumbnail` | varchar | Tên file ảnh → R2: `announcements/{thumbnail}` |
| `is_youtube` | integer | 1 nếu có video YouTube |
| `youtube_url` | varchar | YouTube link |
| `status` | boolean | Hiển thị hay ẩn |

---

### 3.7 Bảng `gallery_items` — 19 ảnh linh thiêng

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| `id` | bigint | PK |
| `title` | varchar | Tên (vd: "Guru Rinpoche") |
| `tibetan_title` | text | Tên Tây Tạng |
| `subtitle` | text | Mô tả ngắn |
| `collection` | varchar | `masters` / `deities` / `mandala` / `sacred_objects` |
| `accent_color` | varchar | Màu chủ đạo hex |
| `image_url` | varchar | Tên file hoặc URL đầy đủ |
| `biography_url` | varchar | Link PDF tiểu sử (nếu có) |
| `is_shareable` | boolean | Cho phép chia sẻ |
| `status` | boolean | Public |
| `display_order` | integer | Thứ tự hiển thị |

**Phân bố collection:**
```
masters         → 6 items  (Guru Rinpoche, Milarepa, Tsongkhapa...)
deities         → 6 items  (Green Tara, Avalokiteśvara, Mañjuśrī...)
mandala         → 4 items  (Kālacakra, Medicine Buddha, Vajradhātu...)
sacred_objects  → 3 items
```

---

### 3.8 Bảng `featured_content` — 5 nội dung nổi bật

| Cột | Kiểu | Mô tả |
|-----|------|-------|
| `content_type` | varchar | `book` / `audio` / `gallery` |
| `content_id` | integer | ID của post hoặc gallery_item |
| `display_order` | integer | Thứ tự hiển thị |
| `title` | varchar | Tiêu đề override (optional) |

---

## 4. Cách Flutter App Load Data

### 4.1 Flow chính: Load list màn Books

```
BooksScreen
    │
    ▼
[1] Supabase: SELECT * FROM categories WHERE status=true
    → List<CategoryModel>
    │
    ▼ user chọn 1 category
[2] Supabase: SELECT * FROM sub_categories WHERE category_id=? AND status=true
    → List<SubCategoryModel>
    │
    ▼ user chọn 1 sub-category  
[3] Supabase: SELECT * FROM posts WHERE sub_category_id=? AND status=true LIMIT 20
    → List<PostModel>
    │
    ▼ render grid
[4] Mỗi PostModel.thumbnail → ghép URL → load ảnh từ R2
    URL = {R2_BASE}/posts/thumbnail/{thumbnail}
    Dùng: CachedNetworkImage (cache local)
```

### 4.2 Flow: Mở đọc 1 cuốn sách (PDF)

```
BookDetailScreen(post)
    │
    ▼
[1] Supabase: SELECT * FROM files WHERE post_id=? AND status=true
    → List<Map> — lấy file_name của file PDF
    │
    ▼ user bấm "Read Now"
[2] Ghép URL: {R2_BASE}/pdf/{file_name}
    Ví dụ: https://pub-xxx.r2.dev/pdf/1623067538.pdf
    │
    ▼
[3] SfPdfViewer.network(url)  ← load PDF trực tiếp từ R2
    → Không cần tải về, stream trực tiếp
    → Progress được save vào Riverpod ReadingProgressProvider
```

### 4.3 Flow: Nghe Audio

```
AudioPlayerScreen(post)
    │
    ▼
[1] Nếu post.audio_url != null → dùng luôn (URL đầy đủ)
    Nếu không → Supabase: SELECT * FROM files WHERE post_id=? AND file_type='audio'
    → lấy file_name
    │
    ▼
[2] Ghép URL: {R2_BASE}/posts/mp3/{file_name}
    Ví dụ: https://pub-xxx.r2.dev/posts/mp3/1623154115.mp3
    │
    ▼
[3] just_audio: AudioPlayer().setUrl(url) → play()
    audio_service: Background playback (lock screen controls)
```

### 4.4 Flow: Home Screen (Featured)

```
HomeScreen
    │
    ├── featuredPostsProvider
    │       Supabase: SELECT * FROM posts WHERE is_featured=true
    │                 AND content_type IN ('book','pdf')
    │                 ORDER BY featured_order LIMIT 10
    │
    └── featuredAudioProvider
            Supabase: SELECT * FROM posts WHERE content_type='audio'
                      ORDER BY created_at DESC LIMIT 8
```

---

## 5. URL Construction — Bảng tổng hợp

> `{R2}` = giá trị của `AppConstants.r2BaseUrl`  
> (Cần enable "Public Development URL" trong Cloudflare R2 Dashboard trước)

| Loại file | Nguồn field trong DB | URL Pattern |
|-----------|---------------------|-------------|
| **Ảnh bìa post** | `posts.thumbnail` | `{R2}/posts/thumbnail/{thumbnail}` |
| **PDF sách** | `files.file_name` (file_type='pdf') | `{R2}/pdf/{file_name}` |
| **MP3 audio** | `files.file_name` (file_type='audio') | `{R2}/posts/mp3/{file_name}` |
| **Ảnh post** | `files.file_name` (file_type='image') | `{R2}/posts/JPG/{file_name}` |
| **Ảnh category** | `categories.banner_image` | `{R2}/categories/{banner_image}` |
| **Ảnh sub-cat** | `sub_categories.banner_image` | `{R2}/sub_categories/{banner_image}` |
| **Ảnh thông báo** | `announcements.thumbnail` | `{R2}/announcements/{thumbnail}` |
| **Ảnh gallery** | `gallery_items.image_url` | URL đầy đủ hoặc `{R2}/gallery/{image_url}` |

**Ví dụ thực tế:**
```
Post thumbnail:  https://pub-xxx.r2.dev/posts/thumbnail/1620918632.jpg
PDF sách:        https://pub-xxx.r2.dev/pdf/1623067538.pdf
MP3 giảng pháp: https://pub-xxx.r2.dev/posts/mp3/1623154115.mp3
Category banner: https://pub-xxx.r2.dev/categories/1620889293.png
```

---

## 6. Backblaze B2 — Backup

**Chỉ dùng để backup, app không bao giờ đọc từ đây.**

**Bucket:** `tersarzoe-backup`  
**Cấu trúc folder:** Giống hệt R2 (được sync bằng rclone)

```bash
# Backup B2 → R2 (cần chạy định kỳ khi có data mới)
rclone sync b2-tersarzoe:tersarzoe-backup r2-tersarzoe:tersarzoe \
  --progress --transfers 8

# Check đồng bộ
rclone check b2-tersarzoe:tersarzoe-backup r2-tersarzoe:tersarzoe
```

**Chi phí so sánh:**
```
Cloudflare R2  (app serving): ~$0.50/tháng  (32GB × $0.015, zero egress)
Backblaze B2   (backup only): ~$0.19/tháng  (32GB × $0.006)
Tổng cộng:                     ~$0.70/tháng

So với AWS S3 + CloudFront cũ: ~$50–80/tháng
Tiết kiệm: ~98%  🎉
```

---

## 7. Việc cần làm trước khi app live

### Bước 1 — Enable R2 Public URL
```
1. Vào https://dash.cloudflare.com
2. R2 → Bucket "tersarzoe" → Settings
3. "Public Development URL" → Enable
4. Copy URL dạng: https://pub-xxxxxxxx.r2.dev
5. Cập nhật trong Flutter:
```
```dart
// lib/core/constants/app_constants.dart
static const r2BaseUrl = 'https://pub-xxxxxxxx.r2.dev';
```

### Bước 2 — Cập nhật R2Helper paths
Sau khi có public URL, verify lại các path trong `r2_helper.dart`:
```dart
// Xác nhận PDF nằm ở /pdf/ hay /posts/pdf/
static String postPdf(String fileName) => '$_base/pdf/$fileName';

// MP3 nằm ở /posts/mp3/
static String postMp3(String fileName) => '$_base/posts/mp3/$fileName';

// Thumbnail nằm ở /posts/thumbnail/
static String postThumbnail(String fileName) => '$_base/posts/thumbnail/$fileName';
```

### Bước 3 — Đánh dấu featured content
```sql
-- Đánh dấu 1 số post là featured để HomeScreen có data
UPDATE posts SET is_featured = true, featured_order = 1 WHERE id = 7;
UPDATE posts SET is_featured = true, featured_order = 2 WHERE id = 8;
-- Thêm các post audio
UPDATE posts SET content_type = 'audio' WHERE id IN (
  SELECT p.id FROM posts p
  JOIN files f ON f.post_id = p.id
  WHERE f.file_type = 'audio'
);
```

### Bước 4 — iOS build fix
Xcode 26 beta có bug CodeSign. Workaround:
```
1. Mở Xcode: open tersarzoe_app/ios/Runner.xcworkspace
2. Runner target → Signing & Capabilities
3. Set Development Team
4. Hoặc dùng flutter run --debug trên device thật
```

---

## 8. Supabase API — Các query chính

```dart
// Load categories
supabase.from('categories')
  .select()
  .eq('status', true)
  .order('display_order')

// Load sub-categories của 1 category
supabase.from('sub_categories')
  .select()
  .eq('category_id', categoryId)
  .eq('status', true)

// Load posts của 1 sub-category (phân trang, 20 items/trang)
supabase.from('posts')
  .select()
  .eq('sub_category_id', subCatId)
  .eq('status', true)
  .order('id')
  .range(page * 20, (page + 1) * 20 - 1)

// Load files của 1 post
supabase.from('files')
  .select()
  .eq('post_id', postId)
  .eq('status', true)

// Featured books cho Home screen
supabase.from('posts')
  .select()
  .eq('status', true)
  .eq('is_featured', true)
  .inFilter('content_type', ['book', 'pdf'])
  .order('featured_order')
  .limit(10)

// Search
supabase.from('posts')
  .select()
  .or('title.ilike.%query%,description.ilike.%query%,tibetan_title.ilike.%query%')
  .eq('status', true)
  .limit(40)

// Gallery
supabase.from('gallery_items')
  .select()
  .eq('is_published', true)
  .order('display_order')
```

---

## 9. Credentials & Config

Tất cả credentials lưu tại: `~/.tersarzoe-credentials` (chmod 600, KHÔNG commit git)

```
SUPABASE_URL=https://arbaychxmbbewogyverv.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
CF_R2_BUCKET=tersarzoe
CF_ACCOUNT_ID=5b62040e9b287077ff4cf4a58ec4da0d
B2_BUCKET=tersarzoe-backup
```

**Flutter app config:** `lib/core/constants/app_constants.dart`
```dart
static const supabaseUrl   = 'https://arbaychxmbbewogyverv.supabase.co';
static const supabaseAnonKey = 'eyJhbGci...';        // public anon key (an toàn)
static const r2BaseUrl     = 'REPLACE_WITH_R2_URL';  // cần update sau khi enable
```

> ⚠️ `supabaseAnonKey` là **public key**, an toàn để hardcode trong app.  
> `supabasePassword` (admin) phải TUYỆT ĐỐI không bao giờ vào code Flutter.

---

## 10. Tóm tắt nhanh cho developer

| Câu hỏi | Trả lời |
|---------|---------|
| Database ở đâu? | Supabase PostgreSQL (free tier) |
| Files ở đâu? | Cloudflare R2 bucket `tersarzoe` |
| Backup ở đâu? | Backblaze B2 bucket `tersarzoe-backup` |
| Có bao nhiêu sách? | ~3,790 posts dạng book, ~4,925 file PDF |
| Có bao nhiêu audio? | ~67 posts audio, ~263 file MP3 |
| URL PDF trông như thế nào? | `{R2_BASE}/pdf/1623067538.pdf` |
| URL ảnh bìa? | `{R2_BASE}/posts/thumbnail/1620918632.jpg` |
| URL MP3? | `{R2_BASE}/posts/mp3/1623154115.mp3` |
| State management? | Riverpod (providers trong `app_providers.dart`) |
| Cache ảnh? | `CachedNetworkImage` (tự cache local) |
| PDF reader? | `syncfusion_flutter_pdfviewer` |
| Audio player? | `just_audio` + `audio_service` |
