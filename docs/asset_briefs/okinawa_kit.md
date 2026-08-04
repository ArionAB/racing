# Kit Okinawa — 11 assets din foaia de referinta

Sursa formelor: `assets/okinawa_inspiration/ChatGPT Image Aug 2, 2026, 07_38_24 PM.png`
(foaia cu TETRAPODS / SHISA GUARDIANS / PALMS AND TREES / CORAL ROCKS / ROADSIDE).

Spre deosebire de briefurile de alaturi, asta **nu e o comanda pentru un agent
Blender extern**: modelele exista deja, construite din `tools/blender/build_*.py`.
Documentul e CONTRACTUL de integrare — ce nume de noduri cauta Godot si ce clasa
de material primeste fiecare. Fara el, integrarea porneste tacut pe fallback
(fiecare punct de incarcare e pazit de `ResourceLoader.exists()`, deci un nume
gresit nu crapa nimic — se vede abia la urmatorul screenshot).

![lotul complet](img/okinawa_kit_lot.png)

## Ce contine

| fisier | noduri | cota | tris | referinta |
|---|---|---|---|---|
| `tetrapod.glb` | `Tetrapod_04` | 3.45 m | 788 | TETRAPOD_04 (3.5 m) |
| `coral_rock.glb` | `CoralRock_04`, `CoralRock_06` | 1.61 / 2.65 m | 1680 | CORAL_ROCK_04/06 |
| `coconut_palm.glb` | `Palm_Bark`, `Palm_Fronds` | 6.70 m | 1742 | COCONUT_PALM_01 (7.0 m) |
| `beach_palm_bent.glb` | `BentPalm_Bark`, `BentPalm_Fronds` | 2.80 m | 1406 | BEACH_PALM_BENT (3.0 m) |
| `pandanus.glb` | `Pandanus_Bark`, `Pandanus_Leaves` | 2.40 m | 2068 | PANDANUS_ADAN (2.5 m) |
| `banyan.glb` | `Banyan_Bark`, `Banyan_Canopy` | 5.56 m | 4852 | BANYAN_GAJUMARU (6.0 m) |
| `hibiscus_bush.glb` | `Hibiscus` | 0.86 m | 788 | HIBISCUS_BUSH (1.0 m) |
| `stone_gate_torii.glb` | `Torii_Stone`, `Torii_Roof` | 4.39 m | 942 | STONE_GATE_TORII (4.5 m) |
| `lighthouse.glb` | `Lighthouse_Stone/White/Red/Metal` | 9.11 m | 2654 | LIGHTHOUSE (9.0 m) |
| `shisa.glb` | `Shisa_Base`, `Shisa_Stone`, `Shisa_Detail` | 1.81 m | 4640 | SHISA_OPEN_MOUTH (1.8 m) |

Total lot: **21.560 de triunghiuri** pentru cate o instanta din fiecare — sub 8%
din pragul de 300k al unei piste (`tools/probe_decor.gd`).

Cotele sunt masurate pe GLB, nu declarate. Unde difera de referinta cu peste 5%
(banyan 5.56 fata de 6.0) e pentru ca inaltimea vine din pozitia bulgarilor de
coroana, iar a o forta ar fi insemnat o coroana subtire pe un trunchi lung.

## Mapare de materiale (asta se scrie in Godot)

```gdscript
Palette.apply_class_materials(glb, {
    # tetrapod.glb
    "Tetrapod_04":      "concrete",
    # coral_rock.glb — TRIPLANAR de lume: placile vecine isi continua tiparul
    "CoralRock":        Palette.TRI_PREFIX + "coral_rock",
    # vegetatie: scoarta texturata, frunzisul pe atlas (nemapat = atlas)
    "Palm_Bark":        "bark",
    "BentPalm_Bark":    "bark",
    "Pandanus_Bark":    "bark",
    "Banyan_Bark":      "bark",
    # piatra
    "Torii_Stone":      "stone_wall",
    "Torii_Roof":       "roof_tiles",
    "Lighthouse_Stone": "stone_wall",
    "Lighthouse_White": "plaster",
    "Shisa_Base":       "stone_wall",
    "Shisa_Stone":      "concrete",
})
```

Nodurile nemapate (`*_Fronds`, `*_Leaves`, `Banyan_Canopy`, `Hibiscus`,
`Lighthouse_Red`, `Lighthouse_Metal`, `Shisa_Detail`) raman pe materialul lumii
— au UV-uri colapsate pe sloturi de paleta si sunt corecte asa.

**Doua clase noi**, generate de `tools/process_class_textures.gd` din surse
PolyHaven CC0 (`assets/textures/classes/src/`):

- **`coral_rock`** ← `coral_fort_wall_03`, ancora `VOLCANIC_BLACK`, triplanar la
  0.85 (o repetitie la 1.18 m). Chiar zidaria de calcar coraligen a castelelor
  din Okinawa.
