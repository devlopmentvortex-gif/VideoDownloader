# Media Downloader Backend

Python FastAPI service that extracts publicly accessible media metadata using yt-dlp.

Supported platforms:

- Instagram
- Facebook
- Pinterest
- WhatsApp (public/shared URLs only)

The backend extracts media information. The Flutter app downloads files directly.

## Start

```bash
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Endpoints

```http
GET /health
POST /api/extract
```

`POST /api/extract` body:

```json
{
  "url": "https://example.com/post"
}
```

Private, login-required, DRM, or paywalled content is rejected with a clean error.
