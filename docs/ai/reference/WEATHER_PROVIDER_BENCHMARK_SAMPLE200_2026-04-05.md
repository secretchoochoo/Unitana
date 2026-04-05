# Weather Provider Benchmark

- Generated at (UTC): `2026-04-05T07:40:51.203019Z`
- Reference time (UTC): `2026-04-05T07:37:37.223735Z`
- Cities evaluated: `200`
- Selection mode: `expanded-sample`
- Fixture/source: `assets/data/cities_v1.json`
- Observation proxy: `METAR airport observations`
- Observation coverage: `97/200`
- Observation gaps: `103`
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
| Open-Meteo | 97 | 55 | 0.713 | 1.4 | 4.5 | 28.7 | 37% | 8 | 0 |
| MET Norway | 97 | 42 | 0.698 | 1.9 | 7.3 | 24.9 | 47% | 4 | 0 |

## Provider Priors

These priors are the benchmark-derived provider weights intended to feed a future runtime confidence score. They should not override live disagreement signals, but they can bias the system toward the better-performing provider when other signals are close.

| Provider | Prior weight | Raw score |
|---|---:|---:|
| Open-Meteo | 50.2% | 0.590 |
| MET Norway | 49.8% | 0.585 |

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
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 32.7 | 10.9 | 40.0 | 24.1 | 0.420 | WMO 1 |

### Casa Santa, Italy (`LICT`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 12.0 | 3.7 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 14.4 | 6.5 | 0.0 | — | 0.844 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 14.5 | 2.3 | 46.0 | 26.1 | 0.673 | WMO 1 |

### Hazleton, United States (`KHZL`)

- Observation: `Cloudy` at `2026-04-05T07:02:00.000Z`
- Observation detail: `OVC`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:02:00.000Z | Cloudy | 5.0 | 14.8 | 100.0 | 1.6 | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Fog / low visibility | 6.2 | 30.2 | 100.0 | — | 0.493 | fog |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Fog / low visibility | 4.9 | 29.5 | 100.0 | 0.0 | 0.549 | WMO 45 |

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
| Open-Meteo | 2026-04-05T06:30:00.000Z | Fog / low visibility | 18.9 | 3.8 | 64.0 | 24.1 | 0.511 | WMO 45 |

### Tukuyu, Tanzania (`HTMB`)

No METAR observation was available for this city at run time.

### Grytviken, South Georgia and the South Sandwich Islands (`no-metar-station`)

No METAR observation was available for this city at run time.

### Tabanan, Indonesia (`WADD`)

- Observation: `Partly cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `SCT`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Partly cloudy | 30.0 | 16.7 | 50.0 | 9.7 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 26.4 | 15.5 | 78.1 | — | 0.488 | lightrainshowers_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Rain | 29.3 | 11.1 | 100.0 | 24.1 | 0.539 | WMO 80 |

### Kensington, United Kingdom (`EGGP`)

- Observation: `Cloudy` at `2026-04-05T07:20:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:20:00.000Z | Cloudy | 6.0 | 27.8 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 5.2 | 38.5 | 82.8 | — | 0.551 | rainshowers_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Rain | 6.1 | 24.8 | 95.0 | 17.5 | 0.655 | WMO 51 |

### Rosamond, United States (`KWJF`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CLR`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 7.2 | 7.4 | 0.0 | 16.1 | — | CLR |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 15.0 | 4.0 | 0.0 | — | 0.558 | clearsky_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Clear | 12.1 | 10.3 | 2.0 | 90.0 | 0.754 | WMO 0 |

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
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 7.4 | 5.4 | 33.0 | 24.1 | 0.678 | WMO 1 |

### Biu, Nigeria (`DNGO`)

No METAR observation was available for this city at run time.

### Bolārum, India (`VOHY`)

- Observation: `Partly cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `FEW`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Partly cloudy | 33.0 | 9.3 | 20.0 | 6.0 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 32.0 | 10.8 | 47.7 | — | 0.899 | partlycloudy_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 34.5 | 14.2 | 22.0 | 24.1 | 0.882 | WMO 1 |

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

- Observation: `Cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `OVC`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Cloudy | 17.0 | 14.8 | 100.0 | 9.7 | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 17.1 | 23.8 | 32.8 | — | 0.670 | fair_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 17.8 | 12.5 | 87.0 | 24.1 | 0.922 | WMO 3 |

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
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 22.7 | 11.4 | 88.0 | 24.1 | 0.666 | WMO 3 |

### Kanchanaburi, Thailand (`VTBG`)

No METAR observation was available for this city at run time.

### Castellar del Vallès, Spain (`LELL`)

