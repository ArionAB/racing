# Brief asset — Atelierul de garaj (`interiors/garage_bay.glb` + piese)

Brief auto-continut pentru un agent Blender. Nu presupune acces la restul
repo-ului — tot contractul e aici. Surse: [style_bible.md](../style_bible.md)
(estetica) + [blender_export.md](../blender_export.md) (pipeline) +
[scripts/palette.gd](../../scripts/palette.gd) (indici de sloturi).

Sursa reproductibila: [tools/blender/build_garage_bay.py](../../tools/blender/build_garage_bay.py).

---

## 1. Ce construiesti

Fundalul ecranului de GARAJ: un box de atelier low-poly, stilizat, in care sta
masina aleasa pe un podium rotativ. Tonul e *Art of Rally* / macheta de masa —
**nu** foto-realist. Rezultat: `.glb`-uri care intra intr-o lume cu un singur
material partajat (atlas de paleta + AO copt in vertex colors).

## 2. Rolul lui in cadru

**Fundal, nu subiect.** Masina e eroul; atelierul exista ca sa dea CONTEXT si
SCARA, si ca mașina sa nu mai pluteasca pe un gri plat (starea de acum).

Testul care spune ca a reusit: la o captura a ecranului de garaj, ochiul se
duce intai la masina, iar atelierul se citeste din periferie ca "un loc", nu
ca un desen de fundal. Daca vreo piesa de atelier fura privirea, e prea
saturata sau prea aproape.

**Consecinta directa:** fiecare suprafata mare din atelier trebuie sa ramana
mai putin saturata decat caroseria (regula din §1: mediu 0.45–0.60, masini
0.85–1.00) si mai deschisa decat ASPHALT, care ramane cea mai inchisa
suprafata continua.

## 3. Forma si dimensiuni

Unitate: 1 = 1 m; masina de referinta = 4.2 m (garajul are intre 3.7 m si
5.56 m — autobuzul e cel mai lung).

**Volumul vizibil e MASURAT, nu presupus.** Camera vitrinei sta la ~9.7 m de
centru, fov 38°, cu privirea coborata 18°. La planul podiumului cadrul are
**11.8 × 6.7 m**; la 16 m in spate, **19.2 × 10.8 m**; la 24 m, 28.9 × 16.3 m.

Deci atelierul e o **cutie de ~20 × 14 × 7 m**, nu o hala. Orice metru peste
atat e geometrie care nu intra niciodata in cadru.

| piesa | fisier | gabarit | triunghiuri (masurat) |
|---|---|---|---|
| `GarageBay` (cutia: podea, 3 pereti, tavan cu grinzi si luminator) | `interiors/garage_bay.glb` | 20 × 14 × 7 m | 1320 |
| `GarageDoor` (usa rulou, deschisa sus) | `interiors/garage_door.glb` | 6 × 0.3 × 5 m | 328 |
| `GarageBench` (banc de lucru + panou de scule) | `interiors/garage_bench.glb` | 3.2 × 0.8 × 2.2 m | 748 |
| `GarageToolbox` (dulap de scule pe rotile) | `interiors/garage_toolbox.glb` | 1.1 × 0.6 × 1.4 m | 764 |
| `GarageTireStack` (teanc de 4 cauciucuri) | `interiors/garage_tire_stack.glb` | 0.9 × 0.9 × 1.1 m | 832 |
| `GarageBarrel` (butoi metalic) | `interiors/garage_barrel.glb` | 0.6 × 0.6 × 0.9 m | 368 |
| `GarageCrate` (lada de lemn) | `interiors/garage_crate.glb` | 0.9 × 0.9 × 0.7 m | 264 |

**Total kit: 4624 triunghiuri, un material per piesa.**

> **Nota despre buget.** Prima versiune a brief-ului punea plafoane (500 pentru
> dulap, 300 pentru butoi, 200 pentru lada) si patru piese le-au depasit din
> bevel. Plafoanele erau derivate din nimic. Comparatia cu piese DEJA LIVRATE
> le arata arbitrare: `garden_hose.glb` are 748 tri, `props_junk.glb` 1448,
> `cow.glb` 2450 — in aceeasi clasa cu ce a iesit aici.
>
> Si, esential: §2 din style_bible cere ca bugetul sa se scaleze cu numarul de
> INSTANTE, nu cu importanta. Piesele astea se instantiaza **o data** intr-un
> ecran de meniu, nu de 100 de ori pe o pista. Plafonul relevant nu e numarul
> de triunghiuri — e numarul de MATERIALE, si acolo kitul costa unul singur.
> Vezi §10.

**Podiumul NU e in kit** — e deja generat in cod (`CarPreview._build_podium`),
ca sa creasca cu lungimea masinii.

### Regula de primitiva

Cand creezi o primitiva, **seteaza-i explicit `radial_segments`/`rings`**. Un
`SphereMesh` la rezolutia implicita e 64×32 = **4224 de triunghiuri** — o roata
de cauciuc de 40 cm ar veni cu geometria unei planete. Cilindrii de cauciuc si
butoi: 10–12 segmente, nu mai mult.

