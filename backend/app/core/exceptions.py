"""Application-level exceptions (mapped to HTTP responses in routers/deps)."""


class AppException(Exception):
    """Business / auth error with HTTP status and public message."""

    def __init__(self, status_code: int, error: str) -> None:
        self.status_code = status_code
        self.error = error
        super().__init__(error)
