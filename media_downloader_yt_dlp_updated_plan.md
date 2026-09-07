# Media Downloader — Updated Implementation Plan
## Exact Scope: WhatsApp + Instagram + Facebook + Pinterest

## 1. Objective

Update the existing Flutter Media Downloader app so the user can:

1. Paste a social-media URL.
2. Tap **Download**.
3. App detects the platform.
4. Backend uses **Python + FastAPI + yt-dlp** for extraction where supported.
5. App receives normalized media information.
6. Existing download-progress UI is shown.
7. Media is downloaded using the existing Dio flow.
8. Downloaded media is saved locally.
9. Existing UI/design/navigation must remain intact.

### Supported app platforms

ONLY these four are in the current product scope:

- Instagram
- Facebook
- Pinterest
- WhatsApp

Do NOT add YouTube, TikTok, X/Twitter, Reddit, etc. to the app UI or product scope.

---

# 2. CRITICAL UI RULE

## DO NOT REDESIGN THE APP

The current UI is already implemented.

The existing Home screen contains:

- URL input field
- Paste button
- Download button
- Supported Socials section
- Facebook
- Instagram
- WhatsApp
- Pinterest
- Existing download progress dialog

Preserve the current:

- layout
- colors
- gradients
- typography
- icons
- spacing
- animations
- navigation
- translations
- dark/light theme
- bottom navigation

Only modify UI code when absolutely necessary for functionality or error states.

The existing HomeTab already contains the four required socials and the URL/download flow. Do not rebuild this screen from scratch.

---

# 3. Existing Flutter Flow

Current intended flow:

```text
User pastes URL
       ↓
Download button
       ↓
MediaDownloaderService.extractMediaUrl()
       ↓
Media extraction
       ↓
DownloadedMediaResult
       ↓
Existing download progress dialog
       ↓
MediaDownloaderService.downloadFile()
       ↓
Dio
       ↓
Local file
```

Keep this overall flow.

---

# 4. New Architecture

Temporary architecture:

```text
Flutter App
      |
      | POST /api/extract
      ↓
Python FastAPI Backend
      |
      ↓
yt-dlp
      |
      ↓
Platform/media extraction
      |
      ↓
Normalized JSON
      |
      ↓
Flutter
      |
      ↓
Existing Dio downloader
      |
      ↓
Device storage
```

Later, when the permanent Node.js backend is ready:

```text
Flutter
   ↓
Node.js / Express
   ↓
Extractor Router
   ├── Python yt-dlp service
   ├── Cobalt
   └── Other supported providers
```

Flutter should not need to change again when the extractor backend changes.

---

# 5. Backend Technology

Create:

```text
media-downloader-backend/
```

Use:

- Python 3.11+
- FastAPI
- Uvicorn
- yt-dlp
- python-dotenv

Optional later:

- slowapi or another rate limiter
- FFmpeg only if testing proves that separate audio/video streams must be merged

Do NOT add unnecessary dependencies.

---

# 6. Backend Folder Structure

Create:

```text
media-downloader-backend/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── extractor.py
│   ├── models.py
│   └── utils.py
├── requirements.txt
├── .env
├── .gitignore
└── README.md
```

Do not create a server-side `downloads/` folder unless server-side downloading is actually required.

---

# 7. Dependencies

`requirements.txt`:

```txt
fastapi
uvicorn[standard]
yt-dlp
python-dotenv
```

Install:

```bash
python -m pip install -r requirements.txt
```

Run:

```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

# 8. Health Endpoint

Create:

```http
GET /health
```

Response:

```json
{
  "success": true,
  "service": "media-downloader-backend"
}
```

This is only for checking whether the backend is running.

---

# 9. Extraction Endpoint

Create:

```http
POST /api/extract
```

Request:

```json
{
  "url": "https://example.com/post"
}
```

Validate:

- URL exists
- URL is not empty
- URL uses HTTP/HTTPS
- URL is syntactically valid

---

# 10. IMPORTANT — Public Content Only

The application is intended for publicly accessible/shared media.

DO NOT implement:

- private-account bypass
- login bypass
- DRM bypass
- paywall bypass
- authentication-token theft
- cookie theft
- access-control bypass

If content requires login or is private, return a clean error.

Example:

```json
{
  "success": false,
  "error": "PRIVATE_CONTENT",
  "message": "This media is private or requires login."
}
```

---

# 11. yt-dlp Extraction

Use the Python API.

Basic pattern:

```python
import yt_dlp

