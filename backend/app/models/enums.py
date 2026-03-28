from enum import Enum


class UserStatus(str, Enum):
    active = "active"
    pending_verification = "pending_verification"
    suspended = "suspended"
    deleted = "deleted"


class ListingStatus(str, Enum):
    draft = "draft"
    pending_review = "pending_review"
    approved = "approved"
    rejected = "rejected"
    archived = "archived"
    inactive = "inactive"
    sold = "sold"


class PaymentStatus(str, Enum):
    pending = "pending"
    successful = "successful"
    failed = "failed"
    cancelled = "cancelled"
    refunded = "refunded"


class ReportStatus(str, Enum):
    pending = "pending"
    reviewed = "reviewed"
    dismissed = "dismissed"
    resolved = "resolved"


class PromotionType(str, Enum):
    featured = "featured"
    boosted = "boosted"
    top_of_feed = "top_of_feed"
    targeted = "targeted"


class FuelType(str, Enum):
    petrol = "petrol"
    diesel = "diesel"
    electric = "electric"
    hybrid = "hybrid"
    lpg = "lpg"
    other = "other"


class TransmissionType(str, Enum):
    manual = "manual"
    automatic = "automatic"
    cvt = "cvt"
    semi_automatic = "semi_automatic"


class BodyType(str, Enum):
    sedan = "sedan"
    suv = "suv"
    hatchback = "hatchback"
    coupe = "coupe"
    convertible = "convertible"
    pickup = "pickup"
    minivan = "minivan"
    wagon = "wagon"
    other = "other"
