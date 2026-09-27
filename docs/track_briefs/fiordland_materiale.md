# Fiordland (Track16) — valul de materiale pe kit

> 27 sep 2026, ramura `fiord/materiale`. Companion la `fiordland_stare_poi.md`
> (acela e despre constructia POI-urilor; asta e despre CE are textura de clasa
> si CE nu, pe tot kitul). Tiparul: `serengeti_materiale.md`. Trei loturi in
> paralel (A fagi, B stanca, C lemn), integrate si verificate aici.

## Bilant

- Garda de materiale (`tools/probe_decor.gd`, toate pistele): **Track16 28 -> 30 / 38**.
  Celelalte piste identice cu linia de baza (01 23, 08 21, 09 26, 10 23, 11 32,
  12 32, 13 21, 14 31, 15 16) — nicio coliziune de nume.
- Zero PNG nou: toate clasele noi refolosesc dale deja in VRAM (`bark`,
  `acacia_canopy`, `wood`) cu tenta calculata, sau clasa pistei `wet_gneiss`.
- Clase noi: `bark_beech`, `beech_canopy` (+2), `wet_wood` (+1 teoretic; cifra
  totala a iesit 30, nu 31 — tabliera podetului avea deja un material propriu,
  inlocuit acum).
- Piese de kit clasate pe pista incarcata: 874 noduri de fag, 287 `guard_rock`,
  266 `moss_boulder_b`, 37 `driftwood`, tabliera podetului Chasm.

## Clasate

| piesa / nod | instante | clasa | de ce (cifra) |
|---|---:|---|---|
| `beech_a/b/c` · `Trunk*` | 386 | `bark_beech` | 100% slot 28 LOG_DARK. Dala `bark` (171.7,140.7,107.7) -> LOG_DARK (74,53,38): tenta (0.431, 0.377, 0.353), toate < 1, fara lift. Scara 0.77 ca `bark`. |
| `beech_a/b/c` · `Crown*` | 386 | `beech_canopy` | 56.3% TROPICAL_GREEN + 43.7% LOG_DARK pe ACELASI interval de y (nu e trunchi separat, e umbrirea coroanei). Dala `acacia_canopy` -> media pe arie (67.8,91.8,50.4): tenta (0.764, 0.849, 0.898). Pe captura: coroanele citesc frunzis verde-negru (brief §4) in loc de verde lacuit. |
| `beech_dead` · `Beech_Dead` | 89 | `bark_beech` | 94.4% slot 28 + 5.6% slot 12 (muschi) — accent sub prag, tot nodul. |
| `rata_tree` · `Rata_Accente` | 13 | `beech_canopy` | ruptura noua: florile (slot 7, KERB_RED, 28.2%) raman pe CORP pe atlas, frunzisul (21+28) trece in `_Accente` (`ACCENT_HOLDS_CLASS`). |
| `guard_rock` · `Rock_002` | 287 | `wet_gneiss` | corp 74.0% slot 29 y 0.00-0.46, capac muschi 26.0% slot 21 y 0.44-0.58: suprapunere 0.02 m (3.4% din h) = ruptura CURATA. Corpul ia gneisul, capacul ramane pictat. |
| `moss_boulder_b` (reuse MP) · `Moss_Boulder_B` | 266 | `wet_gneiss` | dupa `SLOT_REMAP_BY_THEME`: corp 20 y 0.00-1.06, capac 21 y 0.92-1.96, suprapunere 7.2%. Ruptura NOUA scopata pe TEMA (`SPLIT_MODELS_BY_THEME`/`ACCENT_SPLIT_BY_THEME`, call_deferred dupa remap, inainte de clase) — pe Track15 acelasi GLB ramane intreg (verificat). +0 materiale. |
| `driftwood` · `Driftwood` | 37 | `wet_wood` | 100% slot 9. Dala `wood` (124,99,72) -> 65% din WOOD_WEATHERED (brief: "ud = mai inchis"): tenta (0.686, 0.604, 0.471). |
| tabliera podetului Chasm (`LiftBridgeHazard`, `deck_material_class`) | 1 | `wet_wood` | suprafata de DRUM vazuta de la 1-3 m; era culoare plata. Mecanism opt-in per hazard — tabliera de pe Track15 neatinsa. |

