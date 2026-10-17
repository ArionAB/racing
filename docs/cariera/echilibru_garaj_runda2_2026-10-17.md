# Echilibrul garajului — runda 2 (A/B față de runda 1 și linia de bază), 17 oct 2026

`tools/car_balance.sh` pe commit-ul `ad88cdeb` (runda 2: Muscle 36/15/7,5; Autobuzul 35/14,5; Poliția 34,5/17/9,5; Taxi 35/16/9; Pompierii 35/15/8; Buggy 35/16/8,5 + off-road 0,65; masa comprimată √ în stresul gheții; `hazard_mass_ratio` în vârtej/taifun/macara/monorail). Aceleași 12 piste × 2 seed-uri, 240 s, viteză egală.

**Față de linia de bază (23–35%) și runda 1 (5–11%): ecart 3–6% pe 10 piste din 12.** Locul 1: Poliția 5, Taxi 4, Buggy 2, Pompierii 1, Muscle 0 (dar +0–3% peste tot), Autobuzul 0 (+2–6%, identitatea lui e masa). Cele două veto-uri rămase sunt de **gimmick, nu de mașină**: Serengeti 10% (autobuzul, 13 repuneri pe kicker-ul `FlyoffRamp`), Baikal 20% (gheața: 13–22 repuneri pentru toate mașinile, cel mai bun tur al Poliției și al autobuzului include repuneri — cifre zgomotoase pe 2 seed-uri). Aici se oprește tuning-ul din cifre; urmează verdictul dezvoltatorului la volan.

## Cel mai bun tur (s), minimul pe seed-uri — --equal-speed

| Masina | Monument Valley | Kyoto | Cappadocia | Serengeti | Transfagarasan | Chongqing | Machu Picchu | Okinawa | Baikal | Stromboli | Jodhpur | Fiordland | locul 1 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Muscle | 62.6 (+1%) | 64.8 (+1%) | 71.8 (+0%) | 71.7 (+2%) | 69.0 (+2%) | 67.0 (+2%) | 71.1 (+3%) | 61.8 (+2%) | 51.1 (+3%) | 70.0 (+2%) | 67.6 (+2%) | 67.1 (+3%) | 0 |
| Politia | 62.6 (+1%) | 64.2 (+0%) | 73.9 (+3%) | **70.4** | 68.9 (+2%) | **66.0** | 69.5 (+0%) | **60.9** | 59.8 (+20%) | 69.5 (+1%) | **66.4** | **65.4** | 5 |
| Taxi | 62.9 (+1%) | **64.2** | **71.8** | 71.2 (+1%) | **67.6** | 69.3 (+5%) | **69.2** | 61.5 (+1%) | 50.4 (+1%) | 68.7 (+0%) | 67.2 (+1%) | 67.7 (+3%) | 4 |
| Autobuzul | 64.0 (+3%) | 66.6 (+4%) | 73.5 (+2%) | 77.1 (+10%) | 71.2 (+5%) | 69.6 (+5%) | 73.2 (+6%) | 63.2 (+4%) | 59.8 (+20%) | 71.3 (+4%) | 68.8 (+4%) | 69.4 (+6%) | 0 |
| Pompierii | 63.5 (+2%) | 66.6 (+4%) | 74.4 (+4%) | 74.0 (+5%) | 68.8 (+2%) | 68.0 (+3%) | 71.2 (+3%) | 63.0 (+4%) | **49.7** | 71.5 (+4%) | 68.8 (+4%) | 67.6 (+3%) | 1 |
| Buggy | **62.0** | 65.6 (+2%) | 75.9 (+6%) | 71.1 (+1%) | 68.6 (+1%) | 67.7 (+3%) | 72.0 (+4%) | 61.5 (+1%) | 52.3 (+5%) | **68.7** | 67.2 (+1%) | 67.2 (+3%) | 2 |
| *ecart* | 3% | 4% | 6% | 10% VETO | 5% | 5% | 6% | 4% | 20% VETO | 4% | 4% | 6% | |

## Blocaje / repuneri (suma pe seed-uri; raportate, nu veto — "!" de la 3 blocaje); fara tur complet = VETO

| Masina | Monument Valley | Kyoto | Cappadocia | Serengeti | Transfagarasan | Chongqing | Machu Picchu | Okinawa | Baikal | Stromboli | Jodhpur | Fiordland |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Muscle | 1 / 2 | 0 / 1 | 1 / 1 | 0 / 2 | 0 / 3 | 3 / 5 ! | 0 / 2 | 0 / 0 | 0 / 21 | 0 / 4 | 0 / 0 | 0 / 7 |
| Politia | 2 / 3 | 0 / 0 | 1 / 10 | 0 / 3 | 2 / 3 | 0 / 2 | 0 / 0 | 0 / 2 | 3 / 22 ! | 1 / 11 | 0 / 2 | 0 / 1 |
| Taxi | 0 / 1 | 0 / 0 | 0 / 0 | 0 / 5 | 0 / 2 | 2 / 11 | 2 / 2 | 0 / 0 | 0 / 13 | 0 / 5 | 0 / 0 | 0 / 1 |
| Autobuzul | 0 / 0 | 0 / 0 | 0 / 1 | 0 / 13 | 0 / 1 | 2 / 1 | 0 / 0 | 0 / 0 | 0 / 22 | 5 / 5 ! | 0 / 0 | 2 / 2 |
| Pompierii | 0 / 1 | 0 / 0 | 1 / 5 | 0 / 7 | 0 / 0 | 0 / 4 | 0 / 0 | 0 / 0 | 0 / 18 | 1 / 4 | 0 / 0 | 3 / 1 ! |
| Buggy | 0 / 2 | 0 / 0 | 0 / 4 | 0 / 5 | 0 / 0 | 0 / 1 | 0 / 2 | 0 / 0 | 1 / 15 | 0 / 4 | 0 / 0 | 0 / 0 |

VERDICT: PROBLEMA (2 veto-uri: ecart peste 8% sau masina fara tur complet)
