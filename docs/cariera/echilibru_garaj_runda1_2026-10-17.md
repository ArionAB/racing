# Echilibrul garajului — runda 1 (A/B față de linia de bază), 17 oct 2026

`tools/car_balance.sh` pe commit-ul `e2cc9abd` (runda 1: viteza maximă 34,5–36, Muscle 36/14/7, Poliția 34,5/17/10, Taxi 35, Pompierii 35/15, Autobuzul 34,5/14, Buggy off-road 0,65, `hazard_mass_ratio` în vârtej/taifun/macara/monorail). Aceleași 12 piste × 2 seed-uri, 240 s, viteză egală, ca linia de bază `echilibru_garaj_baseline_2026-10-17_viteza_egala.md`.

**Față de linia de bază:** ecart 23–35% → **5–11%** pe 11 piste; Baikal 32% (autobuzul sparge gheața la fiecare placă — 25 de repuneri). Locul 1: Poliția 8, Taxi 4, restul 0. Muscle a devenit cel mai lent pe 5 piste (accelerația 15 → 14 l-a costat mai mult decât i-a dat plafonul). VETO pe 6 piste (8–11%, plus Baikal). Runda 2: Muscle 36/15/7,5; Autobuzul 35/14,5; Poliția grip 9,5; masa comprimată (√) în stresul gheții.

## Cel mai bun tur (s), minimul pe seed-uri — --equal-speed

| Masina | Monument Valley | Kyoto | Cappadocia | Serengeti | Transfagarasan | Chongqing | Machu Picchu | Okinawa | Baikal | Stromboli | Jodhpur | Fiordland | locul 1 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Muscle | 63.1 (+1%) | 67.1 (+4%) | 76.5 (+9%) | 75.2 (+7%) | 70.7 (+6%) | 70.7 (+11%) | 73.1 (+6%) | 63.8 (+5%) | 58.0 (+11%) | 71.3 (+3%) | 69.8 (+5%) | 68.1 (+4%) | 0 |
| Politia | **62.6** | 65.2 (+1%) | **70.0** | **70.1** | 68.0 (+1%) | 65.5 (+2%) | **69.1** | **60.9** | **52.3** | 69.3 (+0%) | **66.2** | **65.5** | 8 |
| Taxi | 63.6 (+2%) | **64.2** | 71.8 (+3%) | 74.3 (+6%) | **67.0** | **64.0** | 69.5 (+1%) | 62.3 (+2%) | 52.4 (+0%) | **69.0** | 66.6 (+1%) | 65.9 (+1%) | 4 |
| Autobuzul | 65.6 (+5%) | 68.3 (+6%) | 77.9 (+11%) | 77.5 (+11%) | 71.8 (+7%) | 69.9 (+9%) | 74.3 (+7%) | 65.8 (+8%) | 69.1 (+32%) | 73.2 (+6%) | 70.5 (+6%) | 71.0 (+9%) | 0 |
| Pompierii | 63.4 (+1%) | 66.6 (+4%) | 74.3 (+6%) | 74.9 (+7%) | 69.2 (+3%) | 68.5 (+7%) | 71.6 (+4%) | 63.5 (+4%) | 53.9 (+3%) | 70.8 (+3%) | 69.2 (+5%) | 68.7 (+5%) | 0 |
| Buggy | 63.5 (+1%) | 64.8 (+1%) | 74.0 (+6%) | 71.2 (+2%) | 68.7 (+3%) | 65.9 (+3%) | 70.1 (+1%) | 61.5 (+1%) | 54.8 (+5%) | 72.3 (+5%) | 66.6 (+1%) | 67.3 (+3%) | 0 |
| *ecart* | 5% | 6% | 11% VETO | 11% VETO | 7% | 11% VETO | 7% | 8% VETO | 32% VETO | 6% | 6% | 9% VETO | |

## Blocaje / repuneri (suma pe seed-uri; raportate, nu veto — "!" de la 3 blocaje); fara tur complet = VETO

| Masina | Monument Valley | Kyoto | Cappadocia | Serengeti | Transfagarasan | Chongqing | Machu Picchu | Okinawa | Baikal | Stromboli | Jodhpur | Fiordland |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Muscle | 0 / 0 | 0 / 1 | 0 / 4 | 0 / 5 | 0 / 1 | 0 / 2 | 0 / 0 | 2 / 4 | 2 / 26 | 0 / 3 | 0 / 0 | 1 / 1 |
| Politia | 0 / 3 | 4 / 2 ! | 0 / 4 | 1 / 1 | 0 / 3 | 0 / 1 | 0 / 0 | 0 / 0 | 7 / 18 ! | 0 / 2 | 0 / 1 | 0 / 1 |
| Taxi | 0 / 0 | 0 / 1 | 0 / 0 | 0 / 4 | 0 / 1 | 0 / 6 | 0 / 2 | 0 / 2 | 0 / 19 | 0 / 4 | 0 / 0 | 2 / 8 |
| Autobuzul | 0 / 2 | 0 / 0 | 0 / 0 | 0 / 16 | 0 / 2 | 0 / 0 | 0 / 1 | 0 / 2 | 0 / 25 | 3 / 7 ! | 0 / 0 | 0 / 1 |
| Pompierii | 0 / 1 | 0 / 0 | 0 / 4 | 1 / 6 | 0 / 1 | 0 / 5 | 0 / 0 | 0 / 6 | 2 / 20 | 0 / 3 | 0 / 1 | 1 / 2 |
| Buggy | 0 / 0 | 0 / 0 | 0 / 2 | 0 / 5 | 0 / 2 | 0 / 2 | 0 / 1 | 0 / 4 | 1 / 19 | 1 / 7 | 0 / 0 | 0 / 1 |

VERDICT: PROBLEMA (6 veto-uri: ecart peste 8% sau masina fara tur complet)
