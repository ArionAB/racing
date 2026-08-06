# Brief asset — <Nume citibil> (`<nume_fisier>.glb`)

> **Sablonul de brief.** Pana acum `water_tower.md` era sablonul *prin
> conventie* — o spunea singur la linia 75 („Daca turnul trece, asta e
> sablonul"). Aici e ca fisier, cu tabelul de `u` pre-calculat, ca niciun brief
> sa nu-l mai recalculeze de mana.
>
> Copiaza fisierul, completeaza cele 12 sectiuni, sterge notele in citat.

Brief auto-continut pentru un agent Blender (ex. Blender MCP). Nu presupune
acces la restul repo-ului — tot contractul e aici. Sursele din care e derivat:
[style_bible.md](../style_bible.md) (estetica) + [blender_export.md](../blender_export.md)
(pipeline) + [scripts/palette.gd](../../scripts/palette.gd) (indici de sloturi).

Sursa reproductibila: [tools/blender/build_<nume>.py](../../tools/blender/build_<nume>.py).

> **Prompt de dat agentului** — de la linia orizontala de mai jos in jos e
> paste-ready. Restul paginii sunt note pentru noi.

---

## 1. Ce construiesti

Construieste <ce>, low-poly si stilizat, pentru un joc de curse cu masinute de
jucarie in stil diorama de desert (ton *Art of Rally* — macheta de masa, NU
foto-realist). Rezultat: un `.glb` care intra intr-o lume cu un singur material
partajat.

## 2. Rolul lui in cadru

> Sectiunea asta decide toate celelalte. Un landmark inalt si subtire, un
> obstacol pe care il lovesti, un filler de margine si un hero de fundal au
> nevoie de decizii diferite la fiecare paragraf de mai jos. Daca nu poti scrie
> propozitia asta, brieful nu e gata.

<De la ce distanta se vede? Ce rupe in silueta? Care e testul care spune ca a
reusit?>

## 3. Forma si dimensiuni

Unitate: 1 = 1 m; masina de referinta = 4.2 m.

- <cota> <de ce atat>
- ...

> Ancoreaza fata de ceva construit deja, nu in abstract: „mai inalt decat moara
> (10.1 m)" e o cota verificabila, „impunator" nu e.

## 4. Orientare

Fata privește spre **-Z in Godot**, adica spre **+Y in Blender** — exportatorul
glTF face `(x, y, z) -> (x, z, -y)`, deci **Blender +Y devine Godot -Z**.

## 5. Culoare — FARA texturi proprii

UV -> sloturi dintr-un atlas de paleta (32 sloturi orizontale). Fiecare fata isi
colapseaza toate UV-urile pe **un singur punct**, centrul slotului:
`u = (slot + 0.5) / 32`, `v = 0.5`.

**Sloturile legale sunt doar 0-13.** 14-16 sunt accente rezervate masinilor
(style_bible §1: masinile raman singurele suprafete saturate din cadru), iar
**17-31 se randeaza magenta in joc** — atlasul le lasa asa intentionat, ca o
greseala de UV sa sara in ochi. `verify_glb.py` pica pe oricare dintre ele.

| slot | nume | **u** | hex | rol |
|---|---|---|---|---|
| 0 | `sand_light` | **0.015625** | `#E8C88B` | nisip in soare, varfuri de faleza |
| 1 | `sand_mid` | **0.046875** | `#D8A86A` | majoritatea terenului |
| 2 | `sand_shadow` | **0.078125** | `#A97A4A` | nisip umbrit, tenta de AO |
| 3 | `rock_light` | **0.109375** | `#C79664` | fete de stanca |
| 4 | `rock_dark` | **0.140625** | `#7E5B3A` | interior de faleza, crapaturi |
| 5 | `asphalt` | **0.171875** | `#4B4B4D` | sosea asfaltata (drumurile nepavate iau nisipul) |
| 6 | `asphalt_edge` | **0.203125** | `#696765` | margini tocite |
| 7 | `kerb_red` | **0.234375** | `#B74A3A` | borduri, marcaje, accente rosii |
| 8 | `concrete` | **0.265625** | `#C8BEAC` | pod, fundatii; cel mai deschis NEUTRU |
| 9 | `wood_weathered` | **0.296875** | `#8A6947` | scanduri, garduri |
| 10 | `rust_metal` | **0.328125** | `#915535` | butoaie, moara, turn de apa, schelete |
| 11 | `painted_metal` | **0.359375** | `#7E96A8` | containere, ornamente |
| 12 | `cactus_green` | **0.390625** | `#617A43` | cactusi, tufe |
| 13 | `dry_vegetation` | **0.421875** | `#AFA25E` | smocuri de iarba |

> Doua note care s-au platit deja o data fiecare:
> **`painted_metal` (11) se citeste RECE pe nisip** — vezi
> `build_route66.py:36-38`. **`concrete` (8) e singurul deschis neutru**, deci
> el se decupeaza si pe cer, si pe nisip; `sand_light` (0) se topeste in teren.

Nu e nevoie sa incarci vreo imagine in Blender; conteaza doar coordonata UV.
Materialul e inlocuit oricum la runtime de `Palette.apply_world_material()`.

## 6. Vertex colors = AO copt

Grayscale, se inmulteste peste culoare in engine. 1.0 = neatins, ~0.5 = adanc.
**Fara el prop-ul e o pata de culoare plata** — nu e optional.

- Gradient vertical: <cat de tare>. Turnuri si cladiri: 0.55 jos. **Pereti plati:
  0.72** — n-au ce sa-si ocluzeze la baza, iar un gradient tare le fura tocmai
  luminozitatea pentru care exista.
- Intuneca unde se ocluza: <unde>.
- Esantioane: 32 ajung pe piese mici; **64 pe suprafete continue mari**, unde la
  32 zgomotul de raycast se vede ca stropi.

## 7. Scara, origine, bevel

- Origine la **baza obiectului, centrata in XZ** (`finish(origin="base")`).
  Exceptie: piese asimetrice a caror origine trebuie sa cada pe o axa anume —
  `origin="base_axis"`.
- Bevel consistent: **prop 0.04 · cladiri 0.08 · stanci 0.15** m.

## 8. Buget de triunghiuri

**<N> triunghiuri**, masurat dupa bevel.

> Bevel-ul la 0.05/30° multiplica cu **~3.7x** (masurat pe toate ajutoarele din
> `build_helpers_demo.py`). Deci bugetul brut util e <N>/3.7 — un landmark de 900
> are loc pentru ~240 brute, adica vreo 20 de cutii. Planifica-ti piesele de la
> cifra aia, nu de la <N>.

Fara suruburi, balustrade subtiri sau detaliu de frecventa inalta: se pierde la
60 km/h si transforma silueta in zgomot (style_bible §3).

## 9. Export

- glTF Binary **(.glb)**, un fisier, nume `<nume_fisier>.glb`, nod
  `<NumeNod>`.
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fara camere, lumini sau
  texturi incorporate.
- **Apply Modifiers: ON** (bevel-ul sa fie in geometrie). Y-up: implicit.
- Daca fisierul contine mai multe variante, ele trebuie sa fie **copii directi ai
  radacinii**, exportate la origine — vezi §"GLB-uri cu variante" din
  [blender_export.md](../blender_export.md).

---

## 10. Note pentru noi (nu fac parte din prompt)

**Masurat:** <N> triunghiuri din <buget>. Verdict `verify_glb.py`: **OK**.
bbox <x> × <y> × <z> m.

```
python tools/blender/verify_glb.py assets/models/<nume>.glb <buget>
```

![<ce arata>](img/<nume>_<unghi>.png)

## 11. Abateri de la brieful original si de ce

> Sectiunea care nu se sare. Tiparul e cel din `build_gas_station.py:18-20`:
> fiecare compromis se justifica impotriva unei sectiuni din `style_bible.md`,
> intr-un comentariu la linia respectiva DIN COD, si se rezuma aici.

- **<ce am schimbat>.** <de ce, cu numarul sectiunii din style bible>

## 12. Dependente si compozitie

- Ajutoare din `dio_lib` folosite: <care>.
- Cu ce se leaga in lume: <ce landmark e langa, la ce distanta, ce anunta>.
  style_bible §7 cere un landmark dominant la fiecare 4-6 secunde.
