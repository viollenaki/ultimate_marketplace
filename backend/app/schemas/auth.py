from pydantic import BaseModel, Field


class FirebaseLoginRequest(BaseModel):
    id_token: str = Field(..., min_length=1, description="Firebase ID token from client SDK")


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = Field(..., description="Access token lifetime in seconds")


class CurrentUserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    firebase_uid: str | None
    account_status: str
