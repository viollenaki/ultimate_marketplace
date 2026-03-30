from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

LISTING_REPORT_REASON_CODES = frozenset(
    {
        "spam",
        "scam",
        "misleading_info",
        "duplicate",
        "offensive",
        "other",
    }
)


class ListingReportCreate(BaseModel):
    reason_code: str = Field(..., min_length=1, max_length=50)
    reason_details: str | None = Field(default=None, max_length=2000)


class ListingReportCreatedResponse(BaseModel):
    id: int
    listing_id: int


class AdminListingReportRow(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    listing_id: int
    reporter_user_id: int
    reporter_email: str | None = None
    reason_code: str
    reason_text: str | None = None
    status: str
    created_at: datetime | None = None


class AdminListingReportAggregate(BaseModel):
    listing_id: int
    report_count: int
    last_reported_at: datetime | None
    listing_title: str | None = None
    listing_owner_id: int | None = None


class AdminListingReportsListResponse(BaseModel):
    items: list[AdminListingReportRow]
    total: int


class AdminListingReportAggregatesResponse(BaseModel):
    items: list[AdminListingReportAggregate]


class AdminReportedListingRow(BaseModel):
    """Listing row with aggregated report counts (moderation inbox)."""

    listing_id: int
    title: str
    owner_id: int
    city: str
    status: str
    price: float
    currency: str
    report_count: int
    pending_report_count: int
    last_report_at: datetime | None = None


class AdminReportedListingsResponse(BaseModel):
    items: list[AdminReportedListingRow]
    total: int