- Observation: `Clear` at `2026-04-05T07:30:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Clear | 14.0 | 0.0 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 13.5 | 7.6 | 0.0 | — | 0.885 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Clear | 16.0 | 3.8 | 0.0 | 39.0 | 0.852 | WMO 0 |

### Acajutla, El Salvador (`MSAC`)

No METAR observation was available for this city at run time.

### Richmond, New Zealand (`NZKI`)

No METAR observation was available for this city at run time.

### Cabrero, Chile (`SCGE`)

No METAR observation was available for this city at run time.

### Nzega, Tanzania (`HTSY`)

No METAR observation was available for this city at run time.

### Mingaladon, Myanmar (`VYYY`)

- Observation: `Partly cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `SCT`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Partly cloudy | 35.0 | 5.6 | 50.0 | 7.0 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 36.6 | 11.5 | 10.2 | — | 0.676 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 36.8 | 8.1 | 62.0 | 24.1 | 0.878 | WMO 2 |

### Telde, Spain (`GCLP`)

- Observation: `Partly cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `FEW`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Partly cloudy | 17.0 | 18.5 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 15.5 | 21.2 | 7.0 | — | 0.753 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 15.5 | 7.4 | 39.0 | 24.1 | 0.795 | WMO 1 |

### Liberia, Costa Rica (`MRLB`)

No METAR observation was available for this city at run time.

### Mangilao Village, Guam (`PGUM`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CLR`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 30.0 | 29.6 | 0.0 | 16.1 | — | CLR |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 29.7 | 34.6 | 40.6 | — | 0.742 | partlycloudy_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 28.4 | 35.1 | 75.0 | 24.1 | 0.628 | WMO 2 |

### Espinal, Colombia (`SKGI`)

No METAR observation was available for this city at run time.

### Sidi Mérouane, Algeria (`DABC`)

- Observation: `Clear` at `2026-04-05T07:30:00.000Z`
- Observation detail: `CLR`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Clear | 7.0 | 3.7 | 0.0 | 9.0 | — | CLR |
| MET Norway | 2026-04-05T07:00:00.000Z | Fog / low visibility | 5.4 | 7.2 | 100.0 | — | 0.524 | fog |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Clear | 7.9 | 1.5 | 1.0 | 20.8 | 0.937 | WMO 0 |

### Şabyā, Saudi Arabia (`OEGN`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `FEW`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 32.0 | 13.0 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 33.7 | 19.8 | 6.2 | — | 0.702 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 32.1 | 13.7 | 96.0 | 24.1 | 0.739 | WMO 3 |

### Brownhills, United Kingdom (`EGBB`)

- Observation: `Partly cloudy` at `2026-04-05T07:20:00.000Z`
- Observation detail: `SCT`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:20:00.000Z | Partly cloudy | 7.0 | 16.7 | 50.0 | 9.7 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 5.7 | 21.6 | 20.3 | — | 0.849 | fair_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 6.3 | 21.6 | 83.0 | 21.9 | 0.736 | WMO 3 |

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

- Observation: `Cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Cloudy | 11.0 | 24.1 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 11.2 | 17.3 | 99.2 | — | 0.771 | partlycloudy_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 11.1 | 20.3 | 100.0 | 26.3 | 0.939 | WMO 3 |

### Cartago, Costa Rica (`MRPV`)

No METAR observation was available for this city at run time.

### Papeete, French Polynesia (`NTAA`)

- Observation: `Cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `OVC`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Cloudy | 29.0 | 20.4 | 100.0 | — | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 25.7 | 36.7 | 86.7 | — | 0.372 | rain |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Storm | 27.9 | 17.4 | 93.0 | 24.1 | 0.612 | WMO 95 |

### Fusagasugá, Colombia (`SKBO`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 14.0 | 3.7 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 16.1 | 5.0 | 100.0 | — | 0.876 | cloudy |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Storm | 18.4 | 2.1 | 100.0 | 18.3 | 0.473 | WMO 95 |

### Hoima, Uganda (`HUMI`)

No METAR observation was available for this city at run time.

### Yazman, Pakistan (`OPMT`)

- Observation: `Partly cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `FEW`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Partly cloudy | 26.0 | 0.0 | 20.0 | 7.0 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 28.3 | 8.6 | 17.2 | — | 0.809 | fair_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Clear | 27.8 | 9.3 | 0.0 | 24.1 | 0.663 | WMO 0 |

### Leszno, Poland (`EPPO`)

- Observation: `Clear` at `2026-04-05T07:30:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Clear | 13.0 | 22.2 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 10.5 | 14.0 | 32.0 | — | 0.626 | fair_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 11.6 | 12.9 | 15.0 | 31.9 | 0.688 | WMO 1 |

### Ancaster, Canada (`CYHM`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `OVC`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 8.0 | 24.1 | 100.0 | 24.1 | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 7.4 | 28.4 | 100.0 | — | 0.918 | cloudy |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 6.4 | 24.4 | 100.0 | 18.3 | 0.914 | WMO 3 |

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
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 28.7 | 35.1 | 75.0 | 24.1 | 0.641 | WMO 2 |

