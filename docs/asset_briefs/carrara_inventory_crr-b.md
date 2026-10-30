# Inventar — kit Carrara (Track23), grupa crr-b: structurile (kit §1.3)

Contract: `docs/asset_briefs/carrara_kit.md` §1.3. Fișierul e al grupei crr-b
(val 1); coordonatorul îl unește cu `carrara_inventory.md`. `gallery_pillar` e
**amânat** (sala de 16 m nu există în cod) și nu s-a modelat.

## Fișiere

| fișier | rol |
|---|---|
| `tools/blender/build_crr_structures.py` | cele trei piese; docstring-ul fiecărei funcții = lista de elemente, scrisă înainte de geometrie. Helpere proprii: `extrude_yz`, `extrude_poly_xz` (piatră cu față bombată), `tapered_split` / `box_split` (masă de marmură tăiată în `*_Marble` / `*_MarbleBase` pe același plan), `streak` (dâră de rugină pe o față, și pe pila teșită), `emit_fixed` (export fără nicio mutare: piesele se construiesc direct față de originea cerută) |
| `tools/blender/measure_crr_structures.py` | gărzile, pe GLB-ul exportat: `deck` (banda drumului pe viaduct), `gap` (golul măsurat ca gol, pe mai multe ferestre), `sabotage` (copie a GLB-ului cu un nod mutat/scalat, pentru dovada că gărzile pică) |
| `tools/blender/preview_crr_structures.py` | `--compare`, `--views`, `--front`; folosește `preview_carrara.py` **neschimbat** (exec) și adaugă doar planul negru din spatele gurii (NU e în GLB) și camera/aspectul per piesă |
| `tools/blender/verify_carrara.sh` | secțiunea „val 1, crr-b": `check`, `crr_deck`, `crr_gap`, `crr_nodes`, cu excepțiile declarate și motivate |

`carrara_shapes.py`, `preview_carrara.py` și `measure_carrara_truck.py` nu s-au
atins.

## Cote măsurate (din GLB, nu din build)

Axele glTF: X lateral, Y sus, Z adâncime (= −Y Blender). Fața pe +Y Blender.

### ponti_di_vara.glb

| | lungime | lățime | înălțime | deck_max în \|x\| ≤ 4,6 | acoperire bandă | parapet |
|---|---:|---:|---:|---:|---:|---|
| contract | 36 m | — | pile de 26 m, h/l ~0,75 | ≤ −0,05 | ≥ 99% | 0,9 m la \|x\| 4,7–5,3, nod separat |
| GLB | **36,00** | 11,10 (cornișa 10,70, soclurile 11,10) | **−26,00 … +0,90** (h/l 0,75) | **−0,060** | **100%** | **4,700–5,300 pe ambele părți, sus 0,900, 36,00 m**, nod `Viaduct_Parapet` |

- Origine: pe axa drumului, la cota drumului (asfaltul din cod e la 0). Fără
  parapet, cel mai înalt punct e fața de sus a cornișei, −0,06, pe toată lățimea.
  `verify_glb --origin=rim --rim-above=0.95`: „coronament: confirmat (Y −26,000 …
  0,900, atârnă sub origine)".
- Triunghiuri: **5.816** (Brick 1.200, Marble 2.712, MarbleBase 816, Rust 240,
  Void 176, Parapet 672). Materiale: **6** (un nod = un material).
- Noduri / sloturi: `Viaduct_Brick` (TILE_TERRACOTTA 23 → clasa `roof_tiles`),
  `Viaduct_Marble` (CORAL_SAND 19 → `carrara_marble`), `Viaduct_MarbleBase`
  (MARBLE_GREY 29, treimea de jos a pilelor, sub −19,3 m), `Viaduct_Rust`
  (LARCH_RUST 27), `Viaduct_Void` (VOLCANIC_BLACK 20, golurile de drenaj),
  `Viaduct_Parapet` (CORAL_SAND 19 bordura + PAINTED_METAL 11 balustrada; stă pe
  atlas).
- Geometrie: 3 arce în plin cintru (deschidere 6,27 m, 14 laturi pe arc, 14
  bolțari pe fiecare față), 2 pile de 3,8 m la creștet teșite la 5,0 m la bază,
  2 culei de 4,8 m, nașterea la −5,40 m.
- Coliziune: kitul cere `mesh` (`hull` ar umple arcele); se setează pe
  instanță la integrare.

### gallery_portal.glb

| | lățime | înălțime | adâncime | gol lateral pe 0–10,5 m | înălțime liberă | gol pe caroserie 0,15–2,0 |
|---|---:|---:|---:|---:|---:|---:|
| contract | 18 | 15 | 3 | **≥ 10,0** | **≥ 10,5** | — |
| GLB | **18,00** | **15,00** | 3,00 ramă (Y −2,65 … +0,35); 3,61 cu lampa | **10,30** (x −5,15 … 5,15) | **10,85** (la mijloc și minimul pe tot golul caroseriei) | 10,30 |

