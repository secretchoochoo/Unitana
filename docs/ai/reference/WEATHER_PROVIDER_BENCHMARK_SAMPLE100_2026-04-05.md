# Weather Provider Benchmark

- Generated at (UTC): `2026-04-05T07:21:00.229045Z`
- Reference time (UTC): `2026-04-05T07:19:11.104822Z`
- Cities evaluated: `100`
- Selection mode: `expanded-sample`
- Fixture/source: `assets/data/cities_v1.json`
- Observation proxy: `METAR airport observations`
- Observation coverage: `39/100`
- Observation gaps: `61`
- Sample seed: `42`

## Caveats

- This is a research harness, not a CI gate.
- The airport METAR is a practical observation proxy, not perfect city-center truth.
- MET Norway is compared via nearest `Locationforecast` timeseries point to the observation/reference time.
- Open-Meteo is compared via its current conditions endpoint.
- In expanded-sample mode, nearest METAR stations are resolved automatically through AviationWeather station metadata and may not be city-center stations.

## Provider Summary

| Provider | Samples | Wins | Avg composite | Avg temp error (C) | Avg wind error (km/h) | Avg cloud error (%) | Exact bucket match | Fog false + | Fog false - |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| MET Norway | 39 | 21 | 0.712 | 1.9 | 6.1 | 25.3 | 46% | 3 | 0 |
| Open-Meteo | 39 | 18 | 0.703 | 1.7 | 4.1 | 31.8 | 36% | 4 | 0 |

## Provider Priors

These priors are the benchmark-derived provider weights intended to feed a future runtime confidence score. They should not override live disagreement signals, but they can bias the system toward the better-performing provider when other signals are close.

| Provider | Prior weight | Raw score |
|---|---:|---:|
| MET Norway | 52.1% | 0.607 |
| Open-Meteo | 47.9% | 0.559 |

## Per-City Results

### Gaoulou, Ivory Coast (`DISS`)

No METAR observation was available for this city at run time.

### Port-aux-Français, French Southern Territories (`no-metar-station`)

No METAR observation was available for this city at run time.

### Bariq, Saudi Arabia (`OEAB`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 22.0 | 7.4 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 32.3 | 7.2 | 0.8 | — | 0.647 | clearsky_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Partly cloudy | 32.4 | 9.3 | 40.0 | 24.1 | 0.436 | WMO 1 |

### Casa Santa, Italy (`LICT`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 12.0 | 3.7 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 14.4 | 6.5 | 0.0 | — | 0.844 | clearsky_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Partly cloudy | 13.9 | 1.3 | 46.0 | 26.1 | 0.689 | WMO 1 |

### Hazleton, United States (`KHZL`)

- Observation: `Cloudy` at `2026-04-05T07:02:00.000Z`
- Observation detail: `OVC`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:02:00.000Z | Cloudy | 5.0 | 14.8 | 100.0 | 1.6 | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Fog / low visibility | 6.2 | 30.2 | 100.0 | — | 0.493 | fog |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Fog / low visibility | 4.7 | 30.1 | 100.0 | 0.0 | 0.534 | WMO 45 |

### Carrum Downs, Australia (`YMMB`)

No METAR observation was available for this city at run time.

### Sete Lagoas, Brazil (`SBCF`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 21.0 | 3.7 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 19.5 | 8.3 | 30.5 | — | 0.708 | fair_night |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Fog / low visibility | 19.1 | 3.8 | 64.0 | 24.1 | 0.520 | WMO 45 |

### Tukuyu, Tanzania (`HTMB`)

No METAR observation was available for this city at run time.

### Grytviken, South Georgia and the South Sandwich Islands (`no-metar-station`)

No METAR observation was available for this city at run time.

### Tabanan, Indonesia (`WADD`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `SCT`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 30.0 | 20.4 | 50.0 | 9.7 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 26.4 | 15.5 | 78.1 | — | 0.451 | lightrainshowers_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Rain | 29.4 | 11.2 | 100.0 | 24.1 | 0.507 | WMO 80 |

