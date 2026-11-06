# Inventar — kit Angkor, val 2, grupul C (naga + uriașii)

Contract: `docs/asset_briefs/angkor_kit.md` §1.5. Decizia dezvoltatorului (6 nov 2026): **tot ce e sculptural e simplificat** —
corpuri-bloc, forme mari și puțin adânci; fața deva e `face_relief` (runda 6), fața asura e o variantă încruntată cu aceleași
principii (`fierce_face` în script). Sculptura adevărată rămâne datorie deschisă (§1.1).

| fișier | rol |
|---|---|
| `tools/blender/build_angkor_naga.py` | cele 5 GLB (`ANK_ONLY=bal|gap|head|deva|asura` reface una) |
| `tools/blender/measure_angkor_w2c.py` | garda pe GLB (coordonate Godot), cu `--selftest` |
| `tools/blender/preview_angkor_w2c.py` | `--row giants` / `--row balustrade` (rând înlănțuit sub camera de joc, `--far` = 60 m); restul modurilor ca `preview_angkor.py` |
| `tools/blender/preview_angkor.py` | doar intrări noi în `SPECS` |
| `tools/blender/verify_angkor.sh` | blocul `# --- val 2, grupul C ---` |

## Convenții comune
- **Trupul naga:** tub de 10 laturi cu jgheaburi de solz la fiecare 0,5 m (adâncime 20% din rază), inelul de la capete plin. **Balustrada, gap și capul: diametru 0,38** (lat ~0,38 × înalt ~0,35; subțire, ca să încapă unda sub 1,05); **uriașii: 0,45** (0,450 × 0,427). Secțiunea e aceeași în balustradă și cap (se leagă), uriașii au trupul lor mai gros, cum cere contractul (brațe). Capetele modulului (z = ±2,0 în Godot) sunt **plane exact** (inelul e forțat).
- **Partea drumului = −X, exteriorul = +X** (Blender și Godot). Uriașii stau cu fața spre −X; rândul de pe cealaltă parte se
  rotește cu 180° în MultiMesh. Capul priveste spre +Y Blender = **−Z Godot**, trupul intră dinspre +Z Godot (−Y Blender).
- Noduri `Naga_Stone`/`Naga_Lichen`, `Deva_*`, `Asura_*`; gresie `ROCK_LIGHT` 3, lichen `CACTUS_GREEN` 12 + câteva pete `LAVA_ORANGE` 30.
  Fără scală/rotație pe rădăcini, zero sloturi noi.

## Piese
| piesă | cote măsurate | triunghiuri | note |
|---|---|---:|---|
| `kit/naga_balustrade.glb` | L 4,000; inaltime **1,031** (max 1,05); grosime **0,590** (max 0,6; 0,54 la baza + pilastri in relief); trup centrat la 0,78 m, diametru 0,38 | 2.012 | **runda 2 (verdictul coordonatorului: zidul din cod e masiv, balustrada trebuie sa se vada la fel de solida).** Baza = piatra continua 0-0,60 m pe toata lungimea, fara nicio deschidere (3 randuri de blocuri cu rosturi pe ambele fete, placa de coronament, patru pilastri in relief la ±0,5/±1,5); sarpele de 0,38 sta PE baza si ondulează ±7 cm (doua cocoase pe modul, zero la capete, aceeasi panta), varful 1,03. Garda `solid_base` priveste modulul din lateral si cere ca fiecare punct (z, y<0,52) sa fie acoperit |
| `kit/naga_balustrade_gap.glb` | L 4,000; inaltime 1,04; X −0,295…+1,40 | 988 | aceeasi baza, **spart zimtat** (miez inclinat, randurile de blocuri opresc la cote diferite, placa mai retrasa), golul liber ~2,0-2,9 m, trupul rupt oblic pe ambele stubs. **Cazute pe +X (exterior):** o bucata de trup de 1,2 m, blocuri de placa/miez, pilastru. Nimic pe −X dincolo de baza |
| `kit/naga_head.glb` | înălțime **2,47**, lățime **1,72** (cerut ~1,6), lungime 1,9; origine la capătul de intrare (z = 0) | 984 | baza continua (y −1,0…−0,4, ca la balustrada) + baza continua + soclu in 3 trepte, trupul de 0,38 urcă de la 0,78 la butuc; șapte capete-bloc (gât + craniu pană + sprânceană + doi ochi-cub) în evantai ±54°, pe placă de evantai în sectoare. Intrarea: aceeași secțiune ca balustrada |
| `kit/deva_giant.glb` | adâncime **1,575** (max 1,6); înălțime **2,97**; L 4,0; trup la **1,40 m** la capete; 2 noduri | 3.324 | vezi mai jos |
| `kit/asura_giant.glb` | adâncime 1,575; înălțime 2,96; L 4,0; trup la 1,40 m; 2 noduri | 3.396 | idem, mai lat în umeri (×1,1), burtă ieșită, față încruntată |

