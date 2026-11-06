# Inventar — kit Angkor, val 2, grupul A

Contract: `docs/asset_briefs/angkor_kit.md` §1.4. Piesele: `kit/elephant_terrace_module.glb`,
`kit/elephant_terrace_end.glb`, `kit/elephant_trunk_pillar.glb`, `props/leper_king_statue.glb`,
`kit/giant_root_ramp.glb` (în `kit/`, cum cere sarcina, nu în `structures/` ca în tabel).
**Nu e acceptare**: forma se judecă pe imagini, acceptarea e a coordonatorului.
Tot ce e sculptural e **simplificat** (decizia dezvoltatorului): forme mari, blocate, puțin adânci.

## Fișiere

| fișier | rol |
|---|---|
| `tools/blender/build_angkor_terrace.py` | cele 5 piese (`ANK_ONLY=module\|end\|pillar\|statue\|ramp`); elefantul în relief e silueta din poartă, scalată; `limb` (membru fațetat cu 6 laturi) |
| `tools/blender/measure_angkor_w2a.py` | gărzile (terasă, stâlp, statuie, rampă) + `--selftest` |
| `tools/blender/preview_angkor.py` | doar intrări `SPECS` + cheia opțională `gc_yaw` (rotește piesa în gamecam) |
| `tools/blender/verify_angkor.sh` | blocul `# --- val 2, grupul A ---` |

## Cote măsurate (din fișier, coordonate Godot)

| piesă | cote |
|---|---|
| modul | L **8,000** (Z), grosime **1,424**, înălțime **4,010** (peste 4,0 doar petele de lichen de 1 cm pe vârful cornișei), capete plane la Z = ±4,0, secțiune identică (22 puncte) |
| capăt | L **7,940**, înălțime 4,010; capătul de sud (Z max) are exact secțiunea modulului |
| stâlp | 1,600 × 1,600 × 4,020 |
| statuie | 2,300 × 2,300 × 3,660 (soclu 1,2 + figură ~2,4) |
| rampă (runda 2) | planul de rulare 7,4 m lat; cu flancurile 10,24 m; lungime 7,93; înălțime **1,200**; abatere **0,0175 m**, panta **16,9%**, cel mai jos sub plan −0,0175, nimic peste plan (max 0,003) |

**Sensul rampei:** capătul de jos e la −Y Blender = **+Z Godot** (la sol, grosime zero, nimic în față);
mașinile vin dinspre +Z Godot și urcă spre **−Z Godot** (+Y Blender), unde buza are 1,2 m și cade
(perdeaua de rădăcini sub buză). Originea: baza, x = 0, la mijlocul planului.

## Triunghiuri, materiale

| piesă | tri | noduri (materiale) |
|---|---:|---|
| modul | 1.372 | Stone, Lichen, Streak (3) |
| capăt | 1.592 | idem (3) |
| stâlp | 1.104 | Pillar_* (3) |
| statuie | 990 | Statue_* (3) |
| rampă | 6.438 | `Root_Ramp` (19, AO cald), `Root_Infill` (`LOG_DARK` 28), `Root_Stone` (3): 3 materiale |

Lichen portocaliu la terasă 0,47%. Scala 1 / rotație identitate pe rădăcini.

## Imagini (`docs/asset_briefs/img/angkor_fidelity/`)

`<nume>.png` (decupare | randare), `<nume>_views.png` pentru toate cinci; `_gamecam.png` pentru
modul, statuie, rampă.

## Citire onestă (terasa, stâlpul și statuia: acceptate de coordonator)

- **Modul / capăt:** elefanții în relief se citesc ca elefanți (corp, cap, ureche, trompă la sol), blocați.
  Abateri de la decupare: **2 elefanți pe modul, nu 3** (la 3 ar fi sub 2,4 m și ar fi dispărut sub
  soarele de 24°; contractul cere 2–3); picioarele sunt blocuri cu goluri, nu siluete rotunjite; câmpul
  de panou e neted (fără rosturi), deci „zidul de piatră” din decupare lipsește; nu sunt coloane de colț
  cu finialuri la capăt. **Capătul:** „capătul întors” = piersă de colț cu soclul și cornișa pe fața +Y,
  zid de capăt cu blocuri și 3 trepte la baza lui; „treptele laterale” sunt **interpretarea mea**
  (trepte pe fața de capăt, nu pe flancuri) — de confirmat. Gamecam-ul terasei **nu e util**: rotirea
  `gc_yaw` o arată din capăt, fața nu se vede.
- **Stâlp:** se citește ca „stâlp cu o figură lungă pe față”; capul de elefant e vag (urechi bune,
  trompă bună, dar fruntea e boxy, ochii și colții se pierd). Cel mai slab dintre cele sculptate.
- **Statuie:** citește ca figură șezând cu un genunchi ridicat și mâna pe el, păr simplu, fără coroană
  și fără aureolă; piciorul stâng e indoit în lateral (nu încrucișat în față). Blocată, cu față
  mică; nu are fusta-șorț din decupare.
- **Rampă, runda a doua (ideea coordonatorului: suprafața ESTE rădăcinile):** 6 rădăcini în evantai
  (lățime ~1,1 m, se strâng 15% spre buză), fiecare cu capacul tăiat plat pe planul de rulare (6 bucăți
  pe lungime, cu mică ondulație laterală), umeri 3,5 cm sub plan; **umplutură `Root_Infill`
  (`LOG_DARK` 28) la 2 cm sub plan** pe toată lățimea; sub buză, **bucăți de zid `Root_Stone`**
  (cinci blocuri, 0,8–1,14 m) peste care curg 6 rădăcini subțiri; câteva rădăcini subțiri pe flancuri.
  Cote: lățime plan 7,4 (10,24 cu flancurile), lungime 7,93, înălțime 1,200, abatere 0,0175 m, cel mai
  jos sub plan −0,0175, panta 16,9%; 6.438 tri, 3 materiale. **Verdict propriu: tot citește ca placă.**
  Rostul dintre rădăcini e de 2 cm: din camera de joc se vede ca linii subțiri, nu ca rădăcini rotunde,
  iar grila de subdivizare apare ca „dale” (artefact de AO/umbrire pe vârfuri, nu relief). Nu ies
  rădăcini cilindrice din plan fiindcă planul unic și „nimic sub plan − 0,05” le interzic prin
  contract; forma de rădăcină rămâne doar pe flancuri, pe buză și sub ea. **M-am oprit aici** (cum a
  cerut coordonatorul). Variante rămase: material de clasă pe `Root_Ramp` cu textură de scoarță, sau
  acceptat ca decor de pistă cu rădăcinile din cod.
- **Datorie de sculptură:** Regele Lepros și stâlpul cu cap de elefant rămân figuri blocate, sub
  datoria deschisă din kit §1.1 (sculptură reală mai târziu).

## Gărzi (`measure_angkor_w2a.py`)

`--selftest`: terasa ridicată cu 0,3 m, bula de 0,2 m pe rampă, **rostul de 0,2 m adânc între rădăcini** și panta ×1,4 pică; originalele trec.