### Kensington, United Kingdom (`EGGP`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 5.0 | 16.7 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 5.2 | 38.5 | 82.8 | — | 0.605 | rainshowers_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Rain | 6.1 | 24.8 | 98.0 | 17.5 | 0.555 | WMO 51 |

### Rosamond, United States (`KWJF`)

No METAR observation was available for this city at run time.

### Logan City, Australia (`YBAF`)

No METAR observation was available for this city at run time.

### Cochabamba, Bolivia (`SLCB`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `FEW`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 13.0 | 11.1 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 8.8 | 5.0 | 25.0 | — | 0.748 | fair_night |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Partly cloudy | 7.5 | 5.8 | 33.0 | 24.1 | 0.687 | WMO 1 |

### Biu, Nigeria (`DNGO`)

No METAR observation was available for this city at run time.

### Bolārum, India (`VOHY`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `FEW`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 33.0 | 14.8 | 20.0 | 6.0 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 32.0 | 10.8 | 47.7 | — | 0.875 | partlycloudy_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Partly cloudy | 34.2 | 13.7 | 22.0 | 24.1 | 0.933 | WMO 1 |

### Guidonia Montecelio, Italy (`LIRG`)

No METAR observation was available for this city at run time.

### Cabo San Lucas, Mexico (`MMSL`)

No METAR observation was available for this city at run time.

### Port Moresby, Papua New Guinea (`AYPY`)

No METAR observation was available for this city at run time.

### Belmonte, Brazil (`SBTC`)

No METAR observation was available for this city at run time.

### Khenifra, Morocco (`GMFI`)

No METAR observation was available for this city at run time.

### Krishnarājpet, India (`VOMY`)

No METAR observation was available for this city at run time.

### Picpus, France (`LFPW`)

No METAR observation was available for this city at run time.

### Puerto Cabezas, Nicaragua (`MNPC`)

No METAR observation was available for this city at run time.

### Manurewa, New Zealand (`NZAA`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `OVC`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 18.0 | 16.7 | 100.0 | 9.7 | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 17.1 | 23.8 | 32.8 | — | 0.654 | fair_night |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Cloudy | 17.9 | 12.6 | 87.0 | 24.1 | 0.935 | WMO 3 |

### Mérida, Venezuela (`SVMD`)

No METAR observation was available for this city at run time.

### Arua, Uganda (`HUAR`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `FEW`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 24.0 | 7.4 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 22.7 | 14.0 | 99.2 | — | 0.623 | cloudy |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Cloudy | 22.4 | 12.1 | 88.0 | 24.1 | 0.646 | WMO 3 |

### Kanchanaburi, Thailand (`VTBG`)

No METAR observation was available for this city at run time.

### Castellar del Vallès, Spain (`LELL`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 11.0 | 3.7 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 13.5 | 7.6 | 0.0 | — | 0.826 | clearsky_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Clear | 14.9 | 4.9 | 0.0 | 39.0 | 0.785 | WMO 0 |

### Acajutla, El Salvador (`MSAC`)

No METAR observation was available for this city at run time.

### Richmond, New Zealand (`NZKI`)

No METAR observation was available for this city at run time.

### Cabrero, Chile (`SCGE`)

No METAR observation was available for this city at run time.

### Nzega, Tanzania (`HTSY`)

No METAR observation was available for this city at run time.

### Mingaladon, Myanmar (`VYYY`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 34.0 | 5.6 | 87.5 | 7.0 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 36.6 | 11.5 | 10.2 | — | 0.471 | clearsky_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Partly cloudy | 36.6 | 8.0 | 62.0 | 24.1 | 0.689 | WMO 2 |

### Telde, Spain (`GCLP`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `FEW`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 17.0 | 14.8 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 15.5 | 21.2 | 7.0 | — | 0.716 | clearsky_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Partly cloudy | 15.2 | 7.6 | 48.0 | 24.1 | 0.807 | WMO 1 |

### Liberia, Costa Rica (`MRLB`)

