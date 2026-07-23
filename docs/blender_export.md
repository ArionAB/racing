# Pipeline assets Blender → Godot (diorámă)

Contractul pe care trebuie să-l respecte orice model generat în Blender ca să
intre în lume cu **un singur material** (few draw calls) și în stilul corect.
Vezi paleta și dimensiunile în [style_bible.md](style_bible.md).

## Ce trebuie să conțină GLB-ul

1. **UV → sloturi de paletă, nu texturi proprii.**
   Nu se pictează texturi. Fiecare față primește un UV care nimerește **centrul**
   slotului de culoare din atlas (`assets/textures/palette_atlas.png`, 32 sloturi).
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
