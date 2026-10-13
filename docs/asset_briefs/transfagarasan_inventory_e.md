# Inventar — kitul Transfăgărășan, val 2, tf-e (clădirile)

Contract: `docs/asset_briefs/transfagarasan_kit.md` §1.3. Build:
`tools/blender/build_tf_buildings.py`. Preview și măsurători:
`tools/blender/preview_tf_e.py` (`--compare`, `--views`, `--facade`).
Verdict: `bash tools/blender/verify_transfagarasan.sh` → `VERDICT KIT: OK`
(secțiunea „val 2, tf-e”).

Cotele sunt MĂSURATE pe GLB (`verify_glb.py --origin=assembly`, Godot Y-up;
Blender +Y = Godot −Z). Fața bogată e măsurată cu `preview_tf_e.py --facade`
(aria golurilor `*_Void` pe direcție și cât iese geometria peste corp).

## Vocabular nou în `transfagarasan_shapes.py`

`tin_roof` nu mai e stub. Acoperiș de tablă cu fălțuiri:
- ape plane groase de 0,12 m, al căror cant se vede ca streașină;
- nervuri de 4,5 × 3,5 cm la 0,5 m, pe pantă, de la streașină la coamă (la
  `hip`, până la muchie);
- capac pe coamă și pe muchiile de hip;
- `kind="gable"` (două ape) sau `"hip"` (patru ape, coama de 2·(hx−hy));
- coama pe X sau pe Y;
- întoarce cotele fețelor de sus și de jos ale tablei, pe care se opresc
  pereții și frontoanele.

`hip` e scris, dar nefolosit încă (îl folosește `arges_house_a`).

## buildings/cabana_balea_lac.glb

| nod | slot | tri |
|---|---|---:|
| `Cabana_Stone` | MARBLE_GREY 29 (parter, pietre de colț, coș) | 604 |
| `Cabana_Wood` | WOOD_WEATHERED 9 (pereți, terasă, scară, borduri) + LOG_DARK 28 (brâuri, stâlpi de colț, rame, montanți) | 3 790 |
| `Cabana_Roof` | PAINTED_METAL 11 (acoperiș + 2 lucarne, falțuri) | 1 212 |
| `Cabana_Void` | VOLCANIC_BLACK 20 (33 de goluri, gura coșului, tubul de aerisire) | 436 |
| total | `--origin=assembly`, scala/rotația aplicate pe rădăcini | **6 042** |

### Cote (contract: 16 × 10 m, 11 m la coamă, ~50°, parter de piatră 3 m)

| cotă | contract | GLB |
|---|---|---|
| corpul de lemn | 16 × 10 m | 16,0 × 10,0 m (piatra 15,7 × 9,7 m + 3 cm pietre de colț; lemnul iese 0,15 m peste piatră) |
| parterul de piatră | 3 m | 3,0 m |
| coama | 11 m | **10,98 m** (capacul); tabla la coamă 10,90 m |
| coșul | — | 12,31 m (1,3 m peste coamă, ca pe decupare) |
| panta | ~50° | **45°** (abatere, vezi mai jos) |
| streașina | — | 0,6 m pe toate laturile; streașina lungă la 5,3 m |
| bbox total | — | 17,20 (X) × 16,43 (Y) × 12,31 m; Y de la −5,71 (streașina din spate) la +10,73 (piciorul scării) |
| golurile | ≥ 0,15 m adâncime | **0,218 m** de la fața peretelui la placa neagră (`Cabana_Void`: \|x\| max 7,782 = 8,0 − 0,218; \|y\| max 4,782 = 5,0 − 0,218), plus rama care iese 5 cm |

**Originea** e pe centrul corpului, iar baza e la 0 (piatra, stâlpii terasei și
piciorul scării ating y = 0). Terasa și scara ies **5,85 m pe +Y** peste corp,
deci originea NU e centrul bbox-ului.

### Fața bogată, măsurată pe GLB (`--facade`)

| direcție (Blender) | Godot | goluri | ce iese peste corp |
|---|---|---:|---|
| **+Y** | **−Z** | **10,00 m²** (10 goluri: 5 ferestre, 2 uși, 2 lucarne, plus fereastra de deasupra terasei) | **terasa + scara: 5,85 m** |
| +X | +X | 6,54 m² (11 goluri: frontonul din decupare) | 0,72 m (streașina) |
| −Y | +Z | 4,73 m² (7 goluri) | 0,83 m (streașina) |
| −X | −X | 3,18 m² (5 goluri) | 0,72 m (streașina) |

Fața bogată e **+Y în Blender = −Z în Godot**, măsurat. Frontonul +X e al
doilea ca număr de goluri: e fața mai frontală din decupare.

### Fidelitate

- Comparația: `docs/asset_briefs/img/transfagarasan_fidelity/cabana_balea_lac.png`.
  Decuparea e în stânga, randarea GLB-ului în dreapta, cu camera la azimutul
  32° și elevația 22°: frontonul +X în stânga, latura +Y cu terasa în dreapta,
  ca pe decupare.