- Observation: `Clear` at `2026-04-05T06:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T06:00:00.000Z | Clear | 27.0 | 13.0 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 25.4 | 22.0 | 89.8 | — | 0.570 | partlycloudy_night |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Clear | 25.2 | 1.3 | 0.0 | 24.1 | 0.770 | WMO 0 |

### Mangilao Village, Guam (`PGUM`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CLR`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 30.0 | 29.6 | 0.0 | 16.1 | — | CLR |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 29.7 | 34.6 | 40.6 | — | 0.742 | partlycloudy_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Partly cloudy | 28.5 | 35.6 | 75.0 | 24.1 | 0.627 | WMO 2 |

### Espinal, Colombia (`SKGI`)

No METAR observation was available for this city at run time.

### Sidi Mérouane, Algeria (`DABC`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CLR`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 5.0 | 3.7 | 0.0 | 6.0 | — | CLR |
| MET Norway | 2026-04-05T07:00:00.000Z | Fog / low visibility | 5.4 | 7.2 | 100.0 | — | 0.585 | fog |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Clear | 7.1 | 1.5 | 1.0 | 20.8 | 0.885 | WMO 0 |

### Şabyā, Saudi Arabia (`OEGN`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `FEW`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 32.0 | 13.0 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 33.7 | 19.8 | 6.2 | — | 0.702 | clearsky_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Cloudy | 32.0 | 12.4 | 96.0 | 24.1 | 0.745 | WMO 3 |

### Brownhills, United Kingdom (`EGBB`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `SCT`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 6.0 | 13.0 | 50.0 | 9.7 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 5.7 | 21.6 | 20.3 | — | 0.856 | fair_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Cloudy | 6.4 | 19.4 | 93.0 | 21.9 | 0.719 | WMO 3 |

### Pleasant View, Canada (`CYKZ`)

No METAR observation was available for this city at run time.

### Mata-Utu, Wallis and Futuna (`NLWW`)

No METAR observation was available for this city at run time.

### La Victoria, Venezuela (`SVBS`)

No METAR observation was available for this city at run time.

### Isiolo, Kenya (`HKIS`)

No METAR observation was available for this city at run time.

### Ban Mai, Thailand (`VTSH`)

No METAR observation was available for this city at run time.

### Vitry-le-François, France (`LFSI`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `FEW`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 12.0 | 22.2 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 11.2 | 17.3 | 99.2 | — | 0.797 | partlycloudy_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Cloudy | 10.6 | 18.5 | 100.0 | 24.5 | 0.647 | WMO 3 |

### Cartago, Costa Rica (`MRPV`)

No METAR observation was available for this city at run time.

### Papeete, French Polynesia (`NTAA`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 28.0 | 18.5 | 87.5 | — | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 25.7 | 36.7 | 86.7 | — | 0.416 | rain |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Storm | 27.9 | 17.4 | 93.0 | 24.1 | 0.676 | WMO 95 |

### Fusagasugá, Colombia (`SKBO`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 14.0 | 3.7 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 16.1 | 5.0 | 100.0 | — | 0.876 | cloudy |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Storm | 18.5 | 2.1 | 100.0 | 18.3 | 0.468 | WMO 95 |

### Hoima, Uganda (`HUMI`)

No METAR observation was available for this city at run time.

### Yazman, Pakistan (`OPMT`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `FEW`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 25.0 | 7.4 | 20.0 | 7.0 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 28.3 | 8.6 | 17.2 | — | 0.839 | fair_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Clear | 27.5 | 8.8 | 0.0 | 24.1 | 0.712 | WMO 0 |

### Leszno, Poland (`EPPO`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `FEW`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 11.0 | 20.4 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 10.5 | 14.0 | 32.0 | — | 0.897 | fair_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Partly cloudy | 10.3 | 12.1 | 59.0 | 29.9 | 0.828 | WMO 2 |

### Ancaster, Canada (`CYHM`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `OVC`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 8.0 | 24.1 | 100.0 | 24.1 | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 7.4 | 28.4 | 100.0 | — | 0.918 | cloudy |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Cloudy | 6.8 | 25.1 | 100.0 | 17.3 | 0.926 | WMO 3 |

