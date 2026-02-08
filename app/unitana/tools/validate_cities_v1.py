#!/usr/bin/env python3
"""Validate the canonical city dataset contract."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any, Dict, List
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


REQUIRED_FIELDS = [
    "id",
    "cityName",
    "countryCode",
    "timeZoneId",
    "currencyCode",
    "defaultUnitSystem",
    "defaultUse24h",
    "lat",
    "lon",
]
_ALPHA2 = re.compile(r"^[A-Z]{2}$")
_ALPHA3 = re.compile(r"^[A-Z]{3}$")
_TZ_CACHE: Dict[str, bool] = {}


def _is_known_timezone(tz_id: str) -> bool:
    if not tz_id:
        return False
    cached = _TZ_CACHE.get(tz_id)
    if cached is not None:
        return cached
    try:
        ZoneInfo(tz_id)
        _TZ_CACHE[tz_id] = True
        return True
    except ZoneInfoNotFoundError:
        _TZ_CACHE[tz_id] = False
        return False


def _validate_row(row: Dict[str, Any], idx: int) -> List[str]:
    errors: List[str] = []

    for field in REQUIRED_FIELDS:
        if field not in row:
            errors.append(f"missing {field}")

    for field in ("id", "cityName", "countryCode", "timeZoneId", "currencyCode"):
        value = row.get(field)
        if not isinstance(value, str) or not value.strip():
            errors.append(f"invalid {field}")

    country_code = str(row.get("countryCode", "")).strip().upper()
    currency_code = str(row.get("currencyCode", "")).strip().upper()
    if not _ALPHA2.match(country_code):
        errors.append("countryCode must be ISO-3166 alpha-2")
    if not _ALPHA3.match(currency_code):
        errors.append("currencyCode must be ISO-4217 alpha-3")

    tz_id = str(row.get("timeZoneId", "")).strip()
    if not _is_known_timezone(tz_id):
        errors.append("timeZoneId is not a known IANA timezone")

    unit_system = row.get("defaultUnitSystem")
    if unit_system not in {"metric", "imperial"}:
        errors.append("invalid defaultUnitSystem")

    if not isinstance(row.get("defaultUse24h"), bool):
        errors.append("invalid defaultUse24h")

    lat = row.get("lat")
    lon = row.get("lon")
    if not isinstance(lat, (int, float)) or not -90 <= float(lat) <= 90:
        errors.append("invalid latitude")
    if not isinstance(lon, (int, float)) or not -180 <= float(lon) <= 180:
        errors.append("invalid longitude")

    if errors:
        return [f"row {idx} ({row.get('id', 'missing-id')}): {', '.join(errors)}"]
    return []


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input",
        default="assets/data/cities_v1.json",
        help="Path to city dataset JSON asset",
    )
    args = parser.parse_args()

    path = Path(args.input).expanduser()
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, list):
        raise SystemExit(f"Dataset must be a JSON array: {path}")

    errors: List[str] = []
    for idx, item in enumerate(raw):
        if not isinstance(item, dict):
            errors.append(f"row {idx}: expected object")
            continue
        errors.extend(_validate_row(item, idx))

    if errors:
        print("City dataset validation failed.")
        for e in errors[:50]:
            print(f"- {e}")
        raise SystemExit(1)

    print(f"City dataset validation passed: {len(raw)} records.")


if __name__ == "__main__":
    main()