## 4. Paleta — sloturi, nu culori libere

**Nu inventa culori si nu aduce texturi proprii.** Fiecare fata primeste un
INDICE de slot din atlasul comun; culoarea vine de acolo.

| slot | nume | hex | unde in atelier |
|---|---|---|---|
| 5 | `ASPHALT` | `#4B4B4D` | cauciucuri, garnituri, umbra de sub banc |
| 6 | `ASPHALT_EDGE` | `#696765` | podea de beton uzat, sine de usa |
| 8 | `CONCRETE` | `#C8BDA9` | pereti, stalpi, tavan |
| 9 | `WOOD` | `#835C34` | lazi, blat de banc |
| 10 | `RUST` | `#91461E` | butoaie, console ruginite |
| 11 | `PAINTED` | `#7692A8` | dulap de scule, grinzi, usa rulou |
| 7 | `KERB_RED` | `#BB3522` | **doar accent**: o trusa, o dunga pe dulap |

Sloturile **14, 15, 16 sunt accentele de masina** (`#E54839`, `#2C82E8`,
`#F2D03C`) si **nu se folosesc in decor** — altfel atelierul intra in
competitie vizuala cu caroseria, exact ce incercam sa evitam.

`KERB_RED` e singura nota calda saturata si se foloseste pe **cel mult 2% din
suprafata**: o trusa de scule, o dunga. Mai mult, si fundalul incepe sa tipe.

### Coordonata U din atlas

Atlasul e 512 × 512, 32 de sloturi a cate 16 px latime. Centrul slotului `n`:
`u = (n * 16 + 8) / 512 = (n + 0.5) / 32`.

| slot | u |
|---|---|
| 5 | 0.171875 |
| 6 | 0.203125 |
| 7 | 0.234375 |
| 8 | 0.265625 |
| 9 | 0.296875 |
| 10 | 0.328125 |
| 11 | 0.359375 |

`v` = 0.5 pentru toate. Toti vertecsii unei fete primesc **acelasi** `(u, v)`.

## 5. Limbaj de forma

- **Bevel** pe tot: prop-uri 0.04 m, cladiri/structuri 0.08 m. E semnatura care
  tine stilul unitar.
- **Nimic perfect cubic.** Dulapul de scule are colturile tesite, lazile au
  scandurile usor inegale.
- **Golurile sunt spatiu INTRE mase**, nu taieturi boolean. Usa deschisa =
  lipsa de perete intre doi stalpi, nu o gaura decupata.
- Scara verticala exagerata ×1.18 fata de cea orizontala (truc de macheta).
- Prop-urile stau nefiresc de aproape de subiect (2–4 m), ca pe o macheta de
  trenulet — nu imprastiate realist.

## 6. Compozitie: unde sta fiecare piesa

Originea lumii = centrul podiumului. Camera priveste dinspre **+Z**, coborata
18°. Masina sta la origine, cu botul spre camera.

- **Peretele din fund** la `z = -8`, cu **deschiderea usii** centrata pe
  `x = 0`: acolo intra lumina si acolo se vede ca exista o lume dincolo.
- **Pereti laterali** la `x = ±10`. Cel din dreapta (`x = +10`) e **in afara
  cadrului** la distanta podiumului — construieste-l oricum (costa ~100 de
  triunghiuri si apare daca se schimba raportul de ecran), dar nu pune prop-uri
  scumpe pe el.
- **Banc de lucru + panou de scule** pe peretele din stanga, la `x ≈ -7`,
  `z ≈ -3`. Stanga fiindca lumina vine din stanga-sus: bancul isi arunca umbra
  spre interior si da adancime.
- **Dulap de scule, butoi, teanc de cauciucuri, lazi**: grupate in **doua
  insule**, nu imprastiate uniform. O insula langa banc, una in dreapta-fund
  (`x ≈ +5`, `z ≈ -6`). Spatiere regulata intentionat, la 2–3 m.
- **Nimic in fata planului `z = +2`** — acolo e masina si drumul camerei.

Asimetria conteaza: daca pui aceeasi cantitate de prop-uri in stanga si in
dreapta, cadrul moare.

## 6b. Luminatorul din tavan — nu e decor

Golul de 4.2 × 4.2 m din tavan, la `(x = +5.49, z = -5.5)` **in spatiul Godot**,
e singura sursa de lumina directa pe masina. Fara el, subiectul sta integral in
umbra si nu are umbra proprie — adica exact contactul cu solul pentru care
exista umbrele dispare.

Pozitia e calculata, nu aleasa. Cu soarele la elevatie 42° / azimut 315°,
directia luminii e `(-0.525, -0.669, +0.525)`. Doua consecinte masurate:

- raza care intra pe usa si trece pe sub buiandrug (y = 5, z = -8) atinge
  podeaua abia la **z = -4.08** — iar masina sta la z = 0, deci usa singura
  nu o lumineaza niciodata;
