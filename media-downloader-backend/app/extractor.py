import logging
import re
from typing import Any
from urllib.request import Request, urlopen

import yt_dlp

from app.utils import ApiError, classify_ytdlp_error, detect_platform

logger = logging.getLogger("media-downloader")

VIDEO_EXTS = {"mp4", "webm", "mkv", "mov", "m4v", "3gp"}
AUDIO_EXTS = {"mp3", "m4a", "aac", "wav", "ogg", "opus", "flac"}
IMAGE_EXTS = {"jpg", "jpeg", "png", "webp", "gif", "bmp"}

YDL_OPTS = {
    "quiet": True,
    "no_warnings": True,
    "noplaylist": False,
    "skip_download": True,
    "extract_flat": False,
    "format": "best[ext=mp4]/best",
    "socket_timeout": 20,
    "http_headers": {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/124.0.0.0 Safari/537.36"
        ),
        "Accept-Language": "en-US,en;q=0.9",
    },
}


def _ext_of(url: str | None) -> str:
    if not url:
        return ""
    path = url.split("?", 1)[0].rsplit(".", 1)
    if len(path) == 2:
        return path[1].lower()
    return ""


def _guess_type(entry: dict[str, Any], media_url: str | None) -> str:
    explicit = (entry.get("ext") or "").lower()
    if explicit in IMAGE_EXTS:
        return "image"
    if explicit in AUDIO_EXTS:
        return "audio"
    if explicit in VIDEO_EXTS:
        return "video"

    vcodec = (entry.get("vcodec") or "").lower()
    acodec = (entry.get("acodec") or "").lower()
    if vcodec in ("none", "images") or entry.get("_type") == "url":
        url_ext = _ext_of(media_url) or _ext_of(entry.get("url"))
        if url_ext in IMAGE_EXTS:
            return "image"
        if url_ext in AUDIO_EXTS:
            return "audio"
        if url_ext in VIDEO_EXTS:
            return "video"

    if vcodec and vcodec not in ("none",):
        return "video"
    if acodec and acodec not in ("none",):
        return "audio"

    url_ext = _ext_of(media_url)
    if url_ext in IMAGE_EXTS:
        return "image"
    if url_ext in AUDIO_EXTS:
        return "audio"
    if entry.get("duration") or entry.get("fps") or entry.get("width"):
        return "video"
    return "video"


def _pick_format_url(entry: dict[str, Any]) -> str | None:
    if entry.get("url") and not entry.get("formats"):
        return entry["url"]

    formats = entry.get("formats") or []
    if not formats:
        return entry.get("url") or entry.get("webpage_url")

    def score(fmt: dict[str, Any]) -> tuple:
        has_video = (fmt.get("vcodec") or "none") not in ("none", None, "")
        has_audio = (fmt.get("acodec") or "none") not in ("none", None, "")
        ext = (fmt.get("ext") or "").lower()
        height = fmt.get("height") or 0
        tbr = fmt.get("tbr") or 0
        protocol = (fmt.get("protocol") or "")
        is_http = 1 if protocol.startswith("http") else 0
        mp4_bonus = 1 if ext == "mp4" else 0
        image_penalty = 0 if ext in IMAGE_EXTS else 1
        return (
            image_penalty,
            int(has_video and has_audio),
            int(has_video),
            mp4_bonus,
            is_http,
            height,
            tbr,
        )

    usable = [f for f in formats if f.get("url")]
    if not usable:
        return entry.get("url")
    usable.sort(key=score, reverse=True)
    return usable[0]["url"]


def _entry_media_url(entry: dict[str, Any]) -> str | None:
    requested = entry.get("requested_formats")
    if requested:
        combined = next((f.get("url") for f in requested if f.get("url") and f.get("vcodec") not in (None, "none") and f.get("acodec") not in (None, "none")), None)
        if combined:
            return combined
        video = next((f.get("url") for f in requested if f.get("vcodec") not in (None, "none")), None)
        if video:
            return video
    url = entry.get("url")
    if url and not str(url).startswith("http"):
        url = None
    return url or _pick_format_url(entry)


def _thumbnail(entry: dict[str, Any]) -> str | None:
    thumb = entry.get("thumbnail")
    if thumb:
        return thumb
    thumbs = entry.get("thumbnails") or []
    if thumbs:
        last = thumbs[-1]
        if isinstance(last, dict):
            return last.get("url")
        return str(last)
    return None