### Pilar, Argentina (`SADD`)

No METAR observation was available for this city at run time.

### Lalibela, Ethiopia (`HADC`)

No METAR observation was available for this city at run time.

### Ciampea, Indonesia (`WIIA`)

No METAR observation was available for this city at run time.

### Zelenogradsk, Russia (`UMKK`)

- Observation: `Clear` at `2026-04-05T07:30:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Clear | 9.0 | 18.5 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 5.7 | 13.3 | 1.8 | — | 0.801 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 7.0 | 14.8 | 32.0 | 35.7 | 0.692 | WMO 1 |

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
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 10.2 | 3.4 | 17.0 | 24.1 | 0.658 | WMO 1 |

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
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 32.9 | 8.0 | 79.0 | 16.5 | 0.550 | WMO 2 |

### Zamość, Poland (`EPLB`)

- Observation: `Clear` at `2026-04-05T07:30:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Clear | 11.0 | 20.4 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 10.4 | 11.5 | 0.0 | — | 0.865 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Clear | 10.3 | 8.3 | 0.0 | 13.0 | 0.822 | WMO 0 |

### La Habana Vieja, Cuba (`MUHA`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `FEW`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 21.0 | 3.7 | 20.0 | 8.0 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 22.5 | 23.0 | 0.0 | — | 0.576 | clearsky_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 23.5 | 14.4 | 69.0 | 24.1 | 0.710 | WMO 2 |

### Flying Fish Cove, Christmas Island (`YPXM`)

- Observation: `Partly cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `FEW`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Partly cloudy | 26.0 | 7.4 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 25.7 | 15.5 | 100.0 | — | 0.651 | cloudy |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 27.6 | 17.1 | 100.0 | 24.1 | 0.578 | WMO 3 |

### Cayambe, Ecuador (`SEQM`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 14.0 | 5.6 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Fog / low visibility | 10.6 | 13.0 | 100.0 | — | 0.458 | fog |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 14.3 | 2.9 | 99.0 | 24.1 | 0.943 | WMO 3 |

### Empangeni, South Africa (`FARB`)

No METAR observation was available for this city at run time.

### Songwŏn, North Korea (`ZKPY`)

No METAR observation was available for this city at run time.

### Ponte de Lima, Portugal (`LEVX`)

- Observation: `Partly cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `FEW`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Partly cloudy | 8.0 | 3.7 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 11.0 | 5.8 | 0.0 | — | 0.683 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Fog / low visibility | 10.6 | 3.5 | 48.0 | 2.4 | 0.542 | WMO 45 |

### Santa Lucía Cotzumalguapa, Guatemala (`MGSJ`)

No METAR observation was available for this city at run time.

### Yaren, Nauru (`ANYN`)

No METAR observation was available for this city at run time.

### Las Piedras, Uruguay (`SUAA`)

No METAR observation was available for this city at run time.

### Dabou, Ivory Coast (`DIAP`)

- Observation: `Storm` at `2026-04-05T07:30:00.000Z`
- Observation detail: `FEW`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Storm | 28.0 | 7.4 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 26.5 | 6.1 | 7.8 | — | 0.603 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Fog / low visibility | 27.0 | 3.4 | 100.0 | 24.1 | 0.496 | WMO 45 |

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
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 12.8 | 12.5 | 95.0 | 24.1 | 0.804 | WMO 3 |

### Kekem, Cameroon (`FKAN`)

No METAR observation was available for this city at run time.

### Ryōtsu-minato, Japan (`RJSD`)

No METAR observation was available for this city at run time.

### Bayreuth, Germany (`EDQD`)

No METAR observation was available for this city at run time.

### Mariel, Cuba (`MUPB`)

No METAR observation was available for this city at run time.

### Faaa, French Polynesia (`NTAA`)

