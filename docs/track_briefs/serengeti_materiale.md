# Serengeti (Track14) — auditul de materiale si acoperire

> Scris in worktree-ul `wt-ser-mat-d` (lotul D al valului de materiale), 12 sep
> 2026. Companion la `serengeti_stare_poi.md` (acela e despre constructia
> POI-urilor; asta e despre CE are textura de clasa si CE nu, pe toata pista).
> Trei agenti frati lucreaza in paralel pe (A) trunchiuri/scoarta, (B)
> coroane/frunzis, (C) termitiere/boma masai — clasele lor NU sunt in tabelul
> de mai jos daca nu erau deja comise la momentul scrierii.

## Ce s-a facut in lotul asta

**Zero cod schimbat.** Niciun material adaugat, niciuna dintre clasele deja
comise (`granite` pe kopje_camp/kopje_kicker/kopje_boulder_a/b/c/crater_gap/
lengai/crater_far_wall) nu a fost atinsa.

Buget Track14: **24/38 inainte, 24/38 dupa** (`tools/probe_decor.gd --track=14`,
verificat si pe celelalte 13 piste — toate `OK`, nicio regresie, nicio schimbare
de cifra, fiindca n-am schimbat cod).

## Partea 1 — panza si props-urile de tabara

### Refuzat: clasa `canvas` pe `safari_tent`

**Masurate 6 instante** pe Track14 (nu doar cele vizibile in captura de
referinta): 4 in `ZoneA_Camp` (langa start, scara 0.75-0.85, deci ~4x2.4x4.8 m
pe ecran) si 2 in `ZoneG_FundulCraterului` (scara 0.95-1.0). Native
`safari_tent.glb`: **5.04 x 2.84 x 5.64 m** — mare, aproape de camera la POI A,
zero problema de banda ingusta (precedentele respinse `talus_gravel`/`Bollard`/
`Jib` erau foi de 0.16-0.37 m grosime; cortul n-are nicio dimensiune sub 2.8 m).

Sloturi (`tools/probe_slots.gd --dir=serengeti/props`):

| slot | nume | hex | % | rol probabil |
|---|---|---|---:|---|
| 28 | LOG_DARK | #4A3526 | 59.4% | umbra/interior cort |
| 19 | CORAL_SAND | #E9DCC0 | 19.4% | panza principala |
| 1 | SAND_MID | #D4994D | 12.3% | panza/stinghii |
| 2 | SAND_SHADOW | #915D27 | 9.0% | tarusi/franjuri |

Ecart de saturatie intre sloturi: **0.555** (calculat HSV pe cele 4 culori).
Sub pragul de respingere masurat pe alte piese cu accente (0.63 la
cave_house_a/b/c, rock_church_facade, House_A/B/C), deci cortul nu are un
accent pictat care s-ar pierde — e o piesa cu adevarat aproape-monocroma
(familia nisip/lemn-inchis).

**Deci pe regula de "accent vs monocrom" cortul AR intra.** Motivul refuzului
e altul, si e mai simplu decat regula de accente:

1. **Nu exista sursa.** Repo-ul n-are nicio textura de panza/tesatura in
   `assets/textures/classes/src/` — toate cele 12 surse existente sunt piatra,
   lemn, tencuiala, beton, zapada, ace de conifer, macchia. O clasa `canvas`
   ar cere sursa externa noua (PolyHaven/ComfyUI) plus trecerea prin
   `tools/process_class_textures.gd` — pipeline complet, nu o linie in
   `CLASSES_BY_MODEL`.
2. **Bugetul lotului e +1 material, pentru TOT lotul** (Partile 1 si 2
   impreuna). Toate celelalte props-uri masurate (land_rover, campfire,
   safari_balloon_landed) sunt respinse la regula de accente (vezi mai jos),
   iar auditul de acoperire (Partea 2) n-a gasit niciun candidat mai ieftin
   care sa merite acelasi slot. Cheltuit pe cort, singurul material disponibil
   s-ar fi dus pe SASE instante dintr-o clasa complet noua, sursa incearca-si-
   vezi, la finalul unei sesiuni fara acces confirmat de retea in acest
   worktree.
3. Un refuz motivat e livrare (lectia repo-ului). Daca urmatorul val are
   sursa de panza deja procesata (poate impreuna cu alt material textil, ca
   sa nu se cheltuiasca un slot intreg pe un singur prop de camp), cortul e
   candidatul clar — cifrele de mai sus raman valabile.

### Respins, cu cifra: piesele cu accente pictate

