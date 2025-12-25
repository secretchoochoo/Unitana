#!/usr/bin/env python3
import csv
import io
import json
import os
import sys
import urllib.request
import zipfile
from typing import Dict, Optional, Tuple

GEONAMES_BASE = "https://download.geonames.org/export/dump"

CITIES_ZIP = f"{GEONAMES_BASE}/cities15000.zip"
COUNTRY_INFO = f"{GEONAMES_BASE}/countryInfo.txt"
ADMIN1_INFO = f"{GEONAMES_BASE}/admin1CodesASCII.txt"

APP_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ASSET_OUT = os.path.join(APP_ROOT, "assets", "data", "cities_world_v1.json")


def fetch_text(url: str) -> str:
    with urllib.request.urlopen(url) as resp:
        return resp.read().decode("utf-8", errors="replace")


def fetch_zip(url: str) -> bytes:
    with urllib.request.urlopen(url) as resp:
        return resp.read()


def parse_country_info(txt: str) -> Dict[str, Dict[str, str]]:
    """
    countryInfo.txt is tab-separated with comment lines starting with '#'
    Columns (subset):
      0 ISO
      4 Country
      10 CurrencyCode
    """
    out: Dict[str, Dict[str, str]] = {}
    for line in txt.splitlines():
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 11:
            continue
        iso = parts[0].strip()
        name = parts[4].strip()
        currency = parts[10].strip()
        if iso:
            out[iso] = {"countryName": name, "currencyCode": currency}
    return out


def parse_admin1_info(txt: str) -> Dict[Tuple[str, str], str]:
    """
    admin1CodesASCII.txt is tab-separated:
      code (e.g. US.CO) \t name \t nameASCII \t geonameId
    We return mapping: (countryCode, admin1Code) -> admin1Name
    """
    out: Dict[Tuple[str, str], str] = {}
    for line in txt.splitlines():
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        code = parts[0].strip()
        name = parts[1].strip()
        if "." not in code:
            continue
        cc, a1 = code.split(".", 1)
        if cc and a1 and name:
            out[(cc, a1)] = name
    return out


def infer_defaults(country_code: str) -> Tuple[str, bool]:
    """
    Conservative MVP defaults:
    - US: imperial, 12h
    - Everyone else: metric, 24h
    """
    if country_code.upper() == "US":
        return ("imperial", False)
    return ("metric", True)


def build_city_id(name: str, country_code: str, admin1: Optional[str]) -> str:
    base = name.strip().lower().replace(" ", "_")
    cc = country_code.strip().lower()
    if admin1 and admin1.strip():
        a1 = admin1.strip().lower()
        return f"{base}_{a1}_{cc}"
    return f"{base}_{cc}"


def main() -> int:
    print("Downloading GeoNames countryInfo.txt...")
    country_txt = fetch_text(COUNTRY_INFO)
    country_map = parse_country_info(country_txt)

    print("Downloading GeoNames admin1CodesASCII.txt...")
    admin_txt = fetch_text(ADMIN1_INFO)
    admin_map = parse_admin1_info(admin_txt)

    print("Downloading GeoNames cities15000.zip...")
    cities_zip_bytes = fetch_zip(CITIES_ZIP)

    with zipfile.ZipFile(io.BytesIO(cities_zip_bytes), "r") as zf:
        # cities15000.zip contains a single file: cities15000.txt
        names = zf.namelist()
        if not names:
            print("ERROR: cities15000.zip contained no files.", file=sys.stderr)
            return 1

        city_file = names[0]
        raw = zf.read(city_file).decode("utf-8", errors="replace")

    # GeoNames cities file is tab-separated.
    # Columns (subset):
    #  1 name
    #  8 country code
    # 10 admin1 code
    # 17 timezone
    rows = []
    reader = csv.reader(raw.splitlines(), delimiter="\t")
    for parts in reader:
        if len(parts) < 18:
            continue

        name = parts[1].strip()
        cc = parts[8].strip()
        admin1 = parts[10].strip()
        tz = parts[17].strip()

        if not name or not cc or not tz:
            continue

        country = country_map.get(cc, {})
        country_name = country.get("countryName", "")
        currency = country.get("currencyCode", "")

        admin1_code = admin1 if admin1 else None
        admin1_name = admin_map.get((cc, admin1), "") if admin1 else ""
        if not admin1_name:
            admin1_name = None

        unit, use24h = infer_defaults(cc)

        cid = build_city_id(name, cc, admin1_code)

        rows.append(
            {
                "id": cid,
                "cityName": name,
                "countryCode": cc,
                "countryName": country_name,
                "admin1Code": admin1_code,
                "admin1Name": admin1_name,
                "timeZoneId": tz,
                "currencyCode": currency,
                "defaultUnitSystem": unit,
                "defaultUse24h": use24h,
            }
        )

    rows.sort(key=lambda r: f"{r['cityName']}, {r['countryCode']}".lower())

    os.makedirs(os.path.dirname(ASSET_OUT), exist_ok=True)
    with open(ASSET_OUT, "w", encoding="utf-8") as f:
        json.dump(rows, f, ensure_ascii=False, indent=2)

    print(f"Wrote {len(rows)} cities to: {ASSET_OUT}")
    print("Next: run flutter pub get, then flutter run.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