def _normalize_entry(entry: dict[str, Any]) -> dict[str, Any] | None:
    media_url = _entry_media_url(entry)
    if not media_url:
        return None
    media_type = _guess_type(entry, media_url)
    return {
        "type": media_type,
        "media_url": media_url,
        "thumbnail": _thumbnail(entry),
        "title": entry.get("title") or entry.get("id") or "Downloaded Media",
    }


def _entries_from_info(info: dict[str, Any]) -> list[dict[str, Any]]:
    if info.get("_type") == "playlist" or info.get("entries"):
        items = []
        for entry in info.get("entries") or []:
            if not entry:
                continue
            if entry.get("entries"):
                items.extend(_entries_from_info(entry))
                continue
            normalized = _normalize_entry(entry)
            if normalized:
                items.append(normalized)
        return items
    normalized = _normalize_entry(info)
    return [normalized] if normalized else []


def _http_get(url: str) -> tuple[str, str]:
    req = Request(url, headers=YDL_OPTS["http_headers"])
    with urlopen(req, timeout=20) as response:
        final_url = response.geturl()
        body = response.read(1_000_000).decode("utf-8", "ignore")
    return final_url, body


def _pinterest_from_html(url: str) -> dict[str, Any] | None:
    try:
        final_url, html = _http_get(url)
    except Exception:
        return None

    title_match = re.search(r"<title>([^<]+)</title>", html, re.IGNORECASE)
    title = (title_match.group(1).strip() if title_match else "Pinterest Pin")[:180]

    originals = re.findall(
        r"https://i\.pinimg\.com/(?:originals|736x)/[^\"'\\s)]+",
        html,
    )
    videos = re.findall(
        r"https://v(?:ideos)?\.pinimg\.com/[^\"'\\s)]+\.mp4",
        html,
    )
    media_url = None
    media_type = "image"
    if videos:
        media_url = videos[0]
        media_type = "video"
    elif originals:
        media_url = originals[0]
        if media_url.lower().endswith((".mp4", ".webm", ".mov")):
            media_type = "video"
    if not media_url:
        return None
    return {
        "success": True,
        "platform": "pinterest",
        "title": title,
        "thumbnail": media_url,
        "type": media_type,
        "media_url": media_url,
        "source_url": final_url,
    }


def extract_media(url: str) -> dict[str, Any]:
    platform = detect_platform(url)
    if platform is None:
        raise ApiError(
            "UNSUPPORTED_PLATFORM",
            "This platform is not supported. Use Instagram, Facebook, Pinterest, or WhatsApp.",
        )

    ytdlp_error: Exception | None = None
    try:
        with yt_dlp.YoutubeDL(YDL_OPTS) as ydl:
            info = ydl.extract_info(url, download=False)
    except yt_dlp.utils.DownloadError as exc:
        ytdlp_error = exc
        info = None
    except Exception as exc:
        logger.exception("extraction failed")
        ytdlp_error = exc
        info = None

    if info is None:
        if platform == "pinterest":
            fallback = _pinterest_from_html(url)
            if fallback:
                fallback.pop("source_url", None)
                return fallback
        if ytdlp_error is not None:
            raise classify_ytdlp_error(ytdlp_error, platform)
        raise ApiError("MEDIA_NOT_FOUND", "Media was not found for this URL.")

    if not info:
        raise ApiError("MEDIA_NOT_FOUND", "Media was not found for this URL.")

    items = _entries_from_info(info)
    if not items:
        if platform == "whatsapp":
            raise ApiError(
                "UNSUPPORTED_URL",
                "This WhatsApp URL cannot be resolved as public media.",
            )
        raise ApiError("EXTRACTION_FAILED", "Unable to extract media from this URL.")

    title = info.get("title") or items[0]["title"] or "Downloaded Media"
    thumbnail = _thumbnail(info) or items[0].get("thumbnail")

    if len(items) == 1:
        item = items[0]
        return {
            "success": True,
            "platform": platform,
            "title": title,
            "thumbnail": thumbnail or item.get("thumbnail"),
            "type": item["type"],
            "media_url": item["media_url"],
        }

    return {
        "success": True,
        "platform": platform,
        "title": title,
        "thumbnail": thumbnail,
        "type": "carousel",
        "items": [
            {
                "type": item["type"],
                "media_url": item["media_url"],
                "thumbnail": item.get("thumbnail"),
            }
            for item in items
        ],
    }
