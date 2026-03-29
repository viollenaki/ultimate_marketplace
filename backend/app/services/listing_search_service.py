"""Elasticsearch: listing index + search for home feed filters."""
from __future__ import annotations

import logging
from typing import Any

from elasticsearch import AsyncElasticsearch, Elasticsearch
from elasticsearch.exceptions import ApiError, ConnectionError as ESConnectionError

from app.core.config import settings
from app.models.enums import ListingStatus
from app.services.listing_search_document import build_listing_search_document

logger = logging.getLogger(__name__)

LISTING_INDEX_MAPPINGS: dict[str, Any] = {
    "properties": {
        "listing_id": {"type": "integer"},
        "title": {"type": "text"},
        "description": {"type": "text"},
        "brand": {
            "type": "text",
            "fields": {"keyword": {"type": "keyword", "ignore_above": 128}},
        },
        "model": {
            "type": "text",
            "fields": {"keyword": {"type": "keyword", "ignore_above": 128}},
        },
        "city": {
            "type": "text",
            "fields": {"keyword": {"type": "keyword", "ignore_above": 128}},
        },
        "year": {"type": "integer"},
        "mileage": {"type": "integer"},
        "price": {"type": "double"},
        "currency": {"type": "keyword"},
        "fuel_type": {"type": "keyword"},
        "transmission": {"type": "keyword"},
        "body_type": {"type": "keyword"},
        "color": {"type": "keyword"},
        "status": {"type": "keyword"},
        "is_deleted": {"type": "boolean"},
        "is_crashed": {"type": "boolean"},
        "published_at": {"type": "date"},
        "search_blob": {"type": "text"},
    }
}


def listings_index_name() -> str:
    return settings.ELASTICSEARCH_LISTINGS_INDEX


def _public_filter_clauses() -> list[dict[str, Any]]:
    return [
        {"term": {"is_deleted": False}},
        {
            "bool": {
                "must_not": {
                    "terms": {
                        "status": [
                            ListingStatus.draft.value,
                            ListingStatus.rejected.value,
                        ]
                    }
                }
            }
        },
    ]


async def ensure_listings_index_async(es: AsyncElasticsearch) -> None:
    name = listings_index_name()
    if await es.indices.exists(index=name):
        return
    await es.indices.create(
        index=name,
        mappings=LISTING_INDEX_MAPPINGS,
    )
    logger.info("Created Elasticsearch index %s", name)


def ensure_listings_index_sync(es: Elasticsearch) -> None:
    name = listings_index_name()
    if es.indices.exists(index=name):
        return
    es.indices.create(index=name, mappings=LISTING_INDEX_MAPPINGS)
    logger.info("Created Elasticsearch index %s", name)


async def index_listing_async(es: AsyncElasticsearch, listing: Any) -> None:
    await ensure_listings_index_async(es)
    doc = build_listing_search_document(listing)
    lid = doc["listing_id"]
    await es.index(
        index=listings_index_name(),
        id=str(lid),
        document=doc,
        refresh=True,
    )


def index_listing_sync(es: Elasticsearch, listing: Any) -> None:
    ensure_listings_index_sync(es)
    doc = build_listing_search_document(listing)
    es.index(
        index=listings_index_name(),
        id=str(doc["listing_id"]),
        document=doc,
        refresh=True,
    )


async def search_public_listing_ids(
    es: AsyncElasticsearch,
    *,
    skip: int,
    limit: int,
    q: str | None = None,
    brands: list[str] | None = None,
    city: str | None = None,
    year_min: int | None = None,
    year_max: int | None = None,
    price_min: float | None = None,
    price_max: float | None = None,
    mileage_min: int | None = None,
    mileage_max: int | None = None,
    fuel_types: list[str] | None = None,
    body_types: list[str] | None = None,
    transmissions: list[str] | None = None,
    colors: list[str] | None = None,
    require_no_accident: bool = False,
) -> tuple[list[int], int]:
    """Return (ordered listing ids, total hits) for public feed filters."""
    await ensure_listings_index_async(es)
    filter_q: list[dict[str, Any]] = [* _public_filter_clauses()]

    if brands:
        filter_q.append(
            {
                "bool": {
                    "should": [
                        {"term": {"brand.keyword": b.strip()}} for b in brands if b.strip()
                    ],
                    "minimum_should_match": 1,
                }
            }
        )
    if city and city.strip():
        filter_q.append(
            {"term": {"city.keyword": city.strip()}},
        )
    if year_min is not None:
        filter_q.append({"range": {"year": {"gte": year_min}}})
    if year_max is not None:
        filter_q.append({"range": {"year": {"lte": year_max}}})
    if price_min is not None:
        filter_q.append({"range": {"price": {"gte": price_min}}})
    if price_max is not None:
        filter_q.append({"range": {"price": {"lte": price_max}}})
    if mileage_min is not None:
        filter_q.append({"range": {"mileage": {"gte": mileage_min}}})
    if mileage_max is not None:
        filter_q.append({"range": {"mileage": {"lte": mileage_max}}})
    if fuel_types:
        filter_q.append({"terms": {"fuel_type": [f.strip() for f in fuel_types if f.strip()]}})
    if body_types:
        filter_q.append({"terms": {"body_type": [b.strip() for b in body_types if b.strip()]}})
    if transmissions:
        filter_q.append(
            {"terms": {"transmission": [t.strip() for t in transmissions if t.strip()]}}
        )
    if colors:
        filter_q.append({"terms": {"color": [c.strip() for c in colors if c.strip()]}})
    if require_no_accident:
        filter_q.append({"term": {"is_crashed": False}})

    must: list[dict[str, Any]] = []
    if q and q.strip():
        must.append(
            {
                "multi_match": {
                    "query": q.strip(),
                    "fields": [
                        "title^3",
                        "brand^2",
                        "model^2",
                        "search_blob",
                        "description",
                    ],
                    "type": "best_fields",
                    "fuzziness": "AUTO",
                }
            }
        )

    bool_query: dict[str, Any] = {"filter": filter_q}
    if must:
        bool_query["must"] = must

    resp = await es.search(
        index=listings_index_name(),
        query={"bool": bool_query},
        from_=skip,
        size=limit,
        sort=[
            {"published_at": {"order": "desc", "missing": "_last"}},
            {"listing_id": {"order": "desc"}},
        ],
        track_total_hits=True,
        source=False,
    )
    hits = resp.get("hits", {})
    total = hits.get("total", {})
    if isinstance(total, dict):
        n_total = int(total.get("value", 0))
    else:
        n_total = int(total or 0)
    ids: list[int] = []
    for h in hits.get("hits", []):
        iid = h.get("_id")
        if iid is not None:
            ids.append(int(iid))
    return ids, n_total


async def safe_index_listing_async(es: AsyncElasticsearch, listing: Any) -> None:
    try:
        await index_listing_async(es, listing)
    except (ESConnectionError, ApiError, TimeoutError, OSError) as e:
        logger.warning("Elasticsearch index listing %s failed: %s", listing.id, e)