- **`bark`** ← `palm_tree_bark`, ancora `WOOD_WEATHERED`, UV cubic 1.3 m = scara
  reala a scanarii, deci inelele de cicatrici cad cat trebuie.

Ambele au fost alese prin `tools/measure_texture_src.gd`, nu din miniatura —
tabelele cu candidatii si motivele respingerilor sunt in comentariile din
`process_class_textures.gd`. Restul claselor folosite (`concrete`, `plaster`,
`stone_wall`, `roof_tiles`) existau deja, deci kitul adauga **doua** materiale
la bugetul pistei, nu unsprezece.

## Ce NU are textura, si de ce

Tot frunzisul (frunze de palmier, sabii de pandanus, coroana de banyan, tufa de
hibiscus) ramane pe atlasul de paleta. Nu e o scurtatura: am masurat patru
candidate de frunzis din PolyHaven fata de ancora `TROPICAL_GREEN` si niciuna nu
e frunzis tropical — `forest_leaves_02/03` sunt litiera de padure (maro,
toamna), `leafy_grass` si `sparse_grass` sunt gazon cu frunze uscate. Gradate cu
45% spre verde ies noroi masliniu. Volumul il dau cuta in V a frunzei si AO-ul
copt, care sunt gratis.

## Verificare

```
python tools/blender/verify_glb.py assets/models/tetrapod.glb 900 --class-parts=Tetrapod_04
python tools/blender/verify_glb.py assets/models/coral_rock.glb 1800
python tools/blender/verify_glb.py assets/models/coconut_palm.glb 2000 \
    --class-parts=Palm_Bark --origin=assembly
python tools/blender/verify_glb.py assets/models/beach_palm_bent.glb 1600 \
    --class-parts=BentPalm_Bark --origin=assembly
python tools/blender/verify_glb.py assets/models/pandanus.glb 2400 \
    --class-parts=Pandanus_Bark --origin=assembly
python tools/blender/verify_glb.py assets/models/banyan.glb 5000 \
    --class-parts=Banyan_Bark --origin=assembly
python tools/blender/verify_glb.py assets/models/hibiscus_bush.glb 900
python tools/blender/verify_glb.py assets/models/stone_gate_torii.glb 1200 \
    --class-parts=Torii_Stone,Torii_Roof --origin=assembly
python tools/blender/verify_glb.py assets/models/lighthouse.glb 3000 \
    --class-parts=Lighthouse_Stone,Lighthouse_White --origin=assembly
python tools/blender/verify_glb.py assets/models/shisa.glb 5000 \
    --class-parts=Shisa_Base,Shisa_Stone --origin=assembly
```

Toate zece dau `VERDICT: OK`.

## Regenerare

Blender deschis cu addon-ul MCP pornit, apoi:

```python
P = r"d:/GameDev/ignition-spike/tools/blender"
g = {"__name__": "__main__", "__file__": P + "/dio_lib.py"}
exec(open(P + "/dio_lib.py").read(), g)
for f in ("build_tetrapod.py", "build_coral_rock.py", "build_palms.py",
          "build_pandanus.py", "build_banyan.py", "build_hibiscus.py",
          "build_torii.py", "build_lighthouse.py", "build_shisa.py"):
    exec(open(P + "/" + f).read(), g)
```

Pentru previzualizari (`tools/blender/preview.py`, randare EEVEE cu lumina din
style_bible §5, nu screenshot de viewport):

```python
exec(open(P + "/preview.py").read(), g)
apply_class(bpy.data.objects["Shisa_Stone"], "concrete")   # textura reala, nu atlasul
shot([bpy.data.objects["Shisa_Stone"]], "d:/tmp/shisa.png", azimuth=90.0)
```

## Trei lucruri invatate aici (ca sa nu se reinvete)

1. **`Builder.rock` face CONURI daca il folosesti pentru frunzis.** Construieste
   inele de la baza in sus si inchide cu capac plat — corect pentru ce sta pe
   sol, gresit pentru o masa suspendata. Coroana banyanului a iesit prima data
   noua corturi de circ. `Builder.boulder` (elipsoid inchis) e primitiva
   corecta.
2. **Primul inel al unui `taper_sweep` e perpendicular pe TANGENTA.** Pe un
   trunchi inclinat asta il baga sub sol cu raza x sin(unghi) — 6.5 cm la
   palmierul de plaja, 10 cm la contrafortii banyanului. Reparatia e un stub
   vertical de 15 cm la baza (doua puncte cu acelasi xy), nu o coborare a
   modelului.
3. **`verify_glb --origin=assembly` nu masura nimic** cand toate piesele aveau
   pivot propriu — adica exact tiparul `finish(origin="base_axis")` +
   `obj.location.z = min_z` folosit de la casa de sat incoace. Raporta „niciun
   nod cu mesh" in loc sa verifice. Reparat in acelasi PR; ambele cote de mai
   sus au fost gasite abia dupa.
