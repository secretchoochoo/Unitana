# Weather Provider Benchmark

- Generated at (UTC): `2026-04-05T06:54:54.487259Z`
- Reference time (UTC): `2026-04-05T06:54:45.036837Z`
- Cities evaluated: `25`
- Fixture: `tool/fixtures/weather_benchmark_cities.json`
- Observation proxy: `METAR airport observations`

## Caveats

- This is a research harness, not a CI gate.
- The airport METAR is a practical observation proxy, not perfect city-center truth.
- MET Norway is compared via nearest `Locationforecast` timeseries point to the observation/reference time.
- Open-Meteo is compared via its current conditions endpoint.

## Provider Summary

| Provider | Samples | Wins | Avg composite | Avg temp error (C) | Avg wind error (km/h) | Avg cloud error (%) | Exact bucket match | Fog false + | Fog false - |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Open-Meteo | 23 | 13 | 0.763 | 1.4 | 6.0 | 25.7 | 61% | 1 | 0 |
| MET Norway | 23 | 10 | 0.727 | 1.4 | 7.0 | 25.8 | 52% | 1 | 0 |

## Per-City Results

### Porto, Portugal (`LPPR`)

- Observation: `Clear` at `2026-04-05T06:30:00.000Z`
- Observation detail: `CLR`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:30:00.000Z | Clear | 7.0 | 3.7 | 0.0 | 7.0 | — | CLR |
| MET Norway | 2026-04-05T06:00:00.000Z | Partly cloudy | 10.5 | 7.2 | 32.8 | — | 0.628 | fair_day |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Fog / low visibility | 8.9 | 2.3 | 96.0 | 1.4 | 0.459 | WMO 45 |

### Reykjavik, Iceland (`BIRK`)

- Observation: `Clear` at `2026-04-05T06:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:00:00.000Z | Clear | -6.0 | 3.7 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T06:00:00.000Z | Fog / low visibility | -8.5 | 10.1 | 97.7 | — | 0.380 | fog |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Cloudy | -2.8 | 4.3 | 97.0 | 50.0 | 0.469 | WMO 3 |

### London, United Kingdom (`EGLL`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 9.0 | 22.2 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 8.6 | 16.6 | 100.0 | — | 0.907 | cloudy |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Cloudy | 9.2 | 16.6 | 98.0 | 24.1 | 0.919 | WMO 3 |

### New York, United States (`KJFK`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `OVC`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 6.7 | 18.5 | 100.0 | 4.0 | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 7.9 | 17.6 | 100.0 | — | 0.928 | cloudy |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Cloudy | 5.7 | 12.4 | 100.0 | 12.2 | 0.877 | WMO 3 |

### Toronto, Canada (`CYYZ`)

- Observation: `Cloudy` at `2026-04-05T06:32:00.000Z`
- Observation detail: `OVC`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:32:00.000Z | Cloudy | 9.0 | 31.5 | 100.0 | 24.1 | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 8.5 | 27.4 | 100.0 | — | 0.926 | cloudy |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Cloudy | 5.9 | 9.2 | 100.0 | 12.2 | 0.605 | WMO 3 |

### Chicago, United States (`KORD`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 4.4 | 24.1 | 87.5 | 16.1 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 4.9 | 24.1 | 96.9 | — | 0.964 | cloudy |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Partly cloudy | 2.6 | 16.8 | 31.0 | 19.2 | 0.629 | WMO 1 |

### San Francisco, United States (`KSFO`)

- Observation: `Partly cloudy` at `2026-04-05T06:00:00.000Z`
- Observation detail: `SCT`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:00:00.000Z | Partly cloudy | 18.9 | 7.4 | 50.0 | 16.1 | — | SCT |
| MET Norway | 2026-04-05T06:00:00.000Z | Clear | 17.4 | 7.6 | 0.0 | — | 0.723 | clearsky_night |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Clear | 16.5 | 10.5 | 0.0 | 46.9 | 0.654 | WMO 0 |

### Honolulu, United States (`PHNL`)

- Observation: `Partly cloudy` at `2026-04-05T06:00:00.000Z`
- Observation detail: `FEW`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:00:00.000Z | Partly cloudy | 22.2 | 9.3 | 20.0 | 16.1 | — | FEW |
| MET Norway | 2026-04-05T06:00:00.000Z | Clear | 21.8 | 29.2 | 5.5 | — | 0.627 | clearsky_night |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Partly cloudy | 22.6 | 8.7 | 25.0 | 24.1 | 0.969 | WMO 1 |

### Anchorage, United States (`PANC`)

- Observation: `Cloudy` at `2026-04-05T06:00:00.000Z`
- Observation detail: `OVC`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:00:00.000Z | Cloudy | 1.1 | 0.0 | 100.0 | 16.1 | — | OVC |
| MET Norway | 2026-04-05T06:00:00.000Z | Cloudy | 1.4 | 14.0 | 100.0 | — | 0.819 | cloudy |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Cloudy | 1.3 | 5.2 | 100.0 | 24.1 | 0.929 | WMO 3 |

### Mexico City, Mexico (`MMMX`)

- Observation: `Clear` at `2026-04-05T06:00:00.000Z`
- Observation detail: `SKC`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:00:00.000Z | Clear | 16.0 | 9.3 | 0.0 | 19.3 | — | SKC |
| MET Norway | 2026-04-05T06:00:00.000Z | Clear | 15.4 | 4.7 | 0.0 | — | 0.915 | clearsky_night |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Clear | 13.7 | 3.9 | 0.0 | 24.1 | 0.819 | WMO 0 |

### Bogota, Colombia (`SKBO`)

- Observation: `Cloudy` at `2026-04-05T06:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:00:00.000Z | Cloudy | 14.0 | 5.6 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T06:00:00.000Z | Cloudy | 12.0 | 4.3 | 99.2 | — | 0.883 | cloudy |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Cloudy | 12.6 | 4.2 | 100.0 | 24.1 | 0.906 | WMO 3 |