options = {
    "quiet": True,
    "no_warnings": True,
    "noplaylist": False,
}

with yt_dlp.YoutubeDL(options) as ydl:
    info = ydl.extract_info(url, download=False)
```

The extraction endpoint should initially use:

```text
download=False
```

The purpose is to extract media information, not download the file to the backend.

---

# 12. Platform Scope

The backend must focus only on:

```text
Instagram
Facebook
Pinterest
WhatsApp
```

Platform support must be based on actual yt-dlp extractor capabilities/testing.

Do NOT claim that every possible URL on these platforms is guaranteed to work.

For each request:

1. Detect/identify platform.
2. Check whether yt-dlp can extract it.
3. Return normalized data.
4. If extraction is unsupported, return `UNSUPPORTED_PLATFORM` or `EXTRACTION_FAILED`.

---

# 13. Instagram Requirements

The app should attempt to support publicly accessible:

- Post URLs
- Reel URLs
- Image posts
- Video posts
- Carousel posts where the extractor exposes multiple media items

Example conceptual flow:

```text
Instagram URL
     ↓
yt-dlp
     ↓
single image/video OR multiple media items
     ↓
normalized response
```

Do not assume every Instagram URL will expose the same response structure.

---

# 14. Facebook Requirements

Attempt to support publicly accessible:

- public video posts
- public supported media posts

Do not bypass Facebook login/private restrictions.

Test actual current public URLs.

---

# 15. Pinterest Requirements

Attempt to support publicly accessible:

- Pin URLs
- `pin.it` short URLs where yt-dlp supports resolving them
- image Pins
- video Pins

Normalize the result into the same API format.

---

# 16. WhatsApp Requirements

WhatsApp requires special handling.

Do NOT assume that an ordinary WhatsApp message/status/share link is a publicly downloadable media URL.

Support only WhatsApp URLs/media that the chosen extractor can actually access publicly.

If yt-dlp cannot extract a WhatsApp URL, return:

```json
{
  "success": false,
  "error": "UNSUPPORTED_URL",
  "message": "This WhatsApp URL cannot be resolved as public media."
}
```

Do not implement WhatsApp login/session scraping.

If later a different legitimate provider is found for a specific public WhatsApp URL format, it can be added as a separate extractor.

---

# 17. Normalized Response

Never send the complete raw yt-dlp response to Flutter.

Create a stable response model.

Single media:

```json
{
  "success": true,
  "platform": "instagram",
  "title": "Example",
  "thumbnail": "https://...",
  "type": "video",
  "media_url": "https://..."
}
```

Image:

```json
{
  "success": true,
  "platform": "pinterest",
  "title": "Example",
  "thumbnail": "https://...",
  "type": "image",
  "media_url": "https://..."
}
```

---

# 18. Carousel / Multiple Media

This is important.

If Instagram/Pinterest/Facebook extraction returns multiple media items, the API must support them.

Use:

```json
{
  "success": true,
  "platform": "instagram",
  "title": "Example Post",
  "type": "carousel",
  "items": [
    {
      "type": "image",
      "media_url": "https://..."
    },
    {
      "type": "video",
      "media_url": "https://..."
    }
  ]
}
```

Do not silently discard carousel items.

However, the existing Flutter UI currently expects a single `DownloadedMediaResult`.

Therefore:

### Phase 1

Support single-media downloads without breaking the current UI.

### Phase 2

Add multi-media/carousel support to Flutter with a proper selection/download UI.

Do NOT redesign the existing UI just to force carousel support into the first version.

---

# 19. Media Type

Normalize:

```text
image
video
audio
carousel
```

For the current app:

- image → `.jpg`/appropriate image extension
- video → `.mp4` where the actual media is MP4
- audio → appropriate audio extension

Do NOT automatically save every media file as `.mp4`.

---

# 20. Format Selection

Do not blindly select the first yt-dlp format.

Prefer a usable format containing:

- video
- audio

Where available.

A strategy similar to:

```text
best[ext=mp4]/best
```

may be used, but test it against each supported platform.

Some extractors may expose separate video/audio streams.

Do not add FFmpeg until required.

---

# 21. Temporary Media URLs

Some extracted URLs may expire.

Therefore:

```text
Extract
  ↓