- Cele 4 azimuturi: `cabana_balea_lac_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| parter de piatră | gri, piatră brută, ~1/3 din înălțimea până la streașină | 3 m, MARBLE_GREY, 4 pietre de colț alternante pe muchie (relief 3 cm) | abatere de culoare: în preview piatra iese aproape albă. Hexul slotului e #B8B4AC, iar lumina harnasului o albește. Piatra brută (rosturile) o dă clasa `stone_wall` la integrare; geometric nu se vede la 30 m |
| etajul de lemn | maro-portocaliu, iese peste piatră, brâu la bază | WOOD_WEATHERED, iese 0,15 m, brâu LOG_DARK, stâlpi de colț închiși | OK ca formă; lemnul e mai închis și mai rece decât portocaliul din desen (#835C34). Scândurile nu sunt geometrie |
| mansarda în fronton | brâu orizontal care desparte etajul de fronton | brâu + scândură înclinată (streașină mică) pe ambele frontoane | OK |
| acoperiș | abrupt, gri, falțuri dese | 45°, PAINTED_METAL cu nervuri la 0,5 m, capac pe coamă, borduri de lemn sub frontoane | formă OK; **culoarea iese albăstruie** (#7692A8, slotul din tabelul de roluri), iar pe planșă e gri neutru. Tenta `*_Roof` se decide la integrare |
| lucarne | 1 pe apa din față | **2** (contractul), 2,4 m late, în două ape de tablă, cu câte o fereastră | după contract |
| coș | 1, cărămiziu, lângă vârful frontonului stâng, iese peste coamă | 1, **piatră** (contractul), la x = +6,5, 1,3 m peste coamă, cu gura neagră | după contract; în preview iese alb, din același motiv ca piatra |
| tub de aerisire pe coamă | punct negru | cilindru negru de 8 cm pe apa din spate | OK |
| ferestre fronton | parter 3, etaj 4 (perechi), mansardă 3 + aerisire | 3 + 4 + 3 + 1, cu ramă LOG_DARK, pervaz și cruce (4 ochiuri), goluri de 0,22 m | OK; se citesc ca goluri. Fundul e #55535A, deci gri închis, nu negru pur |
| ferestre latura +Y | parter 1 + ușa de sub terasă; etaj 4 | 1 + ușă; etaj 4 + ușa spre terasă + 1 fereastră peste terasă | OK |
| terasă | la nivelul etajului, pe stâlpi, balustradă de lemn | 6 × 2,4 m la +3 m, 3 stâlpi, **balustradă din scânduri drepte** pe 3 laturi | OK (corectura „fără balcon sculptat”) |
| scară | coboară din terasă spre privitor | 11 trepte, 1,15 m lată, perpendiculară pe perete spre +Y, cu vang, mână curentă și stâlpi | OK |
| verandă de jos cu acoperiș propriu | da (în dreapta) | **lipsește** | omisă voit: corectura „cel mult o terasă simplă” |
| bolovani, iarbă, tufă | da | nu | corectura: vegetația vine la integrare |
| proporții | casă compactă, h/l ~0,7 | 16 × 10 m. Latura lungă iese mai lungă decât pe desen, unde e ~12–13 m | abatere asumată: cotele vin din tabel, nu din planșă |

**Rundele** (3 din 3):
1. Prima rundă avea un bug: balustrada terasei era la nivelul solului (lipsea
   cota terasei în `railing_boards`). Lucarnele erau mici.
2. Balustrada a fost reparată, iar lucarnele mărite la 2,4 m, cu o fereastră
   de 1 × 0,8 m. Peretele de lemn al laturii lungi încă ieșea ca o fâșie
   scundă, de ~1,9 m sub streașină. Pe decupare e un etaj întreg.
3. Panta a coborât de la 47° la 45°, cu coama păstrată la 11 m, deci peretele
   lung a crescut cu 0,4 m. Ferestrele etajului stau acum sub streașină cu
   lemn deasupra. E starea livrată. După rundă s-a reparat un defect de
   origine, nu de formă: vangul scării cobora 5,7 cm sub sol și ridica toată
   casa de pe z = 0.

### Abateri asumate

- **Panta e 45°, nu ~50°.** Cu 50° și coama la 11 m, peretele de lemn al
  laturii lungi iese 1,6 m sub tablă, sub înălțimea ușii spre terasă.
  Decuparea arată acolo un etaj întreg. Coama s-a păstrat la contract.
- **Culorile din preview:** piatra și coșul ies aproape albe, iar tabla
  albăstruie. Sloturile sunt cele din tabelul de roluri. Tenta se decide la
  integrare (`stone_wall` pe `*_Stone`, `*_Roof`).
- **Veranda de jos** din dreapta decupării nu există (corectura).

## Stare la oprire (etapa 1, 13 oct 2026)

- **Făcut:** `tin_roof`, `cabana_balea_lac` (3 runde), preview `preview_tf_e.py`
  și secțiunea din verify. `VERDICT KIT: OK`.
- **Așteaptă verdictul coordonatorului** pe `cabana_balea_lac`.
- **Nefăcute:** `cabana_balea_cascada`, `stana`, `arges_house_a`,
  `arges_house_b`, `souvenir_stall`.
