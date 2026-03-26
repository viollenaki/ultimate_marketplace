"""
Elasticsearch clients: async for FastAPI, sync for Celery tasks.
"""
from elasticsearch import AsyncElasticsearch, Elasticsearch

from app.core.config import settings

_es_async: AsyncElasticsearch | None = None
_es_sync: Elasticsearch | None = None


def get_async_elasticsearch() -> AsyncElasticsearch:
    """Shared async client for FastAPI handlers."""
    global _es_async
    if _es_async is None:
        _es_async = AsyncElasticsearch(settings.ELASTICSEARCH_URL)
    return _es_async


def get_sync_elasticsearch() -> Elasticsearch:
    """Shared sync client for Celery workers (blocking I/O)."""
    global _es_sync
    if _es_sync is None:
        _es_sync = Elasticsearch(settings.ELASTICSEARCH_URL)
    return _es_sync


async def close_async_elasticsearch() -> None:
    global _es_async
    if _es_async is not None:
        await _es_async.close()
        _es_async = None
