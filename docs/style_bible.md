# Style Bible — "Diorámă stilizată de deșert"

Direcția vizuală a jocului, cu valori numerice. **Orice asset nou se generează
împotriva acestui document.** Sursa: spec derivat din imaginea de referință
(diorámă miniaturală de deșert), adaptat la constrângerile de mobil.

Referință de ton: *Art of Rally* / machetă de masă — **nu** miniatură fotorealistă.

---

## 1. Paletă

O singură textură pentru toată lumea: `assets/textures/palette_atlas.png`
(**512×512**: 32 de sloturi a câte 16px lățime). Indici și helper:
[scripts/palette.gd](../scripts/palette.gd). Fiecare slot e un patch texturat,
nu un pătrat de culoare uniformă — vezi §4.

| slot | rol | hex | folosit la |
|---|---|---|---|
| 0 | sand_light | `#E8C88B` | nisip în soare, vârfuri de faleză |
| 1 | sand_mid | `#D8A86A` | majoritatea terenului |
| 2 | sand_shadow | `#A97A4A` | nisip umbrit, tentă de AO |
| 3 | rock_light | `#C79664` | fețe de stâncă |
| 4 | rock_dark | `#7E5B3A` | interior de faleză, crăpături |
| 5 | asphalt | `#4B4B4D` | șosea |
| 6 | asphalt_edge | `#696765` | margini tocite |
| 7 | kerb_red | `#B74A3A` | borduri, marcaje |
| 8 | concrete | `#C8BEAC` | pod, fundații |
| 9 | wood_weathered | `#8A6947` | scânduri, garduri |
| 10 | rust_metal | `#915535` | butoaie, moară, turn de apă |
| 11 | painted_metal | `#7E96A8` | containere, ornamente |
| 12 | cactus_green | `#617A43` | cactuși, tufe |
| 13 | dry_vegetation | `#AFA25E` | smocuri de iarbă |
| 14-16 | **accente mașini** | `#E54839` `#2C82E8` `#F2D03C` | **doar mașini**, niciodată decor |

**Regulă de saturație:** mediul stă la 0.45–0.60; mașinile la 0.85–1.00. Așa
mașinile se desprind mereu de fundal.

**Regulă de citire:** asfaltul (slot 5) trebuie să rămână **cea mai închisă
suprafață continuă** din scenă — linia de curs se citește la viteză.

---

## 2. Scară și proporție

Unitate de referință: **mașina = 4.0 m lungime**.

| obiect | dimensiune |
|---|---|
| bordură | 0.35 m lățime |
| stâncă mică / medie / mare | 0.7 / 2.5 / 7 m |
| perete de faleză | 6–12 m |
| cactus | 2.8–4.5 m |
| turn de apă | 9.5 m |
| moară de vânt | 11 m |
| benzinărie | 8 × 6 × 5 m |
| pod de lemn | 8 m lungime |
| butoi / ladă / cauciuc | 0.9 / 1.1 / 0.9 m |
| stâlp de gard | 1.0 m |

> ⚠️ **Lățimea șoselei rămâne cea de gameplay (12–16 m), NU cei 5.2 m din spec.**
> Vezi §9 Conflicte.

**Trucurile care fac lumea să pară MACHETĂ (nu deșert real):**
- Scară verticală exagerată ×1.18 față de cea orizontală
- Prop-uri așezate nefiresc de aproape de șosea (2–4 m), ca la un mocheta de trenuleț
- Spațiere regulată intenționat (grupuri la 18–25 m), nu geologic realistă
- Marginea terenului tăiată vertical, ca polistirenul decupat
- Obiectele supradimensionate cu 10–20% față de mașină (mai ales cactuși și butoaie)

---

## 3. Limbaj de formă

**Bevel** (consistent peste tot — semnătura care ține stilul unitar):
prop-uri 0.04 m · clădiri 0.08 m · stânci 0.15 m

**Stânci:** 70% rotunjite / 30% fațetate; straturi orizontale la 0.4–0.8 m;
**niciodată colțuroase**. **Acoperișuri:** pantă 18°. Nimic perfect cubic.