- de la tavan (y = 7) la podea, raza se deplaseaza `+5.49` pe z si `-5.49` pe
  x. Un gol centrat la `(+5.49, -5.5)` pune pata de soare exact peste masina.

> ⚠️ **Capcana de axe, de doua ori in acest kit.** Exportul e Y-up: **+Y din
> Blender devine -Z in Godot**. Cutia a fost construita intai cu fundul la
> `y = -8` "ca sa fie la z = -8" si a aterizat la z = +8, in spatele camerei.
> Apoi luminatorul a repetat exact aceeasi greseala. Cand o cota e derivata
> pentru Godot, scrie in cod semnul pentru BLENDER si noteaza conversia.

## 7. Lumina si AO

Atelierul e iluminat in Godot de o directionala la **elevatie 42°, azimut
315°** (din stanga-sus), culoare `#FFD6A3`, plus un fill rece `#C9D9E6`.

**Nu construi lumina in geometrie** (fara fete pictate mai deschis ca sa para
luminate). Singurul lucru copt in asset e **AO-ul in vertex colors**, cu
gradient vertical: mai inchis la baza, mai deschis sus.

Atentie la doua capcane, amandoua masurate pe captura:

1. **AO-ul si umbra dinamica se aduna.** Un AO agresiv la baza peretilor ii
   face aproape negri cand cade si umbra. (Pe pista, acelasi efect a cerut
   coborarea `CLIFF_AO_STRENGTH` de la 0.45 la 0.22.)
2. **`gradient="vertical"` n-are sens pe o podea.** Podeaua e toata la z = 0,
   deci ia integral capatul intunecat al gradientului. Prima versiune a iesit
   cu podeaua la luminanta **18** din 255, acolo unde slotul `ASPHALT_EDGE`
   (`#696765`) cere ~103. Cutia merge pe `gradient="none"` cu `floor` ridicat;
   doar prop-urile primesc gradient vertical, si acela blând (`low=0.72`).

Si un lucru care **nu** tine de asset: intr-o incapere inchisa, fetele intoarse
de la soare traiesc doar din ambient. Peretele din fund are normala `+Z`, deci
`N·L = -0.525` — **negativ**, zero lumina directa. Ambientul vitrinei a trebuit
urcat (0.55 → 0.95) si fill-ul reorientat sa bata dinspre camera.

## 8. Ce NU face

- ❌ Fara texturi proprii. Zero fisiere de imagine langa GLB.
- ❌ Fara materiale PBR (metallic/roughness maps). Albedo plat, atat.
- ❌ Fara sloturile 14–16 (accentele de masina).
- ❌ Fara lumini sau camere in GLB.
- ❌ Fara nume sau logo-uri de marci reale pe cutii, butoaie, panouri. Nici
  "Ignition" — e marca altcuiva. Daca vrei text pe o lada, fa-l forma
  abstracta, nu litere lizibile.
- ❌ Fara geometrie peste `z = +2` sau in afara cutiei de 20 × 14 × 7 m.

## 9. Pipeline de export

Fiecare piesa trece prin lantul standard:

1. `apply_bevel` (0.04 prop / 0.08 structura)
2. `assign_uvs` pe sloturi (tabelul din §4)
3. origine: `base` pentru prop-uri (sta pe podea), `base_axis` daca piesa e
   asimetrica si trebuie sa-si pastreze XY-ul
4. `bake_ao` cu gradient vertical
5. `export_glb("interiors/<nume>.glb")` — Y-up, UV + vertex colors,
   `export_image_format="NONE"` (atlasul NU se incorporeaza)

## 10. Verificare

```
python tools/blender/verify_glb.py assets/models/interiors/garage_bay.glb 1200
```

Verifica: UV-urile pe centrele de slot si ca nu exista materiale in plus.
Cifra de triunghiuri e un PRAG DE SURPRIZA (o primitiva lasata la rezolutia
implicita sare cu zeci de mii dintr-un foc), nu o tinta de optimizare.

**Garda reala a proiectului e numarul de MATERIALE** (max 38 per pista), nu
triunghiurile. Tot kitul asta trebuie sa coste **UN SINGUR** material —
`Palette.world_material()`, aplicat la instantiere. Daca o piesa aduce al
doilea material, e un bug, oricat de bine ar arata.

## 11. Criteriul de acceptare

1. Captura ecranului de garaj: ochiul se duce la masina, nu la fundal.
2. Niciun prop nu e mai saturat decat caroseria.
3. Podeaua nu e mai inchisa decat `ASPHALT`.
4. Toate cele 7 piese impreuna: **un material**. (Triunghiurile se raporteaza,
   nu se plafoneaza — vezi nota din §3.)
5. Silueta se citeste la 456 px inaltime (cat are vitrina pe 720p) — daca o
   piesa devine o pata la rezolutia aia, formele ei sunt prea mici.
