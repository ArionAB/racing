# Comandă asset — gura de tunel în stâncă (Machu Picchu, POI B)

**O singură piesă.** Completează kitul de 39 de GLB-uri livrat în PR #386;
regulile generale sunt în `docs/asset_briefs/machu_picchu_kit.md` §0 (categorii,
sloturi de paletă, origine, scară) și `docs/blender_export.md`. Nu presupune că
ai citit altceva: tot ce e specific piesei ăsteia e aici.

## 1. De ce se comandă

POI B (Drumul Incaș, frac 0.04–0.20) a fost construit în valul 3 și a livrat
314 piese: perete stratificat care pornește din marginea asfaltului, vegetație
agățată, drumul ca poliță scobită. **Criticul rundei 3 a cerut un singur lucru
care lipsea: gura de tunel cu arc de piatră.**

Constructorul a refuzat corect s-o improvizeze. Citat din raportul lui:

> Nu o fabric din `inca_wall_*` — un arc din trei lespezi nu citește a tunel,
> citește a poartă prăbușită, și POI C are deja poartă.

Brief-ul pistei o cere explicit (§2, rândul POI B): *„un tunel scurt în stâncă
(12 m, tavan 6 m — sub 15 m lungime, clip tolerabil)"*. Kitul de 39 de piese
n-are nicio gură de tunel și niciun arc — verificat piesă cu piesă.

## 2. Contractul geometric — și de ce cifrele sunt astea

**Drumul pe B are semi-lățime 6,32 m, deci 12,64 m între margini** (măsurat,
`SvMpBuza`). Tunelul trebuie să lase mașina să treacă fără să atingă, pe toată
lățimea carosabilului.

| dimensiune | valoare | de unde vine |
|---|---:|---|
| lungime (pe direcția de mers) | **12,0 m** | brief §2; sub 15 m, clip tolerabil |
| **gol liber pe lățime** | **≥ 13,2 m** | 12,64 m carosabil + 0,28 m marjă |
| **gol liber pe înălțime** | **≥ 6,0 m** | brief §2 („tavan 6 m") |
| grosime perete/boltă | 1,2–2,0 m | ca să citească a rocă, nu a decor de carton |
| lățime exterioară totală | ~17–18 m | golul + pereți de o parte și de alta |

**Golul se măsoară pe fereastra pe care o ocupă mașina, nu la bază și nu sub
cheia bolții.** Lecția e plătită deja pe `main_gate`, unde trei cifre diferite
(8,39 / 8,12 / 7,42 m) păreau o contradicție și erau trei tăieturi prin aceeași
piesă trapezoidală. Dacă arcul se strâmtează cu înălțimea:

- în fereastra **y ∈ [0,15 m; 1,80 m]** (gabaritul caroseriei) golul trebuie să
  fie **≥ 13,2 m**;
- sub cheia bolții poate fi mai îngust, e normal pentru un arc.

Verificare: `tools/ProbeMpHGate.tscn` face exact proiecția asta (triunghiurile
pe planul (lateral, y), grilă de 1 cm) — se rulează pe piesa nouă înainte de
livrare, nu după.

## 3. Silueta — ce trebuie să citească

Din bara de referință (`docs/track_briefs/img/bar_machu/bar_poi_B.png`): gura de
tunel e **o tăietură în peretele de stâncă**, nu o construcție lipită pe el.
Arcul e din blocuri de granit potrivite fără mortar (aceeași zidărie ca restul
cetății), iar deasupra lui peretele natural continuă.

Cere deci:

1. **Arc de blocuri** — nu o gaură netedă. Blocurile se văd individual,
   trapezoidale spre cheie, stilul zidăriei incașe din `inca_wall_a/b/c`.
2. **Racord la peretele de stâncă** de o parte și de alta: piesa nu se termină
   într-o muchie dreaptă, ci se pierde în rocă neregulată. Altfel se vede
   îmbinarea cu peretele construit de POI B.
3. **Adâncime citibilă**: intradosul bolții vizibil pe toți cei 12 m, cu
   umbră care se adâncește. Interiorul e ce dovedește că e tunel și nu fațadă.
4. **Fără capăt vizibil**: din față se vede lumina la ieșire, nu un fund.

## 4. Sloturi de paletă (zero sloturi noi)

| element | slot |
|---|---|
| blocurile arcului, granit în soare | `MARBLE_GREY` 29 |
| roca din jur, umbră, intradosul bolții | `ROCK_LIGHT` 3 / `ROCK_DARK` 4 |
| mușchi pe blocurile de jos | `CACTUS_GREEN` 12 |

⚠ **`ROCK_DARK` nu pe suprafețe mari de rocă** — iese ruginiu. Umbra din
intrados o face AO-ul copt în vertex colors, nu slotul (memoria
`rock-dark-nu-pe-bazalt`, lecție plătită pe Stromboli).

## 5. Livrabil

- `assets/models/machupicchu/structures/rock_tunnel.glb`
- build script: `tools/blender/build_mp_tunnel.py`
- preview prin `tools/blender/preview.py` (nu capturi de viewport)
- rând în `docs/asset_briefs/machu_picchu_masuratori.md`: nume real de nod,
  triunghiuri, înălțime, rază, histogramă de sloturi, mod de coliziune

**Coliziune: `none` pe mesh**, și motivul contează. Mașina trece *prin* tunel —
un colizor pe boltă ar fi exact capcana pe care brief-ul o evită cerând „sub
15 m lungime". Pereții laterali ai tunelului sunt deja peretele de stâncă al
lui POI B, care are coliziunea lui. Piesa asta e **fantomă**: geometrie care se
vede, nu corp care oprește (memoria `coliziune-none-e-fantoma-nu-stearsa` —
mesh-ul rămâne, corpul dispare).

**Origine la bază, centrată pe golul de trecere** — nu pe AABB-ul întregii
piese. Dacă racordul de rocă e asimetric (și ar trebui să fie, altfel citește
prefabricat), un `origin="base"` naiv mută axul tunelului față de axul drumului.
Lecția e plătită de două ori: `origin-base-ridica-tot-obiectul` și
`finish-recentreaza-fiecare-nod-separat`.

## 6. Unde se așază (informativ — nu e treaba instanței de assets)

Pe stânga drumului, în intervalul frac **0.10–0.16**, unde POI B a construit
deja peretele. Cota din raycast pe `TerrainBody`, ca tot decorul manual.
Integrarea o face instanța de gameplay, cu `ProbeLaneClear` și `ProbeRace
--slice=0.08,0.20` înainte și după — o piesă peste drum se verifică dinamic,
nu doar geometric (memoria `proberace-la-inceput-nu-la-final`).