**`wet_wood`, nu tenta pe `wood`:** lotul C pusese tenta direct pe clasa `wood`,
cu comentariul ca „n-avea niciun consumator". Are: moara si lazile (Dunele),
barca sabani (Okinawa), portalul si vagonetii minei (`track.gd`). Tenta globala
le-ar fi intunecat pe toate cu 35% — iar garda de materiale NU vede asta
(numara materiale, nu culori). Mutata pe clasa separata la integrare.

## Refuzate, cu cifra

| piesa | motiv |
|---|---|
| `moss_boulder_a` | capac 0.38-0.74 peste corp 0.00-0.68: suprapunere 40.5% din h — muschiul coboara printre fete, ruptura ar taia gresit (ca `stirling_ledge.Overhang`). |
| `moss_boulder_c` | suprapunere 0.69 m = 22.5% din h (ca `inca_house_b`). |
| `scree_slab` | 50.8% SAND_SHADOW (sat 0.73) + 49.2% MARBLE_GREY (sat 0.07), y suprapus aproape complet: ecart de saturatie 0.666 > 0.63. Brief §5.1 cere oricum `gravel_wet` (clasa noua, +1). |
| `stirling_ledge` Overhang / Shelf | decizia din 4129c9d8 ramane (27% / 20% muschi, intervale suprapuse). |
| `chasm_bridge_rail` | 100% slot 9, dar balustrada e ingusta — la 3-5 m fibra cade in mipmap. |
| `stump` | 88.7% LOG_DARK + 11.3% muschi, o singura instanta. |
| `wharf` | nu e lemn: 57.2% TROPICAL_GREEN + 41.8% MARBLE_GREY (piatra de chei), are deja remap. |
| `heli_pad` | 76.2% CONCRETE + 23.8% FOAM_WHITE — marcajul alb e accentul. |
| `wooden_pier` (reuse Okinawa) | 17 sloturi, pictat (SAND_LIGHT + FLAMINGO_PINK). |
| `tussock_clump`, `fern_cluster`, `tree_fern` | fire/frunze subtiri: banda ingusta, mipmap. |
| `fiordland_horizon` | benzi de altitudine pictate intentionat (`horizon_class: ""`). |

## Sonde (raman in repo)

- `tools/ProbeFiordFagiClase.tscn -- --track=16` — per model, cate noduri au clasa fagului.
- `tools/ProbeFiordStancaClase.tscn -- --track=16` (si `--track=15`) — `wet_gneiss` per nod + PURITATEA rupturii (sloturile citite prin index; o ruptura lipsa cu clasa pusa pe tot nodul iese `[20,21]`, nu doar „are material").
- `tools/ProbeFiordWood.tscn -- --track=16` — driftwood + tabliera + comutatorul opt-in.
Toate trei au trecut sabotajul (maparea scoasa -> cifra cade la 0).

## Deschis

1. **Bolovanii mari de pe cornisa (POI B) — `moss_boulder_a/c`** raman cu capac
   verde crud (TROPICAL_GREEN pe atlas) pe corp gri plat: cel mai vizibil defect
   de material ramas, in prim-plan la f0.12. Rezolvarea nu e o clasa, e
   re-exportul capacului ca nod separat (sau un GLB fiordland propriu).
2. **Grohotisul `scree_slab`** (52, POI E) iese portocaliu aprins in captura:
   cere `gravel_wet` (sursa noua) sau un remap de slot pe tema (2 -> 20).
3. **Scandurile palide de la capatul podetului Chasm** (vizibile si pe main,
   neatinse aici) nu sunt tabliera — de identificat.
4. Verdictul de la volan al dezvoltatorului pe coroane (verde-negru vs.
   citibilitatea padurii la POI D).