- Observation: `Cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `OVC`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Cloudy | 29.0 | 20.4 | 100.0 | — | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 26.1 | 30.6 | 53.9 | — | 0.402 | rainshowers_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Storm | 27.8 | 17.4 | 93.0 | 24.1 | 0.607 | WMO 95 |

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
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 25.2 | 11.3 | 88.0 | 24.1 | 0.591 | WMO 3 |

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
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 10.7 | 11.3 | 0.0 | 26.4 | 0.814 | WMO 1 |

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
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 27.9 | 17.3 | 84.0 | 24.1 | 0.561 | WMO 3 |

### Drobeta-Turnu Severin, Romania (`LRCS`)

No METAR observation was available for this city at run time.

### Petit-Bourg, Guadeloupe (`TFFR`)

- Observation: `Rain` at `2026-04-05T07:30:00.000Z`
- Observation detail: `FEW`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Rain | 24.0 | 9.3 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 23.7 | 25.9 | 52.3 | — | 0.772 | lightrainshowers_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 23.8 | 13.8 | 82.0 | 24.1 | 0.553 | WMO 3 |

### Pago Pago, American Samoa (`NSTU`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 27.9 | 3.7 | 87.5 | 16.1 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 26.2 | 8.6 | 96.9 | — | 0.727 | partlycloudy_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 27.4 | 12.8 | 77.0 | 24.1 | 0.736 | WMO 2 |

### Santiago de Surco, Peru (`SPIM`)

No METAR observation was available for this city at run time.

### Tizi Rached, Algeria (`DAAE`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 10.0 | 24.1 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 7.0 | 5.4 | 0.0 | — | 0.626 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Clear | 8.7 | 0.7 | 12.0 | 22.6 | 0.725 | WMO 0 |

### Naju, South Korea (`RKJJ`)

No METAR observation was available for this city at run time.

### Kotlas, Russia (`ULKK`)

No METAR observation was available for this city at run time.

### Sangre Grande, Trinidad and Tobago (`TTPP`)

- Observation: `Rain` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Rain | 24.0 | 5.6 | 87.5 | 6.0 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 23.1 | 23.0 | 100.0 | — | 0.767 | rain |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 24.8 | 9.9 | 100.0 | 18.3 | 0.603 | WMO 3 |

### Alofi, Niue (`NIUE`)

- Observation: `Clear` at `2026-04-05T07:30:00.000Z`
- Observation detail: `CLR`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Clear | 25.0 | 1.9 | 0.0 | 9.7 | — | CLR |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 27.6 | 22.3 | 100.0 | — | 0.502 | partlycloudy_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 27.9 | 15.0 | 100.0 | 24.1 | 0.352 | WMO 3 |

### Tena, Ecuador (`SEJD`)

No METAR observation was available for this city at run time.

### Hwange, Zimbabwe (`FVWN`)

No METAR observation was available for this city at run time.

### Pattoki, Pakistan (`OPLH`)

No METAR observation was available for this city at run time.

### Campo De Ourique, Portugal (`LPPT`)

- Observation: `Clear` at `2026-04-05T07:30:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Clear | 14.0 | 7.4 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 13.9 | 7.9 | 63.3 | — | 0.761 | partlycloudy_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 14.9 | 2.9 | 19.0 | 33.5 | 0.752 | WMO 1 |

### Linstead, Jamaica (`MKJP`)

- Observation: `Unknown` at `2026-04-05T07:00:00.000Z`
- Observation detail: `METAR MKJP 050700Z 36006KT //// ////// 25/20 Q1013 RMK CLD FROM CEILOMETER RWY 30 NCD`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Unknown | 25.0 | 11.1 | — | — | — | METAR MKJP 050700Z 36006KT //// ////// 25/20 Q1013 RMK CLD FROM CEILOMETER RWY 30 NCD |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 20.7 | 7.2 | 7.8 | — | 0.380 | clearsky_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Fog / low visibility | 19.5 | 4.1 | 55.0 | 23.7 | 0.281 | WMO 45 |

### Funafuti, Tuvalu (`NGFU`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 29.0 | 7.4 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 29.2 | 14.4 | 100.0 | — | 0.768 | partlycloudy_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 29.3 | 18.0 | 52.0 | 24.1 | 0.693 | WMO 2 |

### Tarija, Bolivia (`SLTJ`)

No METAR observation was available for this city at run time.

### Logīya, Ethiopia (`HADC`)

No METAR observation was available for this city at run time.

### Chubek, Tajikistan (`UTDK`)

- Observation: `Clear` at `2026-04-05T07:30:00.000Z`
- Observation detail: `CLR`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Clear | 24.0 | 3.7 | 0.0 | 9.7 | — | CLR |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 23.2 | 9.7 | 36.7 | — | 0.715 | fair_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 23.5 | 7.4 | 27.0 | 24.1 | 0.766 | WMO 1 |

### Blankenfelde-Mahlow, Germany (`EDDB`)

- Observation: `Clear` at `2026-04-05T07:20:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:20:00.000Z | Clear | 14.0 | 33.3 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 12.1 | 20.2 | 100.0 | — | 0.395 | cloudy |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 13.2 | 21.7 | 100.0 | 32.4 | 0.459 | WMO 3 |

### Estelí, Nicaragua (`MNJG`)

No METAR observation was available for this city at run time.

### Tandai, Solomon Islands (`AGGH`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 30.0 | 3.7 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 25.8 | 11.9 | 99.2 | — | 0.417 | heavyrain |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 27.6 | 2.5 | 84.0 | 12.1 | 0.878 | WMO 3 |

### Kourou, French Guiana (`SOCA`)

- Observation: `Rain` at `2026-04-05T07:30:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Rain | 24.0 | 1.9 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 26.8 | 30.6 | 100.0 | — | 0.350 | cloudy |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 24.8 | 5.4 | 90.0 | 24.1 | 0.495 | WMO 3 |

### Samfya, Zambia (`FLMA`)

No METAR observation was available for this city at run time.