**Buget de triunghiuri:** ladă 80 · gard 60 · butoi 120 · cactus 180 ·
stâncă mare 250 · turn de apă 900 · moară 1200 · benzinărie 1800

**DA:** siluete mari și lizibile, grinzi groase, colțuri rotunjite, spațiu negativ
**NU:** șuruburi mici, balustrade subțiri, stânci zimțate, detaliu de frecvență înaltă

---

## 4. Suprafață și uzură

**Texturi de suprafață DA, texturi unice per asset NU.**

> Revizuit după comparația cu *Reckless Racing 3* și *Beach Buggy Racing* — jocuri
> de mobil care arată mai bine decât noi cu hardware mai slab (BBR rula pe iPhone
> 7). Diferența principală nu e poligonajul, sunt **culorile plate**: la viteză, o
> suprafață de sute de m² fără nicio variație citește ca plastic. Versiunea
> anterioară a acestui paragraf interzicea orice textură; regula era prea strictă
> și ne costa exact lucrul pe care îl invidiam la referințe.

Ce e permis:
- **Atlasul de paletă** (`palette_atlas.png`, 512×512) — fiecare slot e un *patch
  texturat*: nisip cu granulație, rocă cu straturi orizontale, lemn cu fibră.
  Generat de [tools/generate_palette_atlas.gd](../tools/generate_palette_atlas.gd).
  UV-urile rămân colapsate pe centrul slotului, deci **assets-urile existente nu
  se refac** și materialul rămâne unul singur.
- **Texturi tileabile gri** pentru suprafețele mari (teren, asfalt):
  `surface_sand.png`, `surface_asphalt.png`. Se înmulțesc peste albedo, deci nu
  aduc culori noi. Centrul lor e **alb**, nu gri mediu — o textură centrată pe 0.5
  ar întuneca totul cu 50% și ar spăla culoarea.

Ce rămâne interzis: texturi unice per asset, texturi de murdărie pictate manual,
decals. Umbrirea proprie vine în continuare din **AO copt în vertex colors**.

Plafon: atlasul **nu depășește 512×512**. Peste atât se pierde avantajul de VRAM
fără câștig vizibil la viteza de joc.

| material | roughness | uzură |
|---|---|---|
| nisip | 0.95 | doar AO din paletă |
| stâncă | 0.88 | fețele de jos spre `rock_dark` |
| asfalt | 0.82 | praf spre `sand_mid` pe margini |
| lemn | 0.80 | fețele de sus decolorate +10% valoare |
| metal ruginit | 0.76 | jos mai închis, sus decolorat |
| metal vopsit | 0.60 | fețele de sus spre `concrete` |
| plastic | 0.55 | doar decolorare ușoară |
| vegetație | 0.90 | jumătatea de jos mai închisă prin AO |

---

## 5. Lumină

| parametru | valoare |
|---|---|
| soare: elevație / azimut | 42° / 315° (din stânga-sus) |
| culoare soare | `#FFD6A3`, intensitate 1.25 |
| ambient / cer | `#C9D9E6` |
| tentă de umbră | `#6B7284` (**nu** gri neutru) |
| moliciune umbre | 0.35 |
| bounce cald din nisip | `#E2B77A`, putere 0.18 |

Godot: `rotation_degrees = Vector3(-42, 135, 0)` pentru soare (elevație 42°,
azimut 315°).

**Expunerea se calibrează prin măsurare, nu din ochi.** Cerul de deșert e albastru
intens; luat ca sursă de ambient, își lasă nuanța pe tot ce e deschis la culoare —
măsurat, nisipul ieșea `#EAD8CD` (gri-roz) în loc de `#D8A86A`, cu canalul albastru
urcat de la `0x6A` la `0xCD`. Nu era o problemă de luminozitate (roșul și verdele
erau corecte), deci nici expunerea, nici energia soarelui n-o puteau repara: alea
scad toate cele trei canale deodată.

Soluția pe temă de deșert: ambient dintr-o **culoare caldă** (`#E2B77A`, bounce-ul
de nisip din tabelul de mai sus), nu din cer. Plus soare `0.8` și
`tonemap_exposure 0.75` — valori găsite măsurând pixelii dintr-un snapshot față de
ținta din §1, care au coborât eroarea de la 198 la 10 (din 255).

