from pydantic import BaseModel, ConfigDict, Field, computed_field


class ListingMediaResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    listing_id: int
    storage_bucket: str | None = None
    storage_path: str | None = None
    content_type: str | None = None
    file_size: int | None = None
    file_url: str = Field(..., description="HTTPS URL for Image.network / browsers")
    order_index: int = 0
    is_primary: bool = False

    @computed_field
    @property
    def gs_uri(self) -> str | None:
        if self.storage_bucket and self.storage_path:
            return f"gs://{self.storage_bucket}/{self.storage_path}"
        return None
