import logging
import os
import time
import uuid
from collections import defaultdict, deque
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeout
from typing import Any

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.extractor import extract_media
from app.models import ExtractRequest
from app.utils import ApiError, detect_platform, validate_url

load_dotenv()

EXTRACT_TIMEOUT = int(os.getenv("EXTRACT_TIMEOUT_SECONDS", "25"))
RATE_LIMIT_PER_MINUTE = int(os.getenv("RATE_LIMIT_PER_MINUTE", "30"))
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()

logging.basicConfig(
    level=getattr(logging, LOG_LEVEL, logging.INFO),
    format="%(asctime)s %(levelname)s %(message)s",
)
logger = logging.getLogger("media-downloader")

app = FastAPI(title="media-downloader-backend")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_executor = ThreadPoolExecutor(max_workers=4)
_rate_buckets: dict[str, deque[float]] = defaultdict(deque)


def _client_ip(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


def _enforce_rate_limit(ip: str) -> None:
    now = time.time()
    window = 60.0
    bucket = _rate_buckets[ip]
    while bucket and now - bucket[0] > window:
        bucket.popleft()
    if len(bucket) >= RATE_LIMIT_PER_MINUTE:
        raise ApiError(
            "RATE_LIMITED",
            "Too many requests. Please try again later.",
            status_code=429,
        )
    bucket.append(now)


def _error_payload(code: str, message: str) -> dict[str, Any]:
    return {"success": False, "error": code, "message": message}


@app.exception_handler(RequestValidationError)
async def validation_handler(_request: Request, _exc: RequestValidationError) -> JSONResponse:
    return JSONResponse(
        _error_payload("INVALID_URL", "URL is required."),
        status_code=400,
    )


@app.get("/health")
def health() -> dict[str, Any]:
    return {"success": True, "service": "media-downloader-backend"}


@app.post("/api/extract")
def extract(payload: ExtractRequest, request: Request) -> JSONResponse:
    request_id = str(uuid.uuid4())
    started = time.time()
    platform = None
    hostname = None
    try:
        _enforce_rate_limit(_client_ip(request))
        url = validate_url(payload.url)
        from urllib.parse import urlparse

        hostname = urlparse(url).hostname
        platform = detect_platform(url)
        future = _executor.submit(extract_media, url)
        result = future.result(timeout=EXTRACT_TIMEOUT)
        elapsed_ms = int((time.time() - started) * 1000)
        logger.info(
            "request_id=%s platform=%s hostname=%s success=true processing_ms=%s",
            request_id,
            platform,
            hostname,
            elapsed_ms,
        )
        return JSONResponse(result)
    except FuturesTimeout:
        elapsed_ms = int((time.time() - started) * 1000)
        logger.info(
            "request_id=%s platform=%s hostname=%s success=false processing_ms=%s error=TIMEOUT",
            request_id,
            platform,
            hostname,
            elapsed_ms,
        )
        return JSONResponse(
            _error_payload("TIMEOUT", "Extraction timed out. Please try again."),
            status_code=504,
        )
    except ApiError as exc:
        elapsed_ms = int((time.time() - started) * 1000)
        logger.info(
            "request_id=%s platform=%s hostname=%s success=false processing_ms=%s error=%s",
            request_id,
            platform,
            hostname,
            elapsed_ms,
            exc.code,
        )
        return JSONResponse(
            _error_payload(exc.code, exc.message),
            status_code=exc.status_code,
        )
    except HTTPException:
        raise
    except Exception:
        elapsed_ms = int((time.time() - started) * 1000)
        logger.exception(
            "request_id=%s platform=%s hostname=%s success=false processing_ms=%s error=SERVER_ERROR",
            request_id,
            platform,
            hostname,
            elapsed_ms,
        )
        return JSONResponse(
            _error_payload("SERVER_ERROR", "Unable to extract media from this URL."),
            status_code=500,
        )