### Nyaung, Myanmar (`VYYY`)

- Observation: `Partly cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `SCT`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Partly cloudy | 35.0 | 5.6 | 50.0 | 7.0 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 36.7 | 12.2 | 9.4 | — | 0.663 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 36.9 | 8.1 | 62.0 | 24.1 | 0.873 | WMO 2 |

### Burgdorf, Switzerland (`LSZB`)

- Observation: `Clear` at `2026-04-05T07:20:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:20:00.000Z | Clear | 10.0 | 1.9 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 8.8 | 13.0 | 2.3 | — | 0.833 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Clear | 11.3 | 1.5 | 0.0 | 29.1 | 0.929 | WMO 0 |

### Rio Claro, Trinidad and Tobago (`TTPP`)

- Observation: `Rain` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Rain | 24.0 | 5.6 | 87.5 | 6.0 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 22.8 | 12.6 | 100.0 | — | 0.858 | rain |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Storm | 24.2 | 7.0 | 100.0 | 24.0 | 0.658 | WMO 95 |

### Mont-Dore, New Caledonia (`NWWN`)

No METAR observation was available for this city at run time.

### San Juan Bautista, Paraguay (`SGSJ`)

No METAR observation was available for this city at run time.

### Bembla et Mnara, Tunisia (`DTTM`)

No METAR observation was available for this city at run time.

### Thới Bình, Vietnam (`VVCT`)

- Observation: `Partly cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `SCT`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Partly cloudy | 35.0 | 11.1 | 50.0 | 9.7 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 36.1 | 12.2 | 14.8 | — | 0.888 | fair_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 34.7 | 12.4 | 75.0 | 24.1 | 0.936 | WMO 2 |

### Delft, The Netherlands (`EHRD`)

- Observation: `Partly cloudy` at `2026-04-05T07:25:00.000Z`
- Observation detail: `FEW`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:25:00.000Z | Partly cloudy | 11.0 | 27.8 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 10.4 | 29.9 | 100.0 | — | 0.698 | cloudy |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 11.1 | 28.1 | 99.0 | 50.0 | 0.739 | WMO 3 |

### Juticalpa, Honduras (`MHCA`)

No METAR observation was available for this city at run time.

### Nasinu, Fiji (`NFNA`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 25.0 | 5.6 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 24.1 | 21.6 | 100.0 | — | 0.481 | rain |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Rain | 25.7 | 6.8 | 100.0 | 7.6 | 0.638 | WMO 80 |

### Rémire-Montjoly, French Guiana (`SOCA`)

- Observation: `Rain` at `2026-04-05T07:30:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Rain | 24.0 | 1.9 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 26.7 | 29.9 | 100.0 | — | 0.357 | cloudy |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 24.7 | 1.8 | 88.0 | 24.1 | 0.537 | WMO 3 |

### Monapo, Mozambique (`FQLU`)

No METAR observation was available for this city at run time.

### El Nido, Philippines (`RPVP`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `FEW`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 33.0 | 18.5 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 31.3 | 15.8 | 89.1 | — | 0.795 | partlycloudy_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 30.6 | 15.1 | 31.0 | 24.1 | 0.844 | WMO 1 |

### Oulunkylä, Finland (`EFHK`)

- Observation: `Cloudy` at `2026-04-05T07:20:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:20:00.000Z | Cloudy | 4.0 | 7.4 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 4.3 | 4.7 | 100.0 | — | 0.941 | cloudy |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 4.3 | 6.1 | 100.0 | 30.8 | 0.955 | WMO 3 |

### Barceloneta, Puerto Rico (`TJIG`)

No METAR observation was available for this city at run time.

### Lospalos, Timor Leste (`WPEC`)

No METAR observation was available for this city at run time.

### Yby Yaú, Paraguay (`SGPJ`)

No METAR observation was available for this city at run time.

### Sanyang, Gambia (`GBYD`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 25.0 | 11.1 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 22.6 | 20.2 | 0.0 | — | 0.770 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Clear | 23.2 | 14.7 | 5.0 | 24.1 | 0.878 | WMO 0 |

### Chuk Yuen, Hong Kong (`VHCH`)

No METAR observation was available for this city at run time.

### Boom, Belgium (`EBAW`)

- Observation: `Cloudy` at `2026-04-05T07:20:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:20:00.000Z | Cloudy | 11.0 | 24.1 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 11.6 | 22.0 | 100.0 | — | 0.934 | cloudy |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 11.3 | 25.2 | 100.0 | 50.0 | 0.957 | WMO 3 |

### Noord, Aruba (`TNCA`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `SCT`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 26.0 | 33.3 | 50.0 | 9.7 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 26.2 | 37.4 | 21.1 | — | 0.907 | fair_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 26.5 | 34.9 | 64.0 | 24.1 | 0.941 | WMO 2 |

