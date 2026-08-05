# Pipeline assets Blender → Godot (diorámă)

Contractul pe care trebuie să-l respecte orice model generat în Blender ca să
intre în lume cu **un singur material** (few draw calls) și în stilul corect.
Vezi paleta și dimensiunile în [style_bible.md](style_bible.md).

## Ce trebuie să conțină GLB-ul

1. **UV1 → sloturi de paletă. Assets-urile nu aduc texturi proprii.**
   Nu se pictează texturi per asset. Fiecare față primește un UV care nimerește
   **centrul** slotului de culoare din atlas
   (`assets/textures/palette_atlas.png`, 32 sloturi).

   > **Detaliul de suprafață NU vine de aici.** Un UV colapsat are derivată zero,
   > deci fața citește un singur texel — oricât de texturat ar fi slotul. Asta a
   > fost multă vreme cauza (măsurată) a aspectului plat: fața de faleză avea
   > deviație de luminanță 0.76, referința ~40.
   >
   > Detaliul vine la runtime dintr-un **strat triplanar partajat**
   > (`Palette.world_material()`, `detail_albedo` + `uv2_triplanar`), care își
   > calculează coordonatele din poziția și normala vârfului — **nu citește
   > niciun atribut UV2**. Deci regula de aici rămâne valabilă exact așa cum e
   > scrisă, iar assets-urile nu trebuie modificate.
   >
   > **De ce nu unwrap real:** ar cere texturi per asset sau un al doilea atlas,
   > deci mai multe materiale — exact ce evită tot contractul ăsta. Garda din
   > `tools/probe_decor.gd` numără materiale tocmai pentru că draw call-urile,
   > nu triunghiurile, sunt constrângerea pe mobil.
   UV-ul slotului `i` este:
   ```
   u = (i + 0.5) / 32     v = 0.5
   ```
   Indicii sunt cei din [scripts/palette.gd](../scripts/palette.gd)
   (ex. rust_metal = 10 → u = 0.328125, wood_weathered = 9 → u = 0.296875).
   În Blender: după modelare, se selectează fețele per material logic și li se
   colapsează UV-ul pe punctul respectiv (toate vârfurile feței în același UV).

2. **Vertex colors = AO copt (grayscale).**
   Un strat de Color Attribute pe vârfuri, gri, care se **înmulțește** peste
   culoarea din atlas în Godot (`vertex_color_use_as_albedo`). 1.0 = neatins,
   ~0.5 = adânc/umbrit. Minim: gradient vertical (jos mai închis) + întunecare
   în crăpături/sub streașini. Ideal: bake AO real. Fără el, prop-ul iese plat.

3. **Scară reală (metri), origine la bază.**
   1 unitate Blender = 1 m. Originea (pivotul) la baza obiectului, centrată în XZ,
   ca `global_position` să-l așeze direct pe sol. Axă: Godot e Y-up, -Z înainte;
   la export GLB Blender convertește automat (lasă setările implicite Y-up).

4. **Buget de triunghiuri** per clasă — vezi style_bible §3. Fără detaliu de
   frecvență înaltă (șuruburi, balustrade subțiri): se pierde la viteză și costă.

5. **Bevel consistent** (prop 0.04 / clădiri 0.08 / stânci 0.15 m) — semnătura
   care ține totul în aceeași familie.

## GLB-uri cu variante (mai multe obiecte intr-un fisier)

Conventia asta exista doar in `cliff_wall.md` si in GDScript. Scrisa aici, o data.

**Nume:** familie PascalCase + `_` + eticheta.

| tipar | cand | exemplu real |
|---|---|---|
| litera | frati puri, aceeasi clasa | `Cactus_A/B/C`, `Cliff_A..F` |
| clasa de marime + index | cand marimea conteaza in gameplay | `Cluster_S1/S2/M1/M2/L1` |
| doua familii intr-un fisier | acelasi rol, alta silueta | `Butte_A/B/C` + `Mesa_A/B` in `butte.glb` |

**Sufixul `_col`** = proxy de coliziune pentru nodul vizual cu aceeasi tulpina:
`Cliff_A` <-> `Cliff_A_col`.

Trei reguli care se sparg in tacere daca le incalci:

1. **Variantele se exporta la origine.** Scripturile le decaleaza pe X ca sa fie
   lizibile in viewport, apoi le pun la zero inainte de `export_glb` si le
   redecaleaza dupa — vezi [build_cactus.py:80-87](../tools/blender/build_cactus.py).
   Godot anuleaza oricum offsetul (`track.gd:537`), dar un GLB cu variante
   decalate produce coliziuni asezate gresit.

