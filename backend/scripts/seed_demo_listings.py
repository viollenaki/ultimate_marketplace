#!/usr/bin/env python3
"""
Insert 200 varied car listings (approved, public) and index each in Elasticsearch.

Requires: MySQL migrated, Elasticsearch up, at least one user in `users`.

Run from the `backend` directory:

    python scripts/seed_demo_listings.py

Uses DATABASE_URL and ELASTICSEARCH_URL from the environment or `.env`.
"""
from __future__ import annotations

import asyncio
import random
import sys
from datetime import datetime, timezone
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
COLORS = ["white", "black", "silver", "gray", "blue", "red", "green", "brown"]

# Change this constant if you want a different batch size.
DEMO_LISTING_COUNT = 200


async def main() -> None:
    async with AsyncSessionLocal() as session:
        user = (
            await session.execute(select(User).order_by(User.id).limit(1))
        ).scalar_one_or_none()
        if user is None:
            print("No user found. Create a user first, then re-run.")
            return

        owner_id = int(user.id)
        fuels = [e.value for e in FuelType]
        bodies = [e.value for e in BodyType]
        trans = [e.value for e in TransmissionType]
        created_ids: list[int] = []

        for n in range(50):
            brand = random.choice(list(BRANDS_MODELS))
            model = random.choice(BRANDS_MODELS[brand])
            year = random.randint(2008, 2024)
            mileage = random.randint(5_000, 280_000)
            price = float(random.randint(4_000, 65_000))
            city = random.choice(CITIES)
            row = Listing(
                owner_id=owner_id,
                title=f"{brand} {model} {year} — demo #{n + 1}",
                description=(
                    f"Demo listing {n + 1}. {brand} {model}, well maintained, "
                    f"{mileage} km. Contact for details."
                ),
                price=price,
                currency="USD",
                city=city,
                brand=brand,
                model=model,
                year=year,
                mileage=mileage,
                fuel_type=random.choice(fuels),
                transmission=random.choice(trans),
                body_type=random.choice(bodies),
                color=random.choice(COLORS),
                is_crashed=random.random() < 0.12,
                has_warranty=random.random() < 0.25,
                status=ListingStatus.approved.value,
                moderation_status="approved",
                published_at=datetime.now(timezone.utc),
            )
            session.add(row)
            await session.flush()
            created_ids.append(int(row.id))

        await session.commit()
        print(f"Inserted {len(created_ids)} listings (ids {created_ids[0]}..{created_ids[-1]}).")

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
