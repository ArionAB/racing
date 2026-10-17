# Echilibrul garajului — linia de bază la viteză egală, 17 oct 2026

Raportul `tools/car_balance.sh` (PR #553) pe main `0b9d21e6`: 12 piste din carieră × 2 seed-uri, 240 s/cursă, jucător = Muscle, adversari = Poliția, Taxi, Autobuzul, Pompierii, Buggy (`--ai-cars=1,2,3,4,5`), **toate la `speed_scale` 1,0** (`--equal-speed`), același `AIController` la volanul tuturor. Minimul pe seed-uri = potențialul mașinii, nu media zgomotului. Înlocuiește linia de bază din 16 oct (`echilibru_garaj_baseline_2026-10-16.md`), care avea slotul jucătorului la 1,0 și grila la 0,88–0,97.

E **„înainte”-le pasului 0** (brief `mod_cariera.md` §2.1, §11): orice retuning de `CarData` se compară cu tabelul ăsta, pe aceleași piste și seed-uri.

## Cel mai bun tur (s), minimul pe seed-uri — --equal-speed

| Masina | Monument Valley | Kyoto | Cappadocia | Serengeti | Transfagarasan | Chongqing | Machu Picchu | Okinawa | Baikal | Stromboli | Jodhpur | Fiordland | locul 1 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Muscle | 61.6 (+2%) | 64.1 (+3%) | 73.2 (+7%) | 71.1 (+3%) | 69.2 (+5%) | 64.2 (+2%) | 70.2 (+4%) | 61.0 (+4%) | 52.8 (+4%) | 68.7 (+1%) | 66.5 (+3%) | 67.1 (+5%) | 0 |
| Politia | **60.5** | **62.5** | **68.5** | **69.3** | **65.7** | **63.2** | **67.8** | **58.9** | **50.9** | **68.2** | **64.5** | **63.9** | 12 |
| Taxi | 64.0 (+6%) | 66.8 (+7%) | 71.4 (+4%) | 74.7 (+8%) | 70.2 (+7%) | 67.9 (+7%) | 71.8 (+6%) | 64.2 (+9%) | 53.2 (+4%) | 71.5 (+5%) | 69.1 (+7%) | 69.2 (+8%) | 0 |
| Autobuzul | 77.0 (+27%) | 81.8 (+31%) | 92.3 (+35%) | 15.8 FALS | 85.3 (+30%) | 83.0 (+31%) | 86.8 (+28%) | 77.9 (+32%) | 67.1 (+32%) | 84.1 (+23%) | 82.2 (+27%) | 83.9 (+31%) | 0 |
| Pompierii | 72.5 (+20%) | 75.8 (+21%) | 83.5 (+22%) | 87.0 (+25%) | 79.0 (+20%) | 77.5 (+22%) | 81.9 (+21%) | 71.6 (+22%) | 59.7 (+17%) | 79.6 (+17%) | 77.2 (+20%) | 79.2 (+24%) | 0 |
| Buggy | 61.6 (+2%) | 64.7 (+4%) | 70.8 (+3%) | 73.0 (+5%) | 68.1 (+4%) | 65.5 (+4%) | 70.0 (+3%) | 61.6 (+5%) | 52.8 (+4%) | 68.9 (+1%) | 66.6 (+3%) | 65.9 (+3%) | 0 |
| *ecart* | 27% VETO | 31% VETO | 35% VETO | 25% VETO | 30% VETO | 31% VETO | 28% VETO | 32% VETO | 32% VETO | 23% VETO | 27% VETO | 31% VETO | |

## Blocaje / repuneri (suma pe seed-uri; raportate, nu veto — "!" de la 3 blocaje); fara tur complet = VETO

| Masina | Monument Valley | Kyoto | Cappadocia | Serengeti | Transfagarasan | Chongqing | Machu Picchu | Okinawa | Baikal | Stromboli | Jodhpur | Fiordland |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Muscle | 0 / 1 | 0 / 0 | 0 / 1 | 0 / 2 | 0 / 4 | 0 / 3 | 0 / 0 | 0 / 0 | 2 / 29 | 0 / 2 | 0 / 0 | 0 / 0 |
| Politia | 0 / 0 | 4 / 2 ! | 0 / 3 | 1 / 1 | 0 / 1 | 0 / 0 | 0 / 0 | 0 / 2 | 0 / 25 | 0 / 7 | 0 / 3 | 0 / 2 |
| Taxi | 0 / 2 | 1 / 1 | 0 / 1 | 0 / 7 | 0 / 2 | 0 / 4 | 0 / 3 | 0 / 0 | 0 / 17 | 0 / 3 | 0 / 0 | 0 / 1 |
| Autobuzul | 0 / 0 | 0 / 0 | 0 / 1 | 1 / 18 tur fals | 0 / 0 | 3 / 2 ! | 2 / 1 | 2 / 3 | 0 / 14 | 3 / 3 ! | 0 / 0 | 0 / 0 |
| Pompierii | 0 / 3 | 0 / 0 | 0 / 0 | 0 / 7 | 0 / 0 | 0 / 3 | 3 / 3 ! | 0 / 0 | 0 / 11 | 1 / 6 | 0 / 0 | 0 / 4 |
| Buggy | 0 / 1 | 0 / 0 | 0 / 3 | 0 / 6 | 0 / 1 | 0 / 1 | 1 / 0 | 0 / 2 | 0 / 14 | 2 / 7 | 0 / 0 | 1 / 1 |

VERDICT: PROBLEMA (12 veto-uri: ecart peste 8% sau masina fara tur complet)

## Citire

- **Poliția prima pe 12 din 12 piste**; Muscle +1–7%, Buggy +1–5%, Taxi +4–9%, Pompierii +17–25%, Autobuzul +23–35%. Ecart 23–35% pe fiecare pistă — VETO peste tot, cum trebuie să arate linia de bază.
- **Serengeti, Autobuzul, 15,8 s = tur FALS**: 18 repuneri pe kicker-ul `FlyoffRamp` și o repunere peste linia de start numărată ca tur (brief §12.8). Sonda îl respinge (sub jumătatea medianei pistei); fix-ul real e în `Race`.
- **Baikal: 11–29 repuneri pentru toate mașinile** (plăcile de gheață) — proprietate a pistei, nu a mașinii; cele rapide cad mai des (Muscle 29, Poliția 25, Pompierii 11).
- **Blocaje „!”**: Poliția pe Kyoto (4, lipită de `PereteTunel` la frac 0,49 după ce a fost scoasă de pe linie — AI/pistă), Autobuzul pe Chongqing (3) și Stromboli (3), Pompierii pe Machu Picchu (3) — cele grele se înțepenesc pe pante; de verificat la retuning că „gimmick-urile trec cu orice mașină”.