2. **Variantele trebuie sa fie copii DIRECTI ai radacinii GLB.** Godot le alege
   cu `child.name == node_name`, scanand **doar copiii directi**, in patru locuri
   independente: [track.gd:532](../scenes/tracks/track.gd),
   [track_cliffs.gd:272](../scenes/tracks/track_cliffs.gd),
   [track_decor.gd:301](../scenes/tracks/track_decor.gd) si
   [rockfall_hazard.gd:128](../scenes/hazards/rockfall_hazard.gd).
   Un parinte gol le sparge pe toate patru simultan — si fiecare punct de
   incarcare are fallback procedural, deci **nu crapa nimic**: porneste in tacere
   geometria de rezerva, testele raman verzi, iar diferenta se vede abia la
   urmatorul screenshot.

3. **Numele trebuie sa fie stabile intre rebuild-uri.** De-aia fiecare script
   incepe cu `clear_built(prefix)`: fara el mesh-urile orfane raman in fisier,
   Blender adauga `.001` la nume (`Cactus_A` -> `Cactus_A.001`) si cautarile din
   Godot esueaza — tot in tacere, tot cu fallback.

## Verificare

```
python tools/blender/verify_glb.py assets/models/<nume>.glb <buget>
```

Verifica UV-urile pe centre de slot, **legalitatea sloturilor** (doar 0-13:
14-16 sunt accente de masina, 17-31 se randeaza magenta in joc), `COLOR_0`,
baza la Y=0 si centrarea in XZ. Cu `--front=-Z` verifica in plus ca planul
dominant al modelului e cel cerut — prinde modelul rotit 90°.

**Piesele cu textura de clasa se recunosc singure.** Un nod pe atlas are TOATE
UV-urile colapsate exact pe centre de slot; un nod cu textura de clasa are
proiectie cubica, deci UV-uri continue care nimeresc un centru doar din
intamplare (masurat: 0-1%). Sonda decide din raportul asta si raporteaza
`uv=cub` in loc de lista de sloturi — pe ele verificarea se inverseaza (UV-urile
trebuie sa ACOPERE o suprafata, altfel textura citeste un texel, style_bible
§13.6). `--class-parts=Nod1,Nod2` ramane, dar acum e o **afirmatie**: piesele
numite sunt obligate sa fie pe clasa, si sonda pica daca ajung pe atlas.

Un nod care iese intre cele doua tipare — parte pe centre, parte continue — nu e
clasificat in niciunul: primeste verdict `MIXTE` si pica. Acolo stau greselile
adevarate (un unwrap ramas peste UV-urile de atlas), si o euristica ce le-ar
inghiti ca „textura de clasa" ar goli sonda de rost.

Semnul (fata vs spate) ramane avertisment, nu eroare, si asta e o limitare
reala: la ecranul de drive-in scheletul sta in spate, deci spatele are mai multa
arie decat fata; la benzinarie pompele stau in fata, deci exact invers. Aceeasi
masuratoare ar da verdicte opuse pe doua assets corecte.

## Export GLB (setări)

- Format: **glTF Binary (.glb)**, un fișier.
- Include: Selected Objects (sau tot), **Mesh**, **UVs**, **Vertex Colors**,
  **Normals**. Fără camere/lumini. Fără materiale complexe (le înlocuim în Godot).
- Apply Modifiers: ON (bevel etc. să fie în geometrie).
- Y-up: ON (implicit).
- Destinație: `res://assets/models/<nume>.glb`.

## În Godot

La instanțiere, prop-ului i se pune materialul comun:
```gdscript
var glb := (load("res://assets/models/barrel.glb") as PackedScene).instantiate()
Palette.apply_world_material(glb)   # înlocuiește materialele cu cel partajat
```
UV-urile aduse din Blender arată deja spre atlas, deci culoarea iese corectă, iar
toate prop-urile împart un singur material.

## Când merită Blender vs. GDScript

- **GDScript** (ca [scenes/props/barrel.gd](../scenes/props/barrel.gd)): forme
  simple de revoluție/cutie — butoi, ladă, cauciuc, gard, cactus. Rapid, validabil
  headless, zero dependențe. Recomandat pentru filler.
- **Blender**: piese "hero" cu caracter — benzinărie, moară, turn de apă, arcade
  de piatră. Detaliu și siluetă pe care GDScript nu le scoate practic.