Ecart de saturatie (HSV, calculat pe hex-urile masurate cu `probe_slots.gd`):

| piesa | sloturi | ecart sat. | verdict |
|---|---|---:|---|
| `land_rover` | 4 (#67421F 63.6%), 12 (#5B7C34 19.0%), 19 (#E9DCC0 5.2%), 22 (#E9F2F0 12.1%) | **0.662** | RESPINS — peste pragul 0.63 (cave_house_a/b/c). Slotul 22 e parbrizul/geamurile (FOAM_WHITE, sat 0.04), slotul 4 e vopseaua caroseriei: o clasa ar sterge exact contrastul metal-vopsit / geam pe care `SLOT_REPAINT_BY_BOX` tocmai l-a construit (vezi mai jos). |
| `campfire` | 3 (#C18446 80.5%), 28 (#4A3526 11.7%), **30 (#E8622D 7.8%, LAVA_ORANGE)** | 0.320 numeric, dar irelevant | RESPINS — slotul 30 e LAVA_ORANGE: focul ARDE (accent intentionat, y 0.10-0.79 = flacara). O clasa triplanara ar vopsi si flacara cu piatra/lemn si ar stinge singurul foc din decor. |
| `safari_balloon_landed` | 16 (#F2D03C 36.4%, CAR_YELLOW), 21 (#3F7A3C 56.5%), 9 (#835C34 7.1%) | 0.244 numeric, dar irelevant | RESPINS — slotul 16 e CAR_YELLOW, folosit DELIBERAT ca accent saturat (dunga balonului); style_bible §1 pastreaza 14-16 in afara decorului tocmai ca sa ramana rare si sarite in ochi. O clasa ar sterge dunga galbena, singurul semnal cald al balonului. |
| `ankole_horns` | 0 (#E8C074 80.0%), 2 (#915D27 20.0%) | 0.231 | RESPINS pe marime, nu pe accent — native 1.17 x 0.90 x 0.16 m: coarnele sunt subtiri (0.16 m adancime), sub banda care se mai citeste dupa mipmap (aceeasi lectie ca la marker_post/talus_gravel). Doar 3 instante. |

**Nota despre `SLOT_REPAINT_BY_BOX` pe `land_rover`:** mecanismul exista deja
(adaugat pentru silueta rover-ului — repicteaza rotile pe ICE_CRACK si banda de
geam pe SEA_DEEP, in cutii locale). Repictarea painteaza sloturi din PALETA
(culoare plata), nu aplica o clasa triplanara — deci nu intra in conflict cu
respingerea de mai sus si n-are nevoie de nicio schimbare din partea mea.
Verdictul vizual al reparatiei (`e0fcfc0`) e inca NEVERIFICAT prin captura, per
`serengeti_stare_poi.md` — ramane pe lista celuilalt document, nu a acestuia.

## Partea 2 — auditul de acoperire

### Tabel: toate sursele care ajung in cadru pe Track14

(`tools/probe_decor.gd --track=14`, plus grep pe `Track14.tscn` si
`world_prop.gd`/`palette.gd` pentru starea de clasa)

| sursa | instante | tris | material azi | clasa? | note |
|---|---:|---:|---|---|---|
| MultiMesh neatribuit | 125 942 | 6 510 928 | 9 mat. (atlas) | NU | scatter copt (iarba/nisip/decor mic); vezi nota de mai jos despre `dense_grass` |
| procedural (track.gd) | 1 437 | 1 210 426 | 17 mat. | PARTIAL | teren+drum+apa — vezi detaliere mai jos |
| GLB: fig_tree | 216 | 754 704 | 1 mat. (atlas) | **NU** — teritoriul agentului B | trunchi+coroana, canopy scale (fig_tree e in `serengeti/plants/`) |
| GLB: veg_set | 336 | 216 664 | 1 mat. (atlas) | NU | kit de vegetatie generic (`assets/models/plants/`), nume interne `veg_*`; teritoriul agentului B pentru frunzis |
| GLB: cow | 5 | 12 250 | 1 mat. (atlas) | NU | 0.85 m, animal — prea mic, nu merita clasa |
| GLB: megakit_plants | 22 | 8 888 | 1 mat. (atlas) | NU | tufe MegaKit (`tuft_/scrub_/fan_/rosette_/dead_`); teritoriul agentului B |
| GLB: marker_post | 81 | 5 868 | 1 mat. (atlas) | NU | 0.30 x 1.22 x 0.37 m — stalp subtire, precedent respins (Bollard/Jib) |
| GLB: kopje_camp etc (granit) | — | — | `granite` triplanar | **DA** | deja facut, nu se atinge |
| safari_tent | 6 | — | atlas | NU (vezi refuz motivat mai sus) | |
| land_rover | 5 | — | atlas + SLOT_REPAINT_BY_BOX | NU (accent) | |
| campfire | 4 | — | atlas | NU (accent — foc) | |
| safari_balloon_landed | 1 | — | atlas | NU (accent — CAR_YELLOW) | |
| ankole_horns | 3 | — | atlas | NU (prea subtire) | |

### Detaliu procedural (d): terenul si iarba deasa AU strat de detaliu

Verificat direct in `track.gd`, nu presupus:

- **Terenul** (`_build_terrain`, ~linia 4892) foloseste `terrain_splat.gdshader`
  cu **doua perechi** de texturi gri tileable — `surface_sand`/`surface_sand_macro`
  si `surface_grass`/`surface_grass_macro` (ambele confirmate pe disc,
  `assets/textures/surface_*.png`), amestecate per-vertex prin `COLOR.a`.
  Serengeti seteaza `savanna_grass_w: 0.85` + `savanna_grass_tint` (linia 723) —
  o cheie facuta SPECIAL pentru Serengeti fiindca `inland_tint` (mecanismul
  vechi) porneste de la nivelul marii, iar Serengeti n-are mare. **Deci terenul
  NU e pe atlas plat** — are granulatie reala pe ambele scari (micro 3.1-3.5 m,
  macro ~45 m), exact reteta din style_bible §4.
- **`dense_grass`** (`TrackGrass`, `scenes/tracks/track_grass.gd`) e activat
  (`"dense_grass": true`) si are **materialul lui propriu**, un `ShaderMaterial`
  dedicat cu vant si topire cu distanta (`static var _material`) — o clasa de
  assets cu material partajat, declarata explicit ca `rock_material`/
  `foliage_material`, nu atlas plat.
- **Crusta de soda** (`lagoon_crust_tint`, POI G) e doar o pondere de vertex
  color pe ACELASI mesh de teren — mosteneste automat stratul de detaliu de mai
  sus, nu e o suprafata separata netexturata.

**Concluzie pe punctul (d): nu exista gaura aici.** Memoria
"scatterul-nu-primeste-clasele-temei" (BAIKAL_CLASSES hardcodat) nu se aplica
Serengeti-ului — verificat cu grep, `BAIKAL_CLASSES` nu apare in calea de
scatter a acestei piste (`decor: "none"`, deci `TrackDecor` nici nu ruleaza).

### Cele mai mari suprafete ramase fara textura (in ordinea importantei)

1. **`fig_tree` (216 instante, 754 704 tris)** — cel mai mare consumator de
   ecran fara clasa. Coroana + trunchi pe atlas plat. **Teritoriul agentului
   B** (coroane/frunzis) si posibil A (trunchiuri/scoarta) — nu am atins.
2. **`veg_set` (336 instante, 216 664 tris)** — al doilea ca numar de instante
   pe toata pista. Kit generic (`assets/models/plants/`), fara clasa.
   Teritoriul agentului B.
3. **`safari_tent` (6 instante, ~5x2.8x5.6 m fiecare)** — vezi refuzul motivat
   de mai sus. Cel mai mare prop de camp fara clasa si singurul din lotul meu
   care ar fi trecut regula de accente daca exista sursa.
4. **`megakit_plants` (22 instante, 8 888 tris)** — mic ca tris, dar tot
   teritoriul agentului B daca intra vreodata in clasa de frunzis.
5. **`marker_post` (81 instante, 5 868 tris)** — cel mai numeros dupa
   veg_set/fig_tree, dar fiecare piesa e sub banda vizibila (0.30-0.37 m
   grosime) — nu merita, precedent deja stabilit (Bollard/Jib pe Chongqing).

Terenul si `dense_grass` NU apar in lista de mai sus: au deja strat de
detaliu, verificat direct in cod (sectiunea anterioara).

## Materiale Track14: inainte / dupa

**24/38 inainte -> 24/38 dupa.** Zero adaugate. Verificat cu
`tools/probe_decor.gd --track=14`, si pe toate celelalte 13 piste (niciuna nu
s-a miscat, cum era de asteptat fara nicio schimbare de cod):

```
Track01  23/38  Track08  21/38  Track09  26/38  Track10  23/38
Track11  32/38  Track12  32/38  Track13  21/38  Track14  24/38
```

Toate `OK`.