### Adamstown, Pitcairn (`no-metar-station`)

No METAR observation was available for this city at run time.

### Mercedes, Uruguay (`SUME`)

No METAR observation was available for this city at run time.

### Ikongo, Madagascar (`FMSF`)

No METAR observation was available for this city at run time.

### Kurihashi, Japan (`RJTJ`)

No METAR observation was available for this city at run time.

### Zdolbuniv, Ukraine (`UKLR`)

No METAR observation was available for this city at run time.

### García, Mexico (`MMAN`)

No METAR observation was available for this city at run time.

### Tamuning-Tumon-Harmon Village, Guam (`PGUM`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CLR`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 30.0 | 29.6 | 0.0 | 16.1 | — | CLR |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 29.7 | 34.6 | 40.6 | — | 0.742 | partlycloudy_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Partly cloudy | 28.8 | 35.6 | 75.0 | 24.1 | 0.640 | WMO 2 |

### Pilar, Argentina (`SADD`)

No METAR observation was available for this city at run time.

### Lalibela, Ethiopia (`HADC`)

No METAR observation was available for this city at run time.

### Ciampea, Indonesia (`WIIA`)

No METAR observation was available for this city at run time.

### Zelenogradsk, Russia (`UMKK`)

- Observation: `Clear` at `2026-04-05T07:19:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:19:00.000Z | Clear | 8.0 | 14.8 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 5.7 | 13.3 | 1.8 | — | 0.882 | clearsky_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Clear | 6.3 | 13.7 | 14.0 | 35.7 | 0.893 | WMO 0 |

### El Asintal, Guatemala (`MGRT`)

No METAR observation was available for this city at run time.

### Lae, Papua New Guinea (`AYNZ`)

No METAR observation was available for this city at run time.

### Peñaflor, Chile (`SCEL`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 14.0 | 1.9 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 12.2 | 5.4 | 0.0 | — | 0.866 | clearsky_night |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Partly cloudy | 10.3 | 3.1 | 17.0 | 24.1 | 0.665 | WMO 1 |

### Daggakraal, South Africa (`FAEO`)

No METAR observation was available for this city at run time.

### Engkilili, Malaysia (`WBGY`)

- Observation: `Unknown` at `2026-04-05T07:00:00.000Z`
- Observation detail: `METAR WBGY 050700Z AUTO VRB02KT //// // ////// 32/26 Q1006`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Unknown | 32.0 | 3.7 | — | — | — | METAR WBGY 050700Z AUTO VRB02KT //// // ////// 32/26 Q1006 |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 28.0 | 6.1 | 100.0 | — | 0.413 | cloudy |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Partly cloudy | 32.9 | 7.7 | 79.0 | 16.5 | 0.554 | WMO 2 |

### Zamość, Poland (`EPLB`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 10.0 | 14.8 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 10.4 | 11.5 | 0.0 | — | 0.941 | clearsky_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Clear | 9.4 | 6.5 | 0.0 | 13.0 | 0.871 | WMO 0 |

### La Habana Vieja, Cuba (`MUHA`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `FEW`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 21.0 | 3.7 | 20.0 | 8.0 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 22.5 | 23.0 | 0.0 | — | 0.576 | clearsky_night |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Partly cloudy | 23.5 | 15.1 | 69.0 | 24.1 | 0.703 | WMO 2 |

### Flying Fish Cove, Christmas Island (`YPXM`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 26.0 | 9.3 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 25.7 | 15.5 | 100.0 | — | 0.906 | cloudy |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Cloudy | 27.6 | 17.2 | 100.0 | 24.1 | 0.832 | WMO 3 |

### Cayambe, Ecuador (`SEQM`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 14.0 | 5.6 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Fog / low visibility | 10.6 | 13.0 | 100.0 | — | 0.458 | fog |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Cloudy | 14.4 | 2.6 | 99.0 | 24.1 | 0.936 | WMO 3 |

### Empangeni, South Africa (`FARB`)

