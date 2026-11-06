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
| rampă | planul de rulare 7,4 m lat (|x| ≤ 3,7); cu rădăcinile laterale 10,86 m; lungime 7,57; înălțime **1,211**; abatere de la plan **0,011 m**, panta **17,2%**, lateral 0,00%, nimic peste plan în bandă (max 0,007) |

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
| rampă | 3.582 | `Root_Ramp` (1, `CORAL_SAND` 19, AO cald) |

Lichen portocaliu la terasă 0,47%. Scala 1 / rotație identitate pe rădăcini.

## Imagini (`docs/asset_briefs/img/angkor_fidelity/`)

`<nume>.png` (decupare | randare), `<nume>_views.png` pentru toate cinci; `_gamecam.png` pentru
modul, statuie, rampă.

## Citire onestă

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
- **Rampă: nu o consider reușită vizual.** Contractul de fizică e îndeplinit și garda e verde (un plan
  unic, fără trepte), dar **arată ca o placă plată cu rădăcini-pene pe margini**, nu ca o rădăcină
  uriașă; din gamecam se vede o rampă netedă cu ornamente laterale. După 3 runde n-am găsit o formă
  care să dea „rădăcină” fără să rupă planul (corpul unic convex cu fața de sus plată e tocmai ce cere
  contractul). Variantă de luat în calcul: rădăcini mult mai groase, care înfășoară flancurile și
  ridică marginile **sub** planul de rulare, sau accept ca piesă de decor sub un material de clasă.

## Gărzi (`measure_angkor_w2a.py`)

`--selftest`: terasa ridicată cu 0,3 m, bula de 0,2 m pe rampă și panta rampei ×1,4 pică; originalele trec.
