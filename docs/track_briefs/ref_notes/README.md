# Note de referință — Ignition (1997)

Analiză a 5 curse filmate (21 aug 2026). **Note de design, nu geometrie.**
Scopul e să extragem numerele și deciziile din spatele pistelor, ca să le
putem reconstrui pe fizica și pe temele noastre. Niciun traseu, model sau
textură nu se copiază — vezi CLAUDE.md, „Nume și legal".

- [world_design.md](world_design.md) — **verticalitate si linii de vedere: ce ii place dezvoltatorului**
- [sisteme.md](sisteme.md) — viteze, turbo, costul hazardurilor, cameră, HUD
- [01_ferma_cariera.md](01_ferma_cariera.md) — tren la trecerea de cale ferată, furtună cu fulgere
- [02_desert_oras.md](02_desert_oras.md) — desert fără margini → stradă de oraș
- [03_alpin.md](03_alpin.md) — zăpadă în două regimuri, urme ca semnalizare
- [04_coasta.md](04_coasta.md) — marea ca pedeapsă, parapet ca punctuație
- [05_jungla_ruine.md](05_jungla_ruine.md) — ruine ca și carosabil, cascadă-hazard-fals

## Cele cinci lucruri de furat, în ordinea raportului efect/efort

1. **Fulgerul** (01) — o suprapunere albă full-screen + lumină ambientală mai
   joasă. Aproape gratis, impact enorm, intră în bugetul mobil.
2. **Hazardul fals** (05, cascada) — arată letal, costă zero. Creează
   învățare. Nu cere mecanică nouă.
3. **Schimbarea de regim de suprafață** (02) — 55 s de nisip fără margini,
   apoi 12 s de bulevard. Personalitate de pistă fără cod nou.
4. **Parapetul ca punctuație** (04) — nu ca regulă. Pus unde nu vor să cazi,
   scos unde vor.
5. **Ruina ca și carosabil** (05) — cel mai puternic, și singurul care ne
   costă muncă reală de coliziune.

## Ce am confirmat despre propriile decizii

- **Turbo ≈ +65% viteză.** Al nostru trebuie să mute acul la fel de mult.
- **Tur de 65–80 s.** Pistele noastre sunt dimensionate corect.
- **Cădere/distrugere ≈ 2 s + repornire din stând ≈ 2 poziții.** Țintă de
  calibrare pentru pedepsele noastre.
- **Trenul lor costă 14 s din 70.** Prea mult pentru 2-3 tururi. Echivalentul
  nostru ar fi 4–6 s — și obligatoriu cu rută de ocolire.

## Ce nu se poate afla din cadre statice

Cât grip are fiecare suprafață, cât airtime dă o rampă, dacă podul suspendat
se leagănă, dacă bolovanii de gheață de pe pista alpină cad sau stau. Pentru
astea e nevoie de filmare țintită pe porțiunea respectivă, la viteză mică,
sau de descrierea ta de la volan.
