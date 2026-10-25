# Garaj v2 — brieful comun al constructorului de masina

> Pentru agentii care construiesc cate o masina a garajului v2 in Blender,
> headless, din repo. Partea specifica (ce masina, cote, fisiere) vine in
> promptul agentului. Contextul: `garaj_prompturi_chatgpt.md` §5.

## Ce faci

Construiesti UN vehicul low-poly „jucarie" dupa foaia lui de concept
(`docs/asset_briefs/img/vehicles/concept_<x>.jpeg`: 3/4 mare sus, iar jos
lateral / fata / sus ortografic), ca script Python reproductibil care
exporta un GLB. Tinta e ca **silueta si blocurile de culoare** sa se citeasca
la fel ca in foaie, din toate cele 4 vederi.

## Unde lucrezi — reguli tari

- Worktree: `D:/GameDev/wt-garaj-v2` (ramura `garaj/v2-buggy`). Alti doi
  constructori lucreaza IN ACELASI worktree, pe alte masini.
- **Creezi doar fisierele tale:** `tools/blender/build_<x>.py`, GLB-ul tinta,
  si capturile `snapshots/garaj_v2/<nume>_*.png`. **NU editezi** nimic altceva:
  nici `toy_driver_parts.py`, nici `garage_v2_parts.py`, nici `.tres`, nici
  documente. Daca iti lipseste ceva din ele, scrie functia local in scriptul
  tau si spune in raport.
- **Nu faci commit, nu faci stash, nu schimbi ramura.** Coordonatorul comite.
- Nu porni Godot (captura din joc o face coordonatorul).

## Sablonul

Citeste intai, integral: `tools/blender/build_buggy_v2.py` (exemplul complet,
deja aprobat), `tools/blender/garage_v2_parts.py` (primitivele comune) si
`tools/blender/toy_driver_parts.py` (contractul de roti/lampi/export). Copiaza
structura buggy-ului: constante de contract sus, cate o functie per grup de
piese, `export_vehicle(...)`, apoi `preview_sheet(...)`.

Primitive: `Builder` din dio_lib (`box`, `beam`, `cylinder` pe axe,
`torus`, `ladder`, `prism`, `sweep`), plus `loft` / `mirror_poly` /
`u_section` / `tube` / `rod` / `toy_wheel_fn` / `steering_wheel` din
garage_v2_parts. **Prefera `loft` pentru caroserii** (sectiuni (x, z) la cote y,
cu tesituri ca in foaie) — asta deosebeste v2 de cutiile stivuite din v1
(`build_open_garage.py`, NU il copia ca forma).

### Ce a respins coordonatorul deja (nu repeta)

- **Caroserie din cutii.** Corpul principal (flancuri, capota, portbagaj,
  cabina, cutia) e un `loft` cu sectiuni tesite: prag, flanc, UMAR inclinat
  spre interior (~30°), suprafata de sus. Cutiile raman pentru piese mici
  (bare, grile, faruri, scaune, motor).
- **Aripi ca blocuri lipite deasupra rotilor.** Bombarea peste roti vine din
  loft (statii mai late la y-ul axelor) sau dintr-un arc tesit integrat.
- **Parbriz-panou.** Parbrizul din foi e jos (~0.3 m), inclinat ~30°, fara
  rama neagra groasa.
- **„Silueta se potriveste" spus prea devreme.** Declari potrivire doar daca
  fiecare bloc important are aceeasi FORMA in toate cele 4 vederi, nu doar
  aceeasi culoare si pozitie.

## Conventii (contract cu jocul — nu le schimba)

- Unitati: metri. Blender: **fata masinii spre -Y**, stanga masinii = **+X**,
  Z sus. Originea ansamblului la sol (cel mai jos punct al rotilor z=0).
- Roti: prin `export_vehicle(prefix, body_fn, wheel_spec, "vehicles/<f>.glb",
  SEAT, bevel=0.03, bevel_angle=65.0)` cu
  `wheel_spec = dict(radius=, width=, half_track=, y_front=, y_rear=,
  wheel_factory=toy_wheel_fn, wheel_bevel=0.0)` (optional `radius_rear`,
  `width_rear`, `half_track_rear`). Latimea peste roti = 2*half_track + width.
- Lampi: farurile cu `lamp_head(...)` / `lamp_head_round(...)`, stopurile cu
  `lamp_tail(...)` — noduri separate, jocul le coloreaza si le aprinde. Fara
  ele masina n-are lumini.
- `prefix` = cel din prompt (numele nodurilor: `<Prefix>_Body`,
  `<Prefix>_Wheel_Front_Left` etc.).
