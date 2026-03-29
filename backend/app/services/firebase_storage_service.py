"""Upload objects to Firebase Storage (sync; call via asyncio.to_thread)."""
from __future__ import annotations

import logging
import uuid
from datetime import timedelta
from urllib.parse import quote

from firebase_admin import storage

from app.core.config import settings
from app.core.firebase import ensure_firebase_initialized

logger = logging.getLogger(__name__)

_ALLOWED_EXT = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".heic"}
_ALLOWED_CT = {
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/gif",
    "image/heic",
    "image/heif",
}


def _guess_extension(filename: str, content_type: str) -> str:
    ext = ""
    if "." in filename:
        ext = "." + filename.rsplit(".", 1)[-1].lower()[:12]
        if ext not in _ALLOWED_EXT:
            ext = ""
    if not ext:
        if "png" in content_type:
            return ".png"
        if "webp" in content_type:
            return ".webp"
        if "gif" in content_type:
            return ".gif"
        if "heic" in content_type or "heif" in content_type:
            return ".heic"
        return ".jpg"
    return ext


def _firebase_download_url(bucket_name: str, object_path: str, token: str) -> str:
    enc = quote(object_path, safe="")
    return (
        f"https://firebasestorage.googleapis.com/v0/b/{bucket_name}/o/{enc}"
        f"?alt=media&token={token}"
    )


def upload_listing_image_bytes(
    *,
    listing_id: int,
    data: bytes,
    original_filename: str,
    content_type: str,
) -> tuple[str, str, str]:
    """
    Upload image bytes under listings/{listing_id}/...

    Returns (bucket_name, storage_path, download_url).
    """
    ensure_firebase_initialized()
    bucket_name = (settings.FIREBASE_STORAGE_BUCKET or "").strip()
    if not bucket_name:
        raise ValueError("FIREBASE_STORAGE_BUCKET is not configured")

    ct = (content_type or "application/octet-stream").split(";")[0].strip().lower()
    if ct not in _ALLOWED_CT:
        raise ValueError(f"Unsupported content type: {content_type}")

    ext = _guess_extension(original_filename or "image", ct)
    object_path = f"listings/{listing_id}/{uuid.uuid4().hex}{ext}"

    bucket = storage.bucket(bucket_name)
    blob = bucket.blob(object_path)
    blob.upload_from_string(data, content_type=ct)

    download_url: str
    try:
        token = str(uuid.uuid4())
        meta = dict(blob.metadata or {})
        meta["firebaseStorageDownloadTokens"] = token
        blob.metadata = meta
        blob.patch()
        download_url = _firebase_download_url(bucket_name, object_path, token)
    except Exception as e:
        logger.warning(
            "Could not set Firebase download token (%s); using signed URL",
            e,
        )
        download_url = blob.generate_signed_url(
            expiration=timedelta(days=365 * 7),
            method="GET",
        )

    return bucket_name, object_path, download_url
