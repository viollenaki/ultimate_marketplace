from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.user import UserPublic


class MessageCreateRequest(BaseModel):
    text_body: str = Field(..., min_length=1, max_length=8000)


class MessageResponse(BaseModel):
    id: int
    conversation_id: int
    sender_id: int
    sender: UserPublic
    text_body: str | None
    is_read: bool
    sent_at: datetime | None

    model_config = {"from_attributes": True}


class MessageListResponse(BaseModel):
    messages: list[MessageResponse]
    next_before_id: int | None = Field(
        default=None,
        description="Pass as `before_id` to fetch older messages.",
    )
