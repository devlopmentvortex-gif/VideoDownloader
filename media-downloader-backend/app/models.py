from typing import List, Literal, Optional

from pydantic import BaseModel, Field


class ExtractRequest(BaseModel):
    url: str = Field(..., min_length=1)


class MediaItem(BaseModel):
    type: Literal["image", "video", "audio"]
    media_url: str
    thumbnail: Optional[str] = None


class ExtractSuccess(BaseModel):
    success: Literal[True] = True
    platform: str
    title: str
    thumbnail: Optional[str] = None
    type: Literal["image", "video", "audio", "carousel"]
    media_url: Optional[str] = None
    items: Optional[List[MediaItem]] = None


class ExtractError(BaseModel):
    success: Literal[False] = False
    error: str
    message: str
