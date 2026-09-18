# POI D (Cascada de terase): golul lateral lipsește — măsurat, cu ce ar cere

> Notă de lead, 18 sep 2026. **Nu s-a modificat nimic** — e o decizie de teren,
> deci a dezvoltatorului. Aici sunt cifrele pe care se ia.

## Ce spun criticii, și ce spune măsurătoarea

Toate cele trei runde de critic orb pe POI D au cerut același lucru: terasele
„nu rețin nimic", sunt „lespezi izolate pe o pantă verde continuă", iar „solul
din spatele unui zid e la aceeași cotă cu cel din față".

Constructorul a răspuns corect că nu e treaba lui (`honest_gaps`, punctul 4) și
n-a „reparat" atingând traseul. Măsurat, are dreptate:

`SvMpBuza` — câți metri lateral, dincolo de asfalt, până cazi 3 / 10 / 25 m:

```
D 0.42-0.54  dr   semi_lat 6.00   -3m: 69.6   -10m: 89.7   -25m:  —
D 0.42-0.54  st   semi_lat 6.00   -3m: 67.7   -10m:  —     -25m:  —
```

Pentru comparație, pe C prima cădere de 3 m e la **11,2 m**. Pe D e la **68 m**.

## De ce: intervalul n-are nicio râpă

`custom_ravines` — râpele care ating intervalul lui D (0.42–0.54):

| idx | interval | adâncime | side | ce e |
|---|---|---:|---:|---|
| 2 | 0.5269–0.5834 | 25 | **0** | **viaduct** — sapă SUB drum, nu lângă el |

**Frac 0.42–0.5269 nu e atins de nicio râpă.** Sunt 10,7 % din tur, și exact
porțiunea unde brief-ul cere 10 terase de 2,5 m plus scurtătura „drept în jos"
cu 8 sărituri.

## Ce ar cere o râpă aici (măsurat, `SvMpD.tscn`)

Terenul **coboară odată cu drumul** (axul de la −4,5 la −20,0 pe interval), deci
nu e „platou pe care se taie". Și **partea care cade alternează**, fiindcă
traseul face ace:

| frac | ax | stânga−ax (70 m) | dreapta−ax (70 m) | cade pe |
|---|---:|---:|---:|---|
| 0.420 | −4,5 | **−11,9** | +9,2 | STÂNGA |
| 0.450 | −8,8 | +9,1 | **−9,7** | DREAPTA |
| 0.465 | −11,0 | **−8,0** | +5,7 | STÂNGA |
| 0.480 | −13,1 | **−10,9** | +13,0 | STÂNGA |
| 0.495 | −15,4 | +9,5 | +1,2 | DREAPTA |
| 0.510 | −17,6 | +14,1 | **−22,7** | DREAPTA |

Deci **nu una, ci două râpe**, ca la serpentinele valului 1 (indicii 5–8, parte
alternantă) — altfel jumătate din interval ar primi gol pe partea muntelui.

Propunerea, cu cifrele de mai sus:

```
Vector4(0.4200, 0.4900, 22, -1)   # terasele de sus cad pe stânga
Vector4(0.4900, 0.5300, 22,  1)   # după ac, cad pe dreapta
```
plus ambii indici în `custom_cornice_ravines` (buza la 0,5 m de asfalt, nu la
4 m — vezi `RAVINE_CORNICE_INNER`), `custom_ravine_widths` ~55 m fiecare, și
podea la ≈ −40 ca să se lege de gorja podului de la 0.5269.

## De verificat obligatoriu după, dacă se face

1. **`ProbeLayout`** — panta (11,5 %) și raza (9,0 m) nu au voie să se miște:
   o râpă nu atinge traseul, dar terenul de sub el da.
2. **`ProbeRace --seed=1,2,3`**, de cel puțin 4 ori pe seed: o buză la 0,5 m de
   asfalt e o buză de pe care se cade. Se citește și `[blocaj]`/lent/offroad,
   nu doar „repuneri" (memoria `zero-repuneri-ascunde-blocajul`).
3. **`ProbeBuried`** — terasele stau pe teren, iar terenul se schimbă sub ele.
4. **Captura** la 0.44 / 0.49 / 0.52: dungile alb/umbră ale teraselor sunt
   identitatea POI-ului, iar `scarp_tint` le dă acum fața de piatră.
5. **Decorul existent al lui D (674 noduri) e așezat pe cotele de ACUM.** Dacă
   terenul coboară sub el, plutește. Se re-rulează generatorul
   (`tools/gen_decor_mp_d.gd`), nu se mută piesele de mână.

Punctul 5 e motivul pentru care asta **nu s-a făcut odată cu valul 3**: ar
invalida munca deja merge-uită a POI-ului D, și ordinea corectă e întâi
decizia, apoi terenul, apoi re-rularea generatorului.