- Golul e măsurat ca gol: proiecția tuturor triunghiurilor (toate nodurile,
  inclusiv căptușeala `Portal_Void`) pe planul feței, grilă 5 cm. Lățimea e
  aceeași pe toate ferestrele tipărite (1, 4, 6, 8, 10 m): golul e
  dreptunghiular, tăiat drept. Rama de beton din cod (9,6 × 9,8) încape cu
  0,35 m lateral și 1,05 m deasupra.
- Origine: axa drumului, planul feței, bază la 0 (`--origin=assembly`: „bază
  confirmată, Y = 0,000").
- Triunghiuri: **374** (Marble 140, MarbleBase 48, Rust 108, Glow 12, Void 66).
  Materiale: **5**. Puține triunghiuri fiindcă piesa e din 10 cutii tăiate drept
  (regula 7: muchii vii, fără teșire); forma o dau masele, rosturile și colțurile
  sparte, nu poligoanele.
- Noduri: `Portal_Marble` (19), `Portal_MarbleBase` (29, tot ce e sub 5 m),
  `Portal_Rust` (27, 9 dâre), `Portal_Glow` (SAND_LIGHT 0, sticla lămpii),
  `Portal_Void` (20: căptușeala de 2,0 m, y −0,65 … −2,65, fără podea, plus
  feroneria lămpii).

### marmifera_portal.glb

| | lățime | înălțime | adâncime | gol pe 0–6 m | cheia (mijloc) | gol pe caroserie 0,15–2,0 | gol la 8 m |
|---|---:|---:|---:|---:|---:|---:|---:|
| contract | 14 | 11 | 2,5 | **≥ 10,0** | **≥ 8,5** | — | — |
| GLB | **14,00** | 11,01 (coronamentul 10,75–11,0 + mușchiul de 1,5 cm) | 2,52 ramă (Y −2,30 … +0,22); 7,30 cu șinele (până la +5,0 în față) | **10,20** (x −5,10 … 5,10) | **9,60** | 10,90 | 7,60 |

- Golul e limitat la 6 m de arc (R 5,5, nașterea la 4,2): la 6 m, căptușeala
  cu poligon de 16 laturi dă 10,20. Prima variantă (R 5,4) dădea **exact 10,00**
  pe aceeași măsurătoare; am lărgit arcul în loc s-o declar „trece la limită".
- `--floor=0.1`: șinele (7 cm) și traversele (2 cm) stau pe drum, în gol (kit:
  „pot fi și pe drum: se taie la integrare"). Fără floor, banda 0–2 m e blocată
  de ele, deci cifra fără floor ar fi 0. Garda e dovedită că nu ascunde un
  obstacol mai înalt (sabotajul „șinele +0,2 m" pică, vezi mai jos).
- Lampa atârnă de intrados la x = 2,2, cu baza la 8,62 m, deci nu intră nici în
  banda de 0–6 m, nici sub cheie.
- Origine: axa drumului, planul feței, bază la 0 (`--origin=assembly`).
- Triunghiuri: **1.912** (Stone 1.312, Moss 360, Rail 156, Glow 12, Void 72).
  Materiale: **5**.
- Noduri: `Portal_Stone` (MARBLE_GREY 29 → `tf_stone`), `Portal_Moss`
  (TROPICAL_GREEN 21), `Portal_Rail` (PAINTED_METAL 11 șinele + WOOD 9
  traversele; stă pe atlas), `Portal_Glow` (0), `Portal_Void` (20: căptușeala de
  2,0 m, y −0,3 … −2,3, plus feroneria lămpii).

Comun: niciun FOAM_WHITE 22, niciun slot de mașină, fără text. Scala și rotația
sunt la identitate pe toate rădăcinile (garda din `verify_carrara.sh`).

## Gărzile și sabotajele (rulate pe 27 oct 2026)

Copiile sabotate s-au scris cu `measure_crr_structures.py sabotage` (doar JSON-ul
nodului se schimbă), apoi s-a rulat garda neschimbată:

| sabotaj | gardă | rezultat |
|---|---|---|
| `Viaduct_Marble` +3 cm în sus | deck | **pică**: deck_max −0,030 > −0,05 |
| `Viaduct_Brick` +0,70 m | deck | **pică**: deck_max 0,000. Vârfurile cărămizii sunt la \|x\| = 4,70, în afara benzii, deci doar tăierea triunghiurilor la marginea benzii o prinde; verificarea pe vârfuri (`vert_max`) ar fi ratat-o |
| `Viaduct_Parapet` mutat −0,30 m pe X | deck | **pică**: parapetul iese din 4,7…5,3 pe ambele părți |
| `Portal_Marble` (galerie) × 0,95 pe X | gap | **pică**: 9,80 < 10,0 |
| `Portal_Marble` (galerie) −0,5 m | gap | **pică**: 0,00 pe banda 0–10,5 (buiandrugul la 10,35) |
| `Portal_Stone` (Marmifera) × 0,95 pe X | gap | **pică**: 9,70 < 10,0 |
| `Portal_Stone` (Marmifera) −1,2 m | gap | **pică**: 9,10 < 10,0 și cheia 8,40 < 8,5 |
| `Portal_Rail` +0,2 m (peste floor) | gap | **pică**: 0,00 |
| originalele (control) | toate | **trec** |

`bash tools/blender/verify_carrara.sh` → `VERDICT KIT: OK` (camionul pilot și
cele trei structuri).

## Fidelitate (2 runde din 3 pe fiecare piesă)

Imagini în `docs/asset_briefs/img/carrara_fidelity/`: `<nume>.png` (decupare |
randare, 3/4), `<nume>_views.png` (4 azimuturi), `<nume>_front.png` (elevație,
aproape la nivelul ochiului). Planul negru din spatele gurii portalurilor e doar
în preview.

Runda 1 → 2:
- viaductul a primit **colțare** pe muchiile pilelor (18 asize alternante,
  ieșite 6 cm), fiindcă pilele de 20 m erau plane;
- galeria a primit rosturi de 18 cm, adânci de 25 cm, ieșiri de 0–0,35 m și 4
  colțuri sparte;
- Marmifera a primit **umerii în pantă** sub un coronament mai îngust, cu pietre
  de cap în trepte. Pietrele sunt mai mici (0,5–0,65 × 0,7–1,3 m), bombarea e
  redusă (făcea „piramide"), mușchiul e mai mult și pe laturi, iar șinele merg
  până la 5 m în față;
- camerele portalurilor erau pe latura greșită. Ecranul privește fața +Y, deci
  dreapta ecranului e −X.

### ponti_di_vara

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| arce | 3, de cărămidă, inel de bolțari în relief, aproape semicerc | 3 în plin cintru, 14 bolțari ieșiți 0,10 m pe față, boltă de cărămidă | OK |
| pile | 2 interioare + 2 culei, marmură crem din blocuri, teșite | la fel, capitel, brâu la −14 m, soclu, colțare alternante | OK ca formă. Blocurile de pe fețele mari vin din clasă (nu se văd în preview) |
| proporții | pile scurte, h/l ~0,26 | pile de 26 m, h/l 0,75 | **abatere voită**: kitul cere 26 m, iar diorama le arată înalte. Arcele și banda de cărămidă păstrează proporțiile planșei (deschiderea ≈ 1,65 × pila; planșa ≈ 1,7) |
| timpane | cărămidă, și peste culei | la fel, cu colțare de marmură la capete | OK |
| cornișă | bandă de piatră deschisă | două trepte de marmură, ieșite 0,65 / 0,30 m | OK |
| goluri de drenaj | **4** pe față | **2** pe față, deasupra pilelor | **abatere**: am urmat kitul („două goluri"); se adaugă ușor dacă coordonatorul vrea 4 |
| parapet | balustradă metalică pe bordură | bordură 0,28 m + stâlpi la 1,5 m + 2 rigle, nod separat | OK |
| rugină | pete portocalii pe blocuri | 10 dâre sub capiteluri | OK, subtil |
| patina | — (planșa n-are gri) | treimea de jos a pilelor pe MARBLE_GREY | regula 8 din kit. Pe preview banda gri e dură, cu muchie orizontală; în joc o înmoaie clasa `carrara_marble` (nevăzut încă) |
| tufe și bolovani la bază | da | nu | **abatere voită** (corectura de kit) |

### gallery_portal

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| ramă din blocuri mari | ~11 blocuri: stâlp stâng 2, drept 3, 2 colțuri înalte, buiandrug 2 asize | 10 blocuri: stâlpi 2 + 2, 2 colțuri înalte, buiandrug 2 asize × 2 | abatere mică: stâlpul drept are 2 blocuri, nu 3 (kitul cere 6–10) |
| mase și rosturi | blocuri ieșite, muchii ciobite | ieșiri 0–0,35 m, rosturi de 18 cm, 4 colțuri sparte | OK; mai curat geometric decât planșa |
| gol | dreptunghi tăiat drept, ~45% din lățime | dreptunghi tăiat drept, 58% din lățime (10,4 / 18) | **abatere voită**: golul ≥ 10 × 10,5 cerut de rama codului |
| interior | pereți de marmură luminați, dale, lampă pe peretele din fund | 0,65 m de intrados marmură, apoi negru 2 m | **abatere voită**: Void cerut de kit, podeaua e drumul din cod |
| lampă | în interior, pe peretele din fund | pe buiandrug, deasupra golului | **abatere voită** (kitul o cere pe buiandrug) |
| culoare | crem cu vene portocalii | crem 19, dâre 27; jos gri 29 sub 5 m | venele le dă clasa. Gri-ul de jos e regula 8 (treimea de jos); pe preview e o bandă netă, cu blocurile de jos întregi pe gri |
| moloz la bază | da | nu | **abatere voită** (corectura de kit) |

### marmifera_portal

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| arc | plin cintru din ~13 bolțari + cheie, nașterea la ~3/4 din gol | 15 bolțari, cheia mai mare și mai ieșită, nașterea la 4,2 m din 9,6 | **abatere voită**: golul ≥ 10 m pe 0–6 m coboară nașterea |
| fruntar | piatră brută în asize, rosturi alternate | 61 de pietre cu față bombată, tăiate după extrados | OK |
| silueta de sus | bloc de coronament mai îngust, umeri înclinați, creneluri neregulate | coronament pe \|x\| ≤ 4,6 cu creștete 10,75–11,0, umeri 10,4 → 8,6 cu pietre de cap în trepte | OK |
| raport ramă / gol | ramă groasă, golul ~51% din lățime | golul 79% din lățime (11 / 14), 0,4–0,6 m de piatră lângă inel la naștere | **abatere voită** (gol ≥ 10 m în 14 m de lățime); piesa citește mai „subțire" decât planșa |
| mușchi | pete pe laturi și sus | 7 pete pe față + pete pe coronament / umeri | OK ca loc. Petele sunt verde saturat, cu contur ovoid net; pe planșă mușchiul e mai difuz |
| șine | două, pe traverse, intră în tunel | două, ecartament normal, traverse la 0,65 m, de la +5 m la −2,3 m | OK |
| lampă | pe peretele drept, la jumătatea înălțimii | atârnată de intrados la x 2,2, la 8,6–9,2 m | **abatere voită**: pe perete ar intra în golul de 0–6 m |
| tufe și bolovani | da | nu | **abatere voită** (corectura de kit) |
| culoare | gri-bej cald | MARBLE_GREY → țintă `tf_stone` #8E8C82 | OK; tenta finală o dă clasa |

## Contracte înghețate

- **ponti_di_vara**: originea pe axa drumului, la cota drumului; geometria
  atârnă până la −26,00. **Nimic în afară de `Viaduct_Parapet` peste −0,05 în
  \|x\| ≤ 4,6**, iar tablierul acoperă 100% din bandă. Parapetul e nod separat
  la \|x\| 4,7–5,3, de 0,90 m. Lungimea e 36,00 m pe Z Godot, cu capete plane la
  ±18. Coliziunea `mesh`.
- **gallery_portal**: golul **10,30 × 10,85 m măsurat ca gol** (≥ 10,0 ×
  10,5). Fața pe −Z Godot, originea la planul feței, baza la 0.
- **marmifera_portal**: golul **10,20 m pe 0–6 m**, cheia la **9,60 m**,
  măsurate ca gol, cu șinele excluse (floor 0,1). Fața pe −Z Godot, originea la
  planul feței, baza la 0. Șinele ies 5 m în fața portalului.
- Numele de noduri (verificate în `verify_carrara.sh`).

## Stare la oprire

- Cele trei piese sunt construite, măsurate, cu gărzile și sabotajele dovedite,
  iar comparațiile au fost privite element cu element (2 runde din 3 pe
  fiecare). `verify_carrara.sh` → `VERDICT KIT: OK`.
- Nu s-au atins `scenes/` și `scripts/`. Rămân coordonatorului:
  - integrarea (clasele `roof_tiles` pe `*_Brick`, `carrara_marble` pe
    `*_Marble` / `*_MarbleBase`, `tf_stone` pe `Portal_Stone`);
  - coliziunea `mesh` pe instanțe;
  - stingerea `Viaduct_Parapet` dacă rămâne berma din cod;
  - tăierea șinelor dacă deranjează;
  - importul în Godot (fișierele `.import` nu s-au generat aici).
- Nevăzut: piesele în joc, cu fereastră (lumina temei, clasele, umbrele), și
  coliziunea pe ProbeRace. Nemăsurat: așezarea pe Track23 (golul de ~31 m al
  cheii față de cei 36 m ai viaductului, rama de beton a tubului în gol).
- Deschise (estetic):
  - pe preview, banda de patină e netă pe viaduct și pe galerie;
  - viaductul are 2 goluri de drenaj pe față, planșa are 4;
  - mușchiul de pe Marmifera e mai saturat și mai net decât pe planșă;
  - interiorul galeriei e negru, nu marmură luminată (cerința de Void).