Immediately download
```

Do not permanently store direct media URLs.

If a direct URL expires:

```text
extract again
```

---

# 22. Flutter Service

The existing Flutter project already has:

```text
MediaDownloaderService
DownloadedMediaResult
extractMediaUrl()
downloadFile()
```

Preserve these public interfaces where possible.

The important change is:

```text
OLD:

Flutter → public Cobalt/API instances

NEW:

Flutter → own FastAPI backend → yt-dlp
```

The Flutter app should not directly depend on random public extraction instances.

---

# 23. Flutter Backend Configuration

Create one backend URL configuration.

Development Android Emulator:

```text
http://10.0.2.2:8000
```

Physical Android device:

```text
http://YOUR_COMPUTER_LAN_IP:8000
```

Production:

```text
https://YOUR_DOMAIN
```

Do not hardcode the backend URL in multiple Dart files.

---

# 24. Flutter Request

Use existing Dio/http infrastructure.

Example:

```dart
final response = await dio.post(
  '$backendUrl/api/extract',
  data: {
    'url': socialUrl,
  },
);
```

Expected response:

```json
{
  "success": true,
  "platform": "instagram",
  "title": "...",
  "thumbnail": "...",
  "type": "video",
  "media_url": "https://..."
}
```

Map this into:

```text
DownloadedMediaResult
```

so the current download UI continues to work.

---

# 25. Existing Home UI Must Stay

The current Home UI already has:

```text
URL input
Paste
Download
Supported Socials
Facebook
Instagram
WhatsApp
Pinterest
```

Do not replace it.

The current Download button already triggers extraction and then opens the download progress UI.

Only replace the extraction implementation underneath it.

---

# 26. Extraction Loading State

Keep the current loading behavior.

When extraction starts:

```text
Download button
      ↓
loading spinner
```

When extraction succeeds:

```text
open existing download progress dialog
```

When extraction fails:

```text
show clean SnackBar/error state
```

Do not introduce a completely different loading screen.

---

# 27. Download Progress

Keep the existing progress dialog style.

Current intended flow:

```text
Downloading Media...
0%
25%
50%
75%
100%
Download Complete!
```

Use the existing UI.

Improve only the underlying completion handling if necessary.

---

# 28. IMPORTANT — Await Actual Download

Do not consider a download complete merely because:

```text
progress == 100%
```

The download function should complete successfully.

Then verify:

```text
file exists
AND
file size > 0
```

Only after that show:

```text
Download Complete!
```

---

# 29. File Naming

Use safe filenames.

Example:

```text
instagram_20260907_123456.jpg
instagram_20260907_123456.mp4
pinterest_20260907_123456.jpg
facebook_20260907_123456.mp4
```

Avoid unsafe filesystem characters from titles.

If title is unavailable, use timestamp.

---

# 30. Download Metadata

The Downloads tab should eventually know:

```json
{
  "filePath": "...",
  "platform": "instagram",
  "type": "video",
  "title": "Example",
  "createdAt": "..."
}
```

This allows the Downloads screen to correctly filter:

```text
WhatsApp
Instagram
Facebook
Pinterest
```

Do not rely only on:

```text
.mp4
.jpg
.png
```

because extension does not tell which platform the file came from.

---

# 31. Downloads Tab

Do not redesign the existing Downloads screen.

Only fix its data layer if necessary so platform filtering uses stored metadata.

Existing bottom navigation should remain unchanged:

```text
Home
Shorts
Watch Videos
Downloads
```

---

# 32. Error Contract

Backend errors must be predictable.

Use:

```json
{
  "success": false,
  "error": "EXTRACTION_FAILED",
  "message": "Unable to extract media from this URL."
}
```

Possible errors:

```text
INVALID_URL
UNSUPPORTED_PLATFORM
UNSUPPORTED_URL
PRIVATE_CONTENT
LOGIN_REQUIRED
MEDIA_NOT_FOUND
EXTRACTION_FAILED
TIMEOUT
RATE_LIMITED
SERVER_ERROR
```

Flutter should show user-friendly messages.

Never display Python stack traces to users.

---

# 33. Extraction Timeout

Use a reasonable extraction timeout around:

```text
20–30 seconds
```

Test and adjust if necessary.

Flutter should show an understandable timeout message.

---

# 34. FastAPI Concurrency

yt-dlp extraction is synchronous work.

Do not block the FastAPI event loop unnecessarily.

Run synchronous extraction through an appropriate worker/thread mechanism.

Conceptually:

```text
Request
   ↓