### Malango, Solomon Islands (`AGGH`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 30.0 | 3.7 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 28.5 | 21.2 | 100.0 | — | 0.440 | heavyrain |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 29.7 | 3.8 | 85.0 | 12.1 | 0.982 | WMO 3 |

### Beekhuizen, Suriname (`SMZO`)

No METAR observation was available for this city at run time.

### Zuru, Nigeria (`DNSO`)

No METAR observation was available for this city at run time.

### Toa Payoh New Town, Singapore (`WSAP`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 33.0 | 18.5 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 31.9 | 10.4 | 85.9 | — | 0.734 | partlycloudy_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 31.2 | 5.7 | 98.0 | 24.1 | 0.777 | WMO 3 |

### Odorheiu Secuiesc, Romania (`LRBV`)

- Observation: `Clear` at `2026-04-05T07:30:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Clear | 10.0 | 3.7 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 9.0 | 5.4 | 10.9 | — | 0.923 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 10.8 | 3.1 | 33.0 | 40.3 | 0.774 | WMO 1 |

### Yoro, Honduras (`MHYR`)

No METAR observation was available for this city at run time.

### Port-Vila, Vanuatu (`NVVV`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 27.0 | 9.3 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 25.5 | 32.4 | 89.8 | — | 0.731 | cloudy |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 27.0 | 17.1 | 51.0 | 24.1 | 0.732 | WMO 2 |

### Linden, Guyana (`SYCJ`)

- Observation: `Rain` at `2026-04-05T07:16:00.000Z`
- Observation detail: `OVC`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:16:00.000Z | Rain | 24.0 | 3.7 | 100.0 | 4.0 | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 22.6 | 4.7 | 100.0 | — | 0.916 | rain |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 23.8 | 2.9 | 93.0 | 24.1 | 0.673 | WMO 3 |

### Abomey, Benin (`DBBC`)

No METAR observation was available for this city at run time.

### Tsirang, Bhutan (`VQPR`)

- Observation: `Partly cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `SCT`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Partly cloudy | 23.0 | 33.3 | 50.0 | 9.7 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 18.8 | 9.7 | 100.0 | — | 0.302 | rain |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 21.8 | 11.8 | 91.0 | 6.0 | 0.551 | WMO 3 |

### Yambol, Bulgaria (`LBIA`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `SCT`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 15.0 | 7.4 | 50.0 | 9.7 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 13.7 | 6.8 | 1.6 | — | 0.730 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Rain | 13.5 | 2.0 | 58.0 | 30.2 | 0.568 | WMO 61 |

### Kralendijk, Bonaire, Saint Eustatius and Saba (`TNCB`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 27.0 | 27.8 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 26.3 | 38.9 | 58.6 | — | 0.680 | partlycloudy_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 26.4 | 32.4 | 76.0 | 24.1 | 0.775 | WMO 2 |

### Nuku‘alofa, Tonga (`NFTF`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 25.0 | 5.6 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 27.5 | 19.4 | 100.0 | — | 0.733 | cloudy |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 25.9 | 14.4 | 100.0 | 24.1 | 0.853 | WMO 3 |

### Stanley, Falkland Islands (`SFAL`)

No METAR observation was available for this city at run time.

### Qillīn, Egypt (`HESX`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 21.0 | 9.3 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 22.0 | 6.5 | 0.0 | — | 0.916 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Clear | 20.1 | 5.8 | 0.0 | 42.3 | 0.913 | WMO 0 |

### Horasan, Turkey (`LTCE`)

- Observation: `Partly cloudy` at `2026-04-05T07:20:00.000Z`
- Observation detail: `SCT`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:20:00.000Z | Partly cloudy | 8.0 | 13.0 | 50.0 | 9.7 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 5.9 | 8.3 | 93.7 | — | 0.796 | partlycloudy_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 8.4 | 12.1 | 94.0 | 41.4 | 0.773 | WMO 3 |

### Watermael-Boitsfort, Belgium (`EBBR`)

- Observation: `Cloudy` at `2026-04-05T07:20:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:20:00.000Z | Cloudy | 11.0 | 22.2 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 11.5 | 23.0 | 99.2 | — | 0.952 | cloudy |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 11.0 | 22.0 | 100.0 | 50.0 | 0.968 | WMO 3 |

### Half Way Tree, Jamaica (`MKJP`)

- Observation: `Unknown` at `2026-04-05T07:00:00.000Z`
- Observation detail: `METAR MKJP 050700Z 36006KT //// ////// 25/20 Q1013 RMK CLD FROM CEILOMETER RWY 30 NCD`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Unknown | 25.0 | 11.1 | — | — | — | METAR MKJP 050700Z 36006KT //// ////// 25/20 Q1013 RMK CLD FROM CEILOMETER RWY 30 NCD |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 21.5 | 8.3 | 1.6 | — | 0.434 | clearsky_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 21.6 | 5.1 | 37.0 | 24.1 | 0.401 | WMO 1 |

