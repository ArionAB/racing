# Inventar Angkor — val 2, grupul B (bolta, bloc, sprijin)

Script: `tools/blender/build_angkor_vaults.py`. Garda: `tools/blender/measure_angkor_w2b.py`
(cu `--selftest`). Imagini: `docs/asset_briefs/img/angkor_fidelity/` (`<nume>.png` comparație,
`<nume>_views.png`, `vault_chain_gamecam.png` = 4 cadre: a/b camera de joc la 30/14 m, c camera
coborată sub tavan, d vedere oblică). Sculptura e SIMPLIFICATĂ (decizia dezvoltatorului).

| piesă | tris | noduri | cote (măsurate din GLB) |
|---|---|---|---|
| `kit/vault_intact.glb` | 2832 | Vault_Stone/Lichen/Streak | 9,2 × 4,0 × 7,43; gol 6,637 la 0–3 m; cheie la 6,60 m; capete ±2,0 |
| `kit/vault_broken.glb` | 2996 | idem | 14,33 × 4,0 × 8,02; gol 6,639; +X deschis (nimic în x ∈ [+0,3, +3,3] peste 3,0 m); −X semi-boltă care nu trece de x = +0,2; moloz doar \|x\| ≥ 3,4 |
| `props/fallen_block.glb` | 584 | Block_Stone/Lichen | 2,500 × 2,528 × 2,500 (boulder_roller × 0,5 = 2,5³); raport 1,000 |
| `props/restoration_prop.glb` | 564 | Prop_Stone/Wood/Lichen | 3,13 × 3,35 × 3,02 |

## Ce a mers / ce nu
- Consola din 4 rânduri a câte 0,8 m (retragere 0,75 m) + placă de cheie plată: golul de
  6,6 m și cheia la 6,6 m ies din construcție, nu din reglaj. Se citește ca arc în trepte, dar
  **drept și unghiular** (nu rotunjit ca în decupare), iar randările de joc îl arată întunecat.
- `vault_broken` (runda 2, contract îngustat de coordonator: blocurile cad doar dinspre +X local): **−X păstrează o semi-boltă** (pereți + 4/3/2 rânduri de consolă pe trei bucăți, ultimul rând scurtat, jumătate de placă de cheie până la x = +0,2, blocuri înclinate pe margine); **+X** e perete rupt jos (varf zimțat 3,0–4,2 m, rândurile de consolă tăiate la fața interioară 3,40); **movilă** de blocuri căzute pe exteriorul peretelui +X (x ≥ 4,5, ~2,4 m, 3 straturi + placă de consolă). Garda verifică acum doar x pozitiv, [0,3, 3,3], peste 3,0 m (3,3 nu 3,4: fața peretelui +X, cu relief, e la 3,34–3,40); sabotaj nou: consolă trecută pe +X. Lanțul din `vault_chain_gamecam.png` începe cu modulul prăbușit.
- (runda 1, înlocuită:) `vault_broken` era, prin contract (acoperiș deschis în \|x\| < 3,3), doar **doi pereți ruinați**
  cu moloz în afară: nu mai citește ca „bolta prăbușită” din decupare (care are bolta întreagă
  pe jumătate). Profilul exterior păstrează treptele consolei, tăiate curat la fața interioară.
- **Blocul e 2,5 m pe toate axele** (boulder_roller are AABB 5 m, × 0,5), nu placa lată din
  decupare. Împreună cu `rim_offset` 2 m: blocul (±1,25) trece prin fereastra \|x\| 0,5–3,3 doar
  dacă axa lui e între ~1,75 și 2,05 m, iar `RimBoulderHazard` îl mută liniar de la
  `rim_offset + 0,9·raza` ≈ 3,1 m spre axă: în prima parte a căderii atinge peretele
  (x ≥ 3,34). Coordonatorul: `rim_offset` mai mic (~0,5) sau teste ProbeRace.
- Originea blocului: baza la z = 0, centrat pe X/Y (regula de kit); hazardul îl re-centrează.
- Rămas: Vault_Lichen are ~1000 tri (pete multe); `restoration_prop` are un nod în plus,
  `Prop_Lichen`.
