from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.user import UserPublic


class ConversationCreateRequest(BaseModel):
    """Start or reopen a 1:1 conversation."""

    other_user_id: int = Field(..., ge=1)
    listing_id: int | None = Field(
        default=None,
        description="If set, must involve the listing owner as one participant.",
    )


class ConversationResponse(BaseModel):
    id: int
    listing_id: int | None
    participant_a_id: int
    participant_b_id: int
    other_user: UserPublic
    last_message_at: datetime | None
    last_message_preview: str | None
    created_at: datetime | None

    model_config = {"from_attributes": True}


class ConversationListResponse(BaseModel):
    conversations: list[ConversationResponse]
