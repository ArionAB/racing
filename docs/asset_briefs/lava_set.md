# Brief asset — Setul de lavă (`lava_flow.glb` + `volcanic_bomb.glb`)

Brief auto-conținut pentru un agent Blender. Sursele:
[style_bible.md](../style_bible.md) + [blender_export.md](../blender_export.md) +
[scripts/palette.gd](../../scripts/palette.gd).

Referință vizuală: `docs/track_briefs/img/stromboli_assets_a.png`, panourile 5
(LAVA FLOW, 3 stages) și 6 (VOLCANIC BOMBS). **Corecție față de planșe:** acolo
crusta a ieșit „pavaj de bolovani rotunzi"; noi vrem **crustă de funie
direcțională** — pliuri alungite PE DIRECȚIA curgerii, plăci fațetate, nu
pietre rotunde lipite.

**Rolul (gimmick-ul pistei):** limba de lavă închide ruta scurtă tur după tur —
stadiul 1 liber, stadiul 2 lasă o poartă de 4 m, stadiul 3 e zid. Bombele sunt
proiectilele erupției ciclice de pe Sciara. Contactul cu oricare = distrugere.

> **Prompt de dat agentului** — de la linia orizontală în jos e paste-ready.
> Sunt DOUĂ fișiere de livrat, descrise pe rând.

---

Construiește un set de lavă low-poly pentru un joc de curse în stil dioramă
(ton *Art of Rally*, machetă de masă, NU foto-realist): o limbă de lavă în
trei stadii de avans și trei bombe vulcanice. Crusta e neagră, fațetată, cu
**crăpături incandescente ca geometrie separată de suprafață** — în engine
crăpăturile primesc material emisiv.

## Fișierul 1: `lava_flow.glb` — trei obiecte

Aceeași limbă de lavă la trei momente. Toate: late **8–12 m** (variabil pe
lungime), groase **0.6–1 m** (crusta stă PESTE sol, cu margine laterală
teșită 30–40° — mașina care o atinge trebuie oprită de fizică, nu urcată pe
ea), **frontul bulbos** — lobi rotunjiți care se împing înainte. Suprafața:
**pliuri de funie** alungite pe direcția curgerii (valuri joase de 0.2–0.3 m,
fațetate), NU bolovani.

Crăpăturile incandescente: fâșii de geometrie de 0.15–0.4 m lățime, scufundate
0.05 m în crustă, desenate ca o rețea rară care urmează pliurile + un contur
aproape continuu pe buza frontului. Pe stadiile mai lungi, crăpăturile se
înmulțesc spre front (lava proaspătă) și se răresc spre coadă (lava veche).

### `Lava_Stage1` — ≤ 900 triunghiuri
- Lungime **40 m**, un singur braț, front cu 2–3 lobi.

### `Lava_Stage2` — ≤ 1300 triunghiuri
- Lungime **60 m**; la ~2/3 se **desparte în DOUĂ brațe** care lasă între ele
  un culoar drept, curat, de **4.0 m lățime** (poarta prin care încă se poate
  trece). Ambele brațe au front activ, cu cele mai multe crăpături pe buzele
  culoarului — pericolul trebuie să se vadă exact unde treci.

### `Lava_Stage3` — ≤ 1400 triunghiuri
- Lungime **80 m**, un front lat, continuu, ca un zid revărsat: lobii s-au
  unit, culoarul nu mai există. Cel mai puternic contur incandescent pe front.

Direcția curgerii: **−Z** (frontul spre −Z, coada spre +Z). Cele trei stadii
se suprapun ca poveste — construiește-le din aceeași formă de bază alungită,
ca stadiul 2 să se citească drept „stadiul 1 care a mai curs".

## Fișierul 2: `volcanic_bomb.glb` — trei obiecte

### `Bomb_S` / `Bomb_M` / `Bomb_L` — ≤ 250 triunghiuri fiecare
- Diametre **0.6 / 0.9 / 1.2 m**; siluete ușor turtite, de minge de rugby
  scurtă (bombele reale se rotesc în zbor), fațete mari.
- Crusta neagră crăpată: 4–6 **crăpături incandescente** ca fâșii de geometrie
  scufundate, care înconjoară forma — de la orice unghi se vede măcar una
  (obiectul se rostogolește pe pistă).

NU (ambele fișiere): lavă lichidă transparentă, stropi, fum, particule
modelate, text.

**Culoare — FĂRĂ texturi proprii. UV colapsate pe centrul slotului:**
- Crusta (tot ce e negru): **u = 0.640625, v = 0.5**
- Fețele laterale/umbrite ale crustei, alternativ: **u = 0.140625, v = 0.5**
- **Crăpăturile, buzele frontului, conturul incandescent: u = 0.953125, v = 0.5**

**Vertex colors = AO copt:** crusta 0.7–1.0 cu întunecare între pliuri;
**crăpăturile incandescente rămân la 1.0** (AO peste ele omoară semnalul).

**Scară, origine, orientare:**
- `Lava_Stage*`: origine la **sol, în CENTRUL culoarului la nivelul
  frontului** (punctul unde stadiile se aliniază între ele) — adică toate trei
  exportate astfel încât, suprapuse la origine, fronturile lor să fie la
  −40 / −60 / −80 pe Z față de aceeași coadă. Concret: coada la +Z0 comun,
  frontul crește spre −Z.
- `Bomb_*`: origine în centrul volumului (se rostogolesc — pivotul la centru,
  NU la bază).
- Bevel 0.1 m pe crustă. Export la (0,0,0).
- Buget: `lava_flow.glb` **≤ 3600**; `volcanic_bomb.glb` **≤ 750**.

**Export:** două fișiere glTF Binary: `lava_flow.glb` (obiecte `Lava_Stage1`,
`Lava_Stage2`, `Lava_Stage3`) și `volcanic_bomb.glb` (`Bomb_S`, `Bomb_M`,
`Bomb_L`), copii direcți ai rădăcinii. Mesh + UVs + Vertex Colors + Normals;
Apply Modifiers ON.

---

## Note pentru noi (nu fac parte din prompt)

- **Sloturi:** `VOLCANIC_BLACK` 20, `ROCK_DARK` 4, `LAVA_ORANGE` 30 (adăugat
  în același PR: `scripts/palette.gd` + atlas regenerat).
- **Emisivul e al integrării, nu al asset-ului:** un SINGUR material de clasă
  partajat (lavă + bombe + gurile craterului) cu emission pe albedo-ul
  slotului 30 — garda numără materialele, deci unul, nu trei.
- **Alinierea stadiilor la aceeași origine** e contractul cu `LavaFlowHazard`:
  hazardul schimbă stadiul la `lap_completed` fără să mute nodul — doar swap
  de mesh vizibil. Coada comună + frontul care crește = avansul se citește.
- **Bombele au pivot central** fiindcă `RockfallHazard` le rostogolește
  (traseele `Path3D` de pe Sciara, declanșate de `EruptionCycle`).
- **Coliziune:** limba primește collider din `world_prop` la integrare
  (memoria `decor-manual-coliziune`); marginea teșită sub 40° e ca să nu fie
  citită ca zid vertical de raycast-ul suspensiei la atingeri laterale — dar
  contactul frontal tot distrugere e, prin hazard, nu prin fizică.
- **Destinație:** `assets/models/stromboli/effects/…`.
- **De raportat în PR:** captură de la nivelul drumului cu stadiul 2 —
  testul: poarta de 4 m se citește ca trecere, buzele ei ca pericol?
- **Checklist:** 3+3 noduri cu nume exacte; bugete; crăpături la AO 1.0;
  fronturile spre −Z; bombele cu pivot central.
