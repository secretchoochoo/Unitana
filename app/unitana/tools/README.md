# Unitana City Dataset Builder

This tool generates the offline city dataset used by Unitana's City Picker.

## Output
- `assets/data/cities_world_v1.json`

## Sources (GeoNames)
- `cities15000.zip` (major cities + capitals)
- `countryInfo.txt` (country name + currency)
- `admin1CodesASCII.txt` (state/province names)

## Run
From the Flutter app root:

```bash
cd unitana/app/unitana
python3 tools/build_cities_dataset.py
flutter pub get
flutter run

