# Inventar assets — Cappadocia (`Track13`)

**45 GLB-uri, 62.720 triunghiuri, 2,03 MB** în `assets/models/cappadocia/`.
Sursa: cele 13 grupuri din plansa de referință + `docs/track_briefs/cappadocia.md`.
Verificare: `bash tools/blender/verify_cappadocia.sh` → **VERDICT KIT: OK**.

Cinci scripturi de build, plus `preview_cappadocia.py` care randează planșele de
control **din GLB-urile exportate** (nu le reconstruiește — verifică ce a ajuns
în fișier):

| script | ce produce |
|---|---|
| `build_cappadocia_tuff.py` | hornuri, faleză în benzi, fațada bisericii |
| `build_cappadocia_hero.py` | stânca goală, poarta, gura peșterii, puțul |
| `build_cappadocia_underground.py` | kitul de săli, piatra de moară, torța |
| `build_cappadocia_balloons.py` | baloanele + cele 3 stări ale hornului crăpat |
| `build_cappadocia_village.py` | satul, recuzita, vegetația, porumbelul |
| `build_cappadocia_horizon.py` | Uçhisar, Erciyes, balonul de MultiMesh |

## Inventar

### `rocks/` — geologia de tuf (13 piese, 20.408 tri)

| fișier | tri | notă |
|---|---:|---|
| `chimney_a/b/c.glb` | 526 ×3 | hornuri 10,5 / 13,8 / 16,4 m — **sub bugetul de 600** din brief §6 |
| `chimney_d.glb` | 878 | hornul locuit (ușă + 3 ferestre); peste 600 din cauza golurilor |
| `chimney_mushroom.glb` | 478 | pălărie 3,1× raza gâtului |
| `chimney_triple.glb` | 1.378 | trei gâturi pe un soclu comun = **un** `world_prop` |
| `cliff_band_module.glb` | 1.208 | modul de 20 m, `origin="base_axis"` (se înșiră cap la cap) |
| `rock_church_facade.glb` | 986 | portal săpat + cruce incizată |
| `cracked_chimney_a/b/c.glb` | 1.070 / 1.612 / 2.528 | în picioare / rampă / moloz |
| `uchisar_castle.glb` | 3.986 | fundal, 60 m, la 200–250 m |
| `erciyes.glb` | 706 | fundal, 180 m, la 290–300 m (sub `fog_end`) |
| `balloon_far.glb` | 204 | piesă de MultiMesh |

### `structures/` — hero + subteran (11 piese, 20.978 tri)

| fișier | tri | notă |
|---|---:|---|
| `hollow_rock.glb` | 11.968 | **gimmick-ul**; vezi §„Abateri de la brief" |
| `twin_chimney_gate.glb` | 1.408 | 12 m cotă liberă verticală, 13,2 m orizontală |
| `cave_entrance.glb` | 2.144 | gol 10 × 7,2 m |
| `vent_shaft.glb` | 792 | cilindru Ø5 m, coboară 9 m sub origine (`base_axis`) |
| `hall_column/arch/ceiling_module/alcove.glb` | 382 / 572 / 704 / 752 | kitul sălii |
| `church_arch.glb` | 1.296 | ogivă + fresce abstracte |
| `millstone_door.glb` | 608 | **`origin="center"` + AO sferic** (se rostogolește) |
| `millstone_slot.glb` | 352 | lăcașul + șina |

### `props/`, `buildings/`, `plants/` (21 piese, 21.334 tri)

`balloon_envelope_a/b/c` (1.680 ×3), `balloon_basket` (1.604),
`balloon_landed` (356), `balloon_tether` (544), `torch` (700),
`carpet_terrace` (998), `pottery_cart` (3.800), `pot_stack` (1.180);
`cave_house_a/b/c` (810 / 1.470 / 1.126), `dovecote` (3.466),
`farmhouse` (1.144); `poplar_a/b` (266 ×2), `vine_row` (1.292),
`shrub_dry` (396), `pigeon` (672).

`chevron_post` **nu se generează** — reuse din
`res://assets/models/chongqing/props/chevron_post.glb` (planșa, grupul 13).

