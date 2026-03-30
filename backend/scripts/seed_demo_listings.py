#!/usr/bin/env python3
"""
Insert DEMO_LISTING_COUNT varied car listings (approved) and index each in Elasticsearch.

Requires: MySQL migrated, Elasticsearch up, at least one user in `users`.

Run from the `backend` directory:

    python scripts/seed_demo_listings.py

Uses DATABASE_URL and ELASTICSEARCH_URL from the environment or `.env`.
"""
from __future__ import annotations

import asyncio
import random
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from sqlalchemy import select

from app.core.elasticsearch_client import get_sync_elasticsearch
from app.db.database import AsyncSessionLocal
from app.models import Listing, User
from app.models.enums import (
    BodyType,
    FuelType,
    ListingStatus,
    TransmissionType,
)
from app.repositories.listing_repository import ListingRepository
from app.services.listing_search_service import index_listing_sync

BRANDS_MODELS: dict[str, list[str]] = {
    "Toyota": ["Camry", "RAV4", "Corolla", "Land Cruiser", "Highlander"],
    "BMW": ["320i", "X5", "530d", "X3", "M3"],
    "Mercedes-Benz": ["C200", "E220", "GLE", "GLC", "A200"],
    "Audi": ["A4", "Q5", "A6", "Q7", "TT"],
    "Honda": ["Civic", "CR-V", "Accord", "Pilot", "Fit"],
    "Hyundai": ["Tucson", "Santa Fe", "Elantra", "Sonata", "Creta"],
    "Kia": ["Sportage", "Sorento", "Rio", "Cerato", "Telluride"],
    "Lexus": ["RX", "NX", "ES", "GX", "LX"],
    "Volkswagen": ["Passat", "Tiguan", "Golf", "Polo", "Touareg"],
    "Mazda": ["CX-5", "CX-9", "Mazda3", "Mazda6", "MX-5"],
}

CITIES = ["Bishkek", "Osh", "Jalal-Abad", "Karakol", "Tokmok", "Naryn"]
# Approximate centers (lat, lon) with small jitter applied per row
CITY_COORDS: dict[str, tuple[float, float]] = {
    "Bishkek": (42.8746, 74.5698),
    "Osh": (40.5283, 72.8064),
    "Jalal-Abad": (40.9333, 73.0000),
    "Karakol": (42.4906, 78.3936),
    "Tokmok": (42.8417, 75.3014),
    "Naryn": (41.4283, 75.9911),
}
COLORS = ["white", "black", "silver", "gray", "blue", "red", "green", "brown"]

DEMO_LISTING_COUNT = 200


def _jitter_coord(lat: float, lon: float) -> tuple[float, float]:
    return (
        round(lat + random.uniform(-0.08, 0.08), 6),
        round(lon + random.uniform(-0.08, 0.08), 6),
    )


async def main() -> None:
    async with AsyncSessionLocal() as session:
        users = (await session.execute(select(User).order_by(User.id))).scalars().all()
        if not users:
            print("No user found. Create a user first, then re-run.")
            return

        owner_ids = [int(u.id) for u in users]
        fuels = [e.value for e in FuelType]
        bodies = [e.value for e in BodyType]
        trans = [e.value for e in TransmissionType]
        created_ids: list[int] = []
        now = datetime.now(timezone.utc)

        for n in range(DEMO_LISTING_COUNT):
            brand = random.choice(list(BRANDS_MODELS))
            model = random.choice(BRANDS_MODELS[brand])
            year = random.randint(2008, 2024)
            mileage = random.randint(5_000, 280_000)
            price = float(random.randint(200_000, 4_500_000))
            city = random.choice(CITIES)
            lat0, lon0 = CITY_COORDS[city]
            lat, lon = _jitter_coord(lat0, lon0)
            owner_id = random.choice(owner_ids)

            published_at = now - timedelta(days=random.randint(0, 180))

            row = Listing(
                owner_id=owner_id,
                title=f"{brand} {model} {year} — demo #{n + 1}",
                description=(
                    f"Auto-generated demo listing {n + 1}. {brand} {model}, "
                    f"{mileage} km, located in {city}. Inspection welcome."
                ),
                price=price,
                currency="KGS",
                city=city,
                latitude=lat,
                longitude=lon,
                location_display_name=f"{city}, KG",
                brand=brand,
                model=model,
                year=year,
                mileage=mileage,
                fuel_type=random.choice(fuels),
                transmission=random.choice(trans),
                body_type=random.choice(bodies),
                color=random.choice(COLORS),
                engine_volume=round(random.uniform(1.2, 4.5), 1),
                horsepower=random.randint(90, 350),
                doors=random.choice([2, 4, 5]),
                is_crashed=random.random() < 0.12,
                has_warranty=random.random() < 0.25,
                status=ListingStatus.approved.value,
                moderation_status="approved",
                view_count=random.randint(0, 8_000),
                published_at=published_at,
            )
            session.add(row)
            await session.flush()
            created_ids.append(int(row.id))

        await session.commit()
        print(
            f"Inserted {len(created_ids)} listings "
            f"(ids {created_ids[0]}..{created_ids[-1]}), owners from user id(s) {owner_ids}."
        )

    es = get_sync_elasticsearch()
    repo = ListingRepository()
    indexed = 0
    async with AsyncSessionLocal() as session:
        for lid in created_ids:
            full = await repo.get_by_id(session, lid)
            if full is None:
                continue
            index_listing_sync(es, full)
            indexed += 1
    print(f"Indexed {indexed} listings in Elasticsearch.")
    print("Done.")


if __name__ == "__main__":
    asyncio.run(main())