### Apia, Samoa (`NSAP`)

No METAR observation was available for this city at run time.

### Georgetown, Guyana (`SYGO`)

No METAR observation was available for this city at run time.

### Ben Jerrar, Morocco (`GMAD`)

- Observation: `Clear` at `2026-04-05T07:30:00.000Z`
- Observation detail: `CLR`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Clear | 14.0 | 5.6 | 0.0 | 8.0 | — | CLR |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 12.1 | 5.0 | 7.0 | — | 0.901 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Fog / low visibility | 15.0 | 1.8 | 76.0 | 0.8 | 0.505 | WMO 45 |

### City One, Hong Kong (`VHCH`)

No METAR observation was available for this city at run time.

### Einsiedeln, Switzerland (`LSMD`)

- Observation: `Clear` at `2026-04-05T07:20:00.000Z`
- Observation detail: `CLR`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:20:00.000Z | Clear | 12.0 | 7.4 | 0.0 | — | — | CLR |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 8.5 | 7.9 | 0.0 | — | 0.814 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 12.5 | 6.2 | 1.0 | 40.5 | 0.830 | WMO 1 |

### Levittown, Puerto Rico (`TJIG`)

No METAR observation was available for this city at run time.

### Majuro, Marshall Islands (`PKMR`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `OVC`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 28.8 | 22.2 | 100.0 | 24.1 | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 27.5 | 32.4 | 100.0 | — | 0.541 | rain |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 28.1 | 29.4 | 86.0 | 10.6 | 0.877 | WMO 3 |

### Cametá, Brazil (`SBBE`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 25.0 | 0.0 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 24.0 | 13.3 | 100.0 | — | 0.439 | heavyrain |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Rain | 24.0 | 2.2 | 100.0 | 24.1 | 0.570 | WMO 80 |

### Kandi, Benin (`DBBK`)

No METAR observation was available for this city at run time.

### Navoiy, Uzbekistan (`UZSA`)

- Observation: `Cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Cloudy | 23.0 | 14.8 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 24.4 | 19.8 | 11.7 | — | 0.535 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 21.7 | 19.1 | 79.0 | 24.1 | 0.753 | WMO 2 |

### Kiskőrös, Hungary (`LHKE`)

- Observation: `Clear` at `2026-04-05T07:15:00.000Z`
- Observation detail: `CAVOK`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:15:00.000Z | Clear | 13.0 | 9.3 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 11.9 | 9.0 | 4.7 | — | 0.942 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Clear | 12.5 | 7.6 | 0.0 | 11.0 | 0.955 | WMO 0 |

### Roseau, Dominica (`TDPR`)

No METAR observation was available for this city at run time.

### Suva, Fiji (`NFLB`)

No METAR observation was available for this city at run time.

### Nova Mutum, Brazil (`SBCY`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 23.0 | 3.7 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 22.1 | 6.1 | 89.1 | — | 0.934 | cloudy |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Fog / low visibility | 21.7 | 2.3 | 90.0 | 24.1 | 0.625 | WMO 45 |

### Goudomp, Senegal (`GOGG`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 20.0 | 7.4 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 22.1 | 6.1 | 0.8 | — | 0.894 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 22.7 | 4.1 | 28.0 | 24.1 | 0.672 | WMO 1 |

### Cabayangan, Philippines (`RPMD`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `SCT`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 35.0 | 11.1 | 50.0 | 9.7 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 33.4 | 18.7 | 18.0 | — | 0.806 | fair_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 36.0 | 11.5 | 74.0 | 24.1 | 0.916 | WMO 2 |

### Mátyásföld, Hungary (`LHBP`)

- Observation: `Clear` at `2026-04-05T07:30:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Clear | 14.0 | 3.7 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 11.9 | 4.3 | 11.7 | — | 0.884 | clearsky_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 14.1 | 5.0 | 50.0 | 16.5 | 0.773 | WMO 2 |

### Esperanza, Dominican Republic (`MDST`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `SCT`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 20.0 | 0.0 | 50.0 | 9.7 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 21.2 | 14.0 | 43.0 | — | 0.797 | partlycloudy_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 20.8 | 3.4 | 19.0 | 24.1 | 0.885 | WMO 1 |

### Tarawa, Kiribati (`NGTT`)

No METAR observation was available for this city at run time.

### Dias d'Ávila, Brazil (`SBSV`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 24.0 | 20.4 | 87.5 | 8.0 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 22.8 | 4.7 | 75.8 | — | 0.473 | heavyrainshowers_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Rain | 24.3 | 1.3 | 69.0 | 24.1 | 0.468 | WMO 80 |

### Ankazoabo, Madagascar (`FMSO`)

No METAR observation was available for this city at run time.

### Qusar, Azerbaijan (`UBBQ`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `OVC`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 11.0 | 7.4 | 100.0 | 9.7 | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 7.5 | 24.1 | 100.0 | — | 0.380 | heavyrain |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Rain | 9.0 | 14.0 | 100.0 | 13.3 | 0.547 | WMO 61 |