### Lima, Peru (`SPJC`)

- Observation: `Cloudy` at `2026-04-05T06:37:00.000Z`
- Observation detail: `BKN`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:37:00.000Z | Cloudy | 21.0 | 5.6 | 87.5 | 7.0 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 20.8 | 3.6 | 99.2 | — | 0.819 | partlycloudy_night |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Partly cloudy | 22.0 | 4.1 | 81.0 | 24.1 | 0.797 | WMO 2 |

### Santiago, Chile (`SCEL`)

No METAR observation was available for this city at run time.

### Buenos Aires, Argentina (`SAEZ`)

- Observation: `Clear` at `2026-04-05T06:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:00:00.000Z | Clear | 9.0 | 5.6 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T06:00:00.000Z | Clear | 13.6 | 27.4 | 0.0 | — | 0.528 | clearsky_night |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Clear | 11.0 | 9.0 | 0.0 | 24.1 | 0.857 | WMO 0 |

### Johannesburg, South Africa (`FAOR`)

- Observation: `Clear` at `2026-04-05T06:30:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:30:00.000Z | Clear | 21.0 | 9.3 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T06:00:00.000Z | Clear | 17.4 | 2.9 | 1.6 | — | 0.776 | clearsky_day |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Partly cloudy | 20.2 | 4.3 | 42.0 | 24.1 | 0.717 | WMO 1 |

### Nairobi, Kenya (`HKJK`)

- Observation: `Cloudy` at `2026-04-05T06:30:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:30:00.000Z | Cloudy | 20.0 | 5.6 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T06:00:00.000Z | Rain | 19.2 | 14.0 | 99.2 | — | 0.563 | lightrain |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Cloudy | 19.4 | 11.6 | 86.0 | 24.1 | 0.911 | WMO 3 |

### Cairo, Egypt (`HECA`)

- Observation: `Clear` at `2026-04-05T06:30:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:30:00.000Z | Clear | 21.0 | 3.7 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T06:00:00.000Z | Clear | 17.8 | 7.2 | 0.0 | — | 0.794 | clearsky_day |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Clear | 20.0 | 8.4 | 0.0 | 44.0 | 0.893 | WMO 0 |

