import ipaddress
import re
import socket
from urllib.parse import urlparse


SUPPORTED_PLATFORMS = {
    "instagram": (
        "instagram.com",
        "www.instagram.com",
        "m.instagram.com",
        "instagr.am",
    ),
    "facebook": (
        "facebook.com",
        "www.facebook.com",
        "m.facebook.com",
        "fb.watch",
        "fb.com",
        "www.fb.com",
        "web.facebook.com",
        "mbasic.facebook.com",
    ),
    "pinterest": (
        "pinterest.com",
        "www.pinterest.com",
        "pin.it",
        "www.pin.it",
        "pinterest.co.uk",
        "www.pinterest.co.uk",
        "pinterest.ca",
        "www.pinterest.ca",
        "pinterest.fr",
        "www.pinterest.fr",
        "pinterest.de",
        "www.pinterest.de",
        "pinterest.es",
        "www.pinterest.es",
        "pinterest.it",
        "www.pinterest.it",
        "pinterest.com.au",
        "www.pinterest.com.au",
        "pinterest.jp",
        "www.pinterest.jp",
        "pinterest.in",
        "www.pinterest.in",
    ),
    "whatsapp": (
        "whatsapp.com",
        "www.whatsapp.com",
        "web.whatsapp.com",
        "wa.me",
        "www.wa.me",
        "chat.whatsapp.com",
        "api.whatsapp.com",
    ),
}

_HOST_TO_PLATFORM = {
    host: platform
    for platform, hosts in SUPPORTED_PLATFORMS.items()
    for host in hosts
}

_PRIVATE_NETWORKS = (
    ipaddress.ip_network("10.0.0.0/8"),
    ipaddress.ip_network("127.0.0.0/8"),
    ipaddress.ip_network("169.254.0.0/16"),
    ipaddress.ip_network("172.16.0.0/12"),
    ipaddress.ip_network("192.168.0.0/16"),
    ipaddress.ip_network("::1/128"),
    ipaddress.ip_network("fc00::/7"),
    ipaddress.ip_network("fe80::/10"),
)

_BLOCKED_HOSTS = {
    "localhost",
    "localhost.localdomain",
    "ip6-localhost",
    "ip6-loopback",
    "metadata.google.internal",
    "metadata",
}


class ApiError(Exception):
    def __init__(self, code: str, message: str, status_code: int = 400):
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code


def _strip_www(host: str) -> str:
    return host[4:] if host.startswith("www.") else host


def detect_platform(url: str) -> str | None:
    parsed = urlparse(url)
    host = (parsed.hostname or "").lower().rstrip(".")
    if not host:
        return None
    if host in _HOST_TO_PLATFORM:
        return _HOST_TO_PLATFORM[host]
    bare = _strip_www(host)
    if bare in _HOST_TO_PLATFORM:
        return _HOST_TO_PLATFORM[bare]
    for platform, hosts in SUPPORTED_PLATFORMS.items():
        for known in hosts:
            known_bare = _strip_www(known)
            if host == known or host.endswith("." + known_bare):
                return platform
    return None


def _is_private_ip(ip_str: str) -> bool:
    try:
        ip = ipaddress.ip_address(ip_str)
    except ValueError:
        return True
    if ip.is_private or ip.is_loopback or ip.is_link_local or ip.is_reserved:
        return True
    if ip.is_multicast or ip.is_unspecified:
        return True
    return any(ip in network for network in _PRIVATE_NETWORKS)


def _hostname_is_blocked(hostname: str) -> bool:
    host = hostname.lower().rstrip(".")
    if host in _BLOCKED_HOSTS:
        return True
    if host.endswith(".local") or host.endswith(".internal"):
        return True
    try:
        ip = ipaddress.ip_address(host)
        return _is_private_ip(str(ip))
    except ValueError:
        return False


def _resolve_is_private(hostname: str) -> bool:
    try:
        infos = socket.getaddrinfo(hostname, None)
    except socket.gaierror:
        return False
    for info in infos:
        sockaddr = info[4]
        if sockaddr:
            ip_str = sockaddr[0]
            if "%" in ip_str:
                ip_str = ip_str.split("%", 1)[0]
            if _is_private_ip(ip_str):
                return True
    return False


def validate_url(raw_url: str) -> str:
    if raw_url is None:
        raise ApiError("INVALID_URL", "URL is required.")
    url = raw_url.strip()
    if not url:
        raise ApiError("INVALID_URL", "URL is required.")
    if "://" not in url:
        url = "https://" + url

    parsed = urlparse(url)
    if parsed.scheme not in ("http", "https"):
        raise ApiError("INVALID_URL", "URL must use HTTP or HTTPS.")
    hostname = (parsed.hostname or "").strip().lower().rstrip(".")
    if not hostname or "." not in hostname:
        raise ApiError("INVALID_URL", "URL is not valid.")
    if parsed.username or parsed.password:
        raise ApiError("INVALID_URL", "URL is not valid.")
    if re.search(r"[\s<>\"'\\]", url):
        raise ApiError("INVALID_URL", "URL is not valid.")
    if _hostname_is_blocked(hostname):
        raise ApiError("INVALID_URL", "URL is not valid.")
    if _resolve_is_private(hostname):
        raise ApiError("INVALID_URL", "URL is not valid.")
    return url


def classify_ytdlp_error(exc: BaseException, platform: str | None) -> ApiError:
    text = str(exc).lower()
    if (
        "empty media response" in text
        or "cookies" in text
        or "login required" in text
        or "sign in" in text
        or "not accessible" in text
    ):
        return ApiError(
            "PRIVATE_CONTENT",
            "This media is private or requires login.",
            status_code=403,
        )
    if "private" in text:
        return ApiError(
            "PRIVATE_CONTENT",
            "This media is private or requires login.",
            status_code=403,
        )
    if "unavailable" in text or "not found" in text or "does not exist" in text:
        return ApiError("MEDIA_NOT_FOUND", "Media was not found for this URL.")
    if "unsupported url" in text or "no video formats" in text:
        if platform == "whatsapp":
            return ApiError(
                "UNSUPPORTED_URL",
                "This WhatsApp URL cannot be resolved as public media.",
            )
        return ApiError(
            "UNSUPPORTED_URL",
            "This URL cannot be resolved as public media.",
        )
    if "timed out" in text or "timeout" in text:
        return ApiError(
            "TIMEOUT",
            "Extraction timed out. Please try again.",
            status_code=504,
        )
    if platform == "whatsapp":
        return ApiError(
            "UNSUPPORTED_URL",
            "This WhatsApp URL cannot be resolved as public media.",
        )
    return ApiError("EXTRACTION_FAILED", "Unable to extract media from this URL.")
