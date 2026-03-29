import re

from pydantic import BaseModel, Field, field_validator

# Avoid pydantic EmailStr — it requires the optional `email-validator` package at import time.
_EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class UserRegisterRequest(BaseModel):
    """Create user in Firebase Auth and MySQL (email/password)."""

    email: str = Field(..., min_length=3, max_length=255)
    password: str = Field(..., min_length=8, max_length=72)
    full_name: str = Field(..., min_length=1, max_length=255)

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email(cls, v: object) -> str:
        if not isinstance(v, str):
            raise ValueError("email must be a string")
        s = v.strip().lower()
        if not s or not _EMAIL_PATTERN.fullmatch(s):
            raise ValueError("invalid email address")
        return s


class UserPublic(BaseModel):
    """Minimal user payload for chat / listings context."""

    id: int
    full_name: str
    profile_image_url: str | None = None

    model_config = {"from_attributes": True}