### Floreşti, Moldova (`LUBM`)

No METAR observation was available for this city at run time.

### Quezaltepeque, El Salvador (`MSSS`)

No METAR observation was available for this city at run time.

### Ngerulmud, Palau (`PTRO`)

- Observation: `Cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Cloudy | 29.0 | 18.5 | 87.5 | 20.9 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 26.6 | 16.6 | 93.7 | — | 0.566 | rain |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 28.0 | 13.6 | 100.0 | 24.1 | 0.895 | WMO 3 |

### Venâncio Aires, Brazil (`SBCX`)

No METAR observation was available for this city at run time.

### Serowe, Botswana (`FBSP`)

No METAR observation was available for this city at run time.

### Ki̇̄rtipur, Nepal (`VNKT`)

- Observation: `Partly cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `FEW`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Partly cloudy | 25.0 | 9.3 | 20.0 | 9.7 | — | FEW |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 19.1 | 10.8 | 36.7 | — | 0.701 | fair_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 22.4 | 6.1 | 77.0 | 24.1 | 0.769 | WMO 2 |

### Elefsína, Greece (`LGEL`)

- Observation: `Cloudy` at `2026-04-05T07:20:00.000Z`
- Observation detail: `BKN`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:20:00.000Z | Cloudy | 16.0 | 18.5 | 87.5 | 9.7 | — | BKN |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 15.4 | 21.2 | 20.3 | — | 0.711 | fair_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Cloudy | 16.3 | 15.9 | 100.0 | 38.3 | 0.942 | WMO 3 |

### Constanza, Dominican Republic (`MDST`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `SCT`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 20.0 | 0.0 | 50.0 | 9.7 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Fog / low visibility | 14.6 | 8.6 | 53.1 | — | 0.373 | fog |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Fog / low visibility | 14.1 | 1.8 | 76.0 | 24.1 | 0.385 | WMO 45 |

### Kingston, Norfolk Island (`YSNF`)

- Observation: `Cloudy` at `2026-04-05T07:30:00.000Z`
- Observation detail: `OVC`
- Winner: `Open-Meteo`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:30:00.000Z | Cloudy | 22.0 | 13.0 | 100.0 | 9.7 | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Rain | 23.0 | 24.1 | 64.1 | — | 0.491 | rainshowers_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Rain | 22.2 | 16.3 | 89.0 | 24.1 | 0.641 | WMO 80 |

### Mangaratiba, Brazil (`SBSC`)

- Observation: `Clear` at `2026-04-05T07:00:00.000Z`
- Observation detail: `CAVOK`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Clear | 22.0 | 5.6 | 0.0 | 10.0 | — | CAVOK |
| MET Norway | 2026-04-05T07:00:00.000Z | Clear | 22.1 | 9.7 | 0.0 | — | 0.946 | clearsky_night |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 25.0 | 7.2 | 30.0 | 24.1 | 0.672 | WMO 1 |

### Kirambo, Rwanda (`HRZA`)

No METAR observation was available for this city at run time.

### Bījār, Iran (`OICS`)

No METAR observation was available for this city at run time.

### Seinäjoki, Finland (`EFSI`)

- Observation: `Cloudy` at `2026-04-05T07:20:00.000Z`
- Observation detail: `OVC`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:20:00.000Z | Cloudy | 2.0 | 9.3 | 100.0 | 9.7 | — | OVC |
| MET Norway | 2026-04-05T07:00:00.000Z | Cloudy | 3.1 | 9.0 | 100.0 | — | 0.940 | cloudy |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Rain | 3.2 | 10.1 | 100.0 | 22.6 | 0.639 | WMO 51 |

### Pétionville, Haiti (`CTPP`)

No METAR observation was available for this city at run time.

### Saipan, Northern Mariana Islands (`PGSN`)

- Observation: `Partly cloudy` at `2026-04-05T07:00:00.000Z`
- Observation detail: `SCT`
- Winner: `MET Norway`

| Source | Sampled at UTC | Bucket | Temp C | Wind km/h | Cloud % | Vis km | Composite | Notes |
|---|---|---|---:|---:|---:|---:|---:|---|
| METAR | 2026-04-05T07:00:00.000Z | Partly cloudy | 28.3 | 27.8 | 50.0 | 16.1 | — | SCT |
| MET Norway | 2026-04-05T07:00:00.000Z | Partly cloudy | 27.1 | 34.9 | 46.1 | — | 0.870 | partlycloudy_day |
| Open-Meteo | 2026-04-05T06:30:00.000Z | Partly cloudy | 26.4 | 32.6 | 19.0 | 24.1 | 0.822 | WMO 1 |

### Tambaú, Brazil (`SBYS`)

No METAR observation was available for this city at run time.

