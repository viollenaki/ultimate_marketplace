from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.media import ListingMediaResponse
from app.schemas.user import UserPublic


class ListingCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: str = Field(..., min_length=1)
    price: float = Field(..., gt=0)
    currency: str = Field(default="KGS", max_length=10)
    city: str = Field(..., min_length=1, max_length=100)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)
    location_display_name: str | None = Field(default=None, max_length=255)

    brand: str = Field(..., min_length=1, max_length=100)
    model: str = Field(..., min_length=1, max_length=100)
    year: int = Field(..., ge=1900, le=2100)
    mileage: int = Field(..., ge=0)
    fuel_type: str | None = Field(default=None, max_length=30)
    transmission: str | None = Field(default=None, max_length=30)
    body_type: str | None = Field(default=None, max_length=50)
    color: str | None = Field(default=None, max_length=50)
    engine_volume: float | None = None
    horsepower: int | None = None
    doors: int | None = None
    is_crashed: bool = False
    has_warranty: bool = False


class ListingUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = Field(default=None, min_length=1)
    price: float | None = Field(default=None, gt=0)
    currency: str | None = Field(default=None, max_length=10)
    city: str | None = Field(default=None, min_length=1, max_length=100)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)
    location_display_name: str | None = Field(default=None, max_length=255)

    brand: str | None = Field(default=None, min_length=1, max_length=100)
    model: str | None = Field(default=None, min_length=1, max_length=100)
    year: int | None = Field(default=None, ge=1900, le=2100)
    mileage: int | None = Field(default=None, ge=0)
    fuel_type: str | None = Field(default=None, max_length=30)
    transmission: str | None = Field(default=None, max_length=30)
    body_type: str | None = Field(default=None, max_length=50)
    color: str | None = Field(default=None, max_length=50)
    engine_volume: float | None = None
    horsepower: int | None = None
    doors: int | None = None
    is_crashed: bool | None = None
    has_warranty: bool | None = None


class ListingResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    owner_id: int
    title: str
    description: str
    price: float
    currency: str
    city: str
    latitude: float | None = None
    longitude: float | None = None
    location_display_name: str | None = None
    brand: str
    model: str
    year: int
    mileage: int
    fuel_type: str | None = None
    transmission: str | None = None
    body_type: str | None = None
    color: str | None = None
    engine_volume: float | None = None
    horsepower: int | None = None
    doors: int | None = None
    is_crashed: bool = False
    has_warranty: bool = False
    status: str
    moderation_status: str
    view_count: int = 0
    media: list[ListingMediaResponse] = Field(default_factory=list)
    owner: UserPublic | None = None

    @field_validator("media", mode="before")
    @classmethod
    def _default_media(cls, v: object) -> object:
        return v if v is not None else []


class ListingListResponse(BaseModel):
    items: list[ListingResponse]
    total: int


class FavoriteListingIdsResponse(BaseModel):
    listing_ids: list[int]