Procedura, dacă trebuie refăcută:
1. `godot --path . res://tools/Snapshot.tscn -- --track=0 --frac=0.2 --size=40`
2. media pe o zonă de nisip, departe de drum
3. comparată cu `#D8A86A`

---

## 6. Atmosferă

Cer: zenit `#6EA9E6` → orizont `#F6D6A8`.
Ceață `#E8CDA3`, începe la 90 m, plină la 250 m (Godot: `FOG_MODE_DEPTH`).
Heat haze foarte subtil (amplitudine 0.005, 0.3 Hz).

La distanță: saturație −15%, contrast −20%, luminozitate +8%.

---

## 7. Compoziție

- Un landmark dominant vizibil la fiecare **4–6 secunde** (la 120–180 m)
- Densitate: **18–25 prop-uri per 100 m** de traseu
- Grupuri de 4–8 obiecte; teren gol în fața landmark-urilor majore
- **Niciodată** prop-uri înalte în apexul virajului (blochează citirea)
- 8 m liberi în zonele de frânare; stânci mari doar pe exteriorul virajelor

---

## 8. Post-procesare

Contrast +8% · saturație −6% · warmth +5% · bloom doar threshold 0.04 ·
vignette 0.10 · sharpen 0.08

**Interzis pe mobil:** SSAO, SSR, volumetrice scumpe, reflexii complexe.
(AO vine copt în vertex colors, nu din ecran.)

---

## 9. Ramă de diorámă

Bază de lemn: înălțime 1.2 m, grosime 0.08 m, culoare `#6A4C35`, mat, muchie de
placaj vizibilă. Nisipul se termină **brusc, tăiat la 90°** — asta vinde scara de
machetă.

Dincolo de ramă: doar cer în cursă. Rama întreagă se vede în meniuri / photo mode
/ camere de replay.

---

## 10. Ce NU se poate real-time (și înlocuitorul)

| lux de render offline | înlocuitor pe mobil |
|---|---|
| depth of field | doar în replay/photo mode |
| global illumination | 1 lumină direcțională + ambient + AO copt |
| bounce path-traced | culoare de ambient caldă |
| detaliu micro de rocă | doar variație de siluetă |
| texturi hi-res | atlas de paletă |
| contact shadows | vertex AO |
| zgârieturi micro | omise complet |
| atmosferă volumetrică | ceață exponențială simplă |

---

## 11. Reguli de coerență (cele care se uită cel mai ușor)

1. **Același bevel** peste tot — altfel obiectele par importate din alt joc.
2. **Rotații în trepte de 15°**, exceptând stâncile și vegetația împrăștiată —
   păstrează senzația de așezat de mână.
3. **Teren: variație max ±3.5 m pe orice 50 m.** Relieful mare se face din
   *assets de faleză* (6–12 m), nu din heightmap. Vezi §12.
4. **Vertex colors pentru AO** pe absolut fiecare asset; zero texturi unice.
5. **Asfaltul rămâne cea mai închisă suprafață continuă.**

---

## 12. Conflicte cu gameplay-ul (decizii luate conștient)

Spec-ul e condus de artă și nu cunoaște pilonii de joc. Două abateri asumate:

**a) Lățimea șoselei.** Spec: 5.2 m. Noi păstrăm **12–16 m**. Pilonul #1 e
*bumping cu masă* între 4 mașini plus depășiri; la 5.2 m (≈2.9 lățimi de mașină)
nu există loc de îmbrânceli, iar startul pe 2 coloane nu încape. Compensăm senzația
de îngustime **vizual**: prop-uri aproape de bandă, faleze care strâng cadrul.

**b) Relief.** Regula ±3.5 m/50 m intră în conflict cu canionul procedural de 24 m
din `track.gd` (`CANYON_HEIGHT`). Rezolvare: terenul rămâne domol (±3.5 m), iar
canionul devine **geometrie de faleză** (assets de 6–12 m) așezată pe margine —
mai aproape și de spec-ul de inventar (35 secțiuni de faleză).