FastAPI
   ↓
worker thread
   ↓
yt-dlp
   ↓
normalized result
```

---

# 35. Security / SSRF

Because the backend accepts URLs, protect the endpoint.

Validate:

- scheme
- hostname
- malformed URLs
- localhost/private network targets where appropriate

Do not allow the API to become a general-purpose SSRF proxy.

Do not fetch arbitrary internal services.

---

# 36. Rate Limiting

Before production, add basic rate limiting.

Example:

```text
IP → requests per minute
```

Return:

```http
429 Too Many Requests
```

when exceeded.

---

# 37. Logging

Server logs should include:

```text
timestamp
request id
platform
hostname
success/failure
processing time
error category
```

Never log:

- passwords
- private cookies
- authentication tokens
- sensitive data

---

# 38. yt-dlp Maintenance

Social platforms change frequently.

Keep yt-dlp updated:

```bash
python -m pip install -U yt-dlp
```

The backend should be designed so yt-dlp can be updated without changing the Flutter UI.

---

# 39. Testing Requirements

Do real end-to-end tests.

## Instagram

Test:

- public image post
- public Reel
- public video
- public carousel if supported

Verify:

```text
URL
→ extraction
→ media URL
→ Flutter
→ Dio
→ saved file
```

## Facebook

Test:

- public video
- public supported post

## Pinterest

Test:

- normal Pin URL
- pin.it short URL
- image Pin
- video Pin

## WhatsApp

Test only actual public/shared URL formats supported by the extractor.

If unsupported, verify clean error handling instead of pretending it works.

---

# 40. Negative Tests

Test:

- empty input
- invalid URL
- unsupported URL
- private content
- deleted content
- login-required content
- expired media URL
- extraction timeout
- backend offline
- rate limit
- malformed backend response

The app must not crash.

---

# 41. Backend Offline Behavior

If Flutter cannot connect to FastAPI:

Show a clean message such as:

```text
Unable to connect to download service.
Please try again.
```

Do not show raw Dio exceptions.

---

# 42. Existing Translation System

The app already uses the multilingual package and `.trans()` strings.

Do not remove the multilingual system.

If new user-facing strings are added, add translation keys through the existing translation system rather than hardcoding every new message.

Preserve current language switching behavior.

---

# 43. Existing Theme

Preserve:

- light theme
- dark theme
- existing `ThemeController`
- existing accent colors
- existing app colors

Do not introduce a separate downloader theme.

---

# 44. Files That Should Primarily Change

Prefer changes to:

```text
lib/services/media_downloader_service.dart
```

and, only when necessary:

```text
lib/home_tab.dart
```

or the relevant download metadata/storage layer.

Backend files:

```text
media-downloader-backend/app/main.py
media-downloader-backend/app/extractor.py
media-downloader-backend/app/models.py
media-downloader-backend/app/utils.py
```

Do not unnecessarily modify:

```text
MainScreen
SplashScreen
ShortsTab
WatchTab
theme system
navigation
```

---

# 45. Do Not Break Existing Navigation

The existing MainScreen uses:

```text
HomeTab
ShortsTab
WatchTab
DownloadsTab
```

Keep all four.

Do not replace the navigation architecture.

---

# 46. Development Test Flow

Start backend:

```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Check:

```text
GET /health
```

Then test:

```text
POST /api/extract
```

before connecting Flutter.

After backend extraction works:

```text
Backend
   ↓
Flutter
```

Then test:

```text
Flutter
   ↓
Dio
   ↓
file
```

---

# 47. Important Product Limitation

The requirement is:

> User should be able to paste a WhatsApp, Instagram, Facebook, or Pinterest post/shared URL and download supported public media.

This does NOT mean every URL from every platform is technically guaranteed to work.

Actual support depends on:

- platform URL type
- public/private state
- current platform behavior
- yt-dlp extractor support
- temporary media URLs
- platform changes

The implementation must report unsupported cases clearly instead of returning fake success.

---

# 48. Future Third-Party Fallbacks

The backend should be written so yt-dlp is not permanently the only extractor.

Future architecture:

```text
Extractor Router
      |
      ├── yt-dlp
      |
      ├── Cobalt
      |
      ├── third-party API
      |
      └── future extractor
```

Example:

```text
try yt-dlp
    ↓ fail
try secondary extractor
    ↓ fail
return clean error
```

Do not put third-party API keys inside Flutter.

---

# 49. API Stability

Flutter should depend only on the normalized API contract.

For example:

```json
{
  "success": true,
  "platform": "instagram",
  "title": "...",
  "thumbnail": "...",
  "type": "video",
  "media_url": "https://..."
}
```

This means the extraction engine can later change from:

```text
yt-dlp
```

to:

```text
yt-dlp + Cobalt + other provider
```

without redesigning the Flutter application.

---

# 50. Definition of Done

The implementation is complete only when:

- [ ] Python FastAPI backend runs
- [ ] `/health` works
- [ ] `/api/extract` works
- [ ] yt-dlp is integrated
- [ ] Instagram public media tested
- [ ] Facebook public media tested
- [ ] Pinterest public media tested
- [ ] WhatsApp supported URL format tested OR cleanly reported unsupported
- [ ] Response is normalized
- [ ] Flutter calls backend
- [ ] Existing `DownloadedMediaResult` flow still works
- [ ] Existing Home UI remains visually intact
- [ ] Existing Download button remains
- [ ] Existing progress dialog remains
- [ ] Dio download works
- [ ] File existence/size is verified
- [ ] Correct extension is used
- [ ] Errors are user-friendly
- [ ] Backend timeout is handled
- [ ] Backend offline state is handled
- [ ] No private/login/DRM bypass exists
- [ ] SSRF risk is addressed
- [ ] Rate limiting is considered
- [ ] Downloads metadata stores platform
- [ ] Downloads filtering can use platform metadata
- [ ] No unrelated tabs/navigation are broken

---

# 51. Final Expected User Experience

The final user experience should remain simple:

```text
┌──────────────────────────────────┐
│          Media Downloader        │
│                                  │
│  Paste Instagram/Facebook/...    │
│  [ 🔗  Paste URL             ]   │
│                                  │
│  [ Paste ]       [ Download ]    │
│                                  │
│       Supported Socials          │
│                                  │
│   Facebook       Instagram       │
│   WhatsApp       Pinterest       │
│                                  │
└──────────────────────────────────┘
```

User action:

```text
Paste URL
    ↓
Tap Download
    ↓
"Processing..."
    ↓
Media extracted
    ↓
"Downloading Media..."
    ↓
0% → 100%
    ↓
"Download Complete!"
```

The UI should feel like the current application, not like a newly redesigned application.

---

# 52. Final Completion Message

After implementation and testing, report exactly:

```text
MEDIA DOWNLOADER — YT-DLP INTEGRATION COMPLETE
```

Then provide:

1. Backend start command
2. Backend URL
3. Tested platform results
4. Unsupported/limited URL types
5. Flutter files changed
6. Backend files created/changed
7. Dependencies installed
8. Any remaining limitations