Toate cu 2 materiale-slot (3 + lichen), un singur mesh de gresie per piesă (trupul naga e în același nod `*_Stone`).

## Uriașii
Șezând pe soclu jos în două rânduri (1,56 × 2,40), **genunchii sus și depărtați, tălpile pe soclu, spatele ușor în spate** — nu
picioare încrucișate, fără lotus (brief angkor.md §8). Trunchi hull cu burtă, umeri, două brațe: umăr → cot lateral → antebraț
spre pumnul de deasupra trupului naga, cu degete pe laturile lui; trupul trece peste genunchi și prin brațe și iese la ±2,0 m.
Cap mare (față 0,66 m, lată ×1,25). **Deva:** coroană conică în 6 etaje, `face_relief` (ochi închiși, zâmbet). **Asura:** sprâncene
în V, ochi-disc bulbucați cu pupilă, nas lat, gură încruntată, doi colți-pană, coroană de flăcări (8 țepi + una centrală).
Siluete distincte (conic vs țepos). Lichen: în pete mici pe soclu, genunchi, umeri.

## Ce am văzut (citire onestă, nu acceptare)
Imagini: `docs/asset_briefs/img/angkor_fidelity/` — `<nume>.png` (decupare | randare), `deva_giant_views.png`, `asura_giant_views.png`,
`naga_head_views.png`, `ROW_giants_gamecam.png`, `ROW_giants_gamecam_far.png`, `ROW_balustrade_gamecam.png`.
- **Balustrada (runda 2):** citește acum ca zid de blocuri cu șarpele pe el, ca în desen; nimic transparent. Șarpele e mai neted și mai drept decât al desenului (unda ±7 cm, nu ±20), iar fețele laterale arată plăci întunecate între pilaștri (AO). Fără lei: `naga_lion.glb` (opțional) **nu s-a făcut**, ca să nu consume o rundă.
- **Gap:** golul e clar deschis (~2–2,9 m), capetele zimțate, bucățile pe +X. Se vede ca zid spart, nu ca pasaj.
- **Capul:** silueta de evantai citește bine din față; capetele sunt cuburi cu pană, **nu** capete de cobră — la 30 m e „evantai
  cu creneluri”. Risc de caricatură: mic; de „nu e cobră”: mediu.
- **Uriașii, Buddha?** Risc mic: poza e de tras frânghia (genunchi sus, brațe pe trup naga, soclu jos), coroana conică deva are
  totuși o lectură „statuie asiatică”. **Caricatură/pe lângă:** mare pentru fețe: sub camera de joc (uriașii la 20–40 m) fața e
  de ~1–3 px de latime utilă, deci se citește silueta (cap-bloc, coroană, umeri, trupul prin brațe), nu fața. Capul e o cutie
  înaltă cu față mică; brațele sunt blocuri care citesc ca „cuburi pe pieptul” uriașului, pumnii nu se desluşesc. Asura vs deva se
  deosebesc prin coroană și lățime, nu prin față, de la distanța de joc.
- Trei runde pe uriași nu s-au făcut complet (două: proporții/cap, apoi ajustări); rămân neacceptabile ca „sculptură” — sunt
  **volume lizibile** conform deciziei de simplificare.

## Garda (`measure_angkor_w2c.py`) și sabotajele
`balustrade`, `gap`, `head`, `giant`; `--selftest` cu patru sabotaje (balustradă 1,3 m; **baza spartă** = modulul gap dat drept întreg, prinsă de `solid_base`; uriaș adânc de 2,0; uriaș cu 3 noduri mesh), toate pică, originalele trec. Lățimea capului (1,72) e peste „~1,6” dar în intervalul garda 1,4–1,9.
