from pydantic import BaseModel, Field


class FcmTokenRegister(BaseModel):
    """Client registers/refreshes its FCM registration token after login."""

    token: str = Field(..., min_length=10, max_length=512)
    platform: str | None = Field(
        default=None,
        max_length=20,
        description="e.g. android, ios",
    )


class FcmTestPushBody(BaseModel):
    """Optional override for manual test push to the caller's devices."""

    title: str = Field(default="Test", max_length=200)
    body: str = Field(default="Push works", max_length=500)
    data_type: str = Field(default="test", max_length=50)
    data_id: str = Field(default="0", max_length=64)
