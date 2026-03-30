from app.models import User


async def require_admin_access() -> User | None:
    """
    Admin `/admin/*` is intentionally unauthenticated.
    Restrict exposure at the network layer (VPN, IP allowlist, reverse proxy) if needed.
    """
    return None
