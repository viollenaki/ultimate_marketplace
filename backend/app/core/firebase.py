"""Firebase Admin SDK initialization (lazy)."""
import logging
from pathlib import Path

import firebase_admin
from firebase_admin import credentials

from app.core.config import settings

logger = logging.getLogger(__name__)


def _resolve_credentials_path() -> Path:
    """
    Resolve service account JSON path.

    Tries the configured path as-is, then relative to the backend project root
    (parent of the `app` package) so it works even when cwd is not `/app`.
    """
    raw = Path(settings.FIREBASE_CREDENTIALS_PATH)
    if raw.is_file():
        return raw.resolve()

    backend_root = Path(__file__).resolve().parents[2]
    candidate = backend_root / settings.FIREBASE_CREDENTIALS_PATH
    if candidate.is_file():
        return candidate.resolve()

    raise FileNotFoundError(
        f"Firebase credentials not found. Tried {raw.resolve()} and {candidate}"
    )


def firebase_credentials_resolvable() -> bool:
    """True if [FIREBASE_CREDENTIALS_PATH] points to an existing service account JSON."""
    try:
        _resolve_credentials_path()
        return True
    except FileNotFoundError:
        return False


def ensure_firebase_initialized() -> None:
    """Initialize the default Firebase app once using the service account JSON."""
    if firebase_admin._apps:
        return
    path = _resolve_credentials_path()
    cred = credentials.Certificate(str(path))
    if settings.FIREBASE_STORAGE_BUCKET:
        firebase_admin.initialize_app(
            cred,
            {"storageBucket": settings.FIREBASE_STORAGE_BUCKET},
        )
    else:
        firebase_admin.initialize_app(cred)
    logger.info(
        "Firebase Admin SDK initialized (credentials: %s, storageBucket=%s)",
        path,
        settings.FIREBASE_STORAGE_BUCKET or "(none)",
    )