No METAR observation was available for this city at run time.

### Songwŏn, North Korea (`ZKPY`)

No METAR observation was available for this city at run time.

### Ponte de Lima, Portugal (`LEVX`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `SCT`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 7.0 | 3.7 | 50.0 | 9.7 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 11.0 | 5.8 | 0.0 | — | 0.645 | clearsky_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Fog / low visibility | 9.4 | 4.2 | 48.0 | 2.4 | 0.587 | WMO 45 |

### Santa Lucía Cotzumalguapa, Guatemala (`MGSJ`)

No METAR observation was available for this city at run time.

### Yaren, Nauru (`ANYN`)

No METAR observation was available for this city at run time.

### Las Piedras, Uruguay (`SUAA`)

No METAR observation was available for this city at run time.

### Dabou, Ivory Coast (`DIAP`)

- Observation: `Storm` at `2026-04-05T07:00:00.000Z`
- Observation detail: `FEW`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Storm | 27.0 | 3.7 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 26.5 | 6.1 | 7.8 | — | 0.636 | clearsky_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Fog / low visibility | 26.7 | 2.6 | 100.0 | 24.1 | 0.556 | WMO 45 |

### Dachang, China (`ZGDY`)

No METAR observation was available for this city at run time.

### Shakhtarske, Ukraine (`UKDD`)

No METAR observation was available for this city at run time.

### Basseterre, Saint Kitts and Nevis (`TKPK`)

No METAR observation was available for this city at run time.

### Maubara, Timor Leste (`WPDL`)

No METAR observation was available for this city at run time.

### Villa Constitución, Argentina (`SAAR`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `SCT`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 13.0 | 14.8 | 50.0 | 9.7 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 14.1 | 13.3 | 99.2 | — | 0.728 | cloudy |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Cloudy | 12.8 | 12.5 | 95.0 | 24.1 | 0.804 | WMO 3 |

### Kekem, Cameroon (`FKAN`)

No METAR observation was available for this city at run time.

### Ryōtsu-minato, Japan (`RJSD`)

No METAR observation was available for this city at run time.

### Bayreuth, Germany (`EDQD`)

No METAR observation was available for this city at run time.

### Mariel, Cuba (`MUPB`)

No METAR observation was available for this city at run time.

### Faaa, French Polynesia (`NTAA`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 28.0 | 18.5 | 87.5 | — | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 26.1 | 30.6 | 53.9 | — | 0.446 | rainshowers_night |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Storm | 27.8 | 17.4 | 93.0 | 24.1 | 0.672 | WMO 95 |

### Lelydorp, Suriname (`SMZO`)

No METAR observation was available for this city at run time.

### Koumpentoum, Senegal (`GOTT`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 26.0 | 11.1 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 26.8 | 18.4 | 0.0 | — | 0.874 | clearsky_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Cloudy | 25.1 | 11.4 | 88.0 | 24.1 | 0.586 | WMO 3 |

### Kamālshahr, Iran (`OIIP`)

No METAR observation was available for this city at run time.

### Jihlava, Czechia (`LKNA`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 10.0 | 9.3 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 9.9 | 12.6 | 0.8 | — | 0.961 | clearsky_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Partly cloudy | 10.2 | 9.3 | 12.0 | 25.5 | 0.838 | WMO 1 |

### Tigwav, Haiti (`CTPP`)

No METAR observation was available for this city at run time.

### Dumbéa, New Caledonia (`NWWN`)

No METAR observation was available for this city at run time.

### La Banda, Peru (`SPST`)

No METAR observation was available for this city at run time.

### Bujumbura, Burundi (`HBBA`)

No METAR observation was available for this city at run time.

### Mengcheng Chengguanzhen, China (`ZSOF`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 29.0 | 14.8 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 26.3 | 12.6 | 12.5 | — | 0.841 | clearsky_day |
| Open-Meteo | 2026-04-05T06:15:00.000Z | Cloudy | 28.1 | 18.4 | 84.0 | 24.1 | 0.559 | WMO 3 |