### Cape Town, South Africa (`FACT`)

- Observation: `Partly cloudy` at `2026-04-05T06:21:00.000Z`
- Observation detail: `FEW`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:21:00.000Z | Partly cloudy | 17.0 | 5.6 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T06:00:00.000Z | Partly cloudy | 16.6 | 8.3 | 25.8 | — | 0.947 | fair_day |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Partly cloudy | 17.1 | 4.7 | 33.0 | 24.1 | 0.968 | WMO 1 |

### Dubai, United Arab Emirates (`OMDB`)

No METAR observation was available for this city at run time.

### Mumbai, India (`VABB`)

- Observation: `Partly cloudy` at `2026-04-05T06:30:00.000Z`
- Observation detail: `SCT`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:30:00.000Z | Partly cloudy | 30.0 | 20.4 | 50.0 | 5.0 | — | SCT |
| MET Norway | 2026-04-05T06:00:00.000Z | Clear | 31.0 | 14.8 | 11.7 | — | 0.708 | clearsky_day |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Partly cloudy | 28.0 | 10.8 | 55.0 | 24.1 | 0.809 | WMO 2 |

### Singapore, Singapore (`WSSS`)

- Observation: `Cloudy` at `2026-04-05T06:30:00.000Z`
- Observation detail: `BKN`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:30:00.000Z | Cloudy | 33.0 | 14.8 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T06:00:00.000Z | Rain | 30.3 | 14.0 | 87.5 | — | 0.574 | heavyrain |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Storm | 30.7 | 7.1 | 100.0 | 19.7 | 0.503 | WMO 95 |

### Tokyo, Japan (`RJTT`)

- Observation: `Partly cloudy` at `2026-04-05T06:30:00.000Z`
- Observation detail: `FEW`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:30:00.000Z | Partly cloudy | 20.0 | 33.3 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T06:00:00.000Z | Partly cloudy | 21.3 | 13.3 | 100.0 | — | 0.623 | partlycloudy_day |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Partly cloudy | 22.3 | 6.5 | 71.0 | 24.1 | 0.623 | WMO 2 |

### Sydney, Australia (`YSSY`)

- Observation: `Cloudy` at `2026-04-05T06:30:00.000Z`
- Observation detail: `OVC`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:30:00.000Z | Cloudy | 20.0 | 11.1 | 100.0 | 9.7 | — | OVC |
| MET Norway | 2026-04-05T06:00:00.000Z | Partly cloudy | 20.2 | 16.9 | 64.8 | — | 0.745 | partlycloudy_day |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Partly cloudy | 18.8 | 9.9 | 72.0 | 24.1 | 0.758 | WMO 2 |

### Auckland, New Zealand (`NZAA`)

- Observation: `Cloudy` at `2026-04-05T06:30:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:30:00.000Z | Cloudy | 18.0 | 16.7 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T06:00:00.000Z | Clear | 17.9 | 33.5 | 7.0 | — | 0.467 | clearsky_night |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Cloudy | 18.1 | 14.2 | 96.0 | 24.1 | 0.958 | WMO 3 |

### Istanbul, Turkey (`LTFM`)

- Observation: `Clear` at `2026-04-05T06:20:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:20:00.000Z | Clear | 12.0 | 14.8 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T06:00:00.000Z | Cloudy | 10.4 | 8.6 | 100.0 | — | 0.478 | cloudy |
| Open-Meteo | 2026-04-05T05:45:00.000Z | Cloudy | 11.8 | 5.7 | 95.0 | 21.0 | 0.518 | WMO 3 |