## Ce trebuie știut la integrare

### Abateri de la brief, cu motiv

1. **`hollow_rock`: 3 ture la raza 18 m, nu 2 la raza 28 m; bază 49 m, nu 70 m.**
   Cele trei cifre din brief §5.2 nu închid: o stâncă ce se subțiază de la 70
   la 30 m lasă la vârf o rază interioară utilă de 10,2 m, deci panta ar sări
   de la 10,8% la ~30%. Ce s-a păstrat e **panta** (constrângerea ProbeLayout),
   nu raza: 3 ture × 18 m = 339 m rampă → **11,2%**. Separarea între ture
   devine 38/3 = **12,7 m**, tot peste cele 12 m cerute de
   `custom_overpass_ranges`. **Lotul din hartă se micșorează**, nu crește.
2. **`twin_chimney_gate`: deschidere 20 m între axe, nu 9,4.** La 9,4 m și
   înclinare de 11°, deschiderea liberă sub arc ieșea 4,7 m — sub lățimea
   drumului. Acum e 13,2 m liber la cota arcului, cu drumul de 7 m trecând cu
   3 m de fiecare parte.
3. **`erciyes` are 180 m, nu 3.900.** La 300 m distanță un munte real ar
   subîntinde 85° și ar arăta ca un perete; 180 m dau 31°, adică „munte mare
   la orizont".

### Origini care NU sunt la baza bbox-ului

| piesă | origine | de ce |
|---|---|---|
| `millstone_door` | centrul bbox | se rostogolește; AO sferic (regula din `bake_ao`) |
| `balloon_basket` | **podeaua coșului** (z=0) | mașina stă pe ea — `platform_velocity`, ca podeaua cabinei de telecabină |
| `balloon_envelope_*` | gura pânzei (jos) | se atașează la coș fără offset calculat de mână |
| `vent_shaft` | gura de la suprafață | geometria coboară 9 m **sub** origine |
| `cliff_band_module` | `base_axis` | modulele se înșiră cap la cap; bbox intenționat necentrat |
| `hollow_rock` | axa cilindrului | spirala se aliniază cu Curve3D pe axă |

### Sloturi de paletă

- **Zero sloturi noi.** Tot kitul folosește sloturi existente, conform brief §4.
  Slotul 31 (NEON_PINK) e menționat în brief ca accent de balon dar **nu e
  consumat** de niciun asset — decizia rămâne deschisă.
- **Excepție declarată:** baloanele folosesc sloturile 14–16 (rezervate
  mașinilor). E autorizată explicit în brief §4 și trece prin
  `--allow-car-slots=` în `verify_cappadocia.sh`. Motivul: atlasul n-are altă
  sursă de roșu/albastru/galben saturat, iar pânzele sunt semnal de gameplay.
- **`cracked_chimney_b`** folosește `ASPHALT_EDGE` pe banda de rulare: e
  suprafață pe care se conduce, nu decor.

### Contracte de gameplay înghețate în geometrie

- **Banda de rulare a hornului căzut** e o fâșie continuă cu vârfuri partajate
  (nu plăci independente) și margini în pantă de 0,55 m — prima versiune avea
  trepte de ~15 cm între plăci, adică praguri-zid pentru o roată cu 13 cm până
  la podea.
- **Parapetul rampei elicoidale** are 0,45 m: buză, nu zid, ca marginile fără
  parapet să se taie în pantă (brief §8).
- **Pânza aterizată** are cute de max 0,18 cm și marginile coborâte la sol —
  e suprafață lentă prin care se trece, nu obstacol.
- **Rampa din `hollow_rock` are 7 m**, cu 1 m mai lată decât carosabilul de 6:
  asfaltul se așază peste ea și o acoperă, în loc să lase z-fighting pe margine.

### Ce NU e făcut

Integrarea (`Track13.tscn`, tema `cappadocia`, plantarea). Brief §7 cere întâi
sondele tehnice: preset de cameră în cavernă (captură `--driver` din sala 1),
`ProbeOverpass` pe spirală, coșul ca platformă verticală.
