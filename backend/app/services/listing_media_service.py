"""Listing image uploads to Firebase Storage + MySQL rows."""
import asyncio
import logging

from fastapi import UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import AppException
from app.models import ListingMedia
from app.repositories.listing_media_repository import ListingMediaRepository
from app.repositories.listing_repository import ListingRepository
from app.services.firebase_storage_service import upload_listing_image_bytes

logger = logging.getLogger(__name__)


class ListingMediaService:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session
        self._listings = ListingRepository()
        self._media = ListingMediaRepository()

    async def upload_listing_image(
        self,
        *,
        owner_id: int,
        listing_id: int,
        file: UploadFile,
    ) -> ListingMedia:
        listing = await self._listings.get_owned(
            self._session, listing_id, owner_id
        )
        if listing is None:
            raise AppException(404, "Listing not found or access denied")

        data = await file.read()
        max_b = settings.LISTING_MEDIA_MAX_BYTES
        if len(data) > max_b:
            raise AppException(
                400,
                f"File too large (max {max_b // (1024 * 1024)} MB)",
            )
        if len(data) == 0:
            raise AppException(400, "Empty file")

        filename = file.filename or "image.jpg"
        content_type = file.content_type or "image/jpeg"

        try:
            bucket, path, url = await asyncio.to_thread(
                upload_listing_image_bytes,
                listing_id=listing_id,
                data=data,
                original_filename=filename,
                content_type=content_type,
            )
        except ValueError as e:
            raise AppException(400, str(e)) from e
        except Exception as e:
            logger.exception("Firebase Storage upload failed")
            raise AppException(
                503,
                "Could not store file; check Storage rules and credentials",
            ) from e

        count = await self._media.count_for_listing(self._session, listing_id)
        order_index = await self._media.next_order_index(self._session, listing_id)
        is_primary = count == 0

        ct = content_type.split(";")[0].strip()
        media = await self._media.create(
            self._session,
            listing_id=listing_id,
            file_url=url,
            storage_bucket=bucket,
            storage_path=path,
            content_type=ct,
            file_size=len(data),
            order_index=order_index,
            is_primary=is_primary,
        )
        await self._session.commit()
        await self._session.refresh(media)
        return media