- **Raza rotii din fata** e cea FIZICA (jocul o citeste din prima roata) — nu
  o schimba fata de prompt.

## Culori — doar sloturile astea

| culoarea din foaie | slot (constanta) |
|---|---|
| rosu masina #E54839 | `CAR_RED` |
| albastru masina #2C82E8 | `CAR_BLUE` |
| galben masina #F2D03C | `CAR_YELLOW` |
| alb #E9F2F0 | `FOAM_WHITE` |
| aproape negru #55535A (anvelope, cusca, bare, grile, sasiu) | `VOLCANIC_BLACK` |
| gri deschis #B8B4AC (jante, metal, scari, brate) | `MARBLE_GREY` (= `RIM`) |
| maro inchis #4A3526 (scaune, bene, interior) | `LOG_DARK` |
| turcoaz sticla #7FC4C9 (parbriz, geamuri) | `ICE_TURQUOISE` |
| verde #3F7A3C | `TROPICAL_GREEN` |
| portocaliu #E8622D (accente mici) | `LAVA_ORANGE` |
| gri-albastru #7692A8 (cisterne, echipament) | `PAINTED` |
| rugina #91461E | `RUST` |

Fara texturi, fara text. Un bloc de culoare = fete cu slotul lui.

## Doua capcane deja platite (la buggy)

1. **Figurina soferului are 1.25 m de la sezut la varful castii**, iar
   picioarele coboara **0.41 m sub sezut** (pantofii ies prin podea daca
   sezutul e mai jos de podea + 0.41 — sau ascunde-i intr-un volum solid).
   Orice acoperis, traversa sau girofar care trece PESTE capul soferului (in
   proiectie de sus peste casca) sta cu >= 5 cm peste casca: varful castii =
   `SEAT.z + 1.25`. Un arc / firma / rampa IN SPATELE capului NU trebuie sa
   treaca peste casca — poate sta la nivelul ei, ca in foi (taxiul a iesit cu
   2.28 m din confuzia asta). Inaltimile din prompt sunt minime doar pentru
   piesele de deasupra capului. Mainile ajung la volan la `y = SEAT.y - 0.48`,
   `z = SEAT.z + 0.52` (`steering_wheel(b, SEAT)` le pune acolo). Soferul pe
   stanga = `SEAT.x` pozitiv (~0.40); pe mijloc = 0.
2. **Bugetul:** corpul se exporta cu `bevel_angle=65` (doar cutiile se tesesc);
   tuburile mici cu `segments=6`. Tinta: **TOTAL <= 6500 tri** (buggy-ul are
   6322). Daca treci, taie intai piese mici repetate, nu silueta.

## Bucla de lucru

```bash
cd D:/GameDev/wt-garaj-v2
D:/Blender/blender.exe --background --factory-startup \
    --python tools/blender/run_build.py -- build_<x>.py 2>&1 | grep -E "tris|gabarit|driver_seat|GLB:|Error|Traceback|line "
python tools/blender/compare_concept.py <nume> concept_<x>.jpeg
```
Apoi **deschide plansa** `snapshots/garaj_v2/<nume>_vs_concept.png` (Read) si
compara foaia (sus) cu randarile tale (jos), vedere cu vedere. Scrie-ti cele
3 cele mai mari diferente de SILUETA/proportie/bloc de culoare si corecteaza-le.
Repeta. **Maximum 5 runde**; opreste-te mai devreme cand diferentele ramase sunt
de detaliu, nu de silueta. Vederile ortografice ale foii NU sunt garantat la
aceeasi scara intre ele — cotele vin din prompt, proportiile din fiecare vedere.

Pentru detalii poti decupa/mari foaia cu PIL (python de sistem) intr-un fisier
din scratchpad-ul tau, nu in repo.

La final:
```bash
python tools/blender/verify_glb.py assets/models/vehicles/<f>.glb 6500 --origin=assembly
```
Avertismentele „slot 14/15/16 ILEGAL in decor" si „ansamblu nu atinge solul /
cel mai jos punct Y=0.0xx" sunt asteptate (masina nu e decor). Orice altceva,
repara.

## Raportul (mesajul tau final, scurt)

- fisierele create;
- liniile `gabarit: ...` si `driver_seat = ...` din ultima rulare, si TOTAL tri;
- `wheel_spec` final (raza/latime/ecartament/ampatament);
- abaterile de la cotele din prompt si de ce;
- ce n-ai reusit sa potrivesti cu foaia (sincer — coordonatorul decide);
- calea plansei finale `_vs_concept.png`.
