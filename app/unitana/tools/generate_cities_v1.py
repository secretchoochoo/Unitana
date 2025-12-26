#!/usr/bin/env python3
"""Generate assets/data/cities_v1.json from GeoNames reference datasets.

Unitana uses a precompiled JSON asset for an authoritative, offline-friendly City Picker.
This script builds that asset from GeoNames public data.

Required inputs (download from https://www.geonames.org/export/dump/):
  - cities15000.zip
  - cities1000.zip
  - admin1CodesASCII.txt
  - countryInfo.txt

Usage (from app/unitana):
  python3 tools/generate_cities_v1.py \
    --geonames-dir /path/to/geonames/files \
    --output assets/data/cities_v1.json

Notes:
  - The generated list includes all cities in cities15000 plus any missing capitals found in cities1000.
  - The dataset is large; keep it as a bundled asset for predictable, offline operation.
"""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Set, Tuple


_PUNCT_RE = re.compile(r"[^a-z0-9\s]")
_SPACE_RE = re.compile(r"\s+")


def _strip_diacritics(s: str) -> str:
    return "".join(
        ch for ch in unicodedata.normalize("NFD", s) if unicodedata.category(ch) != "Mn"
    )


def _norm(s: str) -> str:
    s = (s or "").strip().lower()
    s = _strip_diacritics(s)
    s = s.replace("&", " and ")
    s = _PUNCT_RE.sub(" ", s)
    s = _SPACE_RE.sub(" ", s).strip()
    return s


def _capital_variants(capital: str) -> List[str]:
    base = _norm(capital)
    out: Set[str] = {base}

    # Common Saint abbreviations.
    if base.startswith("st "):
        out.add("saint " + base[3:])
    if base.startswith("st "):
        out.add("st" + base[2:])

    # Some countryInfo capitals use hyphenation; try a space variant.
    out.add(base.replace("-", " "))

    # Macau vs Macao.
    if base == "macao":
        out.add("macau")

    return [v for v in out if v]


@dataclass(frozen=True)
class Country:
    code2: str
    name: str
    iso3: str
    capital: str
    continent: str
    currency: str


@dataclass
class GeoRow:
    geonameid: int
    name: str
    asciiname: str
    alternates: List[str]
    country: str
    admin1: str
    tz: str
    population: int


