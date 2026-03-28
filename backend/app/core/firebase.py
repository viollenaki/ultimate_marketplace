"""Firebase Admin SDK initialization (lazy)."""
import logging

import firebase_admin
from firebase_admin import credentials

from app.core.config import settings

logger = logging.getLogger(__name__)


def ensure_firebase_initialized() -> None:
    """Initialize the default Firebase app once using the service account JSON."""
    if firebase_admin._apps:
        return
    cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
    firebase_admin.initialize_app(cred)
    logger.info("Firebase Admin SDK initialized")