def _read_country_info(path: Path) -> Dict[str, Country]:
    countries: Dict[str, Country] = {}
    with path.open("r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            if not line.strip() or line.startswith("#"):
                continue
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 11:
                continue
            code2 = parts[0].strip()
            iso3 = parts[1].strip()
            name = parts[4].strip()
            capital = parts[5].strip()
            continent = parts[8].strip()
            currency = parts[10].strip()
            if not code2:
                continue
            countries[code2] = Country(
                code2=code2,
                name=name,
                iso3=iso3,
                capital=capital,
                continent=continent,
                currency=currency,
            )
    return countries


def _read_admin1(path: Path) -> Dict[str, str]:
    # Key format: CC.ADMIN1 (e.g. US.CO)
    out: Dict[str, str] = {}
    with path.open("r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            if not line.strip() or line.startswith("#"):
                continue
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 2:
                continue
            out[parts[0].strip()] = parts[1].strip()
    return out


def _iter_geonames_cities(zip_path: Path) -> Iterable[GeoRow]:
    with zipfile.ZipFile(zip_path, "r") as z:
        # Each zip contains a single .txt with the same stem.
        txt_names = [n for n in z.namelist() if n.endswith(".txt")]
        if not txt_names:
            raise RuntimeError(f"No .txt found in {zip_path}")
        txt_name = txt_names[0]
        with z.open(txt_name) as raw:
            for b in raw:
                line = b.decode("utf-8", errors="ignore").rstrip("\n")
                if not line:
                    continue
                parts = line.split("\t")
                if len(parts) < 19:
                    continue

                # GeoNames schema for cities*.txt
                # 0 geonameid
                # 1 name
                # 2 asciiname
                # 3 alternatenames
                # 8 country code
                # 10 admin1
                # 14 population
                # 17 timezone
                try:
                    geonameid = int(parts[0])
                except ValueError:
                    continue

                name = parts[1].strip()
                asciiname = parts[2].strip()
                alternates = [a for a in (parts[3] or "").split(",") if a]
                country = parts[8].strip()
                admin1 = parts[10].strip()
                tz = parts[17].strip()
                try:
                    population = int(parts[14])
                except ValueError:
                    population = 0

                # Keep only populated places.
                if parts[6].strip() != "P":
                    continue

                if not (name and country and tz):
                    continue

                yield GeoRow(
                    geonameid=geonameid,
                    name=name,
                    asciiname=asciiname,
                    alternates=alternates,
                    country=country,
                    admin1=admin1,
                    tz=tz,
                    population=population,
                )


def _best_capital_match(rows: List[GeoRow], country_code: str, capital: str) -> Optional[GeoRow]:
    variants = _capital_variants(capital)
    for v in variants:
        best: Optional[GeoRow] = None
        for r in rows:
            if r.country != country_code:
                continue
            if _norm(r.name) == v or _norm(r.asciiname) == v:
                if best is None or r.population > best.population:
                    best = r
        if best is not None:
            return best

    # Fall back to alternatenames matching.
    vset = set(variants)
    best: Optional[GeoRow] = None
    for r in rows:
        if r.country != country_code:
            continue
        if any(_norm(a) in vset for a in r.alternates[:80]):
            if best is None or r.population > best.population:
                best = r
    return best


def _default_unit_system(country_code: str) -> str:
    # Commonly accepted "imperial" default countries.
    if country_code.upper() in {"US", "LR", "MM"}:
        return "imperial"
    return "metric"


def _default_use_24h(country_code: str) -> bool:
    # Pragmatic defaults to align with current onboarding expectations.
    if country_code.upper() in {"US", "CA"}:
        return False
    return True


def build_asset(geonames_dir: Path, output_path: Path) -> None:
    country_info = _read_country_info(geonames_dir / "countryInfo.txt")
    admin1 = _read_admin1(geonames_dir / "admin1CodesASCII.txt")

    cities_15000 = list(_iter_geonames_cities(geonames_dir / "cities15000.zip"))
    cities_1000 = list(_iter_geonames_cities(geonames_dir / "cities1000.zip"))

    # Base set: cities15000.
    by_id: Dict[int, GeoRow] = {r.geonameid: r for r in cities_15000}

    # Ensure capitals: if missing, pull from cities1000.
    missing_capitals: List[Tuple[str, str]] = []
    for cc, c in country_info.items():
        if not c.capital:
            continue
        found = _best_capital_match(cities_15000, cc, c.capital)
        if found is None:
            found = _best_capital_match(cities_1000, cc, c.capital)
            if found is not None:
                by_id.setdefault(found.geonameid, found)
        if found is None:
            # Some entries are obsolete (e.g. AN, CS). We still record them for visibility.
            missing_capitals.append((cc, c.capital))

    # Seed curated IDs so onboarding defaults remain stable even if GeoNames names shift.
    curated = [
        {
            "id": "denver_us",
            "cityName": "Denver",
            "countryCode": "US",
            "timeZoneId": "America/Denver",
            "currencyCode": "USD",
            "defaultUnitSystem": "imperial",
            "defaultUse24h": False,
            "admin1Code": "CO",
            "admin1Name": "Colorado",
            "countryName": "United States",
            "iso3": "USA",
            "continent": "NA",
        },
        {
            "id": "new_york_us",
            "cityName": "New York",
            "countryCode": "US",
            "timeZoneId": "America/New_York",
            "currencyCode": "USD",
            "defaultUnitSystem": "imperial",
            "defaultUse24h": False,
            "admin1Code": "NY",
            "admin1Name": "New York",
            "countryName": "United States",
            "iso3": "USA",
            "continent": "NA",
        },
        {
            "id": "los_angeles_us",
            "cityName": "Los Angeles",
            "countryCode": "US",
            "timeZoneId": "America/Los_Angeles",
            "currencyCode": "USD",
            "defaultUnitSystem": "imperial",
            "defaultUse24h": False,
            "admin1Code": "CA",
            "admin1Name": "California",
            "countryName": "United States",
            "iso3": "USA",
            "continent": "NA",
        },
        {
            "id": "chicago_us",
            "cityName": "Chicago",
            "countryCode": "US",
            "timeZoneId": "America/Chicago",
            "currencyCode": "USD",
            "defaultUnitSystem": "imperial",
            "defaultUse24h": False,
            "admin1Code": "IL",
            "admin1Name": "Illinois",
            "countryName": "United States",
            "iso3": "USA",
            "continent": "NA",
        },
        {
            "id": "miami_us",
            "cityName": "Miami",
            "countryCode": "US",
            "timeZoneId": "America/New_York",
            "currencyCode": "USD",
            "defaultUnitSystem": "imperial",
            "defaultUse24h": False,
            "admin1Code": "FL",
            "admin1Name": "Florida",
            "countryName": "United States",
            "iso3": "USA",
            "continent": "NA",
        },
        {
            "id": "toronto_ca",
            "cityName": "Toronto",
            "countryCode": "CA",
            "timeZoneId": "America/Toronto",
            "currencyCode": "CAD",
            "defaultUnitSystem": "metric",
            "defaultUse24h": False,
            "admin1Code": "ON",
            "admin1Name": "Ontario",
            "countryName": "Canada",
            "iso3": "CAN",
            "continent": "NA",
        },
        {
            "id": "vancouver_ca",
            "cityName": "Vancouver",
            "countryCode": "CA",
            "timeZoneId": "America/Vancouver",
            "currencyCode": "CAD",
            "defaultUnitSystem": "metric",
            "defaultUse24h": False,
            "admin1Code": "BC",
            "admin1Name": "British Columbia",
            "countryName": "Canada",
            "iso3": "CAN",
            "continent": "NA",
        },
        {
            "id": "london_gb",
            "cityName": "London",
            "countryCode": "GB",
            "timeZoneId": "Europe/London",
            "currencyCode": "GBP",
            "defaultUnitSystem": "metric",
            "defaultUse24h": True,
            "countryName": "United Kingdom",
            "iso3": "GBR",
            "continent": "EU",
        },
        {
            "id": "lisbon_pt",
            "cityName": "Lisbon",
            "countryCode": "PT",
            "timeZoneId": "Europe/Lisbon",
            "currencyCode": "EUR",
            "defaultUnitSystem": "metric",
            "defaultUse24h": True,
            "countryName": "Portugal",
            "iso3": "PRT",
            "continent": "EU",
        },
        {
            "id": "tokyo_jp",
            "cityName": "Tokyo",
            "countryCode": "JP",
            "timeZoneId": "Asia/Tokyo",
            "currencyCode": "JPY",
            "defaultUnitSystem": "metric",
            "defaultUse24h": True,
            "countryName": "Japan",
            "iso3": "JPN",
            "continent": "AS",
        },
    ]

    out: List[dict] = []
    out.extend(curated)

    # Sort GeoNames cities deterministically for stable diffs.
    for geonameid in sorted(by_id.keys()):
        r = by_id[geonameid]
        c = country_info.get(r.country)
        country_name = c.name if c else None
        iso3 = c.iso3 if c else None
        continent = c.continent if c else None
        currency = (c.currency if c and c.currency else "USD")

        admin_key = f"{r.country}.{r.admin1}" if r.admin1 else ""
        admin_name = admin1.get(admin_key)

        out.append(
            {
                "id": f"gn_{r.geonameid}",
                "cityName": r.name,
                "countryCode": r.country,
                "timeZoneId": r.tz,
                "currencyCode": currency,
                "defaultUnitSystem": _default_unit_system(r.country),
                "defaultUse24h": _default_use_24h(r.country),
                **({"countryName": country_name} if country_name else {}),
                **({"iso3": iso3} if iso3 else {}),
                **({"admin1Code": r.admin1} if r.admin1 else {}),
                **({"admin1Name": admin_name} if admin_name else {}),
                **({"continent": continent} if continent else {}),
            }
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    print(f"Wrote {output_path}")
    print(f"Total records: {len(out)}")
    print(f"Missing capitals: {len(missing_capitals)}")
    if missing_capitals:
        print("Sample:", missing_capitals[:15])


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--geonames-dir",
        required=True,
        help="Directory containing GeoNames dump files (cities15000.zip, cities1000.zip, admin1CodesASCII.txt, countryInfo.txt)",
    )
    parser.add_argument(
        "--output",
        default="assets/data/cities_v1.json",
        help="Output path for the JSON asset (relative or absolute)",
    )
    args = parser.parse_args()

    geonames_dir = Path(args.geonames_dir).expanduser().resolve()
    output_path = Path(args.output).expanduser().resolve() if args.output.startswith("/") else (Path.cwd() / args.output).resolve()

    for name in ["cities15000.zip", "cities1000.zip", "admin1CodesASCII.txt", "countryInfo.txt"]:
        p = geonames_dir / name
        if not p.exists():
            raise SystemExit(f"Missing required file: {p}")

    build_asset(geonames_dir, output_path)


if __name__ == "__main__":
    main()
